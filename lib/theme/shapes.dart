// lib/theme/shapes.dart
import 'package:flutter/material.dart';
 
class AppShapes {
  AppShapes._();
 
  static const double radiusLg = 20.0;
  static const double radiusMd = 12.0;
 
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius elementRadius = BorderRadius.all(Radius.circular(radiusMd));
 
  static const ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: cardRadius,
  );
 
  static const ShapeBorder dialogShape = RoundedRectangleBorder(
    borderRadius: cardRadius,
  );
}

