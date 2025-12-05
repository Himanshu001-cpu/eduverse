/**
 * Admin Setup Script
 * 
 * This script sets custom claims on a Firebase user to make them an admin.
 * Run this ONCE to bootstrap your first superadmin user.
 * 
 * Prerequisites:
 * 1. Download your Firebase service account key from:
 *    Firebase Console → Project Settings → Service Accounts → Generate new private key
 * 2. Save the file as `service-account-key.json` in this directory (DO NOT commit to git!)
 * 
 * Usage:
 *   node set-admin.js <USER_UID> <ROLE>
 * 
 * Example:
 *   node set-admin.js abc123xyz superadmin
 * 
 * Valid roles: superadmin, admin, content_manager, support, user
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (error) {
    console.error('\n❌ Error: Cannot find service-account-key.json');
    console.error('\nTo fix this:');
    console.error('1. Go to Firebase Console → Project Settings → Service Accounts');
    console.error('2. Click "Generate new private key"');
    console.error('3. Save the downloaded file as "service-account-key.json" in the functions folder');
    console.error('\n⚠️  NEVER commit this file to git!\n');
    process.exit(1);
}

const validRoles = ['superadmin', 'admin', 'content_manager', 'support', 'user'];

async function setAdminRole(uid, role) {
    if (!uid) {
        console.error('❌ Error: User UID is required');
        console.error('Usage: node set-admin.js <USER_UID> <ROLE>');
        process.exit(1);
    }

    if (!validRoles.includes(role)) {
        console.error(`❌ Error: Invalid role "${role}"`);
        console.error(`Valid roles: ${validRoles.join(', ')}`);
        process.exit(1);
    }

    try {
        // Verify the user exists
        const userRecord = await admin.auth().getUser(uid);
        console.log(`\n📧 User found: ${userRecord.email || userRecord.phoneNumber || uid}`);

        // Set custom claims
        await admin.auth().setCustomUserClaims(uid, { role });
        console.log(`✅ Custom claim set: { role: "${role}" }`);

        // Also update Firestore users collection
        await admin.firestore().collection('users').doc(uid).set(
            {
                role,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            },
            { merge: true }
        );
        console.log(`✅ Firestore users/${uid} updated with role: "${role}"`);

        console.log('\n🎉 Success! The user is now a', role);
        console.log('\n⚠️  IMPORTANT: The user must log out and log back in for changes to take effect.\n');

        process.exit(0);
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            console.error(`❌ Error: No user found with UID: ${uid}`);
        } else {
            console.error('❌ Error:', error.message);
        }
        process.exit(1);
    }
}

// Get command line arguments
const args = process.argv.slice(2);
const uid = args[0];
const role = args[1] || 'admin';

setAdminRole(uid, role);
