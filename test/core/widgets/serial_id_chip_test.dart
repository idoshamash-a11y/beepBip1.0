import 'package:beepbip/core/theme/app_theme.dart';
import 'package:beepbip/core/widgets/serial_id_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('SerialIdChip', () {
    testWidgets('renders the serial id', (tester) async {
      await tester.pumpWidget(_wrap(const SerialIdChip(serialId: 'BP-A1B2C3')));
      expect(find.text('BP-A1B2C3'), findsOneWidget);
    });

    testWidgets('renders nothing when serialId is null or empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const SerialIdChip(serialId: null)));
      expect(find.byType(InkWell), findsNothing);

      await tester.pumpWidget(_wrap(const SerialIdChip(serialId: '   ')));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('copies the id to the clipboard on tap', (tester) async {
      String? lastSetClipboardValue;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            lastSetClipboardValue =
                (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(_wrap(const SerialIdChip(serialId: 'BP-XYZ123')));
      await tester.tap(find.byType(SerialIdChip));
      await tester.pump();

      expect(lastSetClipboardValue, 'BP-XYZ123');
    });
  });
}
