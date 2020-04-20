import 'package:flutter/material.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolyLineScreen extends StatefulWidget {
  @override
  _PolyLineScreenState createState() => _PolyLineScreenState();
}

class _PolyLineScreenState extends State<PolyLineScreen> {
  int _polylineCount = 1;
  Map<PolylineId, Polyline> _polyLines = <PolylineId, Polyline>{};
  GoogleMapController _controller;

  GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: "YOUR-API-KEY");

  LatLng _mapInitLocation = LatLng(22.5757505,88.4286015);

  LatLng _originLocation = LatLng(22.5757505,88.4286015);
  LatLng _destinationLocation = LatLng(22.5858591,88.4214645);

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

  _getPolyLinesWithLocation() async {
    List<LatLng> _coordinates =
        await _googleMapPolyline.getCoordinatesWithLocation(
            origin: _originLocation,
            destination: _destinationLocation,
            mode: RouteMode.driving);

    setState(() {
      _polyLines.clear();
    });
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

    setState(() {
        _polyLines[id] = polyline;
        _polylineCount++;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getPolyLinesWithLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.satellite,
        onMapCreated: _onMapCreated,
        polylines: Set<Polyline>.of(_polyLines.values),
        initialCameraPosition: CameraPosition(
          target: _mapInitLocation,
          zoom: 14.55,
        ),
      ),
    );
  }
}
