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
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import type {Request, Response} from "express";
import {
  teeTimeProvider,
  CourseInfo,
  TeeTimeSearchRequest,
} from "./teetimes";

const db = admin.firestore();

class HttpError extends Error {
  constructor(
    public status: number,
    message: string
  ) {
    super(message);
    this.name = "HttpError";
  }
}

interface Caller {
  /** Firebase uid, or null for service-key callers. */
  uid: string | null;
  viaServiceKey: boolean;
}

async function authenticate(req: Request): Promise<Caller> {
  const serviceKey = process.env.CALENDARCADDY_SERVICE_KEY;
  const apiKey = req.headers["x-api-key"];
  if (
    serviceKey &&
    typeof apiKey === "string" &&
    apiKey.length > 0 &&
    apiKey === serviceKey
  ) {
    return {uid: null, viaServiceKey: true};
  }

  const auth = req.headers.authorization;
  if (typeof auth === "string" && auth.startsWith("Bearer ")) {
    try {
      const decoded = await admin.auth().verifyIdToken(auth.slice(7));
      return {uid: decoded.uid, viaServiceKey: false};
    } catch {
      // fall through to 401
    }
  }
  throw new HttpError(
    401,
    "Unauthorized: pass a Firebase ID token or a valid service API key"
  );
}

// ---------------------------------------------------------------------------
// POST /v1/teetimes/search
// ---------------------------------------------------------------------------

function parseSearchBody(body: unknown): TeeTimeSearchRequest {
  const b = (body ?? {}) as Record<string, unknown>;
  const {courses, date, earliestTime, latestTime, players} = b;

  if (!Array.isArray(courses) || courses.length === 0 || courses.length > 20) {
    throw new HttpError(400, "courses must be a non-empty array (max 20)");
  }
  const parsedCourses: CourseInfo[] = courses.map((c, i) => {
    const cc = c as Record<string, unknown>;
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
  if (
    typeof players !== "number" ||
    !Number.isInteger(players) ||
    players < 1 ||
    players > 4
  ) {
    throw new HttpError(400, "players must be an integer from 1 to 4");
  }

  return {courses: parsedCourses, date, earliestTime, latestTime, players};
}

async function handleTeeTimeSearch(req: Request, res: Response): Promise<void> {
  await authenticate(req);
  const search = parseSearchBody(req.body);
  const provider = teeTimeProvider();
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

function startOfDay(d: Date): Date {
  const c = new Date(d);
  c.setHours(0, 0, 0, 0);
  return c;
}

interface LookingFriend {
  userId: string;
  displayName: string;
  availability: string;
  courseName: string | null;
  timeSlots: Array<{day: string; time: string}>;
  weekendDate: string;
}

async function handleFriendsLooking(req: Request, res: Response): Promise<void> {
  const caller = await authenticate(req);

  // Service-key callers act on behalf of a user they name explicitly.
  let uid = caller.uid;
  if (!uid) {
    const q = req.query.userId;
    if (typeof q !== "string" || q.length === 0) {
      throw new HttpError(
        400,
        "userId query param is required for service-key callers"
      );
    }
    uid = q;
  }

  const friendships = await db
    .collection("friendships")
    .where("userIds", "array-contains", uid)
    .get();

  const friendIds = new Set<string>();
  friendships.forEach((doc) => {
    const ids = doc.get("userIds") as string[] | undefined;
    (ids ?? []).forEach((id) => {
      if (id !== uid) friendIds.add(id);
    });
  });

  const today = startOfDay(new Date());
  const horizon = new Date(today.getTime() + 10 * 86400000);
  const friends: LookingFriend[] = [];

  for (const friendId of friendIds) {
    const statusDoc = await db
      .collection("weekendStatuses")
      .doc(friendId)
      .get();
    if (!statusDoc.exists) continue;
    const s = statusDoc.data() as Record<string, unknown>;
    if (s.isVisible !== true) continue;
    if (
      typeof s.availability !== "string" ||
      !LOOKING_AVAILABILITY.has(s.availability)
    ) {
      continue;
    }
    const weekendDate = (
      s.weekendDate as {toDate?: () => Date} | undefined
    )?.toDate?.();
    if (!weekendDate || weekendDate < today || weekendDate > horizon) continue;

    const userDoc = await db.collection("users").doc(friendId).get();
    const u = (userDoc.data() ?? {}) as Record<string, unknown>;

    friends.push({
      userId: friendId,
      displayName:
        typeof u.displayName === "string" ? u.displayName : "Friend",
      availability: s.availability as string,
      courseName:
        typeof s.courseName === "string" ? s.courseName : null,
      timeSlots: Array.isArray(s.timeSlots)
        ? (s.timeSlots as Array<{day: string; time: string}>)
        : [],
      weekendDate: weekendDate.toISOString(),
    });
  }

  res.json({userId: uid, count: friends.length, friends});
}

// ---------------------------------------------------------------------------
// Router (single HTTPS function)
// ---------------------------------------------------------------------------

export const api = onRequest({cors: true}, async (req, res) => {
  try {
    // onRequest mounts at /api; be tolerant if the prefix is still present.
    const path = (req.path.replace(/^\/api/, "") || "/").replace(/\/$/, "") || "/";
    const method = req.method.toUpperCase();

    if (method === "GET" && path === "/health") {
      res.json({ok: true, service: "calendarcaddy-api", version: "1.0.0"});
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
    res.status(404).json({error: `Not found: ${method} ${path}`});
  } catch (e) {
    if (e instanceof HttpError) {
      res.status(e.status).json({error: e.message});
    } else {
      console.error("CalendarCaddy API error:", e);
      res.status(500).json({error: "Internal server error"});
    }
  }
});
