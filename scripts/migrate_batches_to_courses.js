const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Detect Dry-Run Flag
const isDryRun = process.argv.includes('--dry-run');

/**
 * Enterprise-grade SafeBatchWriter
 * Automates Firestore batch management, chunking operations to a safe limit of 450 (below the 500 limit).
 * Seamlessly handles Dry-Run visualization without mutating database state.
 * Implements full async/await scheduling to eliminate any microtask race conditions.
 */
class SafeBatchWriter {
  constructor(db, isDryRun = false) {
    this.db = db;
    this.isDryRun = isDryRun;
    this.batch = db.batch();
    this.opCount = 0;
    this.totalOps = 0;
  }

  async set(ref, data, options = {}) {
    if (this.isDryRun) {
      console.log(`   [DRY-RUN] SET: ${ref.path}`);
      this.totalOps++;
      return;
    }
    this.batch.set(ref, data, options);
    await this._increment();
  }

  async update(ref, data) {
    if (this.isDryRun) {
      console.log(`   [DRY-RUN] UPDATE: ${ref.path}`);
      this.totalOps++;
      return;
    }
    this.batch.update(ref, data);
    await this._increment();
  }

  async delete(ref) {
    if (this.isDryRun) {
      console.log(`   [DRY-RUN] DELETE: ${ref.path}`);
      this.totalOps++;
      return;
    }
    this.batch.delete(ref);
    await this._increment();
  }

  async _increment() {
    this.opCount++;
    this.totalOps++;
    if (this.opCount >= 450) {
      await this.commitSync();
    }
  }

  async commitSync() {
    if (this.opCount === 0) return;
    if (this.isDryRun) {
      this.opCount = 0;
      return;
    }
    const currentCount = this.opCount;
    await this.batch.commit();
    console.log(`   ⚡ Committed chunk of ${currentCount} operations.`);
    this.batch = this.db.batch();
    this.opCount = 0;
  }

  async flush() {
    await this.commitSync();
  }
}

