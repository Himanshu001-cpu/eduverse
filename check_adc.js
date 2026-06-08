const fs = require('fs');
const path = require('path');
const os = require('os');

const adcPath = path.join(os.homedir(), '.config', 'gcloud', 'application_default_credentials.json');
console.log('ADC Path:', adcPath);
console.log('Exists:', fs.existsSync(adcPath));
if (fs.existsSync(adcPath)) {
  try {
    const data = JSON.parse(fs.readFileSync(adcPath, 'utf8'));
    console.log('Client ID exists:', !!data.client_id);
    console.log('Quota Project ID:', data.quota_project_id);
  } catch (e) {
    console.error('Error reading ADC:', e.message);
  }
}
