import '../models/odometer_reading.dart';
import '../models/vehicle.dart';

export '../models/odometer_reading.dart';
export '../models/vehicle.dart';

part 'vehicle_service.dart';
part 'odometer_service.dart';

class YeanYun {
  YeanYun() {
    _vehicleService = VehicleService._(this);
    _odometerService = OdometerService._(this);
  }

  final Map<String, Vehicle> _vehicles = {};
  final Map<String, OdometerReading> _readings = {};
  late final VehicleService _vehicleService;
  late final OdometerService _odometerService;

  VehicleService get vehicles => _vehicleService;
  OdometerService get odometer => _odometerService;
}

void _nonblank(String value, String name) {
  if (value.trim().isEmpty) throw ArgumentError('$name must not be blank.');
}

void _nonnegative(int value, String name) {
  if (value < 0) throw ArgumentError('$name must not be negative.');
}

void _unique<T>(Map<String, T> store, String id) {
  if (store.containsKey(id)) throw StateError('ID already exists: $id');
}

void _vehicleType(VehicleType type, ElectricVehicleSubtype? subtype) {
  if (subtype != null && type != VehicleType.electricCar) {
    throw ArgumentError('Only electric cars may have an EV subtype.');
  }
}
