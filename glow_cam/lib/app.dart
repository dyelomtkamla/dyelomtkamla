import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'features/camera/camera_screen.dart';
import 'features/pro/pro_service.dart';

class GlowCamApp extends StatelessWidget {
  const GlowCamApp({super.key, required this.pro});

  final ProService pro;

  @override
  Widget build(BuildContext context) => ProScope(
        service: pro,
        child: MaterialApp(
          title: 'GlowCam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const CameraScreen(),
        ),
      );
}
