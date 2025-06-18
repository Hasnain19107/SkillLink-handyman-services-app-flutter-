import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const String googleApiKey = "AIzaSyCQ9gH9q9fObXunz3jgiA3sFdCGNU7eHKc";

class LocationSelector extends StatefulWidget {
  final String? initialAddress;
  final bool readOnly;
  final Function(String)? onLocationSelected;

  const LocationSelector({
    Key? key,
    this.initialAddress,
    this.readOnly = false,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(20.5937, 78.9629);
  String _currentAddress = 'Tap map or search to select location';
  bool _isLoading = false;
  bool _isGettingCurrentLocation = false;
  Set<Marker> _markers = {};

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String? _sessionToken;
  final Uuid _uuid = const Uuid();
  bool _showSearchResults = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
    });

    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _searchController.text = widget.initialAddress!;
      Future.delayed(const Duration(milliseconds: 500), () {
        _initializeWithAddress(widget.initialAddress!);
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _handleGetCurrentLocation() async {
    if (_isGettingCurrentLocation) return;

    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedMessage();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final newPosition = LatLng(position.latitude, position.longitude);
      await _updateLocationInfo(newPosition);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15.0),
        );
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to get current location';
      });
    } finally {
      setState(() {
        _isGettingCurrentLocation = false;
      });
    }
  }

  void _showLocationServiceDialog() async {
    final shouldOpen = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text('Would you like to enable location services?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldOpen) {
      await Geolocator.openLocationSettings();
    }
    setState(() => _isGettingCurrentLocation = false);
  }

  void _showPermissionDeniedMessage() {
    setState(() {
      _currentAddress = 'Location permissions denied';
      _isGettingCurrentLocation = false;
    });
  }

  void _showPermissionPermanentlyDeniedDialog() async {
    final shouldOpen = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permissions'),
            content: const Text(
                'Please enable location permissions in app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldOpen) {
      await Geolocator.openAppSettings();
    }
    setState(() => _isGettingCurrentLocation = false);
  }

  Future<void> _updateLocationInfo(LatLng position,
      {String? addressOverride}) async {
    setState(() => _isLoading = true);

    try {
      String finalAddress;
      if (addressOverride != null) {
        finalAddress = addressOverride;
      } else {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          finalAddress = [
            place.name,
            place.street,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        } else {
          finalAddress = 'Address not found for this location';
        }
      }

      setState(() {
        _currentAddress = finalAddress;
        _currentPosition = position;
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: position,
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet: finalAddress,
            ),
          ),
        };
      });

      widget.onLocationSelected?.call(finalAddress);
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to get address for this location';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLocationToFirebase(LatLng position, String address) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': address,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving location: $e')),
        );
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _searchResults = [];
      _showSearchResults = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
    _updateLocationInfo(position);
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _onConfirmLocation() {
    if (_isValidAddress()) {
      _saveLocationToFirebase(_currentPosition, _currentAddress);
      Navigator.pop(context, _currentAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid location first.')),
      );
    }
  }

  bool _isValidAddress() {
    return _currentAddress.isNotEmpty &&
        !_currentAddress.contains('Tap map or search') &&
        !_currentAddress.contains('Unable') &&
        !_currentAddress.contains('not found') &&
        !_currentAddress.contains('denied') &&
        !_currentAddress.contains('disabled');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty && mounted) {
        _fetchAutocompleteResults(_searchController.text.trim());
      } else if (mounted) {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
    });
  }

  Future<void> _fetchAutocompleteResults(String input) async {
    setState(() => _isSearching = true);

    try {
      _sessionToken ??= _uuid.v4();
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}&key=$googleApiKey&sessiontoken=$_sessionToken';

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _searchResults = data['predictions'];
            _showSearchResults = _searchResults.isNotEmpty;
          });
        } else {
          setState(() {
            _searchResults = [];
            _showSearchResults = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchPlaceDetails(String placeId) async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _showSearchResults = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId&key=$googleApiKey&sessiontoken=$_sessionToken'
          '&fields=geometry,formatted_address';

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      _sessionToken = _uuid.v4(); // Reset session token

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final newPosition = LatLng(location['lat'], location['lng']);
          final formattedAddress = result['formatted_address'];

          await _updateLocationInfo(newPosition,
              addressOverride: formattedAddress);

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newPosition, 15.0),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location details: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeWithAddress(String address) async {
    setState(() => _isLoading = true);

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final position =
            LatLng(locations.first.latitude, locations.first.longitude);
        await _updateLocationInfo(position);
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(position, 15.0));
      }
    } catch (e) {
      // Handle error silently or show minimal feedback
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: widget.readOnly ? null : _onMapTap,
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showSearchResults = false;
                                });
                              },
                            )
                          : const Icon(Icons.search),
                ),
              ),
            ),
          ),

          // Search Results
          if (_showSearchResults && _searchResults.isNotEmpty && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_searchResults[index]['description']),
                      onTap: () =>
                          _fetchPlaceDetails(_searchResults[index]['place_id']),
                    );
                  },
                ),
              ),
            ),

          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8.0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16.0,
                  16.0,
                  16.0,
                  MediaQuery.of(context).padding.bottom + 16.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 8),
                        Text('Location',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Text(_currentAddress,
                          style: Theme.of(context).textTheme.bodyMedium),
                    if (!widget.readOnly) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onConfirmLocation,
                          child: const Text('Confirm Location'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 170,
            right: 15,
            child: FloatingActionButton(
              onPressed:
                  _isGettingCurrentLocation ? null : _handleGetCurrentLocation,
              tooltip: 'Get Current Location',
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: _isGettingCurrentLocation
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).colorScheme.primary,
              child: _isGettingCurrentLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
