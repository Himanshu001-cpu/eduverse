const admin = require('firebase-admin');
const { getSecurityRules } = require('firebase-admin/security-rules');
const path = require('path');

process.env.GOOGLE_APPLICATION_CREDENTIALS = path.join(__dirname, 'functions', 'service-account-key.json');

admin.initializeApp();

async function getRules() {
  try {
    const rules = getSecurityRules();
    const ruleset = await rules.getFirestoreRuleset();
    console.log('--- ACTIVE RULES ---');
    console.log(ruleset.source[0].content);
    console.log('--- END ACTIVE RULES ---');
  } catch (error) {
    console.error('Error getting security rules:', error);
    process.exit(1);
  }
}

getRules();
