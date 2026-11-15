enum AppThemeMode { system, light, dark }
enum ReminderPreference { beforeDue, onDueDate, beforeAndOnDueDate }

class AppSettings {
  final String reportingCurrency;
  final int currencyDecimalPlaces;
  final AppThemeMode themeMode;
  final int reminderLeadDays;
  final ReminderPreference reminderPreference;
  final int schemaVersion;

  AppSettings({
    required this.reportingCurrency,
    required this.currencyDecimalPlaces,
    this.themeMode = AppThemeMode.system,
    this.reminderLeadDays = 7,
    this.reminderPreference = ReminderPreference.beforeAndOnDueDate,
    this.schemaVersion = 1,
  });
}
