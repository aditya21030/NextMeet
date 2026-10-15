const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "nextmeet-111"
  });
}

const db = admin.firestore();

async function debugRelationships() {
  console.log("🔍 Debugging Relationships for nextmeet-111...");
  try {
    const relSnap = await db.collection("relationships").get();
    console.log(`Total Relationships in 'relationships' collection: ${relSnap.size}`);

    const statusCounts = {};
    relSnap.forEach(doc => {
      const data = doc.data();
      const status = data.status || "none";
      statusCounts[status] = (statusCounts[status] || 0) + 1;
      
      // If none, check if it has uid1 and uid2
      if (!data.status && data.uid1 && data.uid2) {
          statusCounts["active_no_status"] = (statusCounts["active_no_status"] || 0) + 1;
      }
    });

    console.log("Status Counts:", statusCounts);

    const pendingSnap = await db.collection("pending_relationships").get();
    console.log(`Pending Relationships Collection Size: ${pendingSnap.size}`);

    const acceptedSnap = await db.collection("accepted_relationships").get();
    console.log(`Accepted Relationships Collection Size: ${acceptedSnap.size}`);

    const usersSnap = await db.collection("users_directory").get();
    console.log(`Users Directory Size: ${usersSnap.size}`);

  } catch (error) {
    console.error("❌ Debug failed:", error);
  }
}

debugRelationships().then(() => process.exit(0));
