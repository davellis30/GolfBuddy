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
exports.onWeekendStatusWritten = exports.onMessageCreated = exports.onFriendRequestCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
admin.initializeApp();
const db = admin.firestore();
async function sendPushNotification(recipientUserId, title, body, data, notificationType) {
    const userDoc = await db.collection("users").doc(recipientUserId).get();
    if (!userDoc.exists)
        return;
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken)
        return;
    // Check notification preferences
    const prefs = userData.notificationPreferences;
    if (prefs) {
        if (notificationType === "friendRequest" && prefs.friendRequests === false) {
            return;
        }
        if (notificationType === "message" && prefs.messages === false)
            return;
        if (notificationType === "statusChange" && prefs.statusChanges === false) {
            return;
        }
    }
    try {
        await admin.messaging().send({
            token: fcmToken,
            notification: { title, body },
            data,
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        });
    }
    catch (error) {
        const firebaseError = error;
        if (firebaseError.code === "messaging/registration-token-not-registered" ||
            firebaseError.code === "messaging/invalid-registration-token") {
            // Token is stale — remove it
            await db
                .collection("users")
                .doc(recipientUserId)
                .update({ fcmToken: admin.firestore.FieldValue.delete() });
        }
        else {
            console.error(`Failed to send notification to ${recipientUserId}:`, error);
        }
    }
}
// --- Trigger: Friend Request Created ---
exports.onFriendRequestCreated = (0, firestore_1.onDocumentCreated)("friendRequests/{requestId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const fromUserId = data.fromUserId;
    const toUserId = data.toUserId;
    // Look up sender's display name
    const senderDoc = await db.collection("users").doc(fromUserId).get();
    const senderName = senderDoc.exists
        ? senderDoc.data().displayName || "Someone"
        : "Someone";
    await sendPushNotification(toUserId, "New Friend Request", `${senderName} sent you a friend request`, {
        type: "friendRequest",
        requestId: event.params.requestId,
    }, "friendRequest");
});
// --- Trigger: Message Created ---
exports.onMessageCreated = (0, firestore_1.onDocumentCreated)("conversations/{convoId}/messages/{messageId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const senderId = data.senderId;
    const receiverId = data.receiverId;
    const text = data.text;
    // Look up sender's display name
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists
        ? senderDoc.data().displayName || "Someone"
        : "Someone";
    // Truncate message for notification body
    const truncatedText = text.length > 100 ? text.substring(0, 100) + "..." : text;
    await sendPushNotification(receiverId, senderName, truncatedText, {
        type: "message",
        conversationId: event.params.convoId,
        senderId,
    }, "message");
});
// --- Trigger: Weekend Status Written ---
exports.onWeekendStatusWritten = (0, firestore_2.onDocumentWritten)("weekendStatuses/{userId}", async (event) => {
    var _a;
    // Skip if document was deleted
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.after.exists))
        return;
    const afterData = event.data.after.data();
    if (!afterData)
        return;
    const userId = afterData.userId;
    const availability = afterData.availability;
    const isVisible = afterData.isVisible;
    // Don't notify if status is hidden
    if (!isVisible)
        return;
    // Look up the user's display name
    const userDoc = await db.collection("users").doc(userId).get();
    const userName = userDoc.exists
        ? userDoc.data().displayName || "A friend"
        : "A friend";
    // Find all friends of this user
    const friendshipsSnapshot = await db
        .collection("friendships")
        .where("userIds", "array-contains", userId)
        .get();
    const friendIds = [];
    for (const doc of friendshipsSnapshot.docs) {
        const userIds = doc.data().userIds;
        for (const id of userIds) {
            if (id !== userId) {
                friendIds.push(id);
            }
        }
    }
    // Format availability for display
    const availabilityDisplay = {
        lookingToPlay: "Looking to Play",
        alreadyPlaying: "Already Playing",
        seekingAdditional: "Seeking an Additional Player",
    };
    const statusText = availabilityDisplay[availability] || availability;
    // Send to all friends in parallel
    const notifications = friendIds.map((friendId) => sendPushNotification(friendId, `${userName} updated their status`, statusText, {
        type: "statusChange",
        statusUserId: userId,
    }, "statusChange"));
    await Promise.all(notifications);
});
//# sourceMappingURL=index.js.map