"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
/**
 * CalendarCaddy public API (v1).
 *
 * The single backend shared by the iOS app (client #1) and the Muse
 * connector (client #2). Deployed as one HTTPS Cloud Function; routes:
 *
 *   GET  /health
 *   POST /v1/teetimes/search
 *   GET  /v1/friends/looking
 *
 * Auth: Firebase Auth ID token as `Authorization: Bearer <token>`, or the
 * service API key as `X-API-Key` (set CALENDARCADDY_SERVICE_KEY in runtime
 * config) for trusted server-to-server callers like the Muse connector.
 */
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const teetimes_1 = require("./teetimes");
const db = admin.firestore();
class HttpError extends Error {
    constructor(status, message) {
        super(message);
        this.status = status;
        this.name = "HttpError";
    }
}
async function authenticate(req) {
    const serviceKey = process.env.CALENDARCADDY_SERVICE_KEY;
    const apiKey = req.headers["x-api-key"];
    if (serviceKey &&
        typeof apiKey === "string" &&
        apiKey.length > 0 &&
        apiKey === serviceKey) {
        return { uid: null, viaServiceKey: true };
    }
    const auth = req.headers.authorization;
    if (typeof auth === "string" && auth.startsWith("Bearer ")) {
        try {
            const decoded = await admin.auth().verifyIdToken(auth.slice(7));
            return { uid: decoded.uid, viaServiceKey: false };
        }
        catch (_a) {
            // fall through to 401
        }
    }
    throw new HttpError(401, "Unauthorized: pass a Firebase ID token or a valid service API key");
}
// ---------------------------------------------------------------------------
// POST /v1/teetimes/search
// ---------------------------------------------------------------------------
function parseSearchBody(body) {
    const b = (body !== null && body !== void 0 ? body : {});
    const { courses, date, earliestTime, latestTime, players } = b;
    if (!Array.isArray(courses) || courses.length === 0 || courses.length > 20) {
        throw new HttpError(400, "courses must be a non-empty array (max 20)");
    }
    const parsedCourses = courses.map((c, i) => {
        const cc = c;
        if (typeof cc.id !== "string" || typeof cc.name !== "string") {
            throw new HttpError(400, `courses[${i}].id and courses[${i}].name are required`);
        }
        return {
            id: cc.id,
            name: cc.name,
            holes: typeof cc.holes === "number" ? cc.holes : 18,
        };
    });
    if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        throw new HttpError(400, "date must be YYYY-MM-DD");
    }
    const timeRe = /^([01]\d|2[0-3]):[0-5]\d$/;
    if (typeof earliestTime !== "string" || !timeRe.test(earliestTime)) {
        throw new HttpError(400, "earliestTime must be HH:MM (24h)");
    }
    if (typeof latestTime !== "string" || !timeRe.test(latestTime)) {
        throw new HttpError(400, "latestTime must be HH:MM (24h)");
    }
    if (typeof players !== "number" ||
        !Number.isInteger(players) ||
        players < 1 ||
        players > 4) {
        throw new HttpError(400, "players must be an integer from 1 to 4");
    }
    return { courses: parsedCourses, date, earliestTime, latestTime, players };
}
async function handleTeeTimeSearch(req, res) {
    await authenticate(req);
    const search = parseSearchBody(req.body);
    const provider = (0, teetimes_1.teeTimeProvider)();
    const results = await provider.searchTeeTimes(search);
    res.json({
        provider: provider.name,
        searchedAt: new Date().toISOString(),
        results,
    });
}
// ---------------------------------------------------------------------------
// GET /v1/friends/looking
// Friends with a visible "looking" weekend status for the coming weekend.
// ---------------------------------------------------------------------------
const LOOKING_AVAILABILITY = new Set([
    "Looking to Play",
    "Seeking an Additional Player",
]);
function startOfDay(d) {
    const c = new Date(d);
    c.setHours(0, 0, 0, 0);
    return c;
}
async function handleFriendsLooking(req, res) {
    var _a, _b, _c;
    const caller = await authenticate(req);
    // Service-key callers act on behalf of a user they name explicitly.
    let uid = caller.uid;
    if (!uid) {
        const q = req.query.userId;
        if (typeof q !== "string" || q.length === 0) {
            throw new HttpError(400, "userId query param is required for service-key callers");
        }
        uid = q;
    }
    const friendships = await db
        .collection("friendships")
        .where("userIds", "array-contains", uid)
        .get();
    const friendIds = new Set();
    friendships.forEach((doc) => {
        const ids = doc.get("userIds");
        (ids !== null && ids !== void 0 ? ids : []).forEach((id) => {
            if (id !== uid)
                friendIds.add(id);
        });
    });
    const today = startOfDay(new Date());
    const horizon = new Date(today.getTime() + 10 * 86400000);
    const friends = [];
    for (const friendId of friendIds) {
        const statusDoc = await db
            .collection("weekendStatuses")
            .doc(friendId)
            .get();
        if (!statusDoc.exists)
            continue;
        const s = statusDoc.data();
        if (s.isVisible !== true)
            continue;
        if (typeof s.availability !== "string" ||
            !LOOKING_AVAILABILITY.has(s.availability)) {
            continue;
        }
        const weekendDate = (_b = (_a = s.weekendDate) === null || _a === void 0 ? void 0 : _a.toDate) === null || _b === void 0 ? void 0 : _b.call(_a);
        if (!weekendDate || weekendDate < today || weekendDate > horizon)
            continue;
        const userDoc = await db.collection("users").doc(friendId).get();
        const u = ((_c = userDoc.data()) !== null && _c !== void 0 ? _c : {});
        friends.push({
            userId: friendId,
            displayName: typeof u.displayName === "string" ? u.displayName : "Friend",
            availability: s.availability,
            courseName: typeof s.courseName === "string" ? s.courseName : null,
            timeSlots: Array.isArray(s.timeSlots)
                ? s.timeSlots
                : [],
            weekendDate: weekendDate.toISOString(),
        });
    }
    res.json({ userId: uid, count: friends.length, friends });
}
// ---------------------------------------------------------------------------
// Router (single HTTPS function)
// ---------------------------------------------------------------------------
exports.api = (0, https_1.onRequest)({ cors: true }, async (req, res) => {
    try {
        // onRequest mounts at /api; be tolerant if the prefix is still present.
        const path = (req.path.replace(/^\/api/, "") || "/").replace(/\/$/, "") || "/";
        const method = req.method.toUpperCase();
        if (method === "GET" && path === "/health") {
            res.json({ ok: true, service: "calendarcaddy-api", version: "1.0.0" });
            return;
        }
        if (method === "POST" && path === "/v1/teetimes/search") {
            await handleTeeTimeSearch(req, res);
            return;
        }
        if (method === "GET" && path === "/v1/friends/looking") {
            await handleFriendsLooking(req, res);
            return;
        }
        res.status(404).json({ error: `Not found: ${method} ${path}` });
    }
    catch (e) {
        if (e instanceof HttpError) {
            res.status(e.status).json({ error: e.message });
        }
        else {
            console.error("CalendarCaddy API error:", e);
            res.status(500).json({ error: "Internal server error" });
        }
    }
});
//# sourceMappingURL=api.js.map