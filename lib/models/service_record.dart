class ServiceRecord {
  final String _id;
  final String _vehicleId;
  final DateTime _performedAt;
  final String _title;
  final int _costMinorUnits;
  final int _odometerKm;
  final String? _maintenancePlanId;
  final String? _notes;
  final DateTime? _createdAt;

  ServiceRecord({
    required this._id,
    required this._vehicleId,
    required DateTime performedAt,
    required this._title,
    required this._costMinorUnits,
    required this._odometerKm,
    this._maintenancePlanId,
    this._notes,
    DateTime? createdAt,
  }) : _performedAt = performedAt.toUtc(),
       _createdAt = createdAt?.toUtc();

  String get id => _id;
  String get vehicleId => _vehicleId;
  DateTime get performedAt => _performedAt;
  String get title => _title;
  int get costMinorUnits => _costMinorUnits;
  int get odometerKm => _odometerKm;
  String? get maintenancePlanId => _maintenancePlanId;
  String? get notes => _notes;
  DateTime? get createdAt => _createdAt;
}