async function migrateBatchesToCourses() {
  console.log("=============================================================");
  console.log("🚀 STARTING BATCH-TO-COURSE DATABASE MIGRATION SCRIPT");
  console.log("   MODE: BACKWARDS-COMPATIBLE (old app versions will still work)");
  console.log(isDryRun ? "🧪 RUNNING IN DRY-RUN MODE (NO WRITES WILL BE EXECUTED)" : "⚠️ RUNNING IN LIVE WRITE MODE");
  console.log("=============================================================");
  console.log("");
  console.log("   ℹ️  This script COPIES data to new course-level paths");
  console.log("   ℹ️  It NEVER DELETES legacy batch data, enrollment docs, or progress docs");
  console.log("   ℹ️  Both old and new app versions will continue to work after migration");
  console.log("");

  const writer = new SafeBatchWriter(db, isDryRun);

  // Migration Stats Dashboards
  const stats = {
    coursesProcessed: 0,
    batchesCollapsed: 0,
    lessonsCopied: 0,
    notesCopied: 0,
    plannerItemsCopied: 0,
    quizzesCopied: 0,
    dppsCopied: 0,
    liveClassesCopied: 0,
    enrollmentDocsCreated: 0,
    progressDocsCopied: 0,
    globalEnrollmentsDualWritten: 0,
    legacyDocsPreserved: 0
  };

  // =========================================================================
  // PHASE 1: Promote batch content to course-level (COPY, not MOVE)
  // =========================================================================
  console.log("\n━━━ PHASE 1: Promoting Batch Content to Course Level ━━━");

  const coursesSnapshot = await db.collection("courses").get();

  for (const courseDoc of coursesSnapshot.docs) {
    const courseId = courseDoc.id;
    const courseData = courseDoc.data();
    console.log(`\n📚 Processing Course: ${courseData.title || courseId}`);
    stats.coursesProcessed++;
    
    // 1. Fetch nested batches for the course
    const batchesSnapshot = await courseDoc.ref.collection("batches").get();
    const batches = batchesSnapshot.docs;
    
    if (batches.length === 0) {
      console.log(`   ⚠️ Course has no batches. Skipping.`);
      continue;
    }
    
    console.log(`   Found ${batches.length} batches to collapse.`);
    stats.batchesCollapsed += batches.length;
    
    // Sort batches: active batches first, then by startDate DESC
    batches.sort((a, b) => {
      const aData = a.data();
      const bData = b.data();
      const aActive = aData.isActive ?? true;
      const bActive = bData.isActive ?? true;
      if (aActive !== bActive) {
        return aActive ? -1 : 1;
      }
      const aDate = aData.startDate && aData.startDate.toDate ? aData.startDate.toDate() : new Date(0);
      const bDate = bData.startDate && bData.startDate.toDate ? bData.startDate.toDate() : new Date(0);
      return bDate.getTime() - aDate.getTime();
    });
    
    const primaryBatchDoc = batches[0];
    const primaryBatchData = primaryBatchDoc.data();
    console.log(`   Selected Batch '${primaryBatchData.name}' as primary source for pricing & schedules.`);
    
    // 2. Promote Primary Batch fields to Course document
    //    (adds new fields; does NOT remove any existing course fields)
    await writer.update(courseDoc.ref, {
      realPrice: primaryBatchData.realPrice || courseData.priceDefault || 0.0,
      finalPrice: primaryBatchData.finalPrice || courseData.priceDefault || 0.0,
      startDate: primaryBatchData.startDate || admin.firestore.FieldValue.serverTimestamp(),
      endDate: primaryBatchData.endDate || admin.firestore.FieldValue.serverTimestamp(),
      seatsTotal: primaryBatchData.seatsTotal || 0,
      seatsLeft: primaryBatchData.seatsLeft || 0,
      isActive: primaryBatchData.isActive ?? true,
      duration: primaryBatchData.duration || "Flexible",
      migratedFromPrimaryBatch: primaryBatchDoc.id
    });
    
    // 3. COPY subcollections from batches to course-level subcollections
    //    ⚠️ CRITICAL: We do NOT delete the original batch subcollection items.
    //    The old app still reads from courses/{courseId}/batches/{batchId}/lessons etc.
    const subcollections = [
      { name: 'lessons', statKey: 'lessonsCopied' },
      { name: 'notes', statKey: 'notesCopied' },
      { name: 'planner', statKey: 'plannerItemsCopied' },
      { name: 'quizzes', statKey: 'quizzesCopied' },
      { name: 'dpps', statKey: 'dppsCopied' },
      { name: 'live_classes', statKey: 'liveClassesCopied' }
    ];
    
    for (const batchDoc of batches) {
      const batchId = batchDoc.id;
      const batchData = batchDoc.data();
      
      for (const sub of subcollections) {
        const subSnapshot = await batchDoc.ref.collection(sub.name).get();
        if (subSnapshot.empty) continue;
        
        console.log(`   📦 Copying ${subSnapshot.docs.length} items from batch '${batchData.name}' -> Course/${sub.name} (originals PRESERVED)`);
        
        for (const itemDoc of subSnapshot.docs) {
          const itemData = itemDoc.data();
          
          // Append batch info to title if there are multiple cohorts to prevent name collision
          let finalTitle = itemData.title;
          if (batches.length > 1 && finalTitle) {
            finalTitle = `${finalTitle} (${batchData.name})`;
          }
          
          const newDocRef = courseDoc.ref.collection(sub.name).doc(itemDoc.id);
          
          // Idempotent merge-write to course-level subcollection
          await writer.set(newDocRef, {
            ...itemData,
            ...(finalTitle ? { title: finalTitle } : {}),
            migratedFromBatch: batchId
          }, { merge: true });
          
          // ✅ Original batch subcollection document is NOT deleted
          stats.legacyDocsPreserved++;
          stats[sub.statKey]++;
        }
      }
    }
  }

  // =========================================================================
  // PHASE 2: Dual-write User Enrollments (ADD new docs, KEEP legacy docs)
  // =========================================================================
  console.log("\n━━━ PHASE 2: Dual-Writing User Enrollments & Progress ━━━");
  const usersSnapshot = await db.collection("users").get();
  
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    // Fetch all records in user's enrolledCourses subcollection
    const enrolledSubSnapshot = await userDoc.ref.collection('enrolledCourses').get();
    const enrolledDocs = enrolledSubSnapshot.docs;
    
    // Build a set of pure courseIds from existing enrollments
    // We ADD courseId entries but NEVER remove the old courseId_batchId entries
    const existingArray = userData.enrolledCourses || [];
    const newEnrolledSet = new Set(existingArray); // Keep ALL existing entries
    
    let hasNewEntries = false;

    for (const subDoc of enrolledDocs) {
      const subId = subDoc.id;
      const data = subDoc.data();
      
      const courseId = data.courseId || subId.split('_')[0];
      
      if (courseId) {
        // Add the pure courseId to the array set (old entries are kept too)
        if (!newEnrolledSet.has(courseId)) {
          newEnrolledSet.add(courseId);
          hasNewEntries = true;
        }
        
        // Write a NEW course-level enrollment doc (courseId as doc ID)
        // ⚠️ CRITICAL: We do NOT delete the old courseId_batchId doc
        const isLegacyComposite = subId.includes('_');
        if (isLegacyComposite || subId !== courseId) {
          const newEnrollDocRef = userDoc.ref.collection('enrolledCourses').doc(courseId);
          await writer.set(newEnrollDocRef, {
            courseId: courseId,
            batchId: data.batchId || '', // preserve for old app compat
            enrolledAt: data.enrolledAt || admin.firestore.FieldValue.serverTimestamp(),
            status: data.status || 'active',
            purchaseId: data.purchaseId || 'migrated',
            migratedFrom: subId
          }, { merge: true });
          
          stats.enrollmentDocsCreated++;
          console.log(`   ✅ Dual-write enrollment for user ${userId}: ADDED enrolledCourses/${courseId} (KEPT ${subId})`);
        }
        
        // ✅ Legacy composite document is PRESERVED
        stats.legacyDocsPreserved++;
      }
    }
    
    // Update user document's top-level enrolledCourses array
    // We APPEND new courseId entries while KEEPING old courseId_batchId entries
    if (hasNewEntries) {
      const newEnrolledArray = Array.from(newEnrolledSet).filter(id => id && id.length > 0);
      await writer.update(userDoc.ref, { enrolledCourses: newEnrolledArray });
      console.log(`   ✅ Appended to enrolledCourses array for user ${userId}:`, newEnrolledArray);
    }
    
    // =====================================================================
    // PHASE 2b: COPY batchProgress -> courseProgress (KEEP originals)
    // =====================================================================
    const progressSnapshot = await userDoc.ref.collection('batchProgress').get();
    for (const progDoc of progressSnapshot.docs) {
      const progId = progDoc.id;
      const progData = progDoc.data();
      
      const courseId = progData.courseId || progId.split('_')[0];
      
      // Safety Guard: Only process if it looks like a legacy batchProgress doc
      const isBatchProgressDoc = progId.includes('_') || !!progData.courseId;
      
      if (courseId && isBatchProgressDoc) {
        const courseProgressRef = userDoc.ref.collection('courseProgress').doc(courseId);
        
        // Copy aggregate progress document to new path
        await writer.set(courseProgressRef, {
          courseId: courseId,
          progressPercent: progData.progressPercent || 0.0,
          completedLectures: progData.completedLectures || 0,
          lastUpdated: progData.lastUpdated || admin.firestore.FieldValue.serverTimestamp(),
          migratedFrom: `batchProgress/${progId}`
        }, { merge: true });
        
        stats.progressDocsCopied++;
        
        // Copy nested watched lectures list to new path
        const lectureLogs = await progDoc.ref.collection('lectures').get();
        for (const logDoc of lectureLogs.docs) {
          const destLogRef = courseProgressRef.collection('lectures').doc(logDoc.id);
          await writer.set(destLogRef, logDoc.data(), { merge: true });
          
          // ✅ Original lecture log is NOT deleted
          stats.legacyDocsPreserved++;
        }
        
        // ✅ Original batchProgress document is NOT deleted
        stats.legacyDocsPreserved++;
        console.log(`   ✅ Progress COPIED for user ${userId}: batchProgress/${progId} -> courseProgress/${courseId} (original KEPT)`);
      }
    }
  }

  // =========================================================================
  // PHASE 3: Dual-write Global Enrollments (ADD new keys, KEEP legacy keys)
  // =========================================================================
  console.log("\n━━━ PHASE 3: Dual-Writing Global Enrollment Records ━━━");
  try {
    const globalEnrollmentsSnap = await db.collection("enrollments").get();
    for (const enrollDoc of globalEnrollmentsSnap.docs) {
      const enrollId = enrollDoc.id;
      const data = enrollDoc.data();
      
      let userId = data.userId;
      let courseId = data.courseId;
      
      if (enrollId.includes('_')) {
        const parts = enrollId.split('_');
        if (parts.length === 3) {
          // Format: userId_courseId_batchId
          userId = userId || parts[0];
          courseId = courseId || parts[1];
        } else if (parts.length === 2) {
          // Format: userId_courseId
          userId = userId || parts[0];
          courseId = courseId || parts[1];
        }
      }
      
      if (userId && courseId) {
        const newEnrollId = `${userId}_${courseId}`;
        
        // Only create a new doc if the key actually changed
        if (newEnrollId !== enrollId) {
          const newEnrollRef = db.collection("enrollments").doc(newEnrollId);
          
          await writer.set(newEnrollRef, {
            ...data,
            userId: userId,
            courseId: courseId,
            enrolledAt: data.enrolledAt || admin.firestore.FieldValue.serverTimestamp(),
            status: data.status || 'active',
            migratedFromEnrollment: enrollId
          }, { merge: true });
          
          // ✅ Original enrollment document is NOT deleted
          stats.legacyDocsPreserved++;
          console.log(`   ✅ Global enrollment DUAL-WRITTEN: ADDED ${newEnrollId} (KEPT ${enrollId})`);
        }
        
        stats.globalEnrollmentsDualWritten++;
      }
    }
  } catch (e) {
    console.log("   ⚠️ Global enrollments collection not found or query failed. Skipping.");
  }
  
  // Flush all remaining chunk operations in writer queue
  await writer.flush();
  
  console.log("\n=============================================================");
  console.log("🎉 DATABASE MIGRATION SCRIPT COMPLETED (BACKWARDS-COMPATIBLE)!");
  console.log("=============================================================");
  console.log(`📊 Total Database Operations Executed: ${writer.totalOps}`);
  console.log("-------------------------------------------------------------");
  console.log(`   Courses Processed:               ${stats.coursesProcessed}`);
  console.log(`   Batches Collapsed:               ${stats.batchesCollapsed}`);
  console.log(`   Lessons Copied to Course:        ${stats.lessonsCopied}`);
  console.log(`   Notes Copied to Course:          ${stats.notesCopied}`);
  console.log(`   Planner Items Copied:            ${stats.plannerItemsCopied}`);
  console.log(`   Quizzes Copied:                  ${stats.quizzesCopied}`);
  console.log(`   DPPs Copied:                     ${stats.dppsCopied}`);
  console.log(`   Live Classes Copied:             ${stats.liveClassesCopied}`);
  console.log(`   New Enrollment Docs Created:     ${stats.enrollmentDocsCreated}`);
  console.log(`   Progress Docs Copied:            ${stats.progressDocsCopied}`);
  console.log(`   Global Enrollments Dual-Written: ${stats.globalEnrollmentsDualWritten}`);
  console.log(`   Legacy Docs Preserved (not deleted): ${stats.legacyDocsPreserved}`);
  console.log("=============================================================");
  console.log("");
  console.log("   ✅ Old app versions will continue to work!");
  console.log("   ✅ New app versions will read from course-level paths.");
  console.log("   ℹ️  Once all users have updated, run the cleanup script to");
  console.log("      remove legacy batch documents and composite enrollment keys.");
  console.log("=============================================================\n");
}

migrateBatchesToCourses().catch(console.error);
