const admin = require('firebase-admin');
const { getSecurityRules } = require('firebase-admin/security-rules');
const fs = require('fs');
const path = require('path');

process.env.GOOGLE_APPLICATION_CREDENTIALS = path.join(__dirname, 'functions', 'service-account-key.json');

admin.initializeApp();

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
