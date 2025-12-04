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
            console.error("Enrollment failed", error);
            await snap.ref.update({ status: "failed", error: error.toString() });
        }
    });

// 2. enrollStudent: Callable for admins
export const enrollStudent = functions.https.onCall(async (data, context) => {
    if (!context.auth || !['admin', 'superadmin'].includes(context.auth.token.role)) {
        throw new functions.https.HttpsError('permission-denied', 'Not an admin');
    }

    const { userId, courseId, batchId } = data;
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

// 5. backupFirestoreToStorage
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
