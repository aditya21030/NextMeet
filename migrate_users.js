const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function syncAllAuthUsers() {
  console.log("🚀 Starting Full User Sync from Firebase Auth...");
  let count = 0;
  
  try {
    const listUsers = async (nextPageToken) => {
      const result = await auth.listUsers(1000, nextPageToken);
      const batch = db.batch();
      
      for (const user of result.users) {
        const userRef = db.collection('users_directory').doc(user.uid);
        batch.set(userRef, {
          email: user.email || "No Email",
          displayName: user.displayName || "Anonymous",
          uid: user.uid,
          photoUrl: user.photoURL || "",
          lastLogin: user.metadata.lastSignInTime,
          createdAt: user.metadata.creationTime,
          syncedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        count++;
      }
      
      await batch.commit();
      console.log(`✅ Synced ${count} users so far...`);
      
      if (result.pageToken) {
        await listUsers(result.pageToken);
      }
    };
    
    await listUsers();
    console.log(`\n🎉 COMPLETION REPORT: Total ${count} users synced to 'users_directory' collection.`);
    process.exit(0);
  } catch (error) {
    console.error("❌ Sync Failed:", error);
    process.exit(1);
  }
}

syncAllAuthUsers();
