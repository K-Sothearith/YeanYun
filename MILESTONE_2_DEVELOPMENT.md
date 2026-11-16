# YeanYun — Milestone II Development Plan

**Project:** YeanYun (យានយន្ត) — Offline Vehicle Maintenance Tracker  
**Stack:** Dart / Flutter
**Team:** 2 members (Kong Sothearith & Porleak Vitou)
**Milestone focus:** Domain models, business services, and service unit tests

## 1. Lecturer's acceptance requirements

- Required directories: `lib/model/`, `lib/service/`, `test/`.
- Model layer: **at least 3 classes/entities**, **at least 2 composition or aggregation relationships**, and appropriate constructors, attributes, and methods using OOP principles.
- Service layer: **at least 3 meaningful business operations** using model objects, **at least 1 operation involving multiple entities**, and **at least 1 business rule/validation**.
- Test layer: **at least 5 tests total**, covering **normal**, **invalid**, and **boundary/special** cases.

## 2. Agreed ownership and workflow

### Kong Sothearith: shared models + vehicle/odometer services/tests

**First, on `main`:** define and commit the shared domain models and their contracts before either developer starts service implementation. This is a short, coordinated foundation step, not a separate feature implementation phase.

**Then, on `feature/vehicle-odometer`:**

- Implement `VehicleService`.
- Implement `OdometerService`.
- Write `vehicle_service_test.dart` and `odometer_service_test.dart`.
- Cover vehicle creation/edit/archive/restore and chronological odometer validation.

### Porleak Vitou: maintenance/service-record services/tests

**After the shared models are on `main`, on `feature/maintenance-records`:**

- Implement `MaintenanceService`.
- Implement service-record completion/history operations (either in `MaintenanceService` or a separate `ServiceRecordService`, as agreed).
- Write `maintenance_service_test.dart` and `service_record_service_test.dart` (or equivalent).
- Cover maintenance plan creation, due calculations, completion records, and expense validation.

**Both developers own services and tests.** Models are authored centrally to avoid incompatible constructors and duplicate class definitions. Both developers review the model contract before starting. If a model change becomes necessary, discuss it and merge the small change into `main` first, then update both branches.

## 3. Shared models (Developer 1 prepares on `main`)

Implement these four core entities in `lib/model/`:

| Model | Essential attributes | Invariants to enforce in services |
|---|---|---|
| `Vehicle` | `id`, `name`, `type`, `createdAt`, `isArchived`; optional `subtype`, `make`, `model`, `year`, `notes` | Nonblank ID/name; valid type/subtype combination |
| `OdometerReading` | `id`, `vehicleId`, `recordedAt`, `kilometres` | Nonnegative integer kilometres; nonblank IDs |
| `MaintenancePlan` | `id`, `vehicleId`, `title`, `enabled`, `createdAt`, optional `intervalKm`, `intervalDays`, completion anchors and next-due values | At least one positive interval; nonblank title |
| `ServiceRecord` | `id`, `vehicleId`, `performedAt`, `title`, `costMinorUnits`, `odometerKm`, optional `maintenancePlanId`, `notes` | Nonnegative cost and kilometres; valid references enforced by services |

Use enums for vehicle category and EV subtype. Use integer kilometres and integer minor currency units (not `double` for money). Keep identifiers immutable. Prefer explicit constructors and `copyWith` or equivalent safe update methods. Models are data containers: constructors do not validate input. All field validation and cross-record business rules belong in the service layer, before any state changes. Invalid-input tests must exercise services, not expect model constructors to throw.

### Service validation checklist (pending implementation)

Constructor validation has been removed from `lib/models/`. These rules still need implementation in services; accepting a model instance does not mean it is valid. Apply the same checks to create, edit, and import paths before writing data.

