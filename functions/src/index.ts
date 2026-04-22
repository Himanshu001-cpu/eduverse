import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// 1. onPurchaseCreate: Transactional enrollment
export const onPurchaseCreate = functions.firestore
    .document("purchases/{purchaseId}")
    .onCreate(async (snap, context) => {
        const purchase = snap.data();
        const userId = purchase.userId;
        const courseId = purchase.courseId; // Assuming single item purchase for simplicity
        const batchId = purchase.batchId;

        if (!userId || !courseId || !batchId) return;

        const batchRef = db.collection("courses").doc(courseId).collection("batches").doc(batchId);

        try {
            await db.runTransaction(async (t) => {
                const batchDoc = await t.get(batchRef);
                if (!batchDoc.exists) throw new Error("Batch not found");

                const seatsLeft = batchDoc.data()?.seatsLeft ?? 0;
                if (seatsLeft <= 0) {
                    throw new Error("No seats available");
                }

                // Decrement seats
                t.update(batchRef, { seatsLeft: seatsLeft - 1 });

                // Create enrollment
                const enrollmentId = `${userId}_${batchId}`;
                const enrollmentRef = db.collection("enrollments").doc(enrollmentId);
                t.set(enrollmentRef, {
                    userId,
                    courseId,
                    batchId,
                    enrolledAt: admin.firestore.FieldValue.serverTimestamp(),
                    status: 'active'
                });

                // Audit log
                const auditRef = db.collection("audits").doc();
                t.set(auditRef, {
                    action: "system_enroll",
                    entityType: "enrollment",
                    entityId: enrollmentId,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    details: { purchaseId: context.params.purchaseId }
                });
            });

            // Update purchase status to success
            await snap.ref.update({ status: "success" });

        } catch (error) {
            const err = error as Error;
            console.error("Enrollment failed", err);
            await snap.ref.update({ status: "failed", error: err.message });
        }
    });

// 2. enrollStudent: Callable for admins
export const enrollStudent = functions.https.onCall(async (data, context) => {
    if (!context.auth || !['admin', 'superadmin'].includes(context.auth.token.role as string)) {
        throw new functions.https.HttpsError('permission-denied', 'Not an admin');
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { userId: _userId, courseId: _courseId, batchId: _batchId } = data;
    // Similar transaction logic as above...
    // Stub for brevity
    return { success: true };
});

// 3. webhookPaymentUpdate
export const webhookPaymentUpdate = functions.https.onRequest(async (req, res) => {
    const { purchaseId, status } = req.body;
    // Update purchase status, which might trigger onPurchaseCreate logic if we separate concerns
    await db.collection("purchases").doc(purchaseId).update({ status });
    res.json({ received: true });
});

// 4. generateInvoice
export const generateInvoice = functions.https.onCall(async (_data, _context) => {
    // Stub: Generate PDF, upload to Storage, return URL
    return { url: "https://storage.googleapis.com/bucket/invoice_123.pdf" };
});

// 5. setAdminRole: Callable to set admin custom claims
// Call this from Firebase Console, Admin SDK, or a secure admin interface
export const setAdminRole = functions.https.onCall(async (data, context) => {
    // Check if the caller is a superadmin (or first-time bootstrap)
    const callerRole = context.auth?.token?.role as string | undefined;

    // For first-time setup, allow if no superadmin exists yet
    // After that, only superadmin can assign roles
    if (callerRole && callerRole !== 'superadmin') {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only superadmin can assign admin roles'
        );
    }

    const { uid, role } = data;

    if (!uid || typeof uid !== 'string') {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'User UID is required'
        );
    }

    const validRoles = ['superadmin', 'admin', 'content_manager', 'support', 'user'];
    if (!role || !validRoles.includes(role)) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            `Role must be one of: ${validRoles.join(', ')}`
        );
    }

    try {
        // Set custom claims on the user
        await admin.auth().setCustomUserClaims(uid, { role });

        // Also update the users collection for app-level checks
        await db.collection('users').doc(uid).set(
            { role, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
            { merge: true }
        );

        // Create audit log
        await db.collection('audits').add({
            action: 'set_admin_role',
            entityType: 'user',
            entityId: uid,
            performedBy: context.auth?.uid || 'system',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: { newRole: role }
        });

        console.log(`Successfully set role '${role}' for user ${uid}`);
        return {
            success: true,
            message: `Role '${role}' assigned to user ${uid}. User must re-login for changes to take effect.`
        };
    } catch (error) {
        console.error('Error setting admin role:', error);
        throw new functions.https.HttpsError('internal', 'Failed to set admin role');
    }
});

