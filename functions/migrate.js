const admin = require("firebase-admin");

// Initialize with default credentials (uses the account you're logged into in the Firebase CLI)
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function migrateOldUsers() {
  console.log("🚀 Starting migration for old users...");
  try {
    const batch = db.batch();
    let count = 0;

    // 1. Sync Active Relationships -> accepted_relationships
    console.log("Checking active relationships...");
    const relSnap = await db.collection("relationships").where("status", "==", "active").get();
    console.log(`Found ${relSnap.size} active relationships.`);

    relSnap.forEach((doc) => {
      const data = doc.data();
      const relId = doc.id;
      if (data.uid1 && data.uid2) {
        const acceptedRef = db.collection("accepted_relationships").doc(relId);
        batch.set(acceptedRef, {
          relId,
          uid1: data.uid1,
          uid2: data.uid2,
          userName1: data.userName1 || "Partner 1",
          userName2: data.userName2 || "Partner 2",
          acceptedAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        count++;
      }
    });

    // 2. Sync Pending Invites -> pending_relationships
    console.log("Checking pending invites...");
    const inviteSnap = await db.collection("invites").where("status", "==", "pending").get();
    console.log(`Found ${inviteSnap.size} pending invites.`);

    for (const doc of inviteSnap.docs) {
      const data = doc.data();
      const code = doc.id;
      const relId = data.relationshipId;
      const uid1 = data.creatorUid;

      if (relId && uid1) {
        // Fetch the relationship to get the creator's name
        const relDoc = await db.collection("relationships").doc(relId).get();
        const userName1 = relDoc.exists ? (relDoc.data().userName1 || "Partner 1") : "Partner 1";

        const pendingRef = db.collection("pending_relationships").doc(relId);
        batch.set(pendingRef, {
          relId,
          uid1,
          userName1,
          creatorEmail: data.creatorEmail || "Old User (Email Unknown)",
          inviteCode: code,
          createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        count++;
      }
    }

    if (count > 0) {
      console.log(`Committing batch of ${count} updates...`);
      await batch.commit();
      console.log("✅ Migration complete! All old users are now synced.");
    } else {
      console.log("No old data needed syncing.");
    }

  } catch (error) {
    console.error("❌ Migration failed:", error);
  }
}

migrateOldUsers().then(() => process.exit(0));
