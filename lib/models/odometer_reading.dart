class OdometerReading {
  final String _id;
  final String _vehicleId;
  final DateTime _recordedAt;
  final int _kilometres;
  final String? _note;
  final DateTime? _createdAt;

  OdometerReading({
    required this._id,
    required this._vehicleId,
    required DateTime recordedAt,
    required this._kilometres,
    this._note,
    DateTime? createdAt,
  }) : _recordedAt = recordedAt.toUtc(),
       _createdAt = createdAt?.toUtc();

  String get id => _id;
  String get vehicleId => _vehicleId;
  DateTime get recordedAt => _recordedAt;
  int get kilometres => _kilometres;
  String? get note => _note;
  DateTime? get createdAt => _createdAt;
}
