const admin = require('firebase-admin');
admin.initializeApp();

async function checkImages() {
  try {
    const relationships = await admin.firestore().collection('relationships').limit(5).get();
    if (relationships.empty) {
      console.log('No relationships found.');
      return;
    }

    for (const relDoc of relationships.docs) {
      const memories = await relDoc.ref.collection('memories').orderBy('date', 'asc').limit(5).get();
      for (const mem of memories.docs) {
        const url = mem.data().imageUrl;
        if (url) {
          console.log('Found URL:', url);
          const https = require('https');
          https.get(url, (res) => {
            console.log('Status Code:', res.statusCode);
            if (res.statusCode !== 200) {
              res.on('data', (d) => {
                process.stdout.write(d);
              });
            }
          }).on('error', (e) => {
            console.error(e);
          });
          return;
        }
      }
    }
    console.log('No images found in the first few relationships.');
  } catch(e) {
    console.error(e);
  }
}

checkImages();
