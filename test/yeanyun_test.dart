import 'package:flutter_test/flutter_test.dart';
import 'package:yeanyun/services/yeanyun.dart';

final epoch = DateTime.utc(2026, 1, 1);
final now = DateTime.utc(2026, 6, 1);

Vehicle vehicle({
  String id = 'v1',
  String name = 'Family car',
  VehicleType type = VehicleType.conventionalCar,
  ElectricVehicleSubtype? subtype,
  int? year,
}) => Vehicle(
  id: id,
  name: name,
  type: type,
  addedAt: epoch,
  subtype: subtype,
  year: year,
);

OdometerReading reading(
  String id,
  int day,
  int km, {
  String vehicleId = 'v1',
}) => OdometerReading(
  id: id,
  vehicleId: vehicleId,
  recordedAt: epoch.add(Duration(days: day)),
  kilometres: km,
);

MaintenancePlan plan({
  String id = 'p1',
  String vehicleId = 'v1',
  String title = 'Oil change',
  int? intervalKm = 5000,
  int? intervalDays,
  bool enabled = true,
  int? dueKm,
  DateTime? dueAt,
  int? lastCompletedKm,
  DateTime? lastCompletedAt,
  String? templateKey,
}) => MaintenancePlan(
  id: id,
  vehicleId: vehicleId,
  title: title,
  createdAt: epoch,
  enabled: enabled,
  intervalKm: intervalKm,
  intervalDays: intervalDays,
  dueKm: dueKm,
  dueAt: dueAt,
  lastCompletedKm: lastCompletedKm,
  lastCompletedAt: lastCompletedAt,
  templateKey: templateKey,
);

ServiceRecord record({
  String id = 's1',
  String vehicleId = 'v1',
  String title = 'Oil change service',
  int costMinorUnits = 5000,
  int odometerKm = 5000,
  int day = 30,
  String? maintenancePlanId,
  String? notes,
}) => ServiceRecord(
  id: id,
  vehicleId: vehicleId,
  performedAt: epoch.add(Duration(days: day)),
  title: title,
  costMinorUnits: costMinorUnits,
  odometerKm: odometerKm,
  maintenancePlanId: maintenancePlanId,
  notes: notes,
);

