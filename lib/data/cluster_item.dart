import 'package:google_clustering/src/clustering_geohash.dart';
import 'package:google_clustering/utils/constants.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

mixin ClusterItem {
  LatLng get location;

  String? _geohash;
  String get geohash => _geohash ??= ClusteringGeohash.encode(
        latLng: location,
        codeLength: Constants.precision,
      );
}
