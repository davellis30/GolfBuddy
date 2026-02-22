import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onDocumentWritten} from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();

// --- Helper ---

interface UserDoc {
  displayName?: string;
  fcmToken?: string;
  notificationPreferences?: {
    friendRequests?: boolean;
    messages?: boolean;
    statusChanges?: boolean;
  };
}

type NotificationType = "friendRequest" | "message" | "statusChange";

async function sendPushNotification(
  recipientUserId: string,
  title: string,
  body: string,
  data: Record<string, string>,
  notificationType: NotificationType
): Promise<void> {
  const userDoc = await db.collection("users").doc(recipientUserId).get();
  if (!userDoc.exists) return;

  const userData = userDoc.data() as UserDoc;
  const fcmToken = userData.fcmToken;
  if (!fcmToken) return;

  // Check notification preferences
  const prefs = userData.notificationPreferences;
  if (prefs) {
    if (notificationType === "friendRequest" && prefs.friendRequests === false) {
      return;
    }
    if (notificationType === "message" && prefs.messages === false) return;
    if (notificationType === "statusChange" && prefs.statusChanges === false) {
      return;
    }
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {title, body},
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
  } catch (error: unknown) {
    const firebaseError = error as { code?: string };
    if (
      firebaseError.code === "messaging/registration-token-not-registered" ||
      firebaseError.code === "messaging/invalid-registration-token"
    ) {
      // Token is stale — remove it
      await db
        .collection("users")
        .doc(recipientUserId)
        .update({fcmToken: admin.firestore.FieldValue.delete()});
    } else {
      console.error(
        `Failed to send notification to ${recipientUserId}:`,
        error
      );
    }
  }
}

// --- Trigger: Friend Request Created ---

export const onFriendRequestCreated = onDocumentCreated(
  "friendRequests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const fromUserId = data.fromUserId as string;
    const toUserId = data.toUserId as string;

    // Look up sender's display name
    const senderDoc = await db.collection("users").doc(fromUserId).get();
    const senderName = senderDoc.exists
      ? (senderDoc.data() as UserDoc).displayName || "Someone"
      : "Someone";

    await sendPushNotification(
      toUserId,
      "New Friend Request",
      `${senderName} sent you a friend request`,
      {
        type: "friendRequest",
        requestId: event.params.requestId,
      },
      "friendRequest"
    );
  }
);

// --- Trigger: Message Created ---

export const onMessageCreated = onDocumentCreated(
  "conversations/{convoId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const senderId = data.senderId as string;
    const receiverId = data.receiverId as string;
    const text = data.text as string;

    // Look up sender's display name
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists
      ? (senderDoc.data() as UserDoc).displayName || "Someone"
      : "Someone";

    // Truncate message for notification body
    const truncatedText =
      text.length > 100 ? text.substring(0, 100) + "..." : text;

    await sendPushNotification(
      receiverId,
      senderName,
      truncatedText,
      {
        type: "message",
        conversationId: event.params.convoId,
        senderId,
      },
      "message"
    );
  }
);

// --- Trigger: Weekend Status Written ---

export const onWeekendStatusWritten = onDocumentWritten(
  "weekendStatuses/{userId}",
  async (event) => {
    // Skip if document was deleted
    if (!event.data?.after.exists) return;

    const afterData = event.data.after.data();
    if (!afterData) return;

    const userId = afterData.userId as string;
    const availability = afterData.availability as string;
    const isVisible = afterData.isVisible as boolean;

    // Don't notify if status is hidden
    if (!isVisible) return;

    // Look up the user's display name
    const userDoc = await db.collection("users").doc(userId).get();
    const userName = userDoc.exists
      ? (userDoc.data() as UserDoc).displayName || "A friend"
      : "A friend";

    // Find all friends of this user
    const friendshipsSnapshot = await db
      .collection("friendships")
      .where("userIds", "array-contains", userId)
      .get();

    const friendIds: string[] = [];
    for (const doc of friendshipsSnapshot.docs) {
      const userIds = doc.data().userIds as string[];
      for (const id of userIds) {
        if (id !== userId) {
          friendIds.push(id);
        }
      }
    }

    // Format availability for display
    const availabilityDisplay: Record<string, string> = {
      lookingToPlay: "Looking to Play",
      alreadyPlaying: "Already Playing",
      seekingAdditional: "Seeking an Additional Player",
    };
    const statusText =
      availabilityDisplay[availability] || availability;

    // Send to all friends in parallel
    const notifications = friendIds.map((friendId) =>
      sendPushNotification(
        friendId,
        `${userName} updated their status`,
        statusText,
        {
          type: "statusChange",
          statusUserId: userId,
        },
        "statusChange"
      )
    );

    await Promise.all(notifications);
  }
);
