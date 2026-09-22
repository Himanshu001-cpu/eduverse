# Synthesized Codebase Context & Domain Knowledge

**Ingest Date:** 2026-09-20

## 1. Domain Background
- source: `docs/PRD.md`, `docs/features.md`
- Eduverse is tailored specifically for the Indian competitive examination market (UPSC CSE, State Public Service Commissions, SSC, Banking, JEE, NEET). The educational workflow requires structured cohort-based learning where students enroll in yearly or session-based "Batches", follow structured weekly timetables, attend live interactive streams, practice Daily Practice Problems (DPPs), and track mock quiz percentiles.

## 2. Platform Architecture & Data Model
- source: `docs/architecture.md`, `docs/db-schema.md`, `docs/data-models.md`
- The system employs a multiplatform Flutter client (Android, iOS, Web, Desktop) integrated with Firebase BaaS. Content is organized around `courses` (academic subjects/programs), with sub-entities for `lessons` (lectures, notes, DPPs, tests) and `batches` (enrollment cohorts). Local persistence combines `Hive` for sub-second video timestamp resumes with `SharedPreferences` for user settings.

## 3. Operations & Administrative Console
- source: `docs/screens-guide.md`, `docs/component-inventory.md`
- Built directly into the Flutter binary, the Admin Console provides content creators with WYSIWYG editing (`RichDocumentEditor` with Delta JSON and HTML generation), rich equation authoring (LaTeX via `flutter_math_fork`), interactive tables, and live class management. Route security is strictly enforced by `AuthGuard` using custom JWT claims.

## 4. Deep Linking & Acquisition
- source: `docs/DEEP_LINK_SETUP.md`
- Universal links and app links allow direct sharing of course previews, live classes, and feed items via custom web rewrites (`/.well-known/assetlinks.json` and `/.well-known/apple-app-site-association`). Unauthenticated web visitors land on a responsive landing page (`lib/web/landing/landing_page.dart`) before redirecting to download or login.
