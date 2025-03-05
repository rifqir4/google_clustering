import 'package:flutter/widgets.dart';
import 'package:google_clustering/utils/constants.dart';

class ClusteringOptions {
  ClusteringOptions({
    this.onlyInBounds = true,
    required this.levels,
    required this.extraPercent,
    EdgeInsets? padding,
    this.stopClusteringZoom,
    double? devicePixelRatio,
  })  : _padding = padding,
        assert(
          levels.length <= Constants.precision,
          'Levels length should be less than or equal to precision',
        ),
        devicePixelRatio = devicePixelRatio ??
            WidgetsBinding
                .instance.platformDispatcher.views.first.devicePixelRatio;

  factory ClusteringOptions.basic() {
    return ClusteringOptions(
      levels: [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
      extraPercent: 0.5,
    );
  }

  /// If true, only clusters that are fully in bounds are rendered
  final bool onlyInBounds;

  /// Zoom levels configuration
  final List<double> levels;

  /// Extra percent of markers to be loaded (ex : 0.2 for 20%)
  final double extraPercent;

  /// The padding that is given to GoogleMap.padding
  final EdgeInsets? _padding;

  EdgeInsets? get padding => _padding != null
      ? EdgeInsets.only(
          top: _padding.top * devicePixelRatio,
          left: _padding.left * devicePixelRatio,
          right: _padding.right * devicePixelRatio,
          bottom: _padding.bottom * devicePixelRatio,
        )
      : _padding;

  /// Zoom level to stop cluster rendering
  final double? stopClusteringZoom;

  /// The pixelRatio of the device
  final double devicePixelRatio;
}

class MaxDistParams {
  MaxDistParams({
    required this.epsilon,
    required this.maxItemsForMaxDistAlgo,
  });

  factory MaxDistParams.basic() {
    return MaxDistParams(
      epsilon: 1,
      maxItemsForMaxDistAlgo: Constants.maxItemsForMaxDistAlgo,
    );
  }

  final double epsilon;
  final int maxItemsForMaxDistAlgo;
}
