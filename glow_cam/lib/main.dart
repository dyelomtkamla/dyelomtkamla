import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'features/pro/pro_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final pro = ProService();
  // Don't block the first frame on the store; the paywall shows a loader.
  pro.init();
  runApp(GlowCamApp(pro: pro));
}
