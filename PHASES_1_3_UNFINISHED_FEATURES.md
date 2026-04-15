# Lolipants Unfinished Features (Phases 1-3)

This file tracks open items that are still unfinished or need hardening before moving to later phases.

## Phase 1

- [ ] Final design-system sweep to ensure no hard-coded colors/sizes remain outside shared constants.
- [ ] Full accessibility pass (contrast, semantics labels, touch targets) across core reusable widgets.
- [ ] Complete foundation snapshot/golden coverage for core shared widgets.

## Phase 2

- [ ] Final auth interceptor hardening in shared `DioClient` for token attach/refresh/logout redirect behavior.
- [ ] Role and permission coverage tests for protected routes and server responses.
- [ ] Expand backend API smoke tests for all CRUD endpoints under auth and unauth states.
- [ ] Add stricter contract tests for backend error payload consistency.

## Phase 3

- [ ] Verify backend implementation for `POST /ai/mannequin` (Meshy proxy) with production retry/status handling.
- [ ] Verify backend implementation for `GET /mannequins` fully reflects admin dashboard-managed defaults.
- [ ] Add polling/status UI for long-running 3D mannequin generation jobs.
- [ ] Add API-backed fabric metadata (name, availability, quality) beyond ID-only selection.
- [ ] Add end-to-end tests for editor save flow with print image upload and remote URL persistence.
- [ ] Add real-device QA pass for text drag precision and persistence after save/reload.
- [ ] Harden print-image placement with explicit position controls (chest/back/front offsets).
- [ ] Add loading/error skeleton states on mannequin selector while admin mannequins load.
- [ ] Add integration tests for "Order this design" typed handoff and order summary fallback states.

