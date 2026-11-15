enum VehicleType { motorcycle, conventionalCar, electricCar, truck }
enum ElectricVehicleSubtype { bev, erev, phev }

class Vehicle {
  final String id;
  final String name;
  final VehicleType type;
  final DateTime addedAt;
  final bool isArchived;
  final ElectricVehicleSubtype? subtype;
  final String? make;
  final String? model;
  final int? year;
  final String? notes;

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required DateTime addedAt,
    this.isArchived = false,
    this.subtype,
    this.make,
    this.model,
    this.year,
    this.notes,
  }) : addedAt = addedAt.toUtc();
}
