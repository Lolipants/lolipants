import 'package:geolocator/geolocator.dart';
import 'package:lolipants/core/constants/default_delivery_coords.dart';

/// How delivery / workshop coordinates were obtained.
enum ResolvedLocationSource {
  gps,
  cached,
  fallback,
}

/// GPS or fallback coordinates for tailor proximity assignment.
class ResolvedDeliveryLocation {
  const ResolvedDeliveryLocation({
    required this.lat,
    required this.lng,
    required this.source,
    this.permissionDenied = false,
    this.servicesDisabled = false,
  });

  final double lat;
  final double lng;
  final ResolvedLocationSource source;
  final bool permissionDenied;
  final bool servicesDisabled;

  String get statusLabel {
    return switch (source) {
      ResolvedLocationSource.gps => 'Using your current location',
      ResolvedLocationSource.cached => 'Using your saved delivery location',
      ResolvedLocationSource.fallback when permissionDenied =>
        'Location off — using Doha area for tailor matching',
      ResolvedLocationSource.fallback when servicesDisabled =>
        'Turn on location services for a more accurate match',
      ResolvedLocationSource.fallback =>
        'GPS unavailable — using Doha area for tailor matching',
    };
  }
}

/// Resolves device GPS with permission handling and sensible fallbacks.
abstract final class DeliveryLocationService {
  static Future<ResolvedDeliveryLocation> resolve({
    double? cachedLat,
    double? cachedLng,
    bool preferCached = false,
  }) async {
    final cached = _readCached(cachedLat, cachedLng);
    if (preferCached && cached != null) {
      return ResolvedDeliveryLocation(
        lat: cached.lat,
        lng: cached.lng,
        source: ResolvedLocationSource.cached,
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _fallback(
        cached: cached,
        servicesDisabled: true,
      );
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _fallback(
        cached: cached,
        permissionDenied: true,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return ResolvedDeliveryLocation(
        lat: position.latitude,
        lng: position.longitude,
        source: ResolvedLocationSource.gps,
      );
    } catch (_) {
      return _fallback(cached: cached);
    }
  }

  static ResolvedDeliveryLocation _fallback({
    ({double lat, double lng})? cached,
    bool permissionDenied = false,
    bool servicesDisabled = false,
  }) {
    if (cached != null) {
      return ResolvedDeliveryLocation(
        lat: cached.lat,
        lng: cached.lng,
        source: ResolvedLocationSource.cached,
        permissionDenied: permissionDenied,
        servicesDisabled: servicesDisabled,
      );
    }
    return ResolvedDeliveryLocation(
      lat: DefaultDeliveryCoords.dohaLat,
      lng: DefaultDeliveryCoords.dohaLng,
      source: ResolvedLocationSource.fallback,
      permissionDenied: permissionDenied,
      servicesDisabled: servicesDisabled,
    );
  }

  static ({double lat, double lng})? _readCached(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    return (lat: lat, lng: lng);
  }
}
