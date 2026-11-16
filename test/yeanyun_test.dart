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
}
