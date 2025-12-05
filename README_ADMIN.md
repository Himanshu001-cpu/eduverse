# Admin Panel Error Fixes & Setup Guide

## Key Issues Fixed

### 1. Missing Dependencies
Added to `pubspec.yaml`:

```yaml
firebase_storage: ^13.0.0  # For media uploads
cloud_functions: ^5.2.0    # For callable functions
provider: ^6.1.2           # For state management
file_picker: ^8.1.6        # For CSV import and file uploads
```

### 2. Firebase Admin Service Fixes
**Issue:** Incorrect handling of `putData` return type

**Fix:** Changed from:
```dart
final task = await ref.putData(...);
return await task.ref.getDownloadURL();
```

To:
```dart
final uploadTask = ref.putData(...);
final snapshot = await uploadTask;
return await snapshot.ref.getDownloadURL();
```

**Issue:** Missing `createdAt` field on new courses

**Fix:** Added explicit `createdAt` timestamp in `saveCourse` method

### 3. CSV Importer Fixes
**Issue:** Simple comma split fails with quoted CSV fields

**Fix:** Implemented proper CSV parser that handles quoted fields

### 4. Admin Models
**Issue:** `toMap()` method not including `createdAt` for new courses

**Fix:** Removed `createdAt` from `toMap()` since it's set server-side

## Installation Steps

### 1. Update Dependencies
```bash
flutter pub get
```

### 2. Firebase Setup

#### Enable Authentication
```bash
# In Firebase Console:
# 1. Go to Authentication > Sign-in method
# 2. Enable Email/Password
```

#### Set Up Custom Claims (Required for Admin Access)
```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions
```

#### Set Admin Claims via Firebase CLI
```bash
# Using Firebase Admin SDK or Firebase Console
firebase functions:shell

# In shell:
const admin = require('firebase-admin');
admin.auth().setCustomUserClaims('USER_UID', {role: 'admin'});
```

Or create a function to set claims:
```typescript
// functions/src/index.ts
export const setAdminRole = functions.https.onCall(async (data, context) => {
  // Only allow if caller is already superadmin
  if (!context.auth || context.auth.token.role !== 'superadmin') {
    throw new functions.https.HttpsError('permission-denied', 'Not authorized');
  }
  
  await admin.auth().setCustomUserClaims(data.uid, {
    role: data.role
  });
  
  return { success: true };
});
```

### 3. Create First Admin User

**Option A: Via Firebase Console**
1. Go to Authentication > Users
2. Add user with email/password
3. Note the UID

**Option B: Via Code**
```dart
// Run this once to create admin user
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'admin@yourdomain.com',
  password: 'secure_password',
);
```
Then set claims using the function above.

