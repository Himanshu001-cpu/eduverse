# Synthesized Technical Constraints

**Ingest Date:** 2026-09-20

## CST-SECURITY-01: Write-Locked Transactional Collections
- source: `docs/api-specs.md`, `docs/security.md`
- type: security-constraint
- content: The `enrollments` and `purchases` collections must enforce `allow write: if false` in `firestore.rules` for client requests. All enrollment creations, combo bundle expansions, and seat updates must execute strictly inside server-side Cloud Functions transactions (`onPurchaseCreate`).

## CST-DATABASE-02: Batch Operation Limits
- source: `docs/api-specs.md`
- type: database-constraint
- content: Firestore limits atomic write batches to a maximum of 500 operations. Administrative bulk updates (e.g. archiving lectures, publishing batch schedules) must invoke `commitInChunks()` to partition operations into safe chunks of at most 400 operations.

## CST-PLATFORM-03: Web Video Embedding
- source: `docs/architecture.md`, `docs/screens-guide.md`
- type: platform-constraint
- content: Native video player plugins fail when embedding YouTube live streams on Web. Web builds must conditionally instantiate `youtube_player_iframe` wrapped with `PointerInterceptor` to prevent HTML view overlays from swallowing gestures and pointer clicks.

## CST-SECURITY-04: Hardware Screenshot Protection
- source: `docs/security.md`
- type: security-constraint
- content: Hardware-level screen capture and recording prevention (`ScreenProtector.preventScreenshotOn()`) must remain active by default for all authenticated student sessions on Android and iOS. It is disabled only when `isAdmin()` confirms verified admin privileges.

## CST-PAYMENT-05: Webhook Idempotency
- source: `docs/api-specs.md`
- type: integration-constraint
- content: The `webhookPaymentUpdate` HTTP endpoint must verify the Razorpay HMAC SHA256 signature and check if `purchaseId` is already marked as enrolled before executing transactional fulfillment, preventing duplicate seat decrements.
