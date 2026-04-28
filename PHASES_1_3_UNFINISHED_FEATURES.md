# Lolipants Unfinished Features (Phases 1-3)

This file tracks open items that are still unfinished or need hardening before moving to later phases.

## Phase 1

- [x] Final design-system sweep to ensure no hard-coded colors/sizes remain outside shared constants.
- [x] Full accessibility pass (contrast, semantics labels, touch targets) across core reusable widgets.
- [x] Complete foundation snapshot/golden coverage for core shared widgets.

## Phase 2

- [x] Final auth interceptor hardening in shared `DioClient` for token attach/refresh/logout redirect behavior.
- [x] Role and permission coverage tests for protected routes and server responses.
- [x] Expand backend API smoke tests for all CRUD endpoints under auth and unauth states.
- [x] Add stricter contract tests for backend error payload consistency.

## Phase 3

- [x] Verify backend implementation for `POST /ai/mannequin` (Meshy proxy) with production retry/status handling.
- [x] Verify backend implementation for `GET /mannequins` fully reflects admin dashboard-managed defaults.
- [x] Add polling/status UI for long-running 3D mannequin generation jobs.
- [x] Add API-backed fabric metadata (name, availability, quality) beyond ID-only selection.
- [x] Add end-to-end tests for editor save flow with print image upload and remote URL persistence.
- [ ] Add real-device QA pass for text drag precision and persistence after save/reload. (Automated save/persistence coverage added; device run still pending)
- [x] Harden print-image placement with explicit position controls (chest/back/front offsets).
- [x] Add loading/error skeleton states on mannequin selector while admin mannequins load.
- [x] Add integration tests for "Order this design" typed handoff and order summary fallback states.

