# MVP Go/No-Go Report

Date: 2026-04-28

## Scope freeze

Ship scope remains: `discover -> design -> order -> fulfill`.
Customer-facing MVP scope is women-only (no men/kids surfaces).

## Completed hardening checks

- Payment webhook/docs alignment:
  - Server route uses `POST /payments/webhook/tap`.
  - Runbook now references `/payments/webhook/tap`.
- Payment reconciliation behavior:
  - Webhook parsing now accepts Tap charge-style payloads
    (`reference.transaction`, `status=CAPTURED`).
  - Added contract test coverage for canonical and Tap-shaped payloads.
- Admin order safety:
  - `/admin/orders/:id` now validates status values against canonical states.
  - `/admin/orders/:id` now blocks invalid transitions with `409`.
  - Admin UI status options now match canonical backend workflow.
  - Added RBAC regression tests for invalid status + transition attempts.
- Release surface flags:
  - Documented full MVP flag set in `docs/MVP_FLAGS.md`, including
    `FEATURE_MENS` and `FEATURE_FINAL_RENDER_PREVIEW`.
  - Added one canonical release command profile.
- Deployment docs:
  - API README now documents full migration sequence `0001..0007`.
  - `.env.example` now includes release keys used by the client surface.

## Automated checks run

- `npm test -- --run src/tests/api.contract.test.ts src/tests/api.phase8.test.ts`
  - Result: pass (13/13)
- `flutter analyze lib/features/orders/screens/payment_screen.dart lib/features/admin/screens/admin_orders_screen.dart`
  - Result: no errors, style/info warnings only in pre-existing admin screen formatting.

## Manual go/no-go checks remaining (operator)

- Release-device payment capture using real Tap tokenized card flow.
- End-to-end mobile smoke: auth, browse, design save/reopen, checkout, payment,
  and order status transition visibility across customer/admin.
- Production env smoke with documented secrets and migrations only.

## Verdict

Conditional **GO** once manual release-device payment capture and end-to-end
operator smoke pass on target environment.
