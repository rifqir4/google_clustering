import 'dart:math';

import 'package:example/data/place.dart';
import 'package:example/data/resources.dart';
import 'package:flutter/material.dart';
import 'package:google_clustering/google_clustering.dart' as gc;
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? _controller;
  late gc.ClusterManager<Place> _clusterManager;

  Set<Marker> markers = {};
  Set<Circle> circles = {};

  double lastZoom = 1;
  double zoomlevel = 1;
  double radius = 1000;

  @override
  void initState() {
    _clusterManager = _initClusterManager();
    super.initState();
  }

  gc.ClusterManager<Place> _initClusterManager() {
    return gc.ClusterManager<Place>(
      Resources.places1,
      _updateMarkers,
      markerBuilder: _buildMarker,
      options: gc.ClusteringOptions(
        onlyInBounds: true,
      ),
      clusterAlgorithm: gc.ClusterAlgorithm.dbscan,
      dbScanParams: gc.DbScanParams(
        radius: 5,
      ),
    );
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  Future<Marker> _buildMarker(gc.Cluster<Place> cluster) async {
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: BitmapDescriptor.defaultMarker,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        minMaxZoomPreference: MinMaxZoomPreference(8, 16),
        padding: EdgeInsets.only(
          top: 100,
          bottom: 50,
        ),
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.42796133580664, -122.085749655962),
          zoom: 10,
        ),
        markers: markers,
        circles: markers
            .map((e) => Circle(
                  circleId: CircleId(e.markerId.value),
                  center: e.position,
                  radius: 1000 * (pow(2, (21 - zoomlevel)).toDouble()) * 0.0027,
                  fillColor: Colors.blue.withOpacity(0.1),
                  strokeWidth: 0,
                ))
            .toSet(),
        onCameraMove: (position) {
          _clusterManager.onCameraMove(position);
          zoomlevel = position.zoom;
        },
        onCameraIdle: () {
          _clusterManager.updateMap();
          lastZoom = zoomlevel;
        },
        onMapCreated: (controller) {
          _controller = controller;
          _clusterManager.setMapId(controller.mapId);
        },
      ),
    );
  }
}
