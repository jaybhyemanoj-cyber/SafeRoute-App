import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  /// Calculate bounds to enclose a list of points (e.g., user + destination)
  LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(21.1458, 79.0882),
        const LatLng(21.1458, 79.0882),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    // Add padding margin
    final latPadding = (maxLat - minLat).abs() * 0.25;
    final lonPadding = (maxLon - minLon).abs() * 0.25;

    return LatLngBounds(
      LatLng(minLat - (latPadding == 0 ? 0.01 : latPadding), minLon - (lonPadding == 0 ? 0.01 : lonPadding)),
      LatLng(maxLat + (latPadding == 0 ? 0.01 : latPadding), maxLon + (lonPadding == 0 ? 0.01 : lonPadding)),
    );
  }

  /// Fit map controller camera to bounds smoothly
  void fitBounds(MapController mapController, LatLngBounds bounds) {
    try {
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48.0),
        ),
      );
    } catch (e) {
      // Ignore if map not ready
    }
  }
}
