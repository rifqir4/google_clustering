import 'dart:math';

import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    hide Cluster;

import '../data/cluster.dart';
import '../data/cluster_item.dart';
import '../data/parameters.dart';
import '../utils/extensions.dart';
import '../utils/marker_utils.dart';
import './clustering_max_dist.dart';

enum ClusterAlgorithm { geoHash, maxDist, dbscan }

class ClusterManager<T extends ClusterItem> {
  ClusterManager(
    Iterable<T> initialItems,
    this.onMarkersUpdated, {
    this.markerBuilder,
    ClusteringOptions? options,
    this.clusterAlgorithm = ClusterAlgorithm.geoHash,
    MaxDistParams? maxDistParams,
  })  : _items = initialItems,
        _markerUtils = MarkerUtils(),
        options = options ?? ClusteringOptions.basic(),
        maxDistParams = maxDistParams ?? MaxDistParams.basic();

  /// List of items
  Iterable<T> _items;

  Iterable<T> get items => _items;

  /// Function to update Markers on Google Map
  final void Function(Set<Marker>) onMarkersUpdated;

  final MarkerUtils _markerUtils;

  /// Method to build markers
  final Future<Marker> Function(Cluster<T>)? markerBuilder;

  Future<Marker> Function(Cluster<T>) get _markerBuilder =>
      markerBuilder ?? _markerUtils.basicMarker;

  /// Clustering options
  final ClusteringOptions options;

  /// Clustering algorithm
  final ClusterAlgorithm clusterAlgorithm;

  final MaxDistParams maxDistParams;

  /* Utils Variable */
  /// Google Maps map id
  int? _mapId;

  /// Last known zoom
  late double _zoom;

  final double _maxLng = 180 - pow(10, -10.0) as double;

  GoogleMapsFlutterPlatform get _gmfp => GoogleMapsFlutterPlatform.instance;

  /// Set Google Map Id for the cluster manager
  Future<void> setMapId(int mapId, {bool withUpdate = true}) async {
    _mapId = mapId;
    _zoom = await _gmfp.getZoomLevel(mapId: mapId);
    if (withUpdate) updateMap();
  }

  /// Method called on map update to update cluster. Can also be manually called to force update.
  void updateMap() {
    _updateClusters();
  }

  /// Update all cluster items
  void setItems(List<T> newItems) {
    _items = newItems;
    updateMap();
  }

  /// Add on cluster item
  void addItem(ClusterItem newItem) {
    _items = List.from([...items, newItem]);
    updateMap();
  }

  /// Method called on camera move
  void onCameraMove(CameraPosition position, {bool forceUpdate = false}) {
    _zoom = position.zoom;
    if (forceUpdate) {
      updateMap();
    }
  }

  /// Retrieve cluster markers
  Future<List<Cluster<T>>> getMarkers() async {
    if (_mapId == null) return List.empty();

    final processedItems = await _getVisibleItems();

    /// If no items are visible, return empty list
    if (processedItems.isEmpty) return List.empty();

    /// check if the zoom level is less than the stopClusteringZoom
    final stopClusteringZoom = options.stopClusteringZoom;
    if (stopClusteringZoom != null && _zoom >= stopClusteringZoom) {
      return processedItems.map((i) => Cluster<T>.fromItems([i])).toList();
    }

    List<Cluster<T>> markers;

    if (clusterAlgorithm == ClusterAlgorithm.geoHash ||
        processedItems.length >= maxDistParams.maxItemsForMaxDistAlgo) {
      final level = _findLevel();
      markers = _computeWithGeoHashClusters(
        processedItems,
        List.empty(growable: true),
        level: level,
      );
    } else {
      markers = _computeClustersWithMaxDist(processedItems);
    }

    return markers;
  }

  Future<void> _updateClusters() async {
    final mapMarkers = await getMarkers();

    Set<Marker> markers;
    if (options.onlyInBounds) {
      final result = await Future.wait(
        mapMarkers.map(_markerBuilder),
      );
      markers = Set<Marker>.from(result);
    } else {
      final mapBounds = await _getMapBounds();
      final result = await Future.wait(
        mapMarkers.map((e) {
          if (mapBounds.contains(e.location)) {
            return _markerBuilder.call(e);
          }
          return _markerUtils.offBoundMarker.call(e);
        }),
      );

      markers = Set<Marker>.from(result);
    }

    onMarkersUpdated.call(markers);
  }

