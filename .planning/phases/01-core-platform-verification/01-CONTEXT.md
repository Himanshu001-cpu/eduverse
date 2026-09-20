# Phase 1: Core Platform Verification - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Confirm that the existing multi-platform application, serverless backend, and in-memory test harness operate reliably against established requirements. Verify baseline architecture across Auth, Store, Study, Admin, Profile, and Community Feed modules, ensuring zero regressions across unit, widget, and E2E scenario suites.

</domain>

<decisions>
## Implementation Decisions

### Test Suite Scope
- **D-01:** Run all unit, widget, and E2E scenario tests (`flutter test`) to verify zero regressions across the codebase.
- **D-02:** Strict Zero-Failures: All tests across unit, widget, and E2E suites must pass 100% with 0 failures before baseline verification is certified.

### Backend Simulation
- **D-03:** Rely entirely on the existing hermetic in-memory fake harness (`test/e2e/harness/`, `fake_firebase_firestore.dart`, `fake_firebase_auth.dart`) for fast, zero-dependency testing without requiring external Firebase Local Emulator daemons.
- **D-04:** Fully hermetic 3rd-party integrations: Intercept external dependencies (Razorpay payments, external links, video players) via test fakes (`fake_url_launcher.dart`, simulated payment success/failure) with zero external network traffic.

### Verification Artifact
- **D-05:** Produce a formal verification audit report (`01-VERIFICATION.md`) documenting test suite metrics, requirement-to-test mapping, and debt notes.
- **D-06:** Explicit Requirement Matrix: Map each of the 22 baseline requirements (`AUTH-01..04`, `STORE-01..04`, `STUDY-01..04`, `FEED-01..03`, `ADMIN-01..04`, `PROF-01..03`) to specific test files and assertions with pass status.

### The Agent's Discretion
None — all scope and verification criteria were explicitly specified.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture & Platform
- `docs/ARCHITECTURE.md` — System architecture, module structure, and state management conventions
- `docs/DATA_MODELS.md` — Firestore schema definitions, collection hierarchies, and entity mapping
- `docs/FIREBASE_FUNCTIONS.md` — Cloud Functions specifications, triggers, and callable signatures

### Verification & Testing
- `docs/E2E_TEST_PLAN.md` — E2E test harness design, test cases, and simulation harness architecture
- `docs/OFFLINE_AND_SYNC_STRATEGY.md` — Offline caching, Hive storage, and conflict resolution rules
- `docs/STUDY_MODULE.md` — Course structures, lecture hierarchy, and video playback tracking

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/e2e/harness/e2e_harness.dart` — Master setup/reset harness and baseline data seeder
- `test/e2e/harness/fake_firebase_firestore.dart` — In-memory Firestore with document/collection maps
- `test/e2e/harness/fake_firebase_auth.dart` — In-memory mock authentication provider
- `test/e2e/harness/fake_url_launcher.dart` — Fake platform launcher intercepting external URLs

### Established Patterns
- `EduverseFirebase.mockFirestore` & `EduverseFirebase.mockAuth` — Dependency injection entry points for overriding Firebase singletons in tests
- Clean architecture separation in `lib/study/` (`domain/`, `data/`, `presentation/`)
- In-memory test isolation via `E2EHarness.setUp()` and `E2EHarness.tearDown()`

### Integration Points
- `test/unit_test.dart` — 1,344 LOC comprehensive master regression suite
- `test/e2e/` — 10 end-to-end scenario suites exercising cross-feature user journeys

</code_context>

<specifics>
## Specific Ideas

- Ensure strict 0-failure baseline across all tests before opening Phase 2 feature work.
- Requirement matrix in verification report should provide traceability from PRD/docs requirements to test assertions.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Core Platform Verification*
*Context gathered: 2026-09-20*
