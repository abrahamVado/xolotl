import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xolotl/widgets/report_type_overlay.dart';

void main() {
  group('ReportTypeOverlay', () {
    testWidgets('shows empty state when types list is empty', (tester) async {
      //1.- Pump the widget with an empty list to verify the placeholder message.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReportTypeOverlay(
              types: [],
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      //2.- The overlay should render the friendly empty state text.
      expect(find.text('Sin tipos disponibles'), findsOneWidget);
    });

    testWidgets('invokes callbacks for selection and dismiss', (tester) async {
      //1.- Prepare spies to capture selection and dismiss invocations.
      String? selectedId;
      var dismissed = false;

      //2.- Render the overlay with a single mock type entry.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light(), useMaterial3: true),
          home: Scaffold(
            body: ReportTypeOverlay(
              types: const [
                {'id': 'pothole', 'name': 'Bache', 'emoji': '🕳️'},
              ],
              onSelected: (value) => selectedId = value,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      //3.- Tapping the ghost button should emit the item identifier.
      await tester.tap(find.byKey(const Key('report-type-pothole')));
      await tester.pump();
      expect(selectedId, 'pothole');

      //4.- Activating the close icon should call the dismiss callback.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, isTrue);
    });
  });
}

//1.- _noopOnSelected actúa como callback vacío para escenarios donde no importa.
void _noopOnSelected(String _) {}

//2.- _noopOnDismiss actúa como callback vacío para escenarios donde no importa.
void _noopOnDismiss() {}
