import 'dart:convert';

import 'package:whereisthetoilet/constants/app_colors.dart';
import 'package:whereisthetoilet/constants/app_constants.dart';
import 'package:whereisthetoilet/models/user_models.dart';
import 'package:whereisthetoilet/screens/home_screen/widgets/custom_search_bar.dart';
import 'package:whereisthetoilet/services/permission_services.dart';
import 'package:whereisthetoilet/utils/custom_snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:realm/realm.dart';
import 'package:http/http.dart' as http;
import 'package:whereisthetoilet/widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  final Realm realm;
  final String deviceToken, deviceType;
  const HomeScreen({
    super.key,
    required this.realm,
    required this.deviceToken,
    required this.deviceType,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? userModel;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PermissionService _permissionService = PermissionService();
  Position? _currentPosition;
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(51.5320414, 0.0400036),
    zoom: 14,
  );
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadUserData();
  }

  Future<void> _requestPermissions() async {
    await _permissionService.locationPermission();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
      // Store the location data
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Handle location retrieval error
      CustomSnackBarUtil.showCustomSnackBar('Error retrieving location: $e',
          success: false);
    }
  }

  Future<void> _goToMyLocation() async {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 14,
          ),
        ),
      );
    } else {
      CustomSnackBarUtil.showCustomSnackBar(
        'Location not available. Please enable location services.',
        success: false,
      );
    }
  }

  UserModel? getUserData(Realm realm) {
    final results = realm.all<UserModel>();
    return results.isNotEmpty ? results[0] : null;
  }

  Future<void> _loadUserData() async {
    final user = getUserData(widget.realm);
    if (user != null) {
      setState(() {
        userModel = user;
      });
    }
  }

  void _drawRoute(List<dynamic> steps) async {
    List<LatLng> route = [];

    for (var step in steps) {
      var polylinePoints = step['polyline']['points'];

      // Use flutter_polyline_points to decode
      PolylinePoints polylinePointsDecoder = PolylinePoints();
      List<PointLatLng> pointsList =
          polylinePointsDecoder.decodePolyline(polylinePoints);

      // Convert to LatLng
      route.addAll(_convertToLatLng(pointsList));
    }

    // Add polyline to the map
    setState(() {
      _polylines.clear(); // Clear previous polylines
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: route,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  // Convert PointLatLng to LatLng
  List<LatLng> _convertToLatLng(List<PointLatLng> points) {
    return points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  Future<void> _getDirections(LatLng destination) async {
    if (_currentPosition == null) {
      CustomSnackBarUtil.showCustomSnackBar(
        'Current location is not available. Please enable location services.',
        success: false,
      );
      return;
    }

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&key=${AppConstants.mapsApiKey}';

    try {
      var response = await http.get(Uri.parse(url));
      var json = jsonDecode(response.body);

      if (json['status'] == 'OK') {
        List<dynamic> steps = json['routes'][0]['legs'][0]['steps'];
        _drawRoute(steps);
      } else {
        CustomSnackBarUtil.showCustomSnackBar(
          'Error fetching directions: ${json['status']}',
          success: false,
        );
      }
    } catch (e) {
      CustomSnackBarUtil.showCustomSnackBar(
        'Error getting directions: $e',
        success: false,
      );
    }
  }

  Future<void> _searchPlace(String input) async {
    if (input.isEmpty || _currentPosition == null) return;

    double lat = _currentPosition!.latitude;
    double lng = _currentPosition!.longitude;

    // Construct the URL with location and radius
    String url =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$input&location=$lat,$lng&radius=10000&key=${AppConstants.mapsApiKey}';

    try {
      var response = await http.get(Uri.parse(url));
      var json = jsonDecode(response.body);

      if (json['status'] == 'OK' && json['results'].isNotEmpty) {
        // Clear previous markers
        _markers.clear();

        // Iterate over the results and create markers
        for (var result in json['results']) {
          double placeLat = result['geometry']['location']['lat'];
          double placeLng = result['geometry']['location']['lng'];

          // Add a marker for each place
          _markers.add(
            Marker(
              markerId: MarkerId(result['place_id']),
              position: LatLng(placeLat, placeLng),
              infoWindow: InfoWindow(
                title: result['name'],
                snippet: result['formatted_address'],
              ),
              onTap: () {
                _getDirections(LatLng(placeLat, placeLng));
              },
            ),
          );
        }

        setState(() {}); // Update UI with the new markers

        // Optionally, animate camera to the first result
        double firstPlaceLat =
            json['results'][0]['geometry']['location']['lat'];
        double firstPlaceLng =
            json['results'][0]['geometry']['location']['lng'];

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(firstPlaceLat, firstPlaceLng),
              zoom: 14,
            ),
          ),
        );
      } else {
        CustomSnackBarUtil.showCustomSnackBar('No results found',
            success: false);
      }
    } catch (e) {
      CustomSnackBarUtil.showCustomSnackBar('Error searching places: $e',
          success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height;
    double screenRatio = height / width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCharcoalGray,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Where Is The Toilet',
            style: TextStyle(
              color: AppColors.appBarText,
              fontSize: screenRatio * 10,
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // Google Maps view
              SizedBox(
                width: width,
                height: height -
                    MediaQuery.of(context).padding.top -
                    AppBar().preferredSize.height,
                child: GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  markers: _markers,
                  polylines:
                      _polylines, // Add this line to display the polylines
                ),
              ),
              // Search bar
              CustomSearchBar(
                searchController: _searchController,
                formKey: _formKey,
                size: size,
                onSearch: (value) => _searchPlace(value),
              ),
              // Ads View
              const Positioned(
                bottom: 0,
                child: BannerAdWidget(),
              ),
              Positioned(
                bottom: height * 0.06,
                right: width * 0.02,
                child: FloatingActionButton(
                  onPressed: () {
                    _goToMyLocation();
                  },
                  backgroundColor: AppColors.backgroundCharcoalGray,
                  child: const Icon(
                    Icons.my_location,
                    color: AppColors.lightGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
