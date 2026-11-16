import 'package:flutter_test/flutter_test.dart';
import 'package:yeanyun/services/yeanyun.dart';

final epoch = DateTime.utc(2026, 1, 1);
final now = DateTime.utc(2026, 6, 1);

Vehicle vehicle({
  String id = 'v1',
  String name = 'Mitsubishi Expander',
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

  group('Technical verification', () {
    test('T1: rejects invalid input and duplicate IDs without saving', () {
      expect(
        () => app.vehicles.addVehicle(vehicle(id: 'bad', name: ' ')),
        throwsArgumentError,
      );
      expect(() => app.vehicles.addVehicle(vehicle()), throwsStateError);
      expect(
        () => app.maintenance.createPlan(plan(intervalKm: null)),
        throwsArgumentError,
      );
      expect(app.vehicles.getVehicles(), hasLength(1));
      expect(app.maintenance.getPlans('v1'), isEmpty);
    });

    test('T2: mileage must stay within chronological boundaries', () {
      app.odometer.addReading(reading('first', 0, 10000));
      app.odometer.addReading(reading('latest', 2, 12000));
      expect(
        () => app.odometer.addReading(reading('bad', 1, 12001)),
        throwsArgumentError,
      );
      app.odometer.addReading(reading('middle', 1, 10000));
      expect(app.odometer.getReadings('v1'), hasLength(3));
      expect(app.odometer.getCurrentOdometer('v1')!.id, 'latest');
    });

    test('T3: failed completion leaves the plan and history unchanged', () {
      final original = app.maintenance.createPlan(plan());
      expect(
        () => app.maintenance.recordCompletion(
          'p1',
          record(costMinorUnits: -500),
          now: now,
        ),
        throwsArgumentError,
      );
      app.vehicles.addVehicle(vehicle(id: 'v2'));
      expect(
        () => app.maintenance.recordCompletion(
          'p1',
          record(vehicleId: 'v2'),
          now: now,
        ),
        throwsArgumentError,
      );
      expect(app.maintenance.getPlan('p1'), same(original));
      expect(app.maintenance.getServiceHistory('v1'), isEmpty);
      expect(app.maintenance.getServiceHistory('v2'), isEmpty);
    });
  });

  group('Real-world use cases', () {
    test('U1: archive a vehicle and restore it with its history', () {
      app.odometer.addReading(reading('r1', 0, 10000));
      app.maintenance.addUnscheduledService(record(), now: now);
      app.vehicles.archiveVehicle('v1');
      expect(app.vehicles.getVehicles(includeArchived: false), isEmpty);
      final restored = app.vehicles.restoreVehicle('v1');
      expect(restored.isArchived, isFalse);
      expect(restored.id, 'v1');
      expect(app.odometer.getCurrentOdometer('v1')!.kilometres, 10000);
      expect(app.maintenance.getServiceHistory('v1').single.id, 's1');
    });

    test(
      'U2: oil change becomes due by distance or time, whichever comes first',
      () {
        final oilPlan = app.maintenance.createPlan(plan(intervalDays: 90));
        expect(
          app.maintenance.getDueStatus(oilPlan, epoch, 4999),
          PlanStatus.upcoming,
        );
        expect(
          app.maintenance.getDueStatus(oilPlan, epoch, 5000),
          PlanStatus.due,
        );
        expect(
          app.maintenance.getDueStatus(
            oilPlan,
            epoch.add(const Duration(days: 90)),
            1000,
          ),
          PlanStatus.due,
        );
        expect(
          app.maintenance.getDueStatus(
            oilPlan,
            epoch.add(const Duration(days: 91)),
            1000,
          ),
          PlanStatus.overdue,
        );
      },
    );

    test(
      'U3: completing an oil change saves history and advances the schedule',
      () {
        app.odometer.addReading(reading('baseline', 0, 10000));
        final original = app.maintenance.createPlan(plan(intervalDays: 90));
        expect(original.dueKm, 15000);
        app.odometer.addReading(reading('service-mileage', 30, 15000));
        final saved = app.maintenance.recordCompletion(
          'p1',
          record(odometerKm: 15000, costMinorUnits: 8500),
          now: now,
        );
        final updated = app.maintenance.getPlan('p1');
        expect(saved.maintenancePlanId, 'p1');
        expect(updated.id, original.id);
        expect(original.lastCompletedAt, isNull);
        expect(updated.lastCompletedKm, 15000);
        expect(updated.lastCompletedAt, saved.performedAt);
        expect(updated.dueKm, 20000);
        expect(updated.dueAt, epoch.add(const Duration(days: 120)));
        expect(
          app.maintenance.getDueStatus(updated, saved.performedAt, 15000),
          PlanStatus.upcoming,
        );
        expect(app.maintenance.getServiceHistory('v1').single, same(saved));
      },
    );

    test('U4: total paid and free services separately for each vehicle', () {
      app.vehicles.addVehicle(vehicle(id: 'v2', name: 'Second car'));
      app.maintenance.addUnscheduledService(
        record(id: 'inspection', costMinorUnits: 0),
        now: now,
      );
      app.maintenance.addUnscheduledService(
        record(id: 'oil', costMinorUnits: 2500),
        now: now,
      );
      app.maintenance.addUnscheduledService(
        record(id: 'brakes', costMinorUnits: 7500),
        now: now,
      );
      app.maintenance.addUnscheduledService(
        record(id: 'other-car', vehicleId: 'v2', costMinorUnits: 3000),
        now: now,
      );
      expect(app.maintenance.getServiceHistory('v1'), hasLength(3));
      expect(app.maintenance.getTotalExpense('v1'), 10000);
      expect(app.maintenance.getTotalExpense('v2'), 3000);
    });
  });
}
