import 'package:flutter/foundation.dart';

/// Default backend URL used by the Flutter app.
///
/// Override at build/run time:
/// - `--dart-define=ZYLO_API_BASE_URL=http://10.0.2.2:3000`
const String zyloApiBaseUrl = String.fromEnvironment(
  'ZYLO_API_BASE_URL',
  defaultValue: kIsWeb ? 'http://localhost:3000' : 'http://localhost:3000',
);
