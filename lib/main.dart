import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
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

  int _polylineCount = 1;
  Map<PolylineId, Polyline> _polyLines = <PolylineId, Polyline>{};
  GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: "YOUR-API-KEY");
  LatLng _mapInitLocation = LatLng(22.5757505, 88.4286015);

  LatLng _originLocation = LatLng(22.5757505, 88.4286015);
  LatLng _destinationLocation = LatLng(22.5858591, 88.4214645);

  _getPolyLinesWithLocation(LocationData locationData) async {
    List<LatLng> _coordinates =
        await _googleMapPolyline.getCoordinatesWithLocation(
      origin: LatLng(locationData.latitude,locationData.longitude),
      destination: _destinationLocation,
      mode: RouteMode.driving,
    );
    _addPolyline(_coordinates);
  }

  _addPolyline(List<LatLng> _coordinates) {
    PolylineId id = PolylineId("poly$_polylineCount");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: _coordinates,
      width: 10,
    );

    this.setState(() {
        _polyLines[id] = polyline;
      },
    );
  }

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load('assets/car_icon.png');
    return byteData.buffer.asUint8List();
  }


  void updateMarker(LocationData newLocalData, Uint8List imageData) {
    LatLng latLang = LatLng(newLocalData.latitude, newLocalData.longitude);
    this.setState(() {
      marker = Marker(
        markerId: MarkerId("home"),
        position: latLang,
        rotation: newLocalData.heading,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
        icon: BitmapDescriptor.fromBytes(imageData),
      );
//      circle = Circle(
//        circleId: CircleId("car"),
//        radius: newLocalData.accuracy,
//        zIndex: 1,
//        strokeColor: Colors.blue,
//        center: latlng,
//        fillColor: Colors.blue.withAlpha(70),
//      );
    });
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarker(location, imageData);

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
          _getPolyLinesWithLocation(newLocalData);
          updateMarker(newLocalData, imageData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      _googleMapController = controller;
    });
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
        polylines: Set<Polyline>.of(_polyLines.values),
        initialCameraPosition: CameraPosition(
          target: _mapInitLocation,
          zoom: 14.47,
        ),
        markers: Set.of((marker != null) ? [marker] : []),
     //   circles: Set.of((circle != null) ? [circle] : []),
        onMapCreated: _onMapCreated,
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