- **Vehicle:** nonblank ID/name, unique ID, EV subtype only on electric cars, positive year when supplied.
- **Odometer:** nonblank ID/vehicle ID, existing vehicle, nonnegative kilometres, chronological consistency, and no duplicate effective timestamp per vehicle.
- **Maintenance plan:** nonblank ID/vehicle ID/title, existing vehicle, at least one interval, every supplied interval strictly positive, nonnegative completion/due kilometres, distance due threshold only with a distance interval, date due threshold only with a time interval, and nonblank template key when supplied.
- **Service record:** nonblank ID/vehicle ID/title, nonblank linked plan ID when supplied, existing references, matching vehicle ownership, nonnegative cost/odometer, and no future service date under the initial policy.
- **Maintenance template:** nonblank key/title, compatible vehicle type/subtype, and positive suggested intervals when supplied; a template may omit intervals. User confirmation is required before creating a plan.
- **Settings:** three uppercase letters for the reporting currency code, nonnegative currency decimal precision and reminder lead days, and a positive schema version.
- **Tests:** cover normal, invalid, and boundary service inputs, including failure without partial writes. These checks are pending until services are implemented.

### Aggregation relationships for the review

```text
Vehicle 1 ── aggregates ── 0..* OdometerReading
Vehicle 1 ── aggregates ── 0..* MaintenancePlan
Vehicle 1 ── aggregates ── 0..* ServiceRecord
MaintenancePlan 1 ── referenced by ── 0..* ServiceRecord (optional link)
```

**Important:** `vehicleId` fields alone demonstrate references but may not be enough to convincingly demonstrate OOP aggregation to a lecturer. In your model demonstration, show the parent–child relationship explicitly using typed collections (for example, a `VehicleAggregate` containing a `Vehicle`, `List<OdometerReading>`, and `List<MaintenancePlan>`) or explicit model navigation methods. Do not duplicate mutable state unnecessarily. Explain that the aggregate is an in-memory domain representation and that later persistence may store records separately by foreign key. Agree on this representation before writing services.

### Initial model checklist

- [ ] All four classes compile and expose consistent constructors/types.
- [ ] At least two aggregation relationships are demonstrable in code and a diagram.
- [ ] Fields and enums match `DEVELOPMENT_SPEC.md`.
- [ ] Model invariants are documented.
- [ ] Both developers confirm the service-facing APIs.
- [ ] Commit the models to `main`; both developers pull the same commit.

## 4. Services and operation contracts

### Kong Sothearith: `VehicleService`

| Operation | Preconditions | Expected result |
|---|---|---|
| `createVehicle(input)` | Nonblank name, supported type/subtype, unique ID | Adds vehicle; returns created model |
| `updateVehicle(id, patch)` | Vehicle exists; new values valid | Updates editable fields without changing ID |
| `archiveVehicle(id)` | Vehicle exists and is active | Marks archived; retains related history |
| `restoreVehicle(id)` | Vehicle exists and is archived | Restores active status |

### Kong Sothearith: `OdometerService`

| Operation | Preconditions | Expected result |
|---|---|---|
| `addReading(vehicleId, date, km)` | Vehicle exists; km >= 0; timestamp valid; chronology consistent | Adds reading |
| `updateReading(id, date, km)` | Reading exists; ordering remains valid excluding edited record | Updates reading |
| `getCurrentOdometer(vehicleId)` | Vehicle exists | Returns latest reading by effective date, or a defined empty result |

**Chronological rule:** For a reading inserted between 10,000 km and 12,000 km, the new value must be in that inclusive range. Reject duplicate effective timestamps for the same vehicle. Equal mileage at different times is allowed.

### Porleak Vitou: `MaintenanceService`

| Operation | Preconditions | Expected result |
|---|---|---|
| `createPlan(vehicleId, title, intervalKm?, intervalDays?)` | Vehicle exists; title valid; at least one interval > 0 | Adds plan |
| `getDueStatus(plan, today, currentKm)` | Valid plan and current context | Computes upcoming/due/overdue state deterministically |
| `pausePlan(planId)` / `resumePlan(planId)` | Plan exists | Changes active state while preserving history |
| `recordCompletion(planId, serviceInput)` | Plan and vehicle exist; valid date/km/cost; linked IDs match | Creates `ServiceRecord`, updates plan completion anchors and next due |