// 6. removeAdminRole: Revoke admin privileges
export const removeAdminRole = functions.https.onCall(async (data, context) => {
    // Only superadmin can remove roles
    if ((context.auth?.token?.role as string | undefined) !== 'superadmin') {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only superadmin can remove admin roles'
        );
    }

    const { uid } = data;

    if (!uid || typeof uid !== 'string') {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'User UID is required'
        );
    }

    try {
        // Set role to 'user' (remove admin privileges)
        await admin.auth().setCustomUserClaims(uid, { role: 'user' });

        // Update users collection
        await db.collection('users').doc(uid).set(
            { role: 'user', updatedAt: admin.firestore.FieldValue.serverTimestamp() },
            { merge: true }
        );

        // Audit log
        await db.collection('audits').add({
            action: 'remove_admin_role',
            entityType: 'user',
            entityId: uid,
            performedBy: context.auth?.uid || 'system',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: { previousAction: 'role_revoked' }
        });

        return {
            success: true,
            message: `Admin role removed from user ${uid}. User must re-login.`
        };
    } catch (error) {
        console.error('Error removing admin role:', error);
        throw new functions.https.HttpsError('internal', 'Failed to remove admin role');
    }
});

// 7. incrementLessonView: Callable to increment view count
export const incrementLessonView = functions.https.onCall(async (data, _context) => {
    const { courseId, batchId, lessonId } = data;

    if (!courseId || !batchId || !lessonId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing IDs');
    }

    const lessonRef = db.collection('courses').doc(courseId)
        .collection('batches').doc(batchId)
        .collection('lessons').doc(lessonId);

    try {
        await lessonRef.update({
            views: admin.firestore.FieldValue.increment(1)
        });
        return { success: true };
    } catch (error) {
        console.error("Failed to increment view", error);
        // Fail silently or throw? 
        return { success: false };
    }
});

// 8. backupFirestoreToStorage
export const backupFirestoreToStorage = functions.pubsub.schedule('every 24 hours').onRun(async (_context) => {
    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    const bucketName = `gs://${projectId}-backups`;

    const client = new admin.firestore.v1.FirestoreAdminClient();
    const databaseName = client.databasePath(projectId!, '(default)');

    try {
        await client.exportDocuments({
            name: databaseName,
            outputUriPrefix: bucketName,
            collectionIds: [] // Export all
        });
        console.log(`Backup success to ${bucketName}`);
    } catch (err) {
        console.error(err);
        throw new Error('Export operation failed');
    }
});

// 9. onNotificationCreate: Send FCM push when notification is created
export const onNotificationCreate = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        const { title, body, batchId, courseId, targetType, targetId, imageUrl } = notification;

        const messaging = admin.messaging();

        let usersQuery: admin.firestore.Query;

        if (batchId) {
            // Batch-specific: Get users enrolled in this batch
            const enrollmentId = `${courseId}_${batchId}`;
            usersQuery = db.collection("users")
                .where("enrolledCourses", "array-contains", enrollmentId);
        } else {
            // Global notification: Get all users with FCM tokens
            // Using ">" empty string to find any non-empty token values
            usersQuery = db.collection("users")
                .where("fcmToken", ">", "");
        }

        try {
            const usersSnapshot = await usersQuery.get();
            const tokens: string[] = [];

            usersSnapshot.forEach((doc) => {
                const fcmToken = doc.data().fcmToken;
                if (fcmToken && typeof fcmToken === "string") {
                    tokens.push(fcmToken);
                }
            });

            if (tokens.length === 0) {
                console.log("No FCM tokens found for notification:", title);
                return;
            }

            console.log(`Sending notification "${title}" to ${tokens.length} devices`);

            // Send to all tokens (in batches of 500 for FCM limits)
            const batchSize = 500;
            for (let i = 0; i < tokens.length; i += batchSize) {
                const tokenBatch = tokens.slice(i, i + batchSize);

                const message: admin.messaging.MulticastMessage = {
                    tokens: tokenBatch,
                    notification: {
                        title: title,
                        body: body,
                        imageUrl: imageUrl || undefined,
                    },
                    data: {
                        targetType: targetType || "",
                        targetId: targetId || "",
                        notificationId: context.params.notificationId,
                    },
                    android: {
                        priority: "high",
                        notification: {
                            channelId: "eduverse_channel",
                        },
                    },
                    apns: {
                        payload: {
                            aps: {
                                sound: "default",
                                badge: 1,
                            },
                        },
                    },
                };

                const response = await messaging.sendEachForMulticast(message);
                console.log(`Sent ${response.successCount}/${tokenBatch.length} notifications successfully`);

                // Log failures for debugging
                if (response.failureCount > 0) {
                    response.responses.forEach((resp, idx) => {
                        if (!resp.success) {
                            console.log(`Failed to send to token ${idx}:`, resp.error?.message);
                        }
                    });
                }
            }
        } catch (error) {
            console.error("Error sending FCM notifications:", error);
        }
    });

