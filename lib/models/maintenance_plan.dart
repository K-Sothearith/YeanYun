enum PlanStatus { upcoming, due, overdue, paused }

class MaintenancePlan {
  final String _id;
  final String _vehicleId;
  final String _title;
  final bool _enabled;
  final DateTime _createdAt;
  final int? _intervalKm;
  final int? _intervalDays;
  final DateTime? _lastCompletedAt;
  final int? _lastCompletedKm;
  final DateTime? _dueAt;
  final int? _dueKm;
  final String? _notes;
  final String? _templateKey;

  MaintenancePlan({
    required this._id,
    required this._vehicleId,
    required this._title,
    required DateTime createdAt,
    this._enabled = true,
    this._intervalKm,
    this._intervalDays,
    DateTime? lastCompletedAt,
    this._lastCompletedKm,
    DateTime? dueAt,
    this._dueKm,
    this._notes,
    this._templateKey,
  }) : _createdAt = createdAt.toUtc(),
       _lastCompletedAt = lastCompletedAt?.toUtc(),
       _dueAt = dueAt?.toUtc();

  String get id => _id;
  String get vehicleId => _vehicleId;
  String get title => _title;
  bool get enabled => _enabled;
  DateTime get createdAt => _createdAt;
  int? get intervalKm => _intervalKm;
  int? get intervalDays => _intervalDays;
  DateTime? get lastCompletedAt => _lastCompletedAt;
  int? get lastCompletedKm => _lastCompletedKm;
  DateTime? get dueAt => _dueAt;
  int? get dueKm => _dueKm;
  String? get notes => _notes;
  String? get templateKey => _templateKey;
}
