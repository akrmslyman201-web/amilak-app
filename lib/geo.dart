import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'common.dart';

Future<Position?> getPosition(BuildContext context) async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (context.mounted) msg(context, 'فعّل خدمة الموقع (GPS) في جوالك');
      return null;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (context.mounted) msg(context, 'لم يتم السماح بالوصول إلى الموقع');
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
  } catch (_) {
    if (context.mounted) msg(context, 'تعذر تحديد الموقع، حاول مرة أخرى');
    return null;
  }
}

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

String kmLabel(double km) =>
    km < 1 ? 'أقل من 1 كم' : '${km.toStringAsFixed(km < 10 ? 1 : 0)} كم';
