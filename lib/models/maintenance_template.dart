import 'vehicle.dart';

class MaintenanceTemplate {
  final String _key;
  final VehicleType _vehicleType;
  final String _title;
  final ElectricVehicleSubtype? _subtype;
  final int? _intervalKm;
  final int? _intervalDays;
  final String? _applicabilityNote;

  MaintenanceTemplate({
    required this._key,
    required this._vehicleType,
    required this._title,
    this._subtype,
    this._intervalKm,
    this._intervalDays,
    this._applicabilityNote,
  });

  String get key => _key;
  VehicleType get vehicleType => _vehicleType;
  String get title => _title;
  ElectricVehicleSubtype? get subtype => _subtype;
  int? get intervalKm => _intervalKm;
  int? get intervalDays => _intervalDays;
  String? get applicabilityNote => _applicabilityNote;

  bool matchesVehicle(Vehicle vehicle) =>
      vehicle.type == vehicleType &&
      (subtype == null || subtype == vehicle.subtype);
}
