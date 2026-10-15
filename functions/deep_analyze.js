const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "nextmeet-111"
  });
}

const db = admin.firestore();

async function analyzeRelationships() {
  console.log("🔍 Deep Analysis of Relationships...");
  try {
    const relSnap = await db.collection("relationships").get();
    console.log(`Total Relationships: ${relSnap.size}`);

    let active = 0;
    let waiting = 0;
    let unknown = 0;
    let missingUids = 0;

    relSnap.forEach(doc => {
      const data = doc.data();
      const hasUid1 = !!data.uid1;
      const hasUid2 = !!data.uid2;
      const status = data.status;

      if (hasUid1 && hasUid2) {
        active++;
        if (status !== 'active') {
            console.log(`Potential Missing Active: ${doc.id} (status: ${status})`);
        }
      } else if (hasUid1 && !hasUid2) {
        waiting++;
      } else {
        unknown++;
        if (!hasUid1 && !hasUid2) missingUids++;
      }
    });

    console.log("Analysis Results:");
    console.log(`- Active Couples (has uid1 & uid2): ${active}`);
    console.log(`- Waiting Users (has uid1 only): ${waiting}`);
    console.log(`- Unknown/Empty: ${unknown}`);
    console.log(`- Relationships with NO UIDs: ${missingUids}`);

    // Check collections
    const acceptedSnap = await db.collection("accepted_relationships").get();
    console.log(`Documents in 'accepted_relationships': ${acceptedSnap.size}`);

    const pendingSnap = await db.collection("pending_relationships").get();
    console.log(`Documents in 'pending_relationships': ${pendingSnap.size}`);

  } catch (error) {
    console.error("❌ Analysis failed:", error);
  }
}

analyzeRelationships().then(() => process.exit(0));
