class OdometerReading {
  final String id;
  final String vehicleId;
  final DateTime recordedAt;
  final int kilometres;
  final String? note;
  final DateTime? createdAt;

  OdometerReading({
    required this.id,
    required this.vehicleId,
    required DateTime recordedAt,
    required this.kilometres,
    this.note,
    DateTime? createdAt,
  }) : 
    recordedAt = recordedAt.toUtc(),
    createdAt = createdAt?.toUtc();
}
