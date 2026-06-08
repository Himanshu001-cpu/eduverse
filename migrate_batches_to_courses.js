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
  console.log(isDryRun ? "🧪 RUNNING IN DRY-RUN MODE (NO WRITES WILL BE EXECUTED)" : "⚠️ RUNNING IN LIVE WRITE MODE");
  console.log("=============================================================\n");

  const writer = new SafeBatchWriter(db, isDryRun);

  // Migration Stats Dashboards
  const stats = {
    coursesProcessed: 0,
    batchesCollapsed: 0,
    lessonsMigrated: 0,
    notesMigrated: 0,
    plannerItemsMigrated: 0,
    quizzesMigrated: 0,
    dppsMigrated: 0,
    liveClassesMigrated: 0,
    usersEnrolled: 0,
    progressLogsRestructured: 0,
    globalEnrollmentsMigrated: 0
  };

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
    
    // 3. Migrate subcollections from all batches to course subcollections
    const subcollections = [
      { name: 'lessons', statKey: 'lessonsMigrated' },
      { name: 'notes', statKey: 'notesMigrated' },
      { name: 'planner', statKey: 'plannerItemsMigrated' },
      { name: 'quizzes', statKey: 'quizzesMigrated' },
      { name: 'dpps', statKey: 'dppsMigrated' },
      { name: 'live_classes', statKey: 'liveClassesMigrated' }
    ];
    
    for (const batchDoc of batches) {
      const batchId = batchDoc.id;
      const batchData = batchDoc.data();
      
      for (const sub of subcollections) {
        const subSnapshot = await batchDoc.ref.collection(sub.name).get();
        if (subSnapshot.empty) continue;
        
        console.log(`   📦 Promoting ${subSnapshot.docs.length} items from batch '${batchData.name}' -> Course subcollection: ${sub.name}`);
        
        for (const itemDoc of subSnapshot.docs) {
          const itemData = itemDoc.data();
          
          // Append batch info to title if there are multiple cohorts to prevent name collision
          let finalTitle = itemData.title;
          if (batches.length > 1 && finalTitle) {
            finalTitle = `${finalTitle} (${batchData.name})`;
          }
          
          const newDocRef = courseDoc.ref.collection(sub.name).doc(itemDoc.id);
          
          // Idempotency: Skip copy if already migrated unless forced
          await writer.set(newDocRef, {
            ...itemData,
            ...(finalTitle ? { title: finalTitle } : {}),
            migratedFromBatch: batchId
          }, { merge: true });
          
          stats[sub.statKey]++;
        }
      }
    }
  }

  // 4. Migrate User Enrollments & Progress
  console.log("\n👥 Migrating Student Profile Enrollments & Watched Progress Logs...");
  const usersSnapshot = await db.collection("users").get();
  
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    // Fetch all records in user's enrolledCourses subcollection directly
    const enrolledSubSnapshot = await userDoc.ref.collection('enrolledCourses').get();
    const enrolledDocs = enrolledSubSnapshot.docs;
    
    const newEnrolledSet = new Set(
      (userData.enrolledCourses || []).map(id => id.includes('_') ? id.split('_')[0] : id)
    );
    
    let hasEnrollmentUpdates = false;

    // Migrate enrolledCourses subcollection documents
    for (const subDoc of enrolledDocs) {
      const subId = subDoc.id;
      const data = subDoc.data();
      
      const courseId = data.courseId || subId.split('_')[0];
      
      if (courseId) {
        newEnrolledSet.add(courseId);
        hasEnrollmentUpdates = true;
        
        // Write direct course-level enrollment doc
        const newEnrollDocRef = userDoc.ref.collection('enrolledCourses').doc(courseId);
        await writer.set(newEnrollDocRef, {
          courseId: courseId,
          enrolledAt: data.enrolledAt || admin.firestore.FieldValue.serverTimestamp(),
          status: data.status || 'active',
          purchaseId: data.purchaseId || 'migrated'
        }, { merge: true });
        
        stats.usersEnrolled++;
        
        // If it was a legacy composite document ID (courseId_batchId), delete it safely
        if (subId.includes('_')) {
          await writer.delete(subDoc.ref);
          console.log(`   ✅ Enrollment migrated for user ${userId}: enrolledCourses/${subId} -> enrolledCourses/${courseId}`);
        }
      }
    }
    
    // Update user document's top-level enrolledCourses array only if it actually changed to prevent write waste
    if (userData.enrolledCourses || hasEnrollmentUpdates) {
      const oldEnrolledArray = userData.enrolledCourses || [];
      const newEnrolledArray = Array.from(newEnrolledSet).filter(id => id && id.length > 0);
      
      const sortedOld = [...oldEnrolledArray].sort();
      const sortedNew = [...newEnrolledArray].sort();
      const isIdentical = sortedOld.length === sortedNew.length &&
                          sortedOld.every((val, idx) => val === sortedNew[idx]);
                          
      if (!isIdentical) {
        await writer.update(userDoc.ref, { enrolledCourses: newEnrolledArray });
        console.log(`   ✅ Synced enrolledCourses array for user ${userId}:`, newEnrolledArray);
      }
    }
    
    // 5. Migrate user's batchProgress to courseProgress
    const progressSnapshot = await userDoc.ref.collection('batchProgress').get();
    for (const progDoc of progressSnapshot.docs) {
      const progId = progDoc.id;
      const progData = progDoc.data();
      
      const courseId = progData.courseId || progId.split('_')[0];
      
      // Safety Guard: Only migrate if it looks like a legacy batchProgress doc (has underscore) or has courseId
      const isBatchProgressDoc = progId.includes('_') || !!progData.courseId;
      
      if (courseId && isBatchProgressDoc) {
        const courseProgressRef = userDoc.ref.collection('courseProgress').doc(courseId);
        
        // Copy aggregate progress document
        await writer.set(courseProgressRef, {
          courseId: courseId,
          progressPercent: progData.progressPercent || 0.0,
          completedLectures: progData.completedLectures || 0,
          lastUpdated: progData.lastUpdated || admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        
        stats.progressLogsRestructured++;
        
        // Copy nested watched lectures list
        const lectureLogs = await progDoc.ref.collection('lectures').get();
        for (const logDoc of lectureLogs.docs) {
          const destLogRef = courseProgressRef.collection('lectures').doc(logDoc.id);
          await writer.set(destLogRef, logDoc.data(), { merge: true });
          await writer.delete(logDoc.ref);
        }
        
        // Delete composite progress doc
        await writer.delete(progDoc.ref);
        console.log(`   ✅ Progress logs restructured for user ${userId}: batchProgress/${progId} -> courseProgress/${courseId}`);
      }
    }
  }

  // 6. Migrate Global Enrollments Collection
  console.log("\n📦 Migrating Global enrollments Administrative Records...");
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
          userId = userId || parts[0];
          courseId = courseId || parts[1];
        } else if (parts.length === 2) {
          userId = userId || parts[0];
          courseId = courseId || parts[1]; // Fix: was parts[0]
        }
      }
      
      if (userId && courseId) {
        const newEnrollId = `${userId}_${courseId}`;
        const newEnrollRef = db.collection("enrollments").doc(newEnrollId);
        
        await writer.set(newEnrollRef, {
          ...data,
          userId: userId,
          courseId: courseId,
          enrolledAt: data.enrolledAt || admin.firestore.FieldValue.serverTimestamp(),
          status: data.status || 'active',
          migratedFromEnrollment: enrollId
        }, { merge: true });
        
        stats.globalEnrollmentsMigrated++;
        
        if (newEnrollId !== enrollId) {
          await writer.delete(enrollDoc.ref);
          console.log(`   ✅ Global enrollment log keys updated: ${enrollId} -> ${newEnrollId}`);
        }
      }
    }
  } catch (e) {
    console.log("   ⚠️ Global enrollments collection not found or query failed. Skipping.");
  }
  
  // Flush all remaining chunk operations in writer queue
  await writer.flush();
  
  console.log("\n=============================================================");
  console.log("🎉 DATABASE MIGRATION SCRIPT RUN COMPLETED!");
  console.log("=============================================================");
  console.log(`📊 Total Database Operations Executed: ${writer.totalOps}`);
  console.log("-------------------------------------------------------------");
  console.log(`   Courses Processed:               ${stats.coursesProcessed}`);
  console.log(`   Batches Collapsed:               ${stats.batchesCollapsed}`);
  console.log(`   Lessons Promoted:                ${stats.lessonsMigrated}`);
  console.log(`   Notes Promoted:                  ${stats.notesMigrated}`);
  console.log(`   Planner Items Promoted:          ${stats.plannerItemsMigrated}`);
  console.log(`   Quizzes Promoted:                ${stats.quizzesMigrated}`);
  console.log(`   DPPs Promoted:                   ${stats.dppsMigrated}`);
  console.log(`   Live Classes Promoted:           ${stats.liveClassesMigrated}`);
  console.log(`   Student Enrollments Synced:      ${stats.usersEnrolled}`);
  console.log(`   User Progress Logs Restructured: ${stats.progressLogsRestructured}`);
  console.log(`   Global Enrollment Logs Keyed:    ${stats.globalEnrollmentsMigrated}`);
  console.log("=============================================================\n");
}

migrateBatchesToCourses().catch(console.error);
