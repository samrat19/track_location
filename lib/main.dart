import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

main() => runApp(
      MaterialApp(
        home: MapScreen(),
      ),
    );

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController _googleMapController;
  Location _locationTracker = Location();
  Marker marker;
  Circle circle;
  StreamSubscription _locationSubscription;

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load('assets/car_icon.png');
    return byteData.buffer.asUint8List();
  }

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(22.572645, 88.363892),
    zoom: 14.47,
  );

  void updateMarkerAndCircle(LocationData newLocalData, Uint8List imageData) {
    LatLng latlng = LatLng(newLocalData.latitude, newLocalData.longitude);
    this.setState(() {
      marker = Marker(
          markerId: MarkerId("home"),
          position: latlng,
          rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
      circle = Circle(
          circleId: CircleId("car"),
          radius: newLocalData.accuracy,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: latlng,
          fillColor: Colors.blue.withAlpha(70));
    });
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarkerAndCircle(location, imageData);

      if (_locationSubscription != null) {
        _locationSubscription.cancel();
      }

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_googleMapController != null) {
          _googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                  bearing: 192.8334901395799,
                  target: LatLng(newLocalData.latitude, newLocalData.longitude),
                  tilt: 0,
                  zoom: 18.00),
            ),
          );
          updateMarkerAndCircle(newLocalData, imageData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Location'),
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: initialLocation,
        markers: Set.of((marker != null) ? [marker] : []),
        circles: Set.of((circle != null) ? [circle] : []),
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getCurrentLocation();
        },
        child: Icon(
          Icons.location_searching,
        ),
      ),
    );
  }
}
