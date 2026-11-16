import '../models/vehicle.dart';

class VehicleService {
  final Map<String, Vehicle> _vehicles = {};

  Vehicle getVehicle(String id) {
    _requireNonblank(id, 'id');
    return _vehicles[id] ?? (throw StateError('Vehicle not found: $id'));
  }

  List<Vehicle> getVehicles({bool includeArchived = true}) => List.unmodifiable(
    _vehicles.values.where((v) => includeArchived || !v.isArchived),
  );

  Vehicle addVehicle(Vehicle input) {
    _validate(input);
    _requireUnique(_vehicles, input.id);
    _vehicles[input.id] = input;
    return input;
  }

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
    _vehicles[id] = updated;
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
    _vehicles[id] = updated;
    return updated;
  }

  void _validate(Vehicle v) {
    _requireNonblank(v.id, 'id');
    _requireNonblank(v.name, 'name');
    _validateVehicleType(v.type, v.subtype);
    if (v.year != null && v.year! <= 0) {
      throw ArgumentError('Year must be positive.');
    }
  }

  void _requireNonblank(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError('$name must not be blank.');
  }

  void _requireUnique<T>(Map<String, T> store, String id) {
    if (store.containsKey(id)) throw StateError('ID already exists: $id');
  }

  void _validateVehicleType(VehicleType type, ElectricVehicleSubtype? subtype) {
    if (subtype != null && type != VehicleType.electricCar) {
      throw ArgumentError('Only electric cars may have an EV subtype.');
    }
  }
}
