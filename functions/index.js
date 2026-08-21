"use strict";

const { setGlobalOptions } = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize Firebase Admin SDK
initializeApp();

// ---------------------------------------------------------------------------
// 🌐 GLOBAL HIGH-CONCURRENCY & LOAD BALANCING INFRASTRUCTURE SETTINGS
// ---------------------------------------------------------------------------
setGlobalOptions({
  region: "us-central1",
  maxInstances: 50,     // Auto-scales dynamically under peak traffic surges
  minInstances: 1,      // Always-warm instance eliminates cold-start latency
  concurrency: 80,      // Cloud Run multi-stream concurrency: 80 requests/container
  memory: "512MiB",     // Memory allocation per container instance
  timeoutSeconds: 60,   // Standard timeout threshold
});

/**
 * Calculates distance in kilometers between two GPS coordinates using Haversine formula
 */
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ---------------------------------------------------------------------------
// 🚀 LOAD-BALANCED HTTP API GATEWAY (Cloud Run Edge Anycast CDN)
// ---------------------------------------------------------------------------
exports.api = onRequest(
  {
    cors: true,
    invoker: "public",
  },
  async (req, res) => {
    const path = req.path;
    const method = req.method;
    const db = getFirestore();

    // 1. Health Probe for Load Balancer / Uptime Monitoring
    if (path === "/health" || path === "/healthz") {
      try {
        const ping = await db.collection("settings").doc("global").get();
        return res.status(200).json({
          status: "HEALTHY",
          uptime: process.uptime(),
          timestamp: new Date().toISOString(),
          database: ping.exists ? "connected" : "initialized",
          loadBalancer: "Google Cloud Run Anycast",
        });
      } catch (err) {
        return res.status(500).json({ status: "DEGRADED", error: err.message });
      }
    }

    // 2. Direct Driver Dispatch Trigger API
    if (path === "/dispatch-order" && method === "POST") {
      try {
        const { orderId } = req.body;
        if (!orderId) {
          return res.status(400).json({ error: "Missing orderId parameter" });
        }

        const orderDoc = await db.collection("orders").doc(orderId).get();
        if (!orderDoc.exists) {
          return res.status(404).json({ error: "Order not found" });
        }

        const orderData = orderDoc.data();
        const driversSnap = await db
          .collection("users")
          .where("role", "==", "delivery_partner")
          .where("isActive", "==", true)
          .get();

        if (driversSnap.empty) {
          return res.status(200).json({ message: "No active delivery partners currently online" });
        }

        const deliveryAddress = orderData.deliveryAddress || {};
        const targetLat = deliveryAddress.latitude;
        const targetLng = deliveryAddress.longitude;

        let candidates = [];
        for (const doc of driversSnap.docs) {
          const driver = doc.data();
          const driverLat = driver.currentLatitude || driver.latitude;
          const driverLng = driver.currentLongitude || driver.longitude;

          let distance = 999;
          if (targetLat && targetLng && driverLat && driverLng) {
            distance = getDistanceFromLatLonInKm(targetLat, targetLng, driverLat, driverLng);
          }

          candidates.push({
            id: doc.id,
            name: driver.name || "Delivery Partner",
            phone: driver.phone || "",
            fcmToken: driver.fcmToken,
            distance,
          });
        }

        candidates.sort((a, b) => a.distance - b.distance);
        const closestDriver = candidates[0];

        await orderDoc.ref.update({
          deliveryPartnerId: closestDriver.id,
          deliveryPartnerName: closestDriver.name,
          deliveryPartnerPhone: closestDriver.phone,
          status: "accepted",
          updatedAt: FieldValue.serverTimestamp(),
        });

        if (closestDriver.fcmToken) {
          await db.collection("fcm_send_queue").add({
            title: "🛒 Immediate Pickup Assigned!",
            body: `Order #${orderId.substring(0, 6).toUpperCase()} assigned to you.`,
            tokens: [closestDriver.fcmToken],
            data: { type: "new_order_assigned", orderId },
            createdAt: FieldValue.serverTimestamp(),
          });
        }

        return res.status(200).json({
          success: true,
          assignedDriver: closestDriver.name,
          driverId: closestDriver.id,
          distanceKm: closestDriver.distance,
        });
      } catch (err) {
        return res.status(500).json({ error: err.message });
      }
    }

    // 3. Payment Gateway Webhook Listener (Razorpay / Stripe)
    if (path === "/payment-webhook" && method === "POST") {
      try {
        const payload = req.body;
        const orderId = payload.orderId || payload.order_id;
        const isSuccess = payload.status === "captured" || payload.status === "paid";

        if (orderId && isSuccess) {
          await db.collection("orders").doc(orderId).update({
            isPaid: true,
            paymentStatus: "completed",
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        return res.status(200).json({ received: true });
      } catch (err) {
        return res.status(500).json({ error: err.message });
      }
    }

    return res.status(404).json({ error: "Endpoint not found", path });
  }
);

// ---------------------------------------------------------------------------
// 📦 BACKGROUND EVENT-DRIVEN CLOUD FUNCTIONS
// ---------------------------------------------------------------------------

/**
 * Cloud Function: Push notification worker for fcm_send_queue
 */
exports.sendFcmNotification = onDocumentCreated(
  "fcm_send_queue/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const db = getFirestore();
    const messaging = getMessaging();

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
              resp.error.code === "messaging/registration-token-not-registered")
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

    return null;
  }
);

/**
 * Cloud Function: Automated Smart Driver Dispatch Engine
 * Triggers when a new order is placed or accepted without an assigned delivery partner.
 */
exports.autoDispatchOrder = onDocumentWritten(
  "orders/{orderId}",
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return null;

    const orderData = after.data();
    const orderId = event.params.orderId;

    const isUnassigned = !orderData.deliveryPartnerId;
    const isDispatchable =
      orderData.status === "accepted" || orderData.status === "pending";

    if (!isUnassigned || !isDispatchable) {
      return null;
    }

    const db = getFirestore();
    const deliveryAddress = orderData.deliveryAddress || {};
    const targetLat = deliveryAddress.latitude;
    const targetLng = deliveryAddress.longitude;

    const driversSnap = await db
      .collection("users")
      .where("role", "==", "delivery_partner")
      .where("isActive", "==", true)
      .get();

    if (driversSnap.empty) {
      console.log(`No active delivery partners registered for order ${orderId}`);
      return null;
    }

    let candidates = [];
    for (const doc of driversSnap.docs) {
      const driver = doc.data();
      const driverLat = driver.currentLatitude || driver.latitude;
      const driverLng = driver.currentLongitude || driver.longitude;

      let distance = 999;
      if (targetLat && targetLng && driverLat && driverLng) {
        distance = getDistanceFromLatLonInKm(
          targetLat,
          targetLng,
          driverLat,
          driverLng
        );
      }

      candidates.push({
        id: doc.id,
        name: driver.name || "Delivery Partner",
        phone: driver.phone || "",
        fcmToken: driver.fcmToken,
        distance,
      });
    }

    candidates.sort((a, b) => a.distance - b.distance);
    const closestDriver = candidates[0];

    if (!closestDriver) return null;

    console.log(
      `Auto-dispatching order ${orderId} to driver ${closestDriver.name} (${closestDriver.id}) - Distance: ${closestDriver.distance.toFixed(1)} km`
    );

    await after.ref.update({
      deliveryPartnerId: closestDriver.id,
      deliveryPartnerName: closestDriver.name,
      deliveryPartnerPhone: closestDriver.phone,
      dispatchedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    if (closestDriver.fcmToken) {
      await db.collection("fcm_send_queue").add({
        title: "🛒 New Delivery Order Assigned!",
        body: `Order #${orderId.substring(0, 6).toUpperCase()} is ready for pickup (${orderData.items?.length || 1} items).`,
        tokens: [closestDriver.fcmToken],
        data: {
          type: "new_order_assigned",
          orderId: orderId,
        },
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    return null;
  }
);

/**
 * Cloud Function: Push notification alerts to Customer on Order Status Changes
 */
exports.onOrderStatusNotification = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return null;

    const orderId = event.params.orderId;
    const oldStatus = beforeData.status;
    const newStatus = afterData.status;

    if (oldStatus === newStatus) return null;

    const db = getFirestore();
    const userId = afterData.userId;
    if (!userId) return null;

    const userDoc = await db.collection("users").doc(userId).get();
    const userToken = userDoc.data()?.fcmToken;
    if (!userToken) return null;

    const shortId = orderId.substring(0, 6).toUpperCase();
    let title = "Order Update";
    let body = `Your order #${shortId} status is now ${newStatus}.`;

    switch (newStatus) {
      case "accepted":
        title = "✅ Order Confirmed!";
        body = `Your order #${shortId} has been confirmed and is being packed.`;
        break;
      case "processing":
        title = "📦 Order Being Packed";
        body = `The dark store is packing your fresh grocery items.`;
        break;
      case "shipped":
      case "outForDelivery":
        title = "🚴 Out for Delivery!";
        body = `Your order #${shortId} is on the way with ${afterData.deliveryPartnerName || "our delivery partner"}. Delivery OTP: ${afterData.deliveryOtp || "N/A"}`;
        break;
      case "delivered":
        title = "🎉 Order Delivered!";
        body = `Your order #${shortId} has been successfully delivered. Enjoy your fresh groceries!`;
        break;
      case "cancelled":
        title = "❌ Order Cancelled";
        body = `Your order #${shortId} has been cancelled. Any payments have been refunded to your wallet.`;
        break;
    }

    await db.collection("fcm_send_queue").add({
      title,
      body,
      tokens: [userToken],
      data: {
        type: "order_status_update",
        orderId: orderId,
        status: newStatus,
      },
      createdAt: FieldValue.serverTimestamp(),
    });

    return null;
  }
);

/**
 * Cloud Function: Low Stock Alert Generator
 */
exports.onLowStockAlert = onDocumentUpdated(
  "products/{productId}",
  async (event) => {
    const afterData = event.data?.after.data();
    if (!afterData) return null;

    const stock = Number(afterData.stockQuantity) || 0;
    const productName = afterData.name || "Product";
    const productId = event.params.productId;

    if (stock <= 5 && stock > 0) {
      const db = getFirestore();
      await db.collection("notifications").add({
        title: "⚠️ Low Stock Warning",
        body: `"${productName}" is running low on inventory (${stock} units left). Restock soon.`,
        type: "low_stock",
        productId: productId,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    return null;
  }
);
