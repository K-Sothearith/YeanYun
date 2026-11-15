class ServiceRecord {
  final String id;
  final String vehicleId;
  final DateTime performedAt;
  final String title;
  final int costMinorUnits;
  final int odometerKm;
  final String? maintenancePlanId;
  final String? notes;
  final DateTime? createdAt;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required DateTime performedAt,
    required this.title,
    required this.costMinorUnits,
    required this.odometerKm,
    this.maintenancePlanId,
    this.notes,
    DateTime? createdAt,
  }) : 
    performedAt = performedAt.toUtc(),
    createdAt = createdAt?.toUtc();
}