  Future<List<T>> _getVisibleItems() async {
    List<T> visibleItems = items.toList();
    if (!options.onlyInBounds) return visibleItems;

    final mapBounds = await _getMapBounds();
    return items.where((i) => mapBounds.contains(i.location)).toList();
  }

  Future<LatLngBounds> _getMapBounds() async {
    final mapBounds = await _gmfp.getVisibleRegion(mapId: _mapId!);
    final paddedBounds = await _addPadding(mapBounds);
    final inflatedBounds = switch (clusterAlgorithm) {
      ClusterAlgorithm.geoHash => _inflateBounds(paddedBounds),
      _ => paddedBounds,
    };

    return inflatedBounds;
  }

  Future<LatLngBounds> _addPadding(LatLngBounds mapBounds) async {
    final padding = options.padding;
    final northEastL = mapBounds.northeast;
    final southWestL = mapBounds.southwest;

    if (padding == null) {
      return LatLngBounds(southwest: southWestL, northeast: northEastL);
    }

    final [northEastC, southWestC] = await Future.wait([
      _gmfp.getScreenCoordinate(northEastL, mapId: _mapId!),
      _gmfp.getScreenCoordinate(southWestL, mapId: _mapId!),
    ]);

    final [northEastP, southWestP] = await Future.wait([
      _gmfp.getLatLng(
        northEastC.add(
          x: padding.right.toInt(),
          y: -padding.top.toInt(),
        ),
        mapId: _mapId!,
      ),
      _gmfp.getLatLng(
        southWestC.add(
          x: -padding.left.toInt(),
          y: padding.bottom.toInt(),
        ),
        mapId: _mapId!,
      ),
    ]);
    return LatLngBounds(southwest: southWestP, northeast: northEastP);
  }

  LatLngBounds _inflateBounds(LatLngBounds bounds) {
    final extraPercent = options.extraPercent;
    // Bounds that cross the date line expand compared to their difference with the date line
    double lng = 0.0;
    if (bounds.northeast.longitude < bounds.southwest.longitude) {
      lng = extraPercent *
          ((180.0 - bounds.southwest.longitude) +
              (bounds.northeast.longitude + 180));
    } else {
      lng = extraPercent *
          (bounds.northeast.longitude - bounds.southwest.longitude);
    }

    // Latitudes expanded beyond +/- 90 are automatically clamped by LatLng
    final lat =
        extraPercent * (bounds.northeast.latitude - bounds.southwest.latitude);

    final eLng = (bounds.northeast.longitude + lng).clamp(-_maxLng, _maxLng);
    final wLng = (bounds.southwest.longitude - lng).clamp(-_maxLng, _maxLng);

    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude - lat, wLng),
      northeast: LatLng(
        bounds.northeast.latitude + lat,
        lng != 0 ? eLng : _maxLng,
      ),
    );
  }

  int _findLevel() {
    final levels = options.levels;
    for (var i = levels.length - 1; i >= 0; i--) {
      if (levels[i] <= _zoom) {
        return i + 1;
      }
    }

    return 1;
  }

  int _getZoomLevel(double zoom) {
    final levels = options.levels;
    for (var i = levels.length - 1; i >= 0; i--) {
      if (levels[i] <= zoom) {
        return levels[i].toInt();
      }
    }

    return 1;
  }

  List<Cluster<T>> _computeWithGeoHashClusters(
    List<T> inputItems,
    List<Cluster<T>> markerItems, {
    int level = 5,
  }) {
    if (inputItems.isEmpty) return markerItems;
    final nextGeohash = inputItems[0].geohash.substring(0, level);

    final items = inputItems
        .where((p) => p.geohash.substring(0, level) == nextGeohash)
        .toList();

    markerItems.add(Cluster<T>.fromItems(items));

    final newInputList = List<T>.from(
      inputItems.where((i) => i.geohash.substring(0, level) != nextGeohash),
    );

    return _computeWithGeoHashClusters(newInputList, markerItems, level: level);
  }

  List<Cluster<T>> _computeClustersWithMaxDist(List<T> inputItems) {
    final scanner = MaxDistClustering<T>(
      epsilon: maxDistParams.epsilon,
    );

    return scanner.run(inputItems, _getZoomLevel(_zoom));
  }
}
