# Ingest Conflicts Report

**Analysis Date:** 2026-09-20
**Operation:** Ingest Docs
**Total Documents Analyzed:** 14

### BLOCKERS (0)

None. No contradictory locked architectural decisions or unresolvable cyclic dependencies detected.

### WARNINGS (0)

None. No competing requirement variants or ambiguous acceptance criteria detected.

### INFO (9)

- RFC-001: Dual-format rich content storage (Delta JSON + HTML snapshot) locked from `docs/rfcs.md`
- RFC-002: Purchase & enrollment transactional pipeline (atomic Firestore function) locked from `docs/rfcs.md`
- RFC-003: Secure e-book content protection (MD5 obfuscated cache + ScreenProtector) locked from `docs/rfcs.md`
- RFC-004: Hybrid lecture progress persistence (Hive local box + Firestore sync) locked from `docs/rfcs.md`
- RFC-005: Role-based authorization with dual storage (custom claims + profile document) locked from `docs/rfcs.md`
- RFC-006: Recurring class scheduling system (rule-based timetable generation) locked from `docs/rfcs.md`
- RFC-007: Batch migration to course-level content (flattened content hierarchy) locked from `docs/rfcs.md`
- RFC-008: Live class viewer presence (Firestore metadata + RTDB presence) locked from `docs/rfcs.md`
- RFC-009: Notification delivery pipeline (Firestore trigger + FCM multicast) locked from `docs/rfcs.md`
