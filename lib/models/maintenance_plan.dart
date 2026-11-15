enum PlanStatus { upcoming, due, overdue, paused }

class MaintenancePlan {
  final String id;
  final String vehicleId;
  final String title;
  final bool enabled;
  final DateTime createdAt;
  final int? intervalKm;
  final int? intervalDays;
  final DateTime? lastCompletedAt;
  final int? lastCompletedKm;
  final DateTime? dueAt;
  final int? dueKm;
  final String? notes;
  final String? templateKey;

  MaintenancePlan({
    required this.id,
    required this.vehicleId,
    required this.title,
    required DateTime createdAt,
    this.enabled = true,
    this.intervalKm,
    this.intervalDays,
    DateTime? lastCompletedAt,
    this.lastCompletedKm,
    DateTime? dueAt,
    this.dueKm,
    this.notes,
    this.templateKey,
  }) : createdAt = createdAt.toUtc(),
       lastCompletedAt = lastCompletedAt?.toUtc(),
       dueAt = dueAt?.toUtc();
}
