# Eduverse — Documentation Index

> **Eduverse** is a comprehensive ed-tech platform for competitive exam preparation (UPSC, State PSC, SSC, etc.) built with Flutter + Firebase. It ships a student mobile/web app, a full-featured admin panel, a marketing landing page, and a Firebase Cloud Functions backend.

| Property | Value |
|---|---|
| **App Version** | `1.2.0+21` |
| **Flutter SDK** | `^3.12.0` |
| **Firebase Project** | `eduverse-dad5e` |
| **Platforms** | Android, iOS, Web, Linux, macOS, Windows |
| **Total Dart Files** | ~262 |

---

## 📂 Document Map

| Document | Description |
|---|---|
| [features.md](./features.md) | Complete feature inventory organized by user role (Student, Admin, Teacher, Web) |
| [PRD.md](./PRD.md) | Product Requirements Document — personas, user journeys, priorities, success metrics |
| [architecture.md](./architecture.md) | System architecture — tech stack, module layout, data flows, state management, security |
| [api-specs.md](./api-specs.md) | Cloud Functions API + client-side service API reference |
| [db-schema.md](./db-schema.md) | Firestore collections, RTDB, Hive, SharedPreferences, Storage bucket paths |
| [data-models.md](./data-models.md) | All Dart data model classes with fields, types, and serialization methods |
| [security.md](./security.md) | Authentication, authorization roles, Firestore/Storage rules, App Check, content protection |
| [component-inventory.md](./component-inventory.md) | UI screen map, widget catalog, navigation structure |
| [environment-setup.md](./environment-setup.md) | Environment variables, Firebase setup, dev tooling, deployment |
| [rfcs.md](./rfcs.md) | Technical RFCs documenting major feature designs and decisions |
| [screens-guide.md](./screens-guide.md) | Detailed screen guide for Student, Teacher, and Admin roles |

---

## 🔍 Quick Navigation

| If you need to... | Read |
|---|---|
| Understand what the app does | [features.md](./features.md) |
| Understand the product vision and priorities | [PRD.md](./PRD.md) |
| Understand how the system is structured | [architecture.md](./architecture.md) |
| Find a specific screen or widget | [component-inventory.md](./component-inventory.md) |
| See detailed screen descriptions by role | [screens-guide.md](./screens-guide.md) |
| Understand a Firestore collection or data model | [db-schema.md](./db-schema.md) / [data-models.md](./data-models.md) |
| Understand a Cloud Function or service method | [api-specs.md](./api-specs.md) |
| Understand auth, roles, or security rules | [security.md](./security.md) |
| Set up the development environment | [environment-setup.md](./environment-setup.md) |
| Understand why a major feature was designed a certain way | [rfcs.md](./rfcs.md) |

---

## 🏗 Codebase Module Summary

```
lib/
├── admin/          # Admin panel — 75 files (screens, services, widgets, models)
├── auth/           # Authentication flows — 7 files
├── common/         # Shared widgets, services, styles — 11 files
├── core/           # Core Firebase layer + services — 34 files
├── feed/           # Content feed module — 19 files
├── navigation/     # Bottom nav shell — 1 file
├── profile/        # User profile & performance — 17 files
├── settings/       # Account settings — 1 file
├── store/          # Marketplace & purchases — 25 files
├── study/          # Study module (largest) — 51 files
├── utils/          # Test utilities — 2 files
└── web/            # Web landing page — 17 files
```

## 📦 Key Dependencies

| Category | Packages |
|---|---|
| Firebase | `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `cloud_functions`, `firebase_messaging`, `firebase_app_check`, `firebase_database` |
| Payments | `razorpay_flutter` |
| Video | `youtube_player_flutter`, `youtube_player_iframe`, `video_player`, `chewie` |
| PDF | `syncfusion_flutter_pdfviewer` |
| Rich Text | `super_editor`, `flutter_widget_from_html_core`, `flutter_math_fork` |
| Charts | `fl_chart` |
| Local Storage | `hive`, `hive_flutter`, `shared_preferences` |
| Networking | `dio`, `url_launcher` |
| UI | `google_fonts`, `flutter_animate`, `lucide_icons_flutter`, `cached_network_image`, `carousel_slider`, `photo_view` |
