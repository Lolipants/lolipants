# Lolipants Product Scope: MVP vs Full App

This document clarifies what we are delivering in the current MVP and what remains part of the full product vision.

## MVP We Are Delivering Now

The MVP focus is the core fashion-commerce loop:

1. **Auth + session**
   - Email/password auth
   - OTP/social auth support where configured
   - Role-aware post-login routing

2. **Browse + design**
   - Browse categories and mannequins
   - Open editor and build a garment design
   - Save/reopen designs

3. **Order + checkout**
   - Order summary and checkout flow
   - Delivery details and payment screens
   - Order confirmation and order tracking basics

4. **Operations-ready roles**
   - Admin shell with scoped tabs (stats, users, orders, payouts, moderation, CMS, complaints)
   - Tailor and delivery operational shells/routes
   - Customer role-request flow to become **tailor** or **delivery** + admin approval queue

5. **Admin-managed catalogs**
   - Admin CMS for mannequins/fabrics/patterns/presets
   - API wired to use admin-managed data rather than hardcoded catalogs

6. **Configurable MVP flags**
   - Feature toggles for slimming release surface (community, music mini-player, AI editor tab)
   - See `docs/MVP_FLAGS.md`

## Full App Vision (Beyond MVP)

These capabilities are intended for the full product rollout and deeper post-MVP phases:

1. **Full community ecosystem**
   - Rich creator feed, post interactions, designer discovery/showcase
   - Consultations, pro-designer surfaces, and advanced community monetization loops

2. **Expanded creator economy**
   - End-to-end designer earnings and payouts lifecycle at scale
   - More automation around commissions, disputes, and moderation tooling

3. **Richer AI + media experiences**
   - Expanded AI-assisted editor capabilities beyond MVP scope
   - More advanced rendering, preview, and content workflows

4. **Advanced role and ops tooling**
   - Deeper staffing workflows, approvals, performance analytics, and escalation tooling
   - Additional RBAC hardening and internal operations dashboards

5. **Broader product polish and growth surfaces**
   - Music/player experience as a first-class engagement layer
   - Landing web growth funnel and non-core engagement features
   - More complete QA, hardening, analytics, and lifecycle automation

## Notes

- MVP is intentionally optimized for validating the core business loop: **discover -> design -> order -> fulfill**.
- “Full app” includes all ecosystem and growth capabilities once MVP quality and adoption targets are met.
