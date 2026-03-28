import 'package:geolocator/geolocator.dart';

class GeolocatorService {
  Future<Position> getPosition() async {
    // bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // if (!serviceEnabled) {
    //   return Future.error("Service de localisation desactivé");
    // }
    // LocationPermission permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     return Future.error("Permission réfusée");
    //   }
    // }
    // if (permission == LocationPermission.deniedForever) {
    //   return Future.error(
    //     "Permission refusée de manière permanente, nous ne pouvons pas demander la permission",
    //   );
    // }
    await Geolocator.requestPermission();
    final Position position = await Geolocator.getCurrentPosition();

    return position;
  }
}
