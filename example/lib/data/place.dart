import 'package:google_clustering/google_clustering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place with ClusterItem {
  Place({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;

  final LatLng position;

  @override
  LatLng get location => position;

  @override
  String toString() {
    return 'Place{id: $id, name: $name, location: $location}';
  }
}
