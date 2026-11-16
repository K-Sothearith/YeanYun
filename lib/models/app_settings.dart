enum AppThemeMode { system, light, dark }

enum ReminderPreference { beforeDue, onDueDate, beforeAndOnDueDate }

class AppSettings {
  final String _reportingCurrency;
  final int _currencyDecimalPlaces;
  final AppThemeMode _themeMode;
  final int _reminderLeadDays;
  final ReminderPreference _reminderPreference;
  final int _schemaVersion;

  AppSettings({
    required this._reportingCurrency,
    required this._currencyDecimalPlaces,
    this._themeMode = AppThemeMode.system,
    this._reminderLeadDays = 7,
    this._reminderPreference = ReminderPreference.beforeAndOnDueDate,
    this._schemaVersion = 1,
  });

  String get reportingCurrency => _reportingCurrency;
  int get currencyDecimalPlaces => _currencyDecimalPlaces;
  AppThemeMode get themeMode => _themeMode;
  int get reminderLeadDays => _reminderLeadDays;
  ReminderPreference get reminderPreference => _reminderPreference;
  int get schemaVersion => _schemaVersion;
}
