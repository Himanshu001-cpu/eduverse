const fs = require('fs');
const { execSync } = require('child_process');

const API_KEY = process.env.STITCH_API_KEY || "";
const PROJECT_ID = "4880358185227461688";

const newScreens = [
  { id: "cb16037ca3e3400b8b49a7c398a19624", key: "user_detail_admin", title: "User Detail - The Eduverse Admin" },
  { id: "741d3e3a3f0f425dba5d76361a0590a2", key: "courses_management_admin", title: "Courses Management - The Eduverse Admin" },
  { id: "c97bea7fe8c94e9996fff0adffce7071", key: "admin_dashboard", title: "Admin Dashboard - The Eduverse" },
  { id: "efef1c89afd84cd79b702a180eec37a9", key: "course_detail_admin", title: "Course Detail - The Eduverse Admin" },
  { id: "b4cd957f61d54749a389d5b4811beab1", key: "course_editor_admin", title: "Course Editor - The Eduverse Admin" }
];

if (!fs.existsSync("stitch")) {
  fs.mkdirSync("stitch", { recursive: true });
}

let metadata = {
  projectId: PROJECT_ID,
  projectTitle: "The Eduverse Design System",
  screens: []
};

if (fs.existsSync("stitch/metadata.json")) {
  try {
    const existing = JSON.parse(fs.readFileSync("stitch/metadata.json", "utf8"));
    if (Array.isArray(existing.screens)) {
      metadata.screens = existing.screens.filter(s => !newScreens.some(n => n.id === s.id));
    }
  } catch (e) {}
}

for (let i = 0; i < newScreens.length; i++) {
  const item = newScreens[i];
  console.log(`\n[${i + 1}/${newScreens.length}] Fetching ${item.title} (${item.id})...`);
  
  const apiUrl = `https://stitch.googleapis.com/v1/projects/${PROJECT_ID}/screens/${item.id}`;
  let screenData;
  try {
    const res = execSync(`curl -s -H "X-Goog-Api-Key: ${API_KEY}" "${apiUrl}"`, { encoding: 'utf8' });
    screenData = JSON.parse(res);
  } catch (e) {
    console.error(`  Failed to fetch info for ${item.id}:`, e.message);
    continue;
  }

  const imgPath = `stitch/${item.key}.png`;
  const htmlPath = `stitch/${item.key}.html`;

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
console.log("\nAll 5 Admin screens fetched and downloaded successfully!");
