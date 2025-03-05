import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

extension Add on ScreenCoordinate {
  ScreenCoordinate add({int x = 0, int y = 0}) =>
      ScreenCoordinate(x: this.x + x, y: this.y + y);
}