### 4. Firestore Security Rules
Ensure your `firestore.rules` has admin checks:

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null && 
             request.auth.token.role in ['superadmin', 'admin', 'content_manager'];
    }
    
    match /courses/{courseId} {
      allow read: if resource.data.visibility == 'published' || isAdmin();
      allow write: if isAdmin();
      
      match /batches/{batchId} {
        allow read: if isAdmin() || 
                    get(/databases/$(database)/documents/courses/$(courseId)).data.visibility == 'published';
        allow write: if isAdmin();
        
        match /lectures/{lectureId} {
          allow read: if isAdmin();
          allow write: if isAdmin();
        }
      }
    }
    
    match /audits/{auditId} {
      allow read, write: if isAdmin();
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

### 5. Storage Rules
Update `storage.rules`:

```rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAdmin() {
      return request.auth != null && 
             request.auth.token.role in ['superadmin', 'admin', 'content_manager'];
    }
    
    match /courses/{courseId}/{allPaths=**} {
      allow write: if isAdmin();
      allow read: if true;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only storage
```

## Running the Admin Panel

### Web (Recommended for Admin)
```bash
flutter run -d chrome --web-port=8080
```

### Desktop
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

### Mobile (Development)
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Testing the Admin Panel

### 1. Login Test
1. Run the app
2. Should redirect to login if not authenticated
3. Login with admin credentials
4. Should see dashboard

### 2. Course Creation Test
1. Navigate to Courses
2. Click "+" button
3. Fill in course details
4. Save
5. Verify course appears in list
6. Check Firestore console for new document
7. Check Audits collection for log entry

### 3. Batch Management Test
1. Open a course
2. Click "Manage Batches"
3. Try CSV import with sample CSV:
```csv
name,price,seats,startDate,endDate
"Spring 2024",299.99,30,2024-03-01,2024-06-30
"Summer 2024",349.99,25,2024-06-01,2024-09-30
```
4. Verify batches created

### 4. Media Upload Test
1. Navigate to Lectures
2. Click "+" to add lecture
3. Upload a video file
4. Verify file uploaded to Storage
5. Check Storage console for file

### 5. Function Test (Purchase → Enrollment)
```dart
// Create test purchase document
await FirebaseFirestore.instance.collection('purchases').add({
  'userId': 'test_user_id',
  'courseId': 'course_id',
  'batchId': 'batch_id',
  'amount': 299.99,
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
});

// Check if onPurchaseCreate function triggers
// Should see:
// 1. Enrollment document created
// 2. Batch seatsLeft decremented
// 3. Audit log entry
// 4. Purchase status updated to 'success'
```

## Common Errors & Solutions

### Error: "Insufficient permissions"
**Solution:** Verify user has admin custom claims
```dart
// Check claims
final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
print(token.claims); // Should show role: 'admin'
```

### Error: "No Firebase App"
**Solution:** Ensure Firebase is initialized in `main.dart`:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Error: "Storage upload failed"
**Solution:** Check Storage rules and ensure admin has write permission

### Error: "CSV import not working"
**Solution:** Verify CSV format matches expected columns:
```
name,price,seats,startDate,endDate
```

### Error: "Courses not loading"
**Solution:**
- Check Firestore rules
- Verify courses collection exists
- Check console for errors
- Ensure user is authenticated

## Local Development with Emulators

### Setup Emulators
```bash
# Install
npm install -g firebase-tools

# Initialize (select Firestore, Functions, Auth, Storage)
firebase init emulators

# Start emulators
firebase emulators:start
```

### Configure Flutter to Use Emulators
```dart
// In firebase_admin_service.dart constructor
FirebaseAdminService() {
  // Use emulators in debug mode
  if (kDebugMode) {
    _db.useFirestoreEmulator('localhost', 8080);
    _auth.useAuthEmulator('localhost', 9099);
    _storage.useStorageEmulator('localhost', 9199);
    _functions.useFunctionsEmulator('localhost', 5001);
  }
}
```

## Production Deployment

### Build Web Admin Panel
```bash
flutter build web --release
```

### Deploy to Firebase Hosting
```bash
# Initialize hosting
firebase init hosting

# Set public directory to build/web
# Configure as single-page app: Yes
# Set up automatic builds: Optional

# Deploy
firebase deploy --only hosting
```

## Security Checklist

- ✅ Custom claims properly set for all admins
- ✅ Firestore rules prevent non-admin writes
- ✅ Storage rules prevent non-admin uploads
- ✅ Functions validate admin tokens
- ✅ Audit logs enabled for all actions
- ✅ Production Firebase project configured
- ✅ Environment variables properly set

## Monitoring & Maintenance

### Check Audit Logs
```dart
// Query recent audit logs
final audits = await FirebaseFirestore.instance
    .collection('audits')
    .orderBy('timestamp', descending: true)
    .limit(100)
    .get();
```

### Monitor Function Errors
Check Firebase Console → Functions → Logs

### Storage Usage
Check Firebase Console → Storage → Usage

### Cost Monitoring
Check Firebase Console → Usage and billing

## Support

For issues:
1. Check Firebase Console logs
2. Check Flutter debug console
3. Verify Firestore/Storage rules
4. Test with emulators first
5. Review audit logs for clues
