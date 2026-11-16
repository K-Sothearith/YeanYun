import 'vehicle_service.dart';
import 'odometer_service.dart';
import 'maintenance_service.dart';

export '../models/maintenance_plan.dart';
export '../models/odometer_reading.dart';
export '../models/service_record.dart';
export '../models/vehicle.dart';

export 'vehicle_service.dart';
export 'odometer_service.dart';
export 'maintenance_service.dart';

class YeanYun {
  YeanYun() {
    _vehicleService = VehicleService();
    _odometerService = OdometerService(_vehicleService);
    _maintenanceService = MaintenanceService(_vehicleService, _odometerService);
  }

  late final VehicleService _vehicleService;
  late final OdometerService _odometerService;
  late final MaintenanceService _maintenanceService;

  VehicleService get vehicles => _vehicleService;
  OdometerService get odometer => _odometerService;
  MaintenanceService get maintenance => _maintenanceService;
}
