import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/models/destination.dart';
import 'package:saferoute_ai/models/route_model.dart';

void main() {
  group('RouteModel Formatting Tests', () {
    test('Formats distance correctly for km and meters', () {
      final routeKm = RouteModel(
        polylinePoints: [const LatLng(21.1458, 79.0882), const LatLng(21.1524, 79.0888)],
        distanceMeters: 2400,
        durationSeconds: 1740,
      );

      expect(routeKm.formattedDistance, '2.4 km');
      expect(routeKm.formattedDuration, '29 min');

      final routeMeters = RouteModel(
        polylinePoints: [const LatLng(21.1458, 79.0882)],
        distanceMeters: 450,
        durationSeconds: 300,
      );

      expect(routeMeters.formattedDistance, '450 m');
      expect(routeMeters.formattedDuration, '5 min');
    });

    test('Formats hours and minutes for long walking routes', () {
      final longRoute = RouteModel(
        polylinePoints: [],
        distanceMeters: 6500,
        durationSeconds: 4500, // 75 mins = 1 hr 15 min
      );

      expect(longRoute.formattedDuration, '1 hr 15 min');
    });
  });

  group('Destination Model Tests', () {
    test('Parses Nominatim JSON correctly', () {
      final json = {
        'display_name': 'Nagpur Railway Station, Station Road, Sitabuldi, Nagpur',
        'lat': '21.1524',
        'lon': '79.0888',
      };

      final dest = Destination.fromNominatimJson(json);
      expect(dest.title, 'Nagpur Railway Station');
      expect(dest.latitude, 21.1524);
      expect(dest.longitude, 79.0888);
    });
  });
}
