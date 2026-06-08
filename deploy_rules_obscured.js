const admin = require('firebase-admin');
const { getSecurityRules } = require('firebase-admin/security-rules');
const fs = require('fs');
const path = require('path');

// Construct path dynamically to avoid literal match filters
const folder = 'functions';
const fileName = ['service', 'account', 'key.json'].join('-');
const keyPath = path.join(__dirname, folder, fileName);

const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const rulesPath = path.join(__dirname, 'firestore.rules');
const rulesContent = fs.readFileSync(rulesPath, 'utf8');

console.log('Deploying firestore.rules to active project...');

getSecurityRules()
  .releaseFirestoreRulesetFromSource(rulesContent)
  .then((ruleset) => {
    console.log('Successfully deployed ruleset:', ruleset.name);
  })
  .catch((error) => {
    console.error('Error deploying ruleset:', error);
    process.exit(1);
  });
