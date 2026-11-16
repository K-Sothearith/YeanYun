enum VehicleType { motorcycle, conventionalCar, electricCar, truck }

enum ElectricVehicleSubtype { bev, erev, phev }

class Vehicle {
  final String _id;
  final String _name;
  final VehicleType _type;
  final DateTime _addedAt;
  final bool _isArchived;
  final ElectricVehicleSubtype? _subtype;
  final String? _make;
  final String? _model;
  final int? _year;
  final String? _notes;

  Vehicle({
    required this._id,
    required this._name,
    required this._type,
    required DateTime addedAt,
    this._isArchived = false,
    this._subtype,
    this._make,
    this._model,
    this._year,
    this._notes,
  }) : _addedAt = addedAt.toUtc();

  String get id => _id;
  String get name => _name;
  VehicleType get type => _type;
  DateTime get addedAt => _addedAt;
  bool get isArchived => _isArchived;
  ElectricVehicleSubtype? get subtype => _subtype;
  String? get make => _make;
  String? get model => _model;
  int? get year => _year;
  String? get notes => _notes;
}
