import 'package:flutter/foundation.dart';

/// Default local Admin Dashboard URL used by the Flutter app.
///
/// Override at build/run time:
/// - `--dart-define=ADMIN_DASHBOARD_BASE_URL=http://10.0.2.2:3001`
///
/// Notes:
/// - Android emulator must use `10.0.2.2` to reach your host machine.
const String adminDashboardBaseUrl = String.fromEnvironment(
  'ADMIN_DASHBOARD_BASE_URL',
  defaultValue: kIsWeb ? 'http://localhost:3001' : 'http://localhost:3001',
);
