part of 'yeanyun.dart';

class MaintenanceService {
  MaintenanceService._(this._app);
  final YeanYun _app;

  MaintenancePlan getPlan(String id) {
    _nonblank(id, 'id');
    return _app._plans[id] ??
        (throw StateError('Maintenance plan not found: $id'));
  }

  List<MaintenancePlan> getPlans(
    String vehicleId, {
    bool includeDisabled = true,
  }) {
    _app.vehicles.getVehicle(vehicleId);
    final plans =
        _app._plans.values
            .where(
              (p) => p.vehicleId == vehicleId && (includeDisabled || p.enabled),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(plans);
  }

  MaintenancePlan createPlan(MaintenancePlan input) {
    _validatePlan(input);
    _unique(_app._plans, input.id);

    int? dueKm = input.dueKm;
    if (dueKm == null && input.intervalKm != null) {
      final baseKm =
          input.lastCompletedKm ??
          _app.odometer.getCurrentOdometer(input.vehicleId)?.kilometres ??
          0;
      dueKm = baseKm + input.intervalKm!;
    }

    DateTime? dueAt = input.dueAt;
    if (dueAt == null && input.intervalDays != null) {
      final baseDate = input.lastCompletedAt ?? input.createdAt;
      dueAt = baseDate.add(Duration(days: input.intervalDays!));
    }

    final plan = MaintenancePlan(
      id: input.id,
      vehicleId: input.vehicleId,
      title: input.title,
      createdAt: input.createdAt,
      enabled: input.enabled,
      intervalKm: input.intervalKm,
      intervalDays: input.intervalDays,
      lastCompletedAt: input.lastCompletedAt,
      lastCompletedKm: input.lastCompletedKm,
      dueAt: dueAt,
      dueKm: dueKm,
      notes: input.notes,
      templateKey: input.templateKey,
    );

    _app._plans[plan.id] = plan;
    return plan;
  }

  MaintenancePlan addPlan(MaintenancePlan input) => createPlan(input);

  MaintenancePlan updatePlan(String id, MaintenancePlan input) {
    final current = getPlan(id);
    _validatePlan(input, isUpdate: true);
    if (input.id != id) throw ArgumentError('Plan ID cannot change.');
    if (input.vehicleId != current.vehicleId) {
      throw ArgumentError('Plan vehicle cannot change.');
    }
    final updated = MaintenancePlan(
      id: id,
      vehicleId: current.vehicleId,
      title: input.title,
      createdAt: current.createdAt,
      enabled: current.enabled,
      intervalKm: input.intervalKm,
      intervalDays: input.intervalDays,
      lastCompletedAt: current.lastCompletedAt,
      lastCompletedKm: current.lastCompletedKm,
      dueAt: input.dueAt ?? current.dueAt,
      dueKm: input.dueKm ?? current.dueKm,
      notes: input.notes,
      templateKey: input.templateKey ?? current.templateKey,
    );
    _app._plans[id] = updated;
    return updated;
  }

  MaintenancePlan pausePlan(String planId) => _setPlanEnabled(planId, false);
  MaintenancePlan resumePlan(String planId) => _setPlanEnabled(planId, true);

  MaintenancePlan _setPlanEnabled(String planId, bool enabled) {
    final plan = getPlan(planId);
    if (plan.enabled == enabled) {
      throw StateError(
        enabled ? 'Plan is already active.' : 'Plan is already paused.',
      );
    }
    final updated = MaintenancePlan(
      id: plan.id,
      vehicleId: plan.vehicleId,
      title: plan.title,
      createdAt: plan.createdAt,
      enabled: enabled,
      intervalKm: plan.intervalKm,
      intervalDays: plan.intervalDays,
      lastCompletedAt: plan.lastCompletedAt,
      lastCompletedKm: plan.lastCompletedKm,
      dueAt: plan.dueAt,
      dueKm: plan.dueKm,
      notes: plan.notes,
      templateKey: plan.templateKey,
    );
    _app._plans[planId] = updated;
    return updated;
  }

  PlanStatus getDueStatus(MaintenancePlan plan, DateTime today, int currentKm) {
    if (!plan.enabled) {
      return PlanStatus.paused;
    }

    bool isOverdue = false;
    bool isDue = false;

    // Check distance threshold
    final dueKm =
        plan.dueKm ??
        (plan.intervalKm != null
            ? (plan.lastCompletedKm ?? 0) + plan.intervalKm!
            : null);

    if (dueKm != null) {
      if (currentKm > dueKm) {
        isOverdue = true;
      } else if (currentKm == dueKm) {
        isDue = true;
      }
    }

    // Check time threshold
    final dueAt =
        plan.dueAt ??
        (plan.intervalDays != null
            ? (plan.lastCompletedAt ?? plan.createdAt).add(
                Duration(days: plan.intervalDays!),
              )
            : null);

    if (dueAt != null) {
      final todayUtc = today.toUtc();
      final dueAtUtc = dueAt.toUtc();
      if (todayUtc.isAfter(dueAtUtc)) {
        isOverdue = true;
      } else if (todayUtc.isAtSameMomentAs(dueAtUtc)) {
        isDue = true;
      }
    }

    if (isOverdue) return PlanStatus.overdue;
    if (isDue) return PlanStatus.due;
    return PlanStatus.upcoming;
  }

  PlanStatus getDueStatusById(String planId, DateTime today, int currentKm) {
    return getDueStatus(getPlan(planId), today, currentKm);
  }

  /// Coordinates Vehicle, MaintenancePlan, and ServiceRecord atomically.
  ServiceRecord recordCompletion(
    String planId,
    ServiceRecord record, {
    DateTime? now,
  }) {
    final plan = getPlan(planId);
    _validateServiceRecord(
      record,
      expectedPlanId: planId,
      expectedVehicleId: plan.vehicleId,
      now: now,
    );

    final nextDueKm = plan.intervalKm != null
        ? record.odometerKm + plan.intervalKm!
        : null;
    final nextDueAt = plan.intervalDays != null
        ? record.performedAt.add(Duration(days: plan.intervalDays!))
        : null;

    final updatedPlan = MaintenancePlan(
      id: plan.id,
      vehicleId: plan.vehicleId,
      title: plan.title,
      createdAt: plan.createdAt,
      enabled: plan.enabled,
      intervalKm: plan.intervalKm,
      intervalDays: plan.intervalDays,
      lastCompletedAt: record.performedAt,
      lastCompletedKm: record.odometerKm,
      dueAt: nextDueAt,
      dueKm: nextDueKm,
      notes: plan.notes,
      templateKey: plan.templateKey,
    );

    final storedRecord = ServiceRecord(
      id: record.id,
      vehicleId: plan.vehicleId,
      performedAt: record.performedAt,
      title: record.title,
      costMinorUnits: record.costMinorUnits,
      odometerKm: record.odometerKm,
      maintenancePlanId: planId,
      notes: record.notes,
      createdAt: record.createdAt ?? (now ?? DateTime.now()),
    );

    _app._plans[planId] = updatedPlan;
    _app._records[storedRecord.id] = storedRecord;
    return storedRecord;
  }

  ServiceRecord addUnscheduledService(ServiceRecord input, {DateTime? now}) {
    _validateServiceRecord(input, now: now);
    final stored = ServiceRecord(
      id: input.id,
      vehicleId: input.vehicleId,
      performedAt: input.performedAt,
      title: input.title,
      costMinorUnits: input.costMinorUnits,
      odometerKm: input.odometerKm,
      maintenancePlanId: input.maintenancePlanId,
      notes: input.notes,
      createdAt: input.createdAt ?? (now ?? DateTime.now()),
    );
    _app._records[stored.id] = stored;
    return stored;
  }

  ServiceRecord getServiceRecord(String id) {
    _nonblank(id, 'id');
    return _app._records[id] ??
        (throw StateError('Service record not found: $id'));
  }

  List<ServiceRecord> getServiceHistory(String vehicleId) {
    _app.vehicles.getVehicle(vehicleId);
    final history =
        _app._records.values.where((r) => r.vehicleId == vehicleId).toList()
          ..sort((a, b) => a.performedAt.compareTo(b.performedAt));
    return List.unmodifiable(history);
  }

  int getTotalExpense(String vehicleId) {
    _app.vehicles.getVehicle(vehicleId);
    return _app._records.values
        .where((r) => r.vehicleId == vehicleId)
        .fold(0, (sum, r) => sum + r.costMinorUnits);
  }

  void _validatePlan(MaintenancePlan p, {bool isUpdate = false}) {
    _nonblank(p.id, 'id');
    _nonblank(p.vehicleId, 'vehicleId');
    _nonblank(p.title, 'title');
    _app.vehicles.getVehicle(p.vehicleId);

    if (p.intervalKm == null && p.intervalDays == null) {
      throw ArgumentError('Plan must specify at least one positive interval.');
    }
    if (p.intervalKm != null && p.intervalKm! <= 0) {
      throw ArgumentError('Kilometre interval must be strictly positive.');
    }
    if (p.intervalDays != null && p.intervalDays! <= 0) {
      throw ArgumentError('Day interval must be strictly positive.');
    }
    if (p.dueKm != null && p.intervalKm == null) {
      throw ArgumentError(
        'Distance due threshold requires a distance interval.',
      );
    }
    if (p.dueAt != null && p.intervalDays == null) {
      throw ArgumentError('Date due threshold requires a time interval.');
    }
    if (p.dueKm != null && p.dueKm! < 0) {
      throw ArgumentError('Due kilometres must be non-negative.');
    }
    if (p.lastCompletedKm != null && p.lastCompletedKm! < 0) {
      throw ArgumentError('Last completed kilometres must be non-negative.');
    }
    if (p.templateKey != null && p.templateKey!.trim().isEmpty) {
      throw ArgumentError('Template key must not be blank.');
    }
  }

  void _validateServiceRecord(
    ServiceRecord record, {
    String? expectedPlanId,
    String? expectedVehicleId,
    DateTime? now,
  }) {
    _nonblank(record.id, 'id');
    _unique(_app._records, record.id);
    _nonblank(record.vehicleId, 'vehicleId');
    _nonblank(record.title, 'title');
    _nonnegative(record.costMinorUnits, 'costMinorUnits');
    _nonnegative(record.odometerKm, 'odometerKm');

    final cutoff = (now ?? DateTime.now()).toUtc();
    if (record.performedAt.toUtc().isAfter(cutoff)) {
      throw ArgumentError('Service date cannot be in the future.');
    }

    _app.vehicles.getVehicle(record.vehicleId);

    if (expectedVehicleId != null && record.vehicleId != expectedVehicleId) {
      throw ArgumentError(
        'Service record vehicle does not match plan vehicle: expected $expectedVehicleId, got ${record.vehicleId}',
      );
    }

    if (expectedPlanId != null) {
      if (record.maintenancePlanId != null &&
          record.maintenancePlanId != expectedPlanId) {
        throw ArgumentError(
          'Service record plan ID does not match expected plan ID: expected $expectedPlanId, got ${record.maintenancePlanId}',
        );
      }
    } else if (record.maintenancePlanId != null) {
      _nonblank(record.maintenancePlanId!, 'maintenancePlanId');
      final plan = getPlan(record.maintenancePlanId!);
      if (plan.vehicleId != record.vehicleId) {
        throw ArgumentError(
          'Linked plan does not belong to vehicle: ${record.vehicleId}',
        );
      }
    }
  }
}
