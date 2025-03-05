// ignore_for_file: library_private_types_in_public_api

import 'package:google_clustering/utils/distance_utils.dart';

import '../data/cluster.dart';
import '../data/cluster_item.dart';

class MaxDistClustering<T extends ClusterItem> {
  MaxDistClustering({
    this.epsilon = 1,
  }) : distUtils = DistanceUtils();

  final DistanceUtils distUtils;

  final List<Cluster<T>> _cluster = [];

  ///Complete list of points
  late List<T> dataset;

  ///Threshold distance for two clusters to be considered as one cluster
  final double epsilon;

  ///Run clustering process, add configs in constructor
  List<Cluster<T>> run(List<T> dataset, int zoomLevel) {
    this.dataset = dataset;

    //initial variables
    final distMatrix = <List<double>>[];
    for (final entry1 in dataset) {
      distMatrix.add([]);
      _cluster.add(Cluster.fromItems([entry1]));
    }

    bool changed = true;

    while (changed) {
      changed = false;

      ///calculate distance matrix
      for (final c in _cluster) {
        final (minDistCluster, minDist) = getClosestCluster(c, zoomLevel);

        ///if the closest cluster distance is greater than epsilon, skip
        if (minDist > epsilon) continue;

        ///merge cluster and remove the two clusters
        _cluster
          ..add(Cluster.fromClusters(minDistCluster, c))
          ..remove(c)
          ..remove(minDistCluster);

        changed = true;
        break;
      }
    }
    return _cluster;
  }

  (Cluster<T>, double) getClosestCluster(Cluster cluster, int zoomLevel) {
    double minDist = 1000000000.0;
    Cluster<T> minDistCluster = Cluster<T>.fromItems(const []);
    for (final c in _cluster) {
      if (c.location == cluster.location) continue;
      final tmp = distUtils.getLatLonDist(
        c.location,
        cluster.location,
        zoomLevel,
      );

      if (tmp < minDist) {
        minDist = tmp;
        minDistCluster = Cluster<T>.fromItems(c.items);
      }
    }
    return (minDistCluster, minDist);
  }
}
