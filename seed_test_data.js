const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function seedTestData() {
  console.log("🌱 Seeding Legacy Batch Data into Firestore...");

  const testCourseId = "test_course_101";
  const testBatchId = "test_batch_202";
  const testUserId = "test_student_99";
  const testLessonId = "test_lesson_303";

  // 1. Seed Course Document
  console.log("   Writing course document...");
  await db.collection("courses").doc(testCourseId).set({
    title: "Mastering Physics JEE",
    subtitle: "Advanced Physics for JEE 2026",
    description: "A complete masterclass covering mechanics, electrodynamics, and modern physics.",
    emoji: "⚛️",
    gradientColors: [4279320802, 4278202470], // HSL/RGB Hex values as integers
    priceDefault: 4999.0,
    visibility: "published"
  });

  // 2. Seed Batch Document under Course
  console.log("   Writing batch document...");
  await db.collection("courses").doc(testCourseId).collection("batches").doc(testBatchId).set({
    name: "Morning Batch Cohort A",
    startDate: admin.firestore.Timestamp.fromDate(new Date("2026-06-01")),
    endDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-01")),
    realPrice: 4999.0,
    finalPrice: 3999.0,
    seatsTotal: 100,
    seatsLeft: 84,
    isActive: true,
    duration: "3 months"
  });

  // 3. Seed Lessons under Batch
  console.log("   Writing lessons subcollection...");
  await db.collection("courses").doc(testCourseId).collection("batches").doc(testBatchId).collection("lessons").doc(testLessonId).set({
    title: "Introduction to Kinematics",
    videoUrl: "https://www.youtube.com/watch?v=mock_video_id",
    description: "Learn about 1D and 2D motion vectors.",
    orderIndex: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 4. Seed Notes under Batch
  console.log("   Writing notes subcollection...");
  await db.collection("courses").doc(testCourseId).collection("batches").doc(testBatchId).collection("notes").doc("note_01").set({
    title: "Kinematics Formula Sheet",
    pdfUrl: "https://example.com/kinematics.pdf",
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 5. Seed user record with enrollment and progress
  console.log("   Writing user document, legacy enrollment and progress logs...");
  await db.collection("users").doc(testUserId).set({
    name: "John Doe",
    email: "johndoe@example.com",
    role: "student",
    enrolledCourses: [`${testCourseId}_${testBatchId}`]
  });

  // User enrolledCourses subcollection doc
  await db.collection("users").doc(testUserId).collection("enrolledCourses").doc(`${testCourseId}_${testBatchId}`).set({
    courseId: testCourseId,
    batchId: testBatchId,
    enrolledAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "active",
    purchaseId: "mock_purchase_order_888"
  });

  // User batchProgress doc
  const progressRef = db.collection("users").doc(testUserId).collection("batchProgress").doc(`${testCourseId}_${testBatchId}`);
  await progressRef.set({
    courseId: testCourseId,
    batchId: testBatchId,
    progressPercent: 1.0,
    completedLectures: 1,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  });

  // User watched lecture log
  await progressRef.collection("lectures").doc(testLessonId).set({
    watched: true,
    watchedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log("\n🎉 Seed Data successfully written to database!");
  console.log(`💡 You can now run the migration script to test the collapse structure on this course!`);
}

seedTestData().catch(console.error);
