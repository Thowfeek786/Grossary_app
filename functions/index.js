"use strict";

const functions = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Initialize once at module level — safe for v2 because
// the CLI analysis does NOT execute the handler body.
admin.initializeApp();

exports.sendFcmNotification = functions.onDocumentCreated(
  {
    document: "fcm_send_queue/{docId}",
    region: "us-central1",
    timeoutSeconds: 120,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const db = admin.firestore();
    const messaging = admin.messaging();
    const FieldValue = admin.firestore.FieldValue;

    const data = snap.data();
    const { title, body, tokens, topic, imageUrl, data: notifData } = data;

    if (!tokens || tokens.length === 0) {
      await snap.ref.update({
        status: "completed",
        result: "no_tokens",
        processedAt: FieldValue.serverTimestamp(),
      });
      return null;
    }

    const notification = {
      title: title || "GroceryGo",
      body: body || "",
    };
    if (imageUrl) notification.imageUrl = imageUrl;

    const results = { success: 0, failure: 0, invalidTokens: [] };
    const batchSize = 500;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const chunk = tokens.slice(i, i + batchSize);
      const message = {
        notification,
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title: notification.title, body: notification.body },
              sound: "default",
              badge: 1,
            },
          },
        },
        data: notifData
          ? Object.fromEntries(
              Object.entries(notifData).map(([k, v]) => [k, String(v)])
            )
          : {},
        tokens: chunk,
      };

      try {
        const response = await messaging.sendEachForMulticast(message);
        results.success += response.successCount;
        results.failure += response.failureCount;
        response.responses.forEach((resp, idx) => {
          if (
            !resp.success &&
            resp.error &&
            (resp.error.code === "messaging/invalid-registration-token" ||
              resp.error.code ===
                "messaging/registration-token-not-registered")
          ) {
            results.invalidTokens.push(chunk[idx]);
          }
        });
      } catch (err) {
        console.error("Multicast batch error:", err);
        results.failure += chunk.length;
      }
    }

    await snap.ref.update({
      status: "completed",
      result: results,
      processedAt: FieldValue.serverTimestamp(),
    });

    // Cleanup invalid FCM tokens from user documents
    if (results.invalidTokens.length > 0) {
      const usersSnap = await db.collection("users").get();
      const cleanupBatch = db.batch();
      let count = 0;
      for (const userDoc of usersSnap.docs) {
        const token = userDoc.data().fcmToken;
        if (token && results.invalidTokens.includes(token)) {
          cleanupBatch.update(userDoc.ref, { fcmToken: FieldValue.delete() });
          count++;
        }
      }
      if (count > 0) await cleanupBatch.commit();
      console.log(`Cleaned up ${count} invalid FCM tokens`);
    }

    console.log(
      `FCM sent — success:${results.success} failure:${results.failure} topic:${topic || "none"}`
    );
    return null;
  }
);
