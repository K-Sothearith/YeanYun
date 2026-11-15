import 'vehicle.dart';

class MaintenanceTemplate {
  final String key;
  final VehicleType vehicleType;
  final String title;
  final ElectricVehicleSubtype? subtype;
  final int? intervalKm;
  final int? intervalDays;
  final String? applicabilityNote;

  MaintenanceTemplate({
    required this.key,
    required this.vehicleType,
    required this.title,
    this.subtype,
    this.intervalKm,
    this.intervalDays,
    this.applicabilityNote,
  });

  bool matchesVehicle(Vehicle vehicle) => 
    vehicle.type == vehicleType && (subtype == null || subtype == vehicle.subtype);
}
