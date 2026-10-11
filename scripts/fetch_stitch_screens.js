const fs = require('fs');
const { execSync } = require('child_process');

const API_KEY = process.env.STITCH_API_KEY || "";
const PROJECT_ID = "4880358185227461688";

const targetScreens = [
  { id: "d62c834fdc8d41b0adbc3d9c9ea2fbc6", key: "study_hub", title: "Study Hub - The Eduverse" },
  { id: "19dd6743f618448cb615d7cb74157ecf", key: "terms_and_conditions", title: "Terms & Conditions - The Eduverse" },
  { id: "759ac69abbad440ebc155b9772ff8867", key: "forgot_password", title: "Forgot Password - The Eduverse" },
  { id: "74c93ab8192c4bb68082f5c53758750a", key: "privacy_policy", title: "Privacy Policy - The Eduverse" },
  { id: "c0623e57cf73489d9027cee468fd818e", key: "phone_verification", title: "Phone Verification - The Eduverse" },
  { id: "a8769d9ed59343e9ad09e8b8a2d5ef42", key: "phone_login", title: "Phone Login - The Eduverse" },
  { id: "b1afbac73415442794df98e7d8cc8797", key: "login", title: "Login - The Eduverse" },
  { id: "a38ac8b87aa544bfbe71f1272b2605d5", key: "register", title: "Register - The Eduverse" },
  { id: "f8ca46b247e8478ba8b52e02dd0c6ff3", key: "course_management", title: "Course Management - The Eduverse Admin" },
  { id: "bc2d7c8e9e9944ffa0b607ef169dc0c4", key: "admin_settings", title: "Admin Settings - The Eduverse" },
  { id: "8d0a0c71334d4c63aa6c1ca1de57d56f", key: "reports_and_analytics", title: "Reports & Analytics - The Eduverse" },
  { id: "f6df3d3cbe8043108371b7be0139cd84", key: "teacher_moderation_dashboard", title: "Teacher Moderation Dashboard - The Eduverse" },
  { id: "c6c1a028d8b64590bda46c1960824840", key: "community_forum", title: "Community Forum - The Eduverse" },
  { id: "76b053db2a9b40a095f55571f2131bc1", key: "user_profile", title: "User Profile - The Eduverse" }
];

if (!fs.existsSync("stitch")) {
  fs.mkdirSync("stitch", { recursive: true });
}

const metadata = {
  projectId: PROJECT_ID,
  projectTitle: "The Eduverse Design System",
  screens: []
};

// Preserve existing screens in metadata if available
if (fs.existsSync("stitch/metadata.json")) {
  try {
    const existing = JSON.parse(fs.readFileSync("stitch/metadata.json", "utf8"));
    if (existing.screen) {
      metadata.screens.push(existing.screen);
    } else if (Array.isArray(existing.screens)) {
      metadata.screens = existing.screens.filter(s => !targetScreens.some(t => t.id === s.id));
    }
  } catch (e) {}
}

for (let i = 0; i < targetScreens.length; i++) {
  const item = targetScreens[i];
  console.log(`\n[${i + 1}/${targetScreens.length}] Fetching screen info: ${item.title} (${item.id})...`);
  
  const apiUrl = `https://stitch.googleapis.com/v1/projects/${PROJECT_ID}/screens/${item.id}`;
  let screenData;
  try {
    const res = execSync(`curl -s -H "X-Goog-Api-Key: ${API_KEY}" "${apiUrl}"`, { encoding: 'utf8' });
    screenData = JSON.parse(res);
  } catch (e) {
    console.error(`  Failed to fetch screen info for ${item.id}:`, e.message);
    continue;
  }

  const imgPath = `stitch/${item.key}.png`;
  const htmlPath = `stitch/${item.key}.html`;

  // Download screenshot
  if (screenData.screenshot && screenData.screenshot.downloadUrl) {
    const imgUrl = screenData.screenshot.downloadUrl + "=s0";
    console.log(`  Downloading image -> ${imgPath}`);
    try {
      execSync(`curl -s -L "${imgUrl}" -o "${imgPath}"`);
      const stat = fs.statSync(imgPath);
      console.log(`  Screenshot saved (${(stat.size / 1024).toFixed(1)} KB)`);
    } catch (e) {
      console.error(`  Failed to download image:`, e.message);
    }
  }

  // Download HTML code
  if (screenData.htmlCode && screenData.htmlCode.downloadUrl) {
    const htmlUrl = screenData.htmlCode.downloadUrl;
    console.log(`  Downloading HTML -> ${htmlPath}`);
    try {
      execSync(`curl -s -L -H "X-Goog-Api-Key: ${API_KEY}" "${htmlUrl}" -o "${htmlPath}"`);
      const stat = fs.statSync(htmlPath);
      console.log(`  HTML saved (${(stat.size / 1024).toFixed(1)} KB)`);
    } catch (e) {
      console.error(`  Failed to download HTML:`, e.message);
    }
  }

  metadata.screens.push({
    id: item.id,
    key: item.key,
    name: screenData.name,
    title: item.title,
    width: screenData.width,
    height: screenData.height,
    deviceType: screenData.deviceType || "DESKTOP",
    screenshotPath: imgPath,
    codePath: htmlPath,
    screenshotUrl: screenData.screenshot?.downloadUrl,
    htmlDownloadUrl: screenData.htmlCode?.downloadUrl
  });
}

fs.writeFileSync("stitch/metadata.json", JSON.stringify(metadata, null, 2));
console.log("\nAll 14 screens successfully fetched and downloaded! Updated stitch/metadata.json");
