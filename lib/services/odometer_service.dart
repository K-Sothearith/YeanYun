import '../models/odometer_reading.dart';
import 'vehicle_service.dart';

class OdometerService {
  OdometerService(this._vehicles);
  final Map<String, OdometerReading> _readings = {};
  final VehicleService _vehicles;

  List<OdometerReading> getReadings(String vehicleId) {
    _vehicles.getVehicle(vehicleId);
    final readings = _readings.values.where((r) => r.vehicleId == vehicleId).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List.unmodifiable(readings);
  }
  
  OdometerReading? getCurrentOdometer(String vehicleId) {
    final readings = getReadings(vehicleId);
    return readings.isEmpty ? null : readings.last;
  }

  OdometerReading addReading(OdometerReading input) {
    _requireUnique(_readings, input.id);
    _validate(input);
    _readings[input.id] = input;
    return input;
  }

  OdometerReading updateReading(String id, OdometerReading input) {
    final current = _readings[id];
    if (current == null) throw StateError('Reading not found: $id');
    if (input.id != id || input.vehicleId != current.vehicleId) {
      throw ArgumentError('Reading identity and vehicle cannot change.');
    }
    _validate(input, excludingId: id);
    final updated = OdometerReading(
      id: id,
      vehicleId: current.vehicleId,
      recordedAt: input.recordedAt,
      kilometres: input.kilometres,
      note: input.note,
      createdAt: current.createdAt,
    );
    _readings[id] = updated;
    return updated;
  }

  void _validate(OdometerReading input, {String? excludingId}) {
    _requireNonblank(input.id, 'id');
    _requireNonblank(input.vehicleId, 'vehicleId');
    _requireNonnegative(input.kilometres, 'kilometres');
    for (final other in getReadings(input.vehicleId)) {
      if (other.id == excludingId) continue;
      final order = input.recordedAt.compareTo(other.recordedAt);
      if (order == 0) throw ArgumentError('Duplicate reading timestamp.');
      if ((order < 0 && input.kilometres > other.kilometres) ||
          (order > 0 && input.kilometres < other.kilometres)) {
        throw ArgumentError('Mileage must follow chronological order.');
      }
    }
  }

  void _requireNonblank(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError('$name must not be blank.');
  }

  void _requireNonnegative(int value, String name) {
    if (value < 0) throw ArgumentError('$name must not be negative.');
  }

  void _requireUnique<T>(Map<String, T> store, String id) {
    if (store.containsKey(id)) throw StateError('ID already exists: $id');
  }
}
