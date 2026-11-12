const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Helper to update global statistics in Firestore.
 * This function now counts users directly from Firebase Auth for precision.
 */
async function updateGlobalStats() {
  console.log("Updating global stats from Auth & Firestore...");
  try {
    // 1. Get True Total Auth Users from Firebase Auth
    const authResult = await admin.auth().listUsers(1000); // 1000 is enough for now
    const totalAuthUsers = authResult.users.length;

    // 2. Scan Firestore Collections
    const relsSnap = await admin.firestore().collection("relationships").get();
    const acceptedSnap = await admin.firestore().collection("accepted_relationships").get();
    const pendingSnap = await admin.firestore().collection("pending_relationships").get();

    const stats = {
      total_authenticated_users: totalAuthUsers,
      total_created_journeys: relsSnap.size,
      confirmed_active_couples: acceptedSnap.size,
      confirmed_waiting_users: pendingSnap.size,
      unstarted_users: Math.max(0, totalAuthUsers - relsSnap.size),
      lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore().collection("system_stats").doc("global").set(stats, { merge: true });
    console.log(`Global stats updated: Auth(${totalAuthUsers}), Rels(${relsSnap.size})`);
    return stats;
  } catch (error) {
    console.error("Error updating global stats:", error);
    throw error;
  }
}

/**
 * Helper to sync all Firebase Auth users to the 'users_directory' Firestore collection.
 */
async function syncAllUsersToDirectory() {
    console.log("Starting full Auth-to-Firestore sync...");
    try {
        const authResult = await admin.auth().listUsers(1000);
        const batch = admin.firestore().batch();
        
        authResult.users.forEach(user => {
            const userRef = admin.firestore().collection("users_directory").doc(user.uid);
            batch.set(userRef, {
                email: user.email || "No Email",
                displayName: user.displayName || "Anonymous",
                uid: user.uid,
                photoUrl: user.photoURL || "",
                lastLogin: user.metadata.lastSignInTime,
                createdAt: user.metadata.creationTime,
                syncedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        });
        
        await batch.commit();
        console.log(`Successfully synced ${authResult.users.length} users.`);
    } catch (error) {
        console.error("User sync failed:", error);
    }
}

exports.sendTouchNotification = functions.firestore
  .document("relationships/{relId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (
      newData.lastTouchTime &&
      (!oldData.lastTouchTime ||
        !newData.lastTouchTime.isEqual(oldData.lastTouchTime))
    ) {
      const senderUid = newData.lastTouchFrom;
      const touchType = newData.lastTouchType;
      const relId = context.params.relId;

      const receiverUid = (newData.uids && Array.isArray(newData.uids))
        ? newData.uids.find((uid) => uid !== senderUid)
        : (senderUid === newData.uid1 ? newData.uid2 : newData.uid1);
      if (!receiverUid) return null;

      const userTokens = newData.userTokens || {};
      const receiverToken = userTokens[receiverUid];

      if (!receiverToken) {
        console.log(`No token found for receiver: ${receiverUid}`);
        return null;
      }

      const senderName =
        senderUid === newData.uid1
          ? newData.userName1 || "Partner"
          : newData.userName2 || "Partner";

      let title = "New Interaction ❤️";
      let body = `${senderName} is thinking of you!`;

      if (touchType === "miss") {
        title = "I Miss You! 🥺";
        body = `${senderName} just sent you a "Miss You" nudge.`;
      } else if (touchType === "touch") {
        title = "Digital Touch! ⚡";
        body = `${senderName} just gave you a digital touch.`;
      } else if (touchType === "hug") {
        title = "Digital Hug! 🤗";
        body = `${senderName} just sent you a warm hug.`;
      } else if (touchType === "emoji") {
        title = "Reaction! ✨";
        body = `${senderName} sent you a warm reaction.`;
      }

      const message = {
        token: receiverToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "interaction",
          touchType: touchType,
          relId: relId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channel_id: "high_importance_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);
        return response;
      } catch (error) {
        console.log("Error sending message:", error);
        return null;
      }
    }
    return null;
  });

exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL, metadata } = user;
  console.log(`Syncing new user to directory: ${uid}`);
  await admin.firestore().collection("users_directory").doc(uid).set({
    email: email || "No Email",
    displayName: displayName || "Anonymous",
    uid: uid,
    photoUrl: photoURL || "",
    lastLogin: metadata.lastSignInTime,
    createdAt: metadata.creationTime,
    syncedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  
  await updateGlobalStats();
});

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const { uid } = user;
  console.log(`Removing user from directory: ${uid}`);
  await admin.firestore().collection("users_directory").doc(uid).delete();
  
  await updateGlobalStats();
});

exports.syncRelationshipData = functions.firestore
  .document("relationships/{relId}")
  .onWrite(async (change, context) => {
    const relId = context.params.relId;
    const newData = change.after.exists ? change.after.data() : null;

    if (!newData) {
      console.log(`Deleting helper records for relId: ${relId}`);
      await admin.firestore().collection("pending_relationships").doc(relId).delete();
      await admin.firestore().collection("accepted_relationships").doc(relId).delete();
      return null;
    }

    const { status, uid1, uid2, userName1, userName2, inviteCode, createdAt, uids } = newData;

    if (status === "waiting" || (!status && uid1 && !uid2)) {
      console.log(`Syncing pending relationship for relId: ${relId}`);
      await admin.firestore().collection("pending_relationships").doc(relId).set({
        relId,
        uid1,
        userName1: userName1 || "Partner 1",
        inviteCode: inviteCode || "",
        createdAt: createdAt || admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      await admin.firestore().collection("accepted_relationships").doc(relId).delete();
    } 
    else if (status === "active" || (!status && uid1 && uid2)) {
      console.log(`Syncing accepted relationship for relId: ${relId}`);
      
      let email1 = "Unknown";
      let email2 = "Unknown";
      
      if (uids && uids.length >= 2) {
          const user1Doc = await admin.firestore().collection("users_directory").doc(uids[0]).get();
          const user2Doc = await admin.firestore().collection("users_directory").doc(uids[1]).get();
          email1 = user1Doc.exists ? (user1Doc.data().email || "No Email") : "Unknown";
          email2 = user2Doc.exists ? (user2Doc.data().email || "No Email") : "Unknown";
      }

      await admin.firestore().collection("accepted_relationships").doc(relId).set({
        relId,
        uid1,
        uid2,
        email1,
        email2,
        userName1: userName1 || "Partner 1",
        userName2: userName2 || "Partner 2",
        acceptedAt: newData.acceptedAt || newData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      await admin.firestore().collection("pending_relationships").doc(relId).delete();
    }

    return null;
  });

/**
 * Manual trigger for full database repair & stats refresh.
 * This fixes the '0' issue by counting Auth users directly.
 */
exports.manualUpdateStats = functions.https.onRequest(async (req, res) => {
    console.log("Manual trigger: Syncing all users and updating stats...");
    try {
        await syncAllUsersToDirectory();
        const stats = await updateGlobalStats();
        res.status(200).send({ message: "Full sync & stats update complete.", stats });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});

exports.debugUrls = functions.https.onRequest(async (req, res) => {
    try {
        const relationships = await admin.firestore().collection('relationships').limit(5).get();
        let urls = [];
        for (const rel of relationships.docs) {
            const memories = await rel.ref.collection('memories').limit(5).get();
            memories.forEach(m => {
                if (m.data().imageUrl) urls.push(m.data().imageUrl);
            });
        }
        res.send({urls});
    } catch(e) {
        res.status(500).send({error: e.message});
    }
});
