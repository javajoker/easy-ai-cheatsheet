# Project Type Patterns

Pre-defined component orderings and dependency shapes for common project types.
Use these to skip Step 1 analysis for well-known architectures.
Always verify against the actual input document — these are starting points, not final answers.

---

## Pattern 1: Blockchain / DeFi / DePIN

### Component order (critical path first)
1. **Smart Contracts** (deploy first — everything else reads them)
   - Token contract (if any) → Registry contracts → Logic contracts → Governance
2. **Blockchain Indexer** (reads contract events, feeds backend)
3. **Backend API** (monorepo + DB schema → auth → core services → analytics)
4. **Frontend Apps** (portal/dashboard → operator app → consumer app → explorer)
5. **Infrastructure** (CI/CD, monitoring, deployment scripts)
6. **Documentation** (last, after all features stable)

### Key dependency rules
- Every frontend depends on the backend auth service
- Every backend service that calls contracts depends on the ABI being locked
- The indexer must be running before any frontend can show live data
- Smart contracts must be audited before mainnet deploy

### Common components
- `CTR-001` PMN/ERC-20 Token
- `CTR-002` Registry/Identity contract
- `CTR-003` Core logic contract (staking, escrow)
- `CTR-004` Reward/Distribution contract
- `CTR-005` Governance contract (often P2)
- `BE-001` Monorepo + DB schema
- `BE-002` Auth service
- `BE-003` Core API service(s)
- `BE-004` Blockchain indexer
- `BE-005` Analytics service
- `FE-001` Operator dashboard
- `FE-002` Consumer app
- `FE-003` Network explorer

### Architectural constants to extract
- Token max supply, initial mint, fee percentages
- Staking tier amounts
- Time windows (epoch duration, lock periods, dispute windows)
- Role names (MINTER_ROLE, VALIDATOR_ROLE, etc.)
- Governance quorum, approval thresholds

---

## Pattern 2: SaaS Web Application

### Component order
1. **Infrastructure** (monorepo, CI/CD, cloud setup, DB)
2. **Auth service** (JWT, OAuth, SSO — gates everything)
3. **Core API** (CRUD for primary domain entities)
4. **Business logic services** (payments, notifications, search, integrations)
5. **Frontend web app** (after auth + API available)
6. **Admin dashboard** (often parallel with frontend)
7. **Mobile app** (if any — starts after API stable)
8. **Analytics + reporting** (after data flows established)
9. **Documentation** (last)

### Key dependency rules
- Auth service JWT public key needed by every other service
- DB schema baseline must be committed before any service starts
- Stripe/payment integration needs test mode keys from day 1
- Email templates need SendGrid/SES set up before notification service

### Common components
- `INFRA-001` Monorepo + CI/CD + infrastructure
- `AUTH-001` Authentication service
- `API-001` Core CRUD API
- `API-002` Business logic service (payments, etc.)
- `WEB-001` Frontend web application
- `WEB-002` Admin dashboard
- `MOB-001` Mobile app (if applicable)
- `INT-001` External integrations
- `DOC-001` Documentation

---

## Pattern 3: Mobile App (with backend)

### Component order
1. **Backend API** (auth + core endpoints)
2. **Design system + shared components** (mobile + web share tokens)
3. **Core screens** (auth, home, primary flows)
4. **Feature screens** (secondary flows, settings, notifications)
5. **Native integrations** (camera, biometrics, push, BLE)
6. **App Store submission assets** (screenshots, descriptions)
7. **Web version** (if any — parallel with native features)

### Key dependency rules
- Push notifications require FCM/APNS setup before notification UX
- Native hardware features (camera, BLE) often require bare workflow
- App Store review takes 1–7 days — submit early
- TestFlight/internal testing needed before public submission

### Component structure
- `BE-001` Backend API
- `MOB-001` App scaffold + navigation + design system
- `MOB-002` Auth screens
- `MOB-003` Primary feature screens
- `MOB-004` Secondary feature screens
- `MOB-005` Native integrations
- `MOB-006` App Store submission

---

## Pattern 4: API / SDK / Developer Tool

### Component order
1. **Core library** (the thing being wrapped/exposed)
2. **Type definitions** (TypeScript types, OpenAPI spec, protobuf)
3. **Primary language SDK** (the main language of your users)
4. **Additional language SDKs** (each parallel after types locked)
5. **CLI tool** (if any)
6. **Documentation** (API reference auto-generated; guides hand-written)
7. **Example applications** (show the SDK in context)
8. **Testing harness** (mocks, fixtures, test helpers for SDK users)

### Key dependency rules
- Type definitions must be locked before any SDK can be finalised
- Documentation lags implementation by 1–2 sprints
- Versioning strategy (semver) must be decided before first public release
- Breaking changes require migration guide

---

## Pattern 5: Data Pipeline

### Component order
1. **Infrastructure** (cloud setup, data lake, orchestrator)
2. **Data ingestion** (connectors, streaming, batch)
3. **Data transformation** (ETL/ELT jobs, dbt models)
4. **Data storage** (warehouse schema, indexing)
5. **Data quality** (validation, monitoring, alerts)
6. **Serving layer** (API, query engine, caching)
7. **Dashboard / visualisation** (reads from serving layer)
8. **Data documentation** (data dictionary, lineage)

### Key dependency rules
- Never transform before ingestion is validated
- Schema-on-write pipelines need schema defined before ingestion starts
- Dashboard can only be built once the serving layer API is stable

---

## Pattern 6: Hardware + Software (IoT / Embedded)

### Component order
1. **Hardware specification** (component selection, PCB design)
2. **Firmware** (chip SDK, low-level protocol)
3. **Hardware SDK** (Python, C++, JS wrappers around firmware commands)
4. **Cloud API** (receives data from devices, stores state)
5. **Device management app** (pairs, configures, monitors hardware)
6. **Consumer/end-user app** (uses outputs from devices)
7. **Documentation** (hardware setup guide, SDK reference)

### Key dependency rules
- Hardware spec must be locked before firmware starts
- Firmware protocol must be locked before SDK starts
- Build a mock/simulator for the hardware ASAP — unblocks software without waiting for physical units
- OTA update mechanism must be designed before first firmware version ships (hard to add later)

---

## Pattern 7: Marketplace

### Component order
1. **Backend API** (auth + listings + search)
2. **Seller/creator portal** (register, list, manage)
3. **Buyer/consumer app** (browse, purchase)
4. **Transaction engine** (payments, escrow, payout)
5. **Moderation tooling** (admin dashboard, review queue)
6. **Review and trust system** (ratings, disputes)
7. **Analytics** (GMV, conversion, supply/demand balance)
8. **SEO + marketing pages** (product pages, landing pages)

### Key dependency rules
- Payment/payout system must be designed before seller portal (revenue share logic)
- Search is often a separate service (Elasticsearch) — provision early
- Trust and safety features are P1 even if they feel like polish
- Two-sided marketplace: seller and buyer flows are parallel after backend API ready

---

## Unknown Project Type: Derive the Pattern

If the project doesn't match any above, derive the pattern using these heuristics:

1. **What must exist for any user to get value?** → That's your Phase 1.
2. **What is the riskiest technical component?** → Build it in Phase 1 to de-risk early.
3. **What is the most common user flow?** → Build the components in that flow in dependency order.
4. **What is the last thing to build?** → Documentation, analytics, admin tooling, notifications.
5. **What can be parallelised?** → Components that share no code and have different engineers.
