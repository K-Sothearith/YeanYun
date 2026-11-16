part of 'yeanyun.dart';

class VehicleService {
  VehicleService._(this._app);
  final YeanYun _app;

  Vehicle getVehicle(String id) {
    _nonblank(id, 'id');
    return _app._vehicles[id] ?? (throw StateError('Vehicle not found: $id'));
  }

  List<Vehicle> getVehicles({bool includeArchived = true}) => List.unmodifiable(
    _app._vehicles.values.where((v) => includeArchived || !v.isArchived),
  );

  Vehicle addVehicle(Vehicle input) {
    _validate(input);
    _unique(_app._vehicles, input.id);
    _app._vehicles[input.id] = input;
    return input;
  }

  /// Replaces editable fields, including nullable fields. Identity, creation
  /// date and archive state are preserved; use archive/restore for transitions.
  Vehicle updateVehicle(String id, Vehicle input) {
    final current = getVehicle(id);
    _validate(input);
    if (input.id != id) throw ArgumentError('Vehicle ID cannot change.');
    final updated = Vehicle(
      id: id,
      name: input.name,
      type: input.type,
      addedAt: current.addedAt,
      isArchived: current.isArchived,
      subtype: input.subtype,
      make: input.make,
      model: input.model,
      year: input.year,
      notes: input.notes,
    );
    _app._vehicles[id] = updated;
    return updated;
  }

  Vehicle archiveVehicle(String id) => _setArchived(id, true);
  Vehicle restoreVehicle(String id) => _setArchived(id, false);

  Vehicle _setArchived(String id, bool archived) {
    final v = getVehicle(id);
    if (v.isArchived == archived) {
      throw StateError(
        archived ? 'Vehicle already archived.' : 'Vehicle active.',
      );
    }
    final updated = Vehicle(
      id: v.id,
      name: v.name,
      type: v.type,
      addedAt: v.addedAt,
      isArchived: archived,
      subtype: v.subtype,
      make: v.make,
      model: v.model,
      year: v.year,
      notes: v.notes,
    );
    _app._vehicles[id] = updated;
    return updated;
  }

  void _validate(Vehicle v) {
    _nonblank(v.id, 'id');
    _nonblank(v.name, 'name');
    _vehicleType(v.type, v.subtype);
    if (v.year != null && v.year! <= 0) {
      throw ArgumentError('Year must be positive.');
    }
  }
}