### Porleak Vitou: service-record/history operations

Implement either a dedicated `ServiceRecordService` or clearly separated methods in `MaintenanceService`:

- `addUnscheduledService(vehicleId, input)`: create an independent maintenance log.
- `getServiceHistory(vehicleId)`: retrieve records for one vehicle.
- `getTotalExpense(vehicleId)`: sum `costMinorUnits` for that vehicle.

**Multi-entity demonstration:** `recordCompletion` must coordinate a `Vehicle`, `MaintenancePlan`, and `ServiceRecord` (and optionally `OdometerReading`). This satisfies the requirement for an operation involving multiple entities. It must not partially mutate data on validation failure.

**Due logic:** If a plan has both time and kilometre intervals, reaching **either** threshold makes it due. Use fixed `intervalDays` for the first version. After completion, compute next thresholds from completion date and odometer. Use an injected or explicit `today` value in tests rather than the real system clock.

## 5. In-memory implementation for this milestone

Use simple in-memory collections or repository fakes to keep service logic testable without SQLite. Decide on one shared contract before implementing:

```text
VehicleStore: findById, save, list
OdometerStore: findById, listByVehicle, save
MaintenancePlanStore: findById, listByVehicle, save
ServiceRecordStore: findById, listByVehicle, save
```

These are **proposed internal abstractions**, not lecturer-mandated classes. For the milestone, services can accept these stores through constructors. Later, SQLite-backed implementations can replace the in-memory stores without rewriting business rules.

For `recordCompletion`, avoid partial writes: validate all inputs before mutation, then apply changes together in a controlled in-memory unit of work. In the later database phase, replace this with a transaction.

## 6. Test plan

Use `flutter_test` / Dart unit tests. Each test should have a descriptive name and assert an observable outcome. The following 18 tests are a proposed target, not an exhaustive list.

| ID | Owner | Scenario | Type |
|---|---|---|---|
| V01 | Dev 1 | Create a valid vehicle | Normal |
| V02 | Dev 1 | Reject blank vehicle name | Invalid |
| V03 | Dev 1 | Reject incompatible vehicle type and EV subtype | Invalid |
| V04 | Dev 1 | Archive and restore a vehicle without losing its identity | Normal |
| O01 | Dev 1 | Add sequential odometer readings | Normal |
| O02 | Dev 1 | Reject negative kilometres | Invalid |
| O03 | Dev 1 | Accept historical reading exactly equal to earlier/later boundary | Boundary |
| O04 | Dev 1 | Reject historical reading outside neighbouring range | Invalid |
| O05 | Dev 1 | Reject duplicate reading timestamp for one vehicle | Special |
| M01 | Dev 2 | Create a valid distance-based plan | Normal |
| M02 | Dev 2 | Reject a plan with no interval or a zero interval | Invalid |
| M03 | Dev 2 | Mark plan due at exact kilometre threshold | Boundary |
| M04 | Dev 2 | Mark combined time/distance plan due when either threshold is met | Boundary |
| M05 | Dev 2 | Pause plan without deleting service history | Normal |
| S01 | Dev 2 | Complete plan and create linked service record | Normal / multi-entity |
| S02 | Dev 2 | Reject negative service expense without partial changes | Invalid |
| S03 | Dev 2 | Reject service record linked to a plan from another vehicle | Invalid |
| S04 | Dev 2 | Sum multiple expenses including zero-cost service | Boundary |

**Extra integration test recommended:** Create a vehicle → record odometer → create maintenance plan → complete plan → verify linked record and updated next-due thresholds. Run this after merging both branches.

### Commands

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

If tests fail, fix them before requesting a pull-request review. Do not weaken assertions merely to make tests pass.

## 7. GitHub branching and pull requests

### Branches

