import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_cam/core/theme.dart';
import 'package:glow_cam/features/editor/widgets/option_strip.dart';

void main() {
  testWidgets('OptionTile shows Pro badge and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: OptionTile(
            label: 'وردي',
            isPro: true,
            selected: false,
            onTap: () => taps++,
            child: const ColoredBox(color: Colors.pink),
          ),
        ),
      ),
    ));
    expect(find.text('وردي'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    await tester.tap(find.text('وردي'));
    expect(taps, 1);
  });
}
