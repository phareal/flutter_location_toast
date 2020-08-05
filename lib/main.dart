import 'package:date_format/date_format.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'Helpers/PinInfo.dart';
import 'Helpers/MapPill.dart';
import 'Helpers/Utils.dart';
import 'package:http/http.dart' as http;



const double CAMERA_ZOOM = 16;
FToast fToast;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
const LatLng SOURCE_LOCATION = LatLng(42.747932, -71.167889);

const simpleTaskKey = "simpleTask";
const simpleDelayedTask = "simpleDelayedTask";
const simplePeriodicTask = "simplePeriodicTask";
const simplePeriodic1HourTask = "simplePeriodic1HourTask";




void main(){
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MapPage()));
}



class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
// for my drawn routes on the map
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];

  String googleAPIKey = 'AIzaSyCGcz2NIWrB4jTBKWcg2oSQF89MHXXq2og';
// for my custom marker pins
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
// the user's initial location and current location
// as it moves
  LocationData currentLocation;
// a reference to the destination location
  bool isLoaded = false;
// wrapper around the location API
  Location location;
  double pinPillPosition = -100;
  PinInformation currentlySelectedPin = PinInformation(
      pinPath: 'assets/driving_pin.png',
      avatarPath: 'assets/driving_pin.png',
      location: LatLng(0, 0),
      locationName: '',
      labelColor: Colors.grey);
  PinInformation sourcePinInfo;
  PinInformation destinationPinInfo;

  @override
  void initState() {
    super.initState();


    // create an instance of Location
    location = new Location();
    fToast = FToast(context);



    location.onLocationChanged.listen((LocationData cLoc) {
      setState(() {
        currentLocation = cLoc;
        isLoaded = true;
      });

      updatePinOnMap();
      print(isLoaded);
    });
    // set custom marker pins
    setSourceAndDestinationIcons();
    // set the initial location
    setInitialLocation();




  }



  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0), 'assets/driving_pin.png')
        .then((onValue) {
      sourceIcon = onValue;
    });

  }

  void setInitialLocation() async {
    // set the initial location by pulling the user's
    // current location from the location's getLocation()
    try{

      var _location =  await location.getLocation();
      //currentLocation = await location.getLocation();

      setState(() {
        currentLocation = _location;
        isLoaded = true;
      });



    }catch (e){
      currentLocation = null;
    }


    // hard-coded destination for this example
  }

  @override
  Widget build(BuildContext context) {

    CameraPosition initialCameraPosition = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: SOURCE_LOCATION);
    if (currentLocation != null) {
      initialCameraPosition = CameraPosition(
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING);
    }
    return Scaffold(
      body: Container(
        child:isLoaded ? Stack(
          children: <Widget>[
            GoogleMap(
                myLocationEnabled: true,
                compassEnabled: true,
                tiltGesturesEnabled: false,
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                initialCameraPosition: initialCameraPosition,
                onTap: (LatLng loc) {
                  pinPillPosition = -100;
                },
                onMapCreated: (GoogleMapController controller) {
                  controller.setMapStyle(Utils.mapStyles);
                  _controller.complete(controller);

                  showPinsOnMap(context);
                }),
            MapPinPillComponent(
                pinPillPosition: pinPillPosition,
                currentlySelectedPin: currentlySelectedPin)
          ],
        ) : Center(
          child:  CircularProgressIndicator(),
        ) ,
      )

    );
  }

  void showPinsOnMap(BuildContext context) {
    // get a LatLng for the source location
    // from the LocationData currentLocation object

    Fluttertoast.showToast(
        msg: "${currentLocation.latitude} ${currentLocation.longitude}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0
    );

    print("dsdsdsd");
    print("is ${this.isLoaded}");
    var pinPosition;
    if (currentLocation == null){


      }else{
        pinPosition= LatLng(currentLocation.latitude, currentLocation.longitude);
        sourcePinInfo = PinInformation(
            locationName: "Start Location",
            location: SOURCE_LOCATION,
            pinPath: "assets/driving_pin.png",
            avatarPath: "assets/friend1.jpg",
            labelColor: Colors.blueAccent);


        // add the initial source location pin
        _markers.add(Marker(
            markerId: MarkerId('sourcePin'),
            position: pinPosition,
            onTap: () {
              setState(() {
                currentlySelectedPin = sourcePinInfo;
                pinPillPosition = 0;
              });
            },
            icon: sourceIcon));
        // destination pin



        new Timer.periodic(Duration(seconds: 15),(Timer t)=>{

          Fluttertoast.showToast(
              msg: "${currentLocation.latitude} ${currentLocation.longitude}",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          ),

          this.postData(currentLocation)
        });

    }

    // get a LatLng out of the LocationData object





    // set the route lines on the map from source to destination
    // for more info follow this tutorial
  }


  void postData(LocationData locationData) async {
    var url ="http://dev.nivida.in/nivida_eis/City/App_LatLong";

    String date = formatDate(DateTime.now(), [dd, '-', mm, '-', yyyy, ' ', HH, ':', nn]);


    var response = await http.post(url, body: {
      'latitude': locationData.latitude.toString(),
      'longitude': locationData.longitude.toString(),
      'date':date
    });

    print("date is ${date}");
    print("response is ${response.body}");

  }


  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation
    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(currentLocation.latitude, currentLocation.longitude),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    setState(() {
      // updated position
      var pinPosition =
      LatLng(currentLocation.latitude, currentLocation.longitude);

      sourcePinInfo.location = pinPosition;

      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          onTap: () {
            setState(() {
              currentlySelectedPin = sourcePinInfo;
              pinPillPosition = 0;
            });
          },
          position: pinPosition, // updated position
          icon: sourceIcon));
    });
  }
}

