import 'package:autosphere/screens.dart';
import 'package:autosphere/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late AppState state;

  setUp(() {
    state = _WidgetTestAppState()
      ..isLoading = false
      ..maintenanceRecords = [
        {
          'id': 1,
          'date': '2026-05-14',
          'type': 'service',
          'title': '10,000 Km Service @ Mandovi Motors',
          'cost': 4500.0,
          'odometer': 10000,
        },
        {
          'id': 2,
          'date': '2026-08-10',
          'title': '360 Camera System Upgrade',
          'cost': 0.0,
        },
      ];
  });

  tearDown(() {
    state.dispose();
  });

  test('rejects a fourth vehicle before writing to the database', () async {
    state.vehicles = List.generate(
      AppState.maximumVehicles,
      (index) => {'id': index + 1},
    );

    await expectLater(
      state.addVehicle(
        nickname: 'Fourth',
        make: 'Toyota',
        model: 'Corolla',
        year: 2025,
        fuelType: 'Petrol',
        registration: '',
        odometer: 0,
      ),
      throwsStateError,
    );
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
  }

  testWidgets('shows vehicle, garage stats, and maintenance history', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('Your garage'), findsNWidgets(2));
    expect(find.text('Toyota Innova Hycross'), findsOneWidget);
    expect(find.text('₹4,500'), findsWidgets);
    expect(find.text('2 records'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('10,000 Km Service @ Mandovi Motors'),
      300,
    );
    expect(find.text('May 14, 2026'), findsOneWidget);
  });

  testWidgets('opens and validates the service interval editor', (
    tester,
  ) async {
    state.vehicles = [
      Map<String, dynamic>.unmodifiable({
        'id': 1,
        'nickname': 'Hycross',
        'make': 'Toyota',
        'model': 'Innova Hycross',
        'year': 2025,
        'fuel_type': 'Hybrid',
        'odometer': 10100,
        'service_interval': 5000,
      }),
    ];
    state.currentVehicleId = 1;
    await pumpDashboard(tester);

    await tester.tap(find.text('Set service interval'));
    await tester.pumpAndSettle();
    expect(find.text('Service interval'), findsOneWidget);
    expect(find.text('Distance between services'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number greater than 0'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '7500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Every 7,500 km'), findsOneWidget);
    expect(find.text('Next at 17,500 km'), findsOneWidget);
  });

  testWidgets('validates the add-maintenance form', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Add record'));
    await tester.pumpAndSettle();
    expect(find.text('Add maintenance record'), findsOneWidget);

    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a description'), findsOneWidget);
  });

  testWidgets('opens the timeline, analytics, and document vault tabs', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Activity timeline'), findsOneWidget);

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Fuel efficiency'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Monthly spending'), 300);
    expect(find.text('Monthly spending'), findsOneWidget);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Document vault'), findsOneWidget);
    expect(find.text('No paperwork yet'), findsOneWidget);
  });

  testWidgets('builds only the selected feature tab', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Fuel efficiency', skipOffstage: false), findsNothing);
    expect(find.text('Document vault', skipOffstage: false), findsNothing);

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Fuel efficiency', skipOffstage: false), findsOneWidget);
    expect(find.text('Document vault', skipOffstage: false), findsNothing);
  });

  testWidgets('opens the fuel form from the timeline quick action', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fuel fill'));
    await tester.pumpAndSettle();

    expect(find.text('Log fuel fill'), findsOneWidget);
    expect(find.text('Fuel station'), findsOneWidget);
    expect(find.text('Litres'), findsOneWidget);
    expect(find.text('Odometer (km)'), findsOneWidget);

    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsNWidgets(4));
  });

  testWidgets('disables adding vehicles after reaching the three-vehicle cap', (
    tester,
  ) async {
    state.vehicles = List.generate(
      AppState.maximumVehicles,
      (index) => {
        'id': index + 1,
        'nickname': 'Vehicle ${index + 1}',
        'make': 'Toyota',
        'model': 'Corolla',
        'year': 2025,
      },
    );
    state.currentVehicleId = 1;

    await pumpDashboard(tester);

    expect(find.byTooltip('Maximum 3 vehicles'), findsOneWidget);
    await tester.tap(find.byTooltip('Maximum 3 vehicles'));
    await tester.pumpAndSettle();
    expect(find.text('Add vehicle'), findsNothing);
    expect(state.canAddVehicle, isFalse);
  });
}

class _WidgetTestAppState extends AppState {
  @override
  Future<void> setServiceInterval({
    required int vehicleId,
    required int interval,
  }) async {
    vehicles = vehicles
        .map(
          (vehicle) => vehicle['id'] == vehicleId
              ? {...vehicle, 'service_interval': interval}
              : vehicle,
        )
        .toList();
    notifyListeners();
  }
}