void main() {
  late YeanYun app;
  setUp(() {
    app = YeanYun();
    app.vehicles.addVehicle(vehicle());
  });

  group('Vehicles', () {
    test('creates a valid vehicle and a compatible electric car', () {
      expect(app.vehicles.getVehicle('v1').name, 'Family car');
      final ev = app.vehicles.addVehicle(
        vehicle(
          id: 'ev',
          type: VehicleType.electricCar,
          subtype: ElectricVehicleSubtype.bev,
        ),
      );
      expect(ev.subtype, ElectricVehicleSubtype.bev);
      expect(app.vehicles.getVehicles(), hasLength(2));
    });

    test('rejects invalid fields and duplicate IDs without writing', () {
      for (final invalid in [
        vehicle(id: ''),
        vehicle(id: 'new', name: '  '),
        vehicle(id: 'new', subtype: ElectricVehicleSubtype.bev),
        vehicle(id: 'new', year: 0),
        vehicle(id: 'new', year: -1),
      ]) {
        expect(() => app.vehicles.addVehicle(invalid), throwsArgumentError);
      }
      expect(() => app.vehicles.addVehicle(vehicle()), throwsStateError);
      expect(app.vehicles.getVehicles(), hasLength(1));
    });

    test('updates editable values while preserving identity and creation', () {
      final updated = app.vehicles.updateVehicle(
        'v1',
        Vehicle(
          id: 'v1',
          name: 'Renamed',
          type: VehicleType.truck,
          addedAt: now,
          year: 2026,
          notes: 'Work',
        ),
      );
      expect(updated.id, 'v1');
      expect(updated.addedAt, epoch);
      expect(updated.name, 'Renamed');
      expect(updated.notes, 'Work');
      expect(
        () => app.vehicles.updateVehicle('v1', vehicle(name: ' ')),
        throwsArgumentError,
      );
      expect(app.vehicles.getVehicle('v1'), same(updated));
      expect(
        () => app.vehicles.updateVehicle('v1', vehicle(id: 'other')),
        throwsArgumentError,
      );
    });

    test('archives and restores identity and related history', () {
      app.odometer.addReading(reading('r1', 0, 0));
      expect(app.vehicles.archiveVehicle('v1').isArchived, isTrue);
      expect(app.vehicles.getVehicles(includeArchived: false), isEmpty);
      expect(() => app.vehicles.archiveVehicle('v1'), throwsStateError);
      final restored = app.vehicles.restoreVehicle('v1');
      expect(restored.id, 'v1');
      expect(restored.isArchived, isFalse);
      expect(app.odometer.getReadings('v1').single.id, 'r1');
      expect(() => app.vehicles.restoreVehicle('v1'), throwsStateError);
    });

    test('rejects missing vehicle operations', () {
      expect(() => app.vehicles.getVehicle('missing'), throwsStateError);
      expect(() => app.vehicles.archiveVehicle('missing'), throwsStateError);
      expect(() => app.vehicles.restoreVehicle('missing'), throwsStateError);
      expect(
        () => app.vehicles.updateVehicle('missing', vehicle()),
        throwsStateError,
      );
    });
  });

  group('Odometer', () {
    test('returns an empty result and then latest chronological reading', () {
      expect(app.odometer.getCurrentOdometer('v1'), isNull);
      app.odometer.addReading(reading('later', 2, 12000));
      app.odometer.addReading(reading('earlier', 0, 10000));
      expect(app.odometer.getCurrentOdometer('v1')!.id, 'later');
      expect(app.odometer.getReadings('v1').map((r) => r.id), [
        'earlier',
        'later',
      ]);
    });

    for (final km in [10000, 12000]) {
      test('accepts historical mileage at inclusive boundary $km', () {
        app.odometer.addReading(reading('a', 0, 10000));
        app.odometer.addReading(reading('b', 2, 12000));
        expect(
          app.odometer.addReading(reading('middle', 1, km)).kilometres,
          km,
        );
      });
    }

    test('rejects mileage outside either neighbour without writes', () {
      app.odometer.addReading(reading('a', 0, 10000));
      app.odometer.addReading(reading('b', 2, 12000));
      for (final km in [9999, 12001, -1]) {
        expect(
          () => app.odometer.addReading(reading('invalid', 1, km)),
          throwsArgumentError,
        );
      }
      expect(app.odometer.getReadings('v1'), hasLength(2));
    });

    test('rejects duplicate timestamps including equivalent time zones', () {
      app.odometer.addReading(reading('a', 0, 0));
      final sameInstant = OdometerReading(
        id: 'b',
        vehicleId: 'v1',
        recordedAt: DateTime.parse('2026-01-01T07:00:00+07:00'),
        kilometres: 0,
      );
      expect(() => app.odometer.addReading(sameInstant), throwsArgumentError);
      app.vehicles.addVehicle(vehicle(id: 'v2'));
      app.odometer.addReading(reading('c', 0, 0, vehicleId: 'v2'));
      expect(app.odometer.getReadings('v2'), hasLength(1));
    });

    test('validates IDs and references before storing readings', () {
      expect(
        () => app.odometer.addReading(reading('', 0, 0)),
        throwsArgumentError,
      );
      expect(
        () => app.odometer.addReading(reading('a', 0, 0, vehicleId: '')),
        throwsArgumentError,
      );
      expect(
        () => app.odometer.addReading(reading('a', 0, 0, vehicleId: 'missing')),
        throwsStateError,
      );
      app.odometer.addReading(reading('a', 0, 0));
      expect(
        () => app.odometer.addReading(reading('a', 1, 1)),
        throwsStateError,
      );
    });

    test(
      'updates excluding itself while enforcing neighbours and identity',
      () {
        app.odometer.addReading(reading('a', 0, 100));
        app.odometer.addReading(reading('b', 1, 200));
        app.odometer.addReading(reading('c', 3, 300));
        final updated = app.odometer.updateReading('b', reading('b', 2, 300));
        expect(updated.kilometres, 300);
        expect(
          () => app.odometer.updateReading('b', reading('b', 2, 301)),
          throwsArgumentError,
        );
        expect(
          () => app.odometer.updateReading('b', reading('b', 3, 300)),
          throwsArgumentError,
        );
        expect(
          () => app.odometer.updateReading('b', reading('different', 2, 300)),
          throwsArgumentError,
        );
        expect(
          () => app.odometer.updateReading(
            'b',
            reading('b', 2, 300, vehicleId: 'v2'),
          ),
          throwsArgumentError,
        );
        expect(
          () =>
              app.odometer.updateReading('missing', reading('missing', 2, 300)),
          throwsStateError,
        );
        expect(app.odometer.getReadings('v1')[1], same(updated));
      },
    );
  });

  test('collections are immutable snapshots and instances are independent', () {
    final snapshot = app.odometer.getReadings('v1');
    expect(() => snapshot.add(reading('r1', 0, 0)), throwsUnsupportedError);
    expect(() => app.vehicles.getVehicles().clear(), throwsUnsupportedError);
    app.odometer.addReading(reading('r1', 0, 0));
    expect(snapshot, isEmpty);
    expect(app.odometer.getReadings('v1'), hasLength(1));
    expect(YeanYun().vehicles.getVehicles(), isEmpty);
  });

  group('Maintenance Plans', () {
    // M01: Create a valid distance-based plan (Normal)
    test('creates a valid distance-based maintenance plan', () {
      final created = app.maintenance.createPlan(
        plan(id: 'p1', intervalKm: 5000),
      );
      expect(created.id, 'p1');
      expect(created.vehicleId, 'v1');
      expect(created.intervalKm, 5000);
      expect(created.dueKm, 5000);
      expect(created.enabled, isTrue);
      expect(app.maintenance.getPlan('p1'), same(created));
      expect(app.maintenance.getPlans('v1'), hasLength(1));
    });

    // M02: Reject a plan with no interval or a zero interval (Invalid)
    test('rejects plan with missing or invalid intervals, blank fields, or duplicate ID', () {
      // Missing both intervals
      expect(
        () => app.maintenance.createPlan(
          plan(intervalKm: null, intervalDays: null),
        ),
        throwsArgumentError,
      );
      // Zero or negative kilometre interval
      expect(
        () => app.maintenance.createPlan(plan(intervalKm: 0)),
        throwsArgumentError,
      );
      expect(
        () => app.maintenance.createPlan(plan(intervalKm: -100)),
        throwsArgumentError,
      );
      // Zero or negative day interval
      expect(
        () =>
            app.maintenance.createPlan(plan(intervalKm: null, intervalDays: 0)),
        throwsArgumentError,
      );
      expect(
        () => app.maintenance.createPlan(
          plan(intervalKm: null, intervalDays: -5),
        ),
        throwsArgumentError,
      );
      // Blank ID, title, or vehicleId
      expect(
        () => app.maintenance.createPlan(plan(id: '   ')),
        throwsArgumentError,
      );
      expect(
        () => app.maintenance.createPlan(plan(title: '')),
        throwsArgumentError,
      );
      // Non-existent vehicle
      expect(
        () => app.maintenance.createPlan(plan(vehicleId: 'nonexistent')),
        throwsStateError,
      );
      // Distance threshold without distance interval
      expect(
        () => app.maintenance.createPlan(
          plan(intervalKm: null, intervalDays: 90, dueKm: 5000),
        ),
        throwsArgumentError,
      );
      // Date threshold without date interval
      expect(
        () => app.maintenance.createPlan(
          plan(intervalKm: 5000, dueAt: epoch.add(const Duration(days: 30))),
        ),
        throwsArgumentError,
      );

      // Verify no plans were saved
      expect(app.maintenance.getPlans('v1'), isEmpty);

      // Duplicate ID rejected
      app.maintenance.createPlan(plan(id: 'p1'));
      expect(
        () => app.maintenance.createPlan(plan(id: 'p1')),
        throwsStateError,
      );
      expect(app.maintenance.getPlans('v1'), hasLength(1));
    });

    // M03: Mark plan due at exact kilometre threshold (Boundary)
    test('evaluates due status at boundary values for distance-based plan', () {
      final p = app.maintenance.createPlan(
        plan(id: 'p1', intervalKm: 5000, dueKm: 5000),
      );
      // Upcoming before threshold
      expect(app.maintenance.getDueStatus(p, epoch, 4999), PlanStatus.upcoming);
      // Exactly at threshold -> due
      expect(app.maintenance.getDueStatus(p, epoch, 5000), PlanStatus.due);
      // Exceeding threshold -> overdue
      expect(app.maintenance.getDueStatus(p, epoch, 5001), PlanStatus.overdue);
    });

    // M04: Mark combined time/distance plan due when either threshold is met (Boundary)
    test(
      'marks combined time and distance plan due when either threshold is met',
      () {
        final combined = app.maintenance.createPlan(
          plan(
            id: 'p_combined',
            intervalKm: 5000,
            intervalDays: 180,
            dueKm: 5000,
            dueAt: epoch.add(const Duration(days: 180)),
          ),
        );

        // Neither threshold reached -> upcoming
        expect(
          app.maintenance.getDueStatus(
            combined,
            epoch.add(const Duration(days: 90)),
            3000,
          ),
          PlanStatus.upcoming,
        );

        // Exact distance threshold met, date not met -> due
        expect(
          app.maintenance.getDueStatus(
            combined,
            epoch.add(const Duration(days: 90)),
            5000,
          ),
          PlanStatus.due,
        );

        // Exact date threshold met, distance not met -> due
        expect(
          app.maintenance.getDueStatus(
            combined,
            epoch.add(const Duration(days: 180)),
            2000,
          ),
          PlanStatus.due,
        );

        // Distance exceeded -> overdue
        expect(
          app.maintenance.getDueStatus(
            combined,
            epoch.add(const Duration(days: 30)),
            5500,
          ),
          PlanStatus.overdue,
        );

        // Date exceeded -> overdue
        expect(
          app.maintenance.getDueStatus(
            combined,
            epoch.add(const Duration(days: 200)),
            1000,
          ),
          PlanStatus.overdue,
        );
      },
    );

    // M05: Pause plan without deleting service history (Normal)
    test(
      'pauses and resumes plan while preserving status and service history',
      () {
        app.maintenance.createPlan(plan(id: 'p1'));
        app.maintenance.recordCompletion(
          'p1',
          record(id: 's1', costMinorUnits: 3000, odometerKm: 5000),
        );

        // Pause plan
        final paused = app.maintenance.pausePlan('p1');
        expect(paused.enabled, isFalse);
        expect(
          app.maintenance.getDueStatus(
            paused,
            epoch.add(const Duration(days: 365)),
            99999,
          ),
          PlanStatus.paused,
        );
        // History is preserved
        expect(app.maintenance.getServiceHistory('v1'), hasLength(1));
        // Re-pausing throws StateError
        expect(() => app.maintenance.pausePlan('p1'), throwsStateError);

        // Resume plan
        final resumed = app.maintenance.resumePlan('p1');
        expect(resumed.enabled, isTrue);
        expect(() => app.maintenance.resumePlan('p1'), throwsStateError);
      },
    );
  });

  group('Service Records', () {
    // S01: Complete plan and create linked service record (Normal / multi-entity)
    test('completes plan atomically, linking service record and advancing due targets', () {
      app.maintenance.createPlan(
        plan(
          id: 'p1',
          intervalKm: 5000,
          intervalDays: 180,
          dueKm: 5000,
          dueAt: epoch.add(const Duration(days: 180)),
        ),
      );

      final completionRecord = record(
        id: 's1',
        costMinorUnits: 4500,
        odometerKm: 5000,
        day: 60,
        notes: 'Oil changed using synthetic 5W-30',
      );

      final saved = app.maintenance.recordCompletion('p1', completionRecord);
      expect(saved.id, 's1');
      expect(saved.maintenancePlanId, 'p1');
      expect(saved.vehicleId, 'v1');
      expect(saved.costMinorUnits, 4500);
      expect(saved.odometerKm, 5000);

      // Verify plan anchors and next-due values are updated
      final updatedPlan = app.maintenance.getPlan('p1');
      expect(updatedPlan.lastCompletedKm, 5000);
      expect(updatedPlan.lastCompletedAt, epoch.add(const Duration(days: 60)));
      expect(updatedPlan.dueKm, 10000); // 5000 + 5000
      expect(updatedPlan.dueAt, epoch.add(const Duration(days: 60 + 180)));

      // Verify service history reflects the record
      final history = app.maintenance.getServiceHistory('v1');
      expect(history, hasLength(1));
      expect(history.single.id, 's1');
    });

    // S02: Reject negative service expense without partial changes (Invalid)
    test('rejects invalid service expense or mileage without partial state mutation', () {
      final initialPlan = app.maintenance.createPlan(
        plan(id: 'p1', intervalKm: 5000, dueKm: 5000),
      );

      // Negative expense
      expect(
        () => app.maintenance.recordCompletion(
          'p1',
          record(id: 's_bad1', costMinorUnits: -500),
        ),
        throwsArgumentError,
      );

      // Negative odometer
      expect(
        () => app.maintenance.recordCompletion(
          'p1',
          record(id: 's_bad2', odometerKm: -1),
        ),
        throwsArgumentError,
      );

      // Blank title
      expect(
        () => app.maintenance.recordCompletion(
          'p1',
          record(id: 's_bad3', title: '   '),
        ),
        throwsArgumentError,
      );

      // Verify plan state is completely untouched (no partial writes)
      final planAfterErrors = app.maintenance.getPlan('p1');
      expect(planAfterErrors.lastCompletedKm, isNull);
      expect(planAfterErrors.dueKm, initialPlan.dueKm);
      expect(app.maintenance.getServiceHistory('v1'), isEmpty);
    });

    // S03: Reject service record linked to a plan from another vehicle (Invalid)
    test('rejects service record linked to another vehicles plan', () {
      app.vehicles.addVehicle(vehicle(id: 'v2', name: 'Second car'));
      app.maintenance.createPlan(plan(id: 'p1', vehicleId: 'v1'));

      // recordCompletion with mismatched vehicleId on record
      expect(
        () => app.maintenance.recordCompletion(
          'p1',
          record(id: 's1', vehicleId: 'v2'),
        ),
        throwsArgumentError,
      );

      // addUnscheduledService linking to a plan owned by another vehicle
      expect(
        () => app.maintenance.addUnscheduledService(
          record(id: 's2', vehicleId: 'v2', maintenancePlanId: 'p1'),
        ),
        throwsArgumentError,
      );

      expect(app.maintenance.getServiceHistory('v1'), isEmpty);
      expect(app.maintenance.getServiceHistory('v2'), isEmpty);
    });

    // S04: Sum multiple expenses including zero-cost service (Boundary)
    test('sums multiple service expenses including zero-cost records', () {
      expect(app.maintenance.getTotalExpense('v1'), 0);

      // Unscheduled zero-cost inspection
      app.maintenance.addUnscheduledService(
        record(id: 's1', costMinorUnits: 0, day: 10),
      );
      expect(app.maintenance.getTotalExpense('v1'), 0);

      // Scheduled services with costs
      app.maintenance.createPlan(plan(id: 'p1'));
      app.maintenance.recordCompletion(
        'p1',
        record(id: 's2', costMinorUnits: 2500, day: 20),
      );
      app.maintenance.addUnscheduledService(
        record(id: 's3', costMinorUnits: 7500, day: 30),
      );

      expect(app.maintenance.getTotalExpense('v1'), 10000);
    });
  });

  group('Cross-domain Integration', () {
    test('full workflow: vehicle -> odometer -> plan -> completion -> due progression', () {
      final truck = app.vehicles.addVehicle(
        vehicle(id: 'trk-1', name: 'Work Truck', type: VehicleType.truck),
      );
      expect(truck.id, 'trk-1');

      // 1. Initial odometer reading
      app.odometer.addReading(reading('odo-1', 0, 10000, vehicleId: 'trk-1'));
      expect(app.odometer.getCurrentOdometer('trk-1')!.kilometres, 10000);

      // 2. Create maintenance plan with 5,000 km or 180 days interval
      final oilPlan = app.maintenance.createPlan(
        plan(
          id: 'truck-oil',
          vehicleId: 'trk-1',
          title: 'Heavy Duty Oil Change',
          intervalKm: 5000,
          intervalDays: 180,
        ),
      );
      // Since current odometer is 10000, next due should be 15000
      expect(oilPlan.dueKm, 15000);

      // 3. Status is upcoming at 12,000 km (day 30)
      app.odometer.addReading(reading('odo-2', 30, 12000, vehicleId: 'trk-1'));
      expect(
        app.maintenance.getDueStatus(
          oilPlan,
          epoch.add(const Duration(days: 30)),
          12000,
        ),
        PlanStatus.upcoming,
      );

      // 4. Vehicle reaches 15,000 km at day 60 -> Plan is due
      app.odometer.addReading(reading('odo-3', 60, 15000, vehicleId: 'trk-1'));
      expect(
        app.maintenance.getDueStatus(
          oilPlan,
          epoch.add(const Duration(days: 60)),
          15000,
        ),
        PlanStatus.due,
      );

      // 5. Complete maintenance service at 15,000 km for $85.00 (8500 cents)
      final record = app.maintenance.recordCompletion(
        'truck-oil',
        ServiceRecord(
          id: 'rec-1',
          vehicleId: 'trk-1',
          performedAt: epoch.add(const Duration(days: 60)),
          title: 'Changed 15W-40 oil and filter',
          costMinorUnits: 8500,
          odometerKm: 15000,
        ),
      );
      expect(record.maintenancePlanId, 'truck-oil');

      // 6. Verify plan due targets advanced to 20,000 km and day 240
      final refreshedPlan = app.maintenance.getPlan('truck-oil');
      expect(refreshedPlan.lastCompletedKm, 15000);
      expect(refreshedPlan.dueKm, 20000);
      expect(refreshedPlan.dueAt, epoch.add(const Duration(days: 60 + 180)));

      // 7. Verify plan is back to upcoming after completion
      expect(
        app.maintenance.getDueStatus(
          refreshedPlan,
          epoch.add(const Duration(days: 60)),
          15000,
        ),
        PlanStatus.upcoming,
      );

      // 8. Verify total expenses
      expect(app.maintenance.getTotalExpense('trk-1'), 8500);
      expect(app.maintenance.getServiceHistory('trk-1'), hasLength(1));
    });
  });
}
