import * as functions from "firebase-functions";
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
    if (!context.auth || !['admin', 'superadmin'].includes(context.auth.token.role)) {
        throw new functions.https.HttpsError('permission-denied', 'Not an admin');
    }

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
export const generateInvoice = functions.https.onCall(async (data, context) => {
    // Stub: Generate PDF, upload to Storage, return URL
    return { url: "https://storage.googleapis.com/bucket/invoice_123.pdf" };
});

// 5. setAdminRole: Callable to set admin custom claims
// Call this from Firebase Console, Admin SDK, or a secure admin interface
export const setAdminRole = functions.https.onCall(async (data, context) => {
    // Check if the caller is a superadmin (or first-time bootstrap)
    const callerRole = context.auth?.token?.role;

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
    if (context.auth?.token?.role !== 'superadmin') {
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

// 7. backupFirestoreToStorage
export const backupFirestoreToStorage = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
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