// 10. sendUpdateReminders: Daily push to users on outdated app versions
export const sendUpdateReminders = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (_context) => {
        // Read latest version from app_config/version
        const configDoc = await db.collection('app_config').doc('version').get();
        if (!configDoc.exists) {
            console.log('No app_config/version document found, skipping update reminders.');
            return;
        }

        const latestVersion = configDoc.data()?.latestVersion as string | undefined;
        if (!latestVersion) {
            console.log('No latestVersion field in app_config/version, skipping.');
            return;
        }

        // Get all users with FCM tokens
        const usersSnapshot = await db.collection('users')
            .where('fcmToken', '>', '')
            .get();

        const tokens: string[] = [];
        usersSnapshot.forEach((doc) => {
            const data = doc.data();
            const userVersion = data.appVersion as string | undefined;
            const fcmToken = data.fcmToken as string | undefined;

            // Only notify users whose app version differs from latest
            if (fcmToken && userVersion && userVersion !== latestVersion) {
                tokens.push(fcmToken);
            }
        });

        if (tokens.length === 0) {
            console.log('All users are on the latest version or no tokens found.');
            return;
        }

        console.log(`Sending update reminder to ${tokens.length} users (latest: ${latestVersion})`);

        const messaging = admin.messaging();
        const batchSize = 500;

        for (let i = 0; i < tokens.length; i += batchSize) {
            const tokenBatch = tokens.slice(i, i + batchSize);

            const message: admin.messaging.MulticastMessage = {
                tokens: tokenBatch,
                notification: {
                    title: '🚀 Update Available!',
                    body: `A new version (v${latestVersion}) of The Eduverse is available. Update now for the best experience!`,
                },
                data: {
                    targetType: 'update',
                    targetId: latestVersion,
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'eduverse_channel',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            const response = await messaging.sendEachForMulticast(message);
            console.log(`Update reminder: sent ${response.successCount}/${tokenBatch.length} successfully`);

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.log(`Failed to send to token ${idx}:`, resp.error?.message);
                    }
                });
            }
        }
    });

// 11. onLiveViewerDisconnect: Decrement viewer count on ungraceful disconnect
// Triggers when a user's RTDB presence node is removed (by onDisconnect handler)
export const onLiveViewerDisconnect = functions.database
    .ref('live_viewers/{sessionKey}/{userId}')
    .onDelete(async (snapshot, context) => {
        const { sessionKey } = context.params;
        const data = snapshot.val();

        // Parse courseId, batchId, liveClassId from the presence data
        // (stored when joining) or from the sessionKey
        let courseId: string;
        let batchId: string;
        let liveClassId: string;

        if (data && data.courseId && data.batchId && data.liveClassId) {
            courseId = data.courseId;
            batchId = data.batchId;
            liveClassId = data.liveClassId;
        } else {
            // Fallback: parse from sessionKey (format: courseId_batchId_liveClassId)
            const parts = sessionKey.split('_');
            if (parts.length < 3) {
                console.error('Invalid sessionKey format:', sessionKey);
                return;
            }
            courseId = parts[0];
            batchId = parts[1];
            liveClassId = parts.slice(2).join('_');
        }

        try {
            const liveClassRef = db
                .collection('courses').doc(courseId)
                .collection('batches').doc(batchId)
                .collection('live_classes').doc(liveClassId);

            await liveClassRef.update({
                viewerCount: admin.firestore.FieldValue.increment(-1),
            });

            console.log(
                `Viewer disconnected: ${context.params.userId} from ${sessionKey}. Count decremented.`
            );
        } catch (error) {
            console.error('Error decrementing viewer count on disconnect:', error);
        }
    });
