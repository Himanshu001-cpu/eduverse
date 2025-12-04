# Eduverse Admin Panel

## Setup Instructions

1.  **Firebase Project**:
    *   Create a project at [console.firebase.google.com](https://console.firebase.google.com).
    *   Enable **Authentication** (Email/Password).
    *   Enable **Firestore** (Production mode).
    *   Enable **Storage**.
    *   Enable **Functions** (Blaze plan required).

2.  **Deploy Rules & Functions**:
    ```bash
    # Install tools
    npm install -g firebase-tools
    firebase login

    # Deploy Rules
    firebase deploy --only firestore:rules,storage:rules

    # Deploy Functions
    cd functions
    npm install
    npm run build
    firebase deploy --only functions
    ```

3.  **Create Admin User**:
    *   Sign up a user in the app or console.
    *   Run the claim script (create `set_admin.js` locally):
        ```javascript
        const admin = require('firebase-admin');
        admin.initializeApp();
        admin.auth().setCustomUserClaims('USER_UID', { role: 'superadmin' });
        ```

4.  **Run Admin Panel**:
    *   **Mobile**: `flutter run -t lib/admin/admin_app.dart`
    *   **Web**: `flutter run -d chrome -t lib/admin/admin_app.dart`

5.  **Local Emulators**:
    ```bash
    firebase emulators:start
    ```

## Features
*   **Dashboard**: Stats & Audit Logs.
*   **Courses**: CRUD with Draft/Published states.
*   **Batches**: CSV Import & Management.
*   **Lectures**: Media Upload & Reordering.
*   **Security**: RBAC via Custom Claims.
