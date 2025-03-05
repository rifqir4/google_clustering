import 'package:flutter/foundation.dart';

class Constants {
  Constants._();

  /// Maximum number of items for max distance algorithm
  static const int maxItemsForMaxDistAlgo = 1000;

  /// Precision of the geohash
  static const int precision = kIsWeb ? 12 : 20;
}
