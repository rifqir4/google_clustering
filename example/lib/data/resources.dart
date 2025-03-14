import 'package:example/data/place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Resources {
  Resources._();

  static List<Place> places1 = [
    Place(
        id: "1",
        name: "Place 1",
        position: LatLng(37.42796133580664, -122.085749655962)),
    Place(id: "2", name: "Place 2", position: LatLng(37.43, -122.085749655962)),
    Place(id: "3", name: "Place 3", position: LatLng(37.44, -122.085749655962)),
    Place(id: "4", name: "Place 4", position: LatLng(37.45, -122.085749655962)),
    Place(id: "5", name: "Place 5", position: LatLng(37.46, -122.085749655962)),
    Place(id: "6", name: "Place 6", position: LatLng(37.47, -122.085749655962)),
  ];
}