```text
main                            # Stable; shared model baseline and approved merges
├── feature/vehicle-odometer    # Developer 1: services + tests
└── feature/maintenance-records # Developer 2: services + tests
```

**Directly committing the initial shared models to `main` is acceptable for this two-person project**, provided both developers review the model API and the initial commit passes `flutter analyze` and `flutter test` (where tests exist). After that, protect `main` by merging service changes via pull requests instead of direct pushes. If branch protection is unavailable, follow the rule manually.

### Setup sequence

**Developer 1 — initial model baseline:**

```bash
git switch main
git pull origin main
# Create lib/model/ files and any agreed shared interfaces
dart format lib test
flutter analyze
git add lib/model lib/service test
# Stage only paths that exist; or use `git add -A` after reviewing `git status`
git commit -m "feat(model): define YeanYun domain entities"
git push origin main
```

**Each developer — start from updated `main`:**

```bash
git switch main
git pull origin main
git switch -c feature/vehicle-odometer
# Teammate substitutes: feature/maintenance-records
```

**Publish and open PR:**

```bash
dart format lib test
flutter analyze
flutter test
git status
git add lib/service test
git commit -m "feat(service): implement vehicle and odometer operations"
git push -u origin feature/vehicle-odometer
```

The teammate uses a corresponding maintenance commit message and branch. Create a PR **into `main`**, have the other developer review it, and merge only after tests pass.

### Prevent conflicts

- Do not edit the same service file on both feature branches.
- Do not redefine or duplicate shared models on feature branches.
- If a model contract must change, coordinate a small model PR first; both developers then merge/rebase the updated `main` into their branches.
- Prefer small, focused commits; do not commit generated build folders or local IDE settings.
- After the first PR merges, the second developer updates their branch from `main` and reruns the complete test suite before merging.
- Confirm both contributors appear in GitHub history through their actual commits; Git does not credit overwritten or uncommitted work automatically.

### Suggested PR checklist

- [ ] Only intended files changed.
- [ ] Service preconditions and failure behavior documented.
- [ ] Normal, invalid, and boundary tests included.
- [ ] `dart format`, `flutter analyze`, and `flutter test` pass.
- [ ] No UI/database/network dependency introduced.
- [ ] Other developer reviewed and approved.

## 8. Implementation order

1. **Agree on models:** types, IDs, relationships, errors, method signatures, store interfaces.
2. **Developer 1 commits models to `main`:** ensure both developers pull the same baseline.
3. **Parallel service development:** each developer builds their assigned services and tests on separate feature branches.
4. **PR review and merge:** run the entire test suite after each merge.
5. **Integration and milestone evidence:** add cross-domain integration test, draw model relationship diagram, and prepare service/test demonstration.

## 9. Milestone II demonstration plan

1. **Architecture:** the `lib/model/`, `lib/service/`, and `test/` directories.
2. **OOP model layer:** four classes, constructors/fields/methods, and at least two demonstrable aggregation relationships.
3. **Business services:** operations from both team members; explain preconditions and validation.
4. **Multi-entity operation:** completing maintenance creates a service record and updates its plan.
5. **Tests:** execute `flutter test`; point out successful, invalid, and boundary scenarios.
6. **Collaboration:** GitHub branches, PRs, reviews, and commits from both contributors.

## 10. Milestone completion checklist

- [ ] At least 3 domain classes (target 4) and 2 real aggregation/composition relationships.
- [ ] Constructors, attributes, and methods reflect the domain.
- [ ] At least 3 meaningful service operations (target substantially more).
- [ ] At least 1 validated business rule.
- [ ] At least 1 operation uses multiple entities.
- [ ] At least 5 tests covering normal, invalid, and boundary cases (target 18).
- [ ] Both developers contributed services **and** tests.
- [ ] Both feature branches merged to `main` through reviewed PRs.
- [ ] `flutter analyze` and `flutter test` pass on `main`.
- [ ] Milestone demonstration and diagram are ready.
