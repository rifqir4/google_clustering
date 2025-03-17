import 'dart:developer';

import 'package:google_clustering/data/cluster.dart';
import 'package:google_clustering/data/cluster_item.dart';
import 'package:google_clustering/utils/distance_utils.dart';

class DbscanClustering<T extends ClusterItem> {
  DbscanClustering({
    required this.points,
    required this.radius,
    required this.minPts,
    required this.zoomLevel,
    this.devicePixelRatio = 1,
  })  : clusters = List.filled(points.length, 0),
        _distUtils = DistanceUtils(devicePixelRatio: devicePixelRatio);

  final List<T> points;
  final double radius;
  final int minPts;
  final int zoomLevel;
  final double devicePixelRatio;
  final DistanceUtils _distUtils;

  double get _radius => _distUtils.getCalculatedEpsilon(radius);

  List<int> clusters;

  List<Cluster<T>> run() {
    int clusterId = 0;

    for (int i = 0; i < points.length; i++) {
      if (clusters[i] != 0) {
        continue;
      }

      final neighbors = _regionQuery(i);
      log("\n");

      if (neighbors.length < minPts) {
        clusters[i] = -1;
      } else {
        clusterId++;
        _expandCluster(i, clusterId, neighbors);
      }
    }

    return _getClusters();
  }

  List<int> _regionQuery(int pointIndex) {
    final neighbors = <int>[];
    for (int j = 0; j < points.length; j++) {
      final distance = _distUtils.getLatLonDist(
        points[pointIndex].location,
        points[j].location,
        zoomLevel,
      );

      if (distance <= _radius) {
        neighbors.add(j);
      }
    }
    return neighbors;
  }

  void _expandCluster(int pointIndex, int clusterId, List<int> neighbors) {
    clusters[pointIndex] = clusterId;

    final stack = <int>[pointIndex];

    while (stack.isNotEmpty) {
      final currentPointIndex = stack.removeLast();
      final currentNeighbors = _regionQuery(currentPointIndex);

      if (currentNeighbors.length >= minPts) {
        for (final neighborIndex in currentNeighbors) {
          if (clusters[neighborIndex] == 0) {
            clusters[neighborIndex] = clusterId;
            stack.add(neighborIndex);
          } else if (clusters[neighborIndex] == -1) {
            clusters[neighborIndex] = clusterId;
          }
        }
      }
    }
  }

  List<Cluster<T>> _getClusters() {
    final clusterMap = <int, List<T>>{};

    var lastClusterId = 0;
    for (var i = 0; i < points.length; i++) {
      final clusterId = clusters[i];
      if (clusterId != -1) {
        if (!clusterMap.containsKey(clusterId)) {
          clusterMap[clusterId] = [];
        }

        clusterMap[clusterId]!.add(points[i]);
        lastClusterId = clusterId;
      }
    }

    for (var i = 0; i < points.length; i++) {
      if (clusters[i] == -1) {
        lastClusterId += 1;
        clusterMap[lastClusterId] = [points[i]];
      }
    }

    return clusterMap.values.map(Cluster.fromItems).toList();
  }

  // List<List<LatLng>> getClusters() {
  //   final clusterMap = <int, List<LatLng>>{};
  //   for (int i = 0; i < points.length; i++) {
  //     final clusterId = clusters[i];
  //     if (clusterId != -1) {
  //       if (!clusterMap.containsKey(clusterId)) {
  //         clusterMap[clusterId] = [];
  //       }
  //       clusterMap[clusterId]!.add(points[i]);
  //     }
  //   }
  //   return clusterMap.values.toList();
  // }

  // List<LatLng> getNoisePoints() {
  //   final noise = <LatLng>[];
  //   for (int i = 0; i < points.length; i++) {
  //     if (clusters[i] == -1) {
  //       noise.add(points[i]);
  //     }
  //   }
  //   return noise;
  // }
}
