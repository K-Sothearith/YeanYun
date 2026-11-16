part of 'yeanyun.dart';

class OdometerService {
  OdometerService._(this._app);
  final YeanYun _app;

  List<OdometerReading> getReadings(String vehicleId) {
    _app.vehicles.getVehicle(vehicleId);
    final readings =
        _app._readings.values.where((r) => r.vehicleId == vehicleId).toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List.unmodifiable(readings);
  }

  /// Latest reading by effective timestamp, or null if none exists.
  OdometerReading? getCurrentOdometer(String vehicleId) {
    final readings = getReadings(vehicleId);
    return readings.isEmpty ? null : readings.last;
  }

  OdometerReading addReading(OdometerReading input) {
    _unique(_app._readings, input.id);
    _validate(input);
    _app._readings[input.id] = input;
    return input;
  }

  OdometerReading updateReading(String id, OdometerReading input) {
    final current = _app._readings[id];
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
    _app._readings[id] = updated;
    return updated;
  }

  void _validate(OdometerReading input, {String? excludingId}) {
    _nonblank(input.id, 'id');
    _nonblank(input.vehicleId, 'vehicleId');
    _nonnegative(input.kilometres, 'kilometres');
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
}
