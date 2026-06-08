const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function verifyData() {
  console.log("🔍 STARTING DATABASE VERIFICATION...");

  const testCourseId = "test_course_101";
  const testUserId = "test_student_99";

  // 1. Verify Course Document
  console.log("\n--- Checking Course Document ---");
  const courseDoc = await db.collection("courses").doc(testCourseId).get();
  if (courseDoc.exists) {
    console.log("Course data:", courseDoc.data());
  } else {
    console.log("❌ Course not found!");
  }

  // 2. Verify Promoted Subcollections (lessons, notes)
  console.log("\n--- Checking Promoted Lessons ---");
  const lessonsSnap = await db.collection("courses").doc(testCourseId).collection("lessons").get();
  lessonsSnap.docs.forEach(doc => {
    console.log(`Lesson ID: ${doc.id}, Data:`, doc.data());
  });

  console.log("\n--- Checking Promoted Notes ---");
  const notesSnap = await db.collection("courses").doc(testCourseId).collection("notes").get();
  notesSnap.docs.forEach(doc => {
    console.log(`Note ID: ${doc.id}, Data:`, doc.data());
  });

  // 3. Verify User Document enrolledCourses array
  console.log("\n--- Checking User Top-Level Profile ---");
  const userDoc = await db.collection("users").doc(testUserId).get();
  if (userDoc.exists) {
    console.log("User enrolledCourses array:", userDoc.data().enrolledCourses);
  } else {
    console.log("❌ User not found!");
  }

  // 4. Verify User's enrolledCourses Subcollection
  console.log("\n--- Checking User Enrolled Courses Subcollection ---");
  const userEnrollmentsSnap = await db.collection("users").doc(testUserId).collection("enrolledCourses").get();
  userEnrollmentsSnap.docs.forEach(doc => {
    console.log(`Enrollment ID: ${doc.id}, Data:`, doc.data());
  });

  // 5. Verify User's courseProgress Subcollection
  console.log("\n--- Checking User Course Progress ---");
  const userProgressSnap = await db.collection("users").doc(testUserId).collection("courseProgress").get();
  for (const doc of userProgressSnap.docs) {
    console.log(`Progress ID: ${doc.id}, Data:`, doc.data());
    
    // Check nested lectures
    const lecturesSnap = await doc.ref.collection("lectures").get();
    lecturesSnap.docs.forEach(lDoc => {
      console.log(`  └─ Lecture ID: ${lDoc.id}, Data:`, lDoc.data());
    });
  }

  // 6. Verify Deletion of Legacy Subcollections (batches, batchProgress)
  console.log("\n--- Checking Deletion of Legacy Subcollections ---");
  const batchesSnap = await db.collection("courses").doc(testCourseId).collection("batches").get();
  console.log(`Legacy Batches subcollection count: ${batchesSnap.docs.length}`);

  const legacyProgressSnap = await db.collection("users").doc(testUserId).collection("batchProgress").get();
  console.log(`Legacy batchProgress subcollection count: ${legacyProgressSnap.docs.length}`);

  console.log("\n✅ VERIFICATION COMPLETE!");
}

verifyData().catch(console.error);
