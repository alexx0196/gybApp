/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// для этой штуки нужна блатная подписка на firebase
// const functions = require("firebase-functions");
// const admin = require("firebase-admin");

// admin.initializeApp();

// exports.deleteUnverifiedUsers = functions.pubsub
//   .schedule("every 2 minutes") // "every 24 hours"
//   .timeZone("UTC")
//   .onRun(async () => {
//     const now = Date.now();
//     // const WEEK = 7 * 24 * 60 * 60 * 1000;
//     const MINUTE = 60 * 1000;

//     let deletedCount = 0;

//     const listAllUsers = async (nextPageToken) => {
//       const result = await admin.auth().listUsers(1000, nextPageToken);

//       for (const user of result.users) {
//         const createdAt = new Date(user.metadata.creationTime).getTime();

//         if (
//           !user.emailVerified &&
//           now - createdAt > MINUTE
//         ) {
//           await admin.auth().deleteUser(user.uid);
//           deletedCount++;
//         }
//       }

//       if (result.pageToken) {
//         await listAllUsers(result.pageToken);
//       }
//     };

//     await listAllUsers();

//     console.log(`Deleted ${deletedCount} unverified users`);
//     return null;
//   });


const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteUnverifiedUsersTest = functions.https.onRequest(async (req, res) => {
  const now = Date.now();
  const TEST_PERIOD = 1 * 60 * 1000; // 1 минута для теста
  let deletedCount = 0;

  const listAllUsers = async (nextPageToken) => {
    const result = await admin.auth().listUsers(1000, nextPageToken);

    for (const user of result.users) {
      const createdAt = new Date(user.metadata.creationTime).getTime();
      if (!user.emailVerified && now - createdAt > TEST_PERIOD) {
        await admin.auth().deleteUser(user.uid);
        deletedCount++;
      }
    }

    if (result.pageToken) {
      await listAllUsers(result.pageToken);
    }
  };

  await listAllUsers();
  console.log(`Deleted ${deletedCount} unverified users`);
  res.send(`Deleted ${deletedCount} unverified users`);
});
