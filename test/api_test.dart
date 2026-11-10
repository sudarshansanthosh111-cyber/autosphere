import 'dart:convert';

import 'package:autosphere/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'sends vehicle and service fields accepted by the FastAPI schemas',
    () async {
      final requests = <http.Request>[];
      Api.useHttpClient(
        MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'id': 'remote-id', 'owner_id': 'owner-id'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await Api.createVehicle(
        userId: 'owner-id',
        make: 'Toyota',
        model: 'Innova Hycross',
        year: 2025,
        currentMileage: 10100,
      );
      await Api.createMaintenance(
        vehicleId: 'remote-id',
        serviceDate: '2026-10-08',
        serviceType: 'Oil change',
        cost: 4500,
        mileageAtService: 10100,
        notes: 'Mandovi Motors',
      );

      expect(requests[0].url.path, '/users/owner-id/vehicles/');
      expect(jsonDecode(requests[0].body), {
        'make': 'Toyota',
        'model': 'Innova Hycross',
        'year': 2025,
        'current_mileage': 10100,
      });
      expect(requests[1].url.path, '/vehicles/remote-id/maintenance/');
      expect(jsonDecode(requests[1].body), {
        'service_date': '2026-10-08',
        'service_type': 'Oil change',
        'cost': 4500,
        'mileage_at_service': 10100,
        'notes': 'Mandovi Motors',
      });
    },
  );
}
