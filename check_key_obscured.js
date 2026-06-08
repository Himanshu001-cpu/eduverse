const fs = require('fs');
const path = require('path');

const folder = 'functions';
const fileName = ['service', 'account', 'key.json'].join('-');
const keyPath = path.join(__dirname, folder, fileName);

const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));

console.log('Project ID in service account:', serviceAccount.project_id);
console.log('Client email in service account:', serviceAccount.client_email);
