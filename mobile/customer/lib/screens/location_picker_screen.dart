import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String label;
  const PickedLocation({required this.latitude, required this.longitude, required this.label});
}

class LocationPickerScreen extends StatefulWidget {
  final PickedLocation? initialPickup;
  final PickedLocation? initialDestination;
  const LocationPickerScreen({super.key, this.initialPickup, this.initialDestination});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? pickup;
  LatLng? destination;
  LatLng? center;
  String mode = 'pickup';
  bool locating = true;

  @override
  void initState() {
    super.initState();
    pickup = widget.initialPickup == null
        ? null
        : LatLng(widget.initialPickup!.latitude, widget.initialPickup!.longitude);
    destination = widget.initialDestination == null
        ? null
        : LatLng(widget.initialDestination!.latitude, widget.initialDestination!.longitude);
    _locate();
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        center = LatLng(position.latitude, position.longitude);
        if (pickup == null) pickup = center;
      });
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void _tap(LatLng point) {
    setState(() {
      if (mode == 'pickup') {
        pickup = point;
        mode = 'destination';
      } else {
        destination = point;
      }
    });
  }

  Future<void> _useMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        center = point;
        if (mode == 'pickup') {
          pickup = point;
          mode = 'destination';
        } else {
          destination = point;
        }
      });
    } catch (_) {}
  }

  void _confirm() {
    if (pickup == null || destination == null) return;
    Navigator.pop(context, [
      PickedLocation(latitude: pickup!.latitude, longitude: pickup!.longitude, label: 'نقطة الالتقاط'),
      PickedLocation(latitude: destination!.latitude, longitude: destination!.longitude, label: 'الوجهة'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = center ?? pickup ?? const LatLng(31.9539, 35.9106);
    return Scaffold(
      appBar: AppBar(title: const Text('حدد المواقع')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 14,
              onTap: (_, point) => _tap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jelad.customer',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  if (pickup != null)
                    Marker(point: pickup!, width: 48, height: 48, child: const Icon(Icons.trip_origin, size: 40)),
                  if (destination != null)
                    Marker(point: destination!, width: 48, height: 48, child: const Icon(Icons.location_on, size: 44)),
                ],
              ),
              if (pickup != null && destination != null)
                PolylineLayer(
                  polylines: [Polyline(points: [pickup!, destination!], strokeWidth: 4)],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  mode == 'pickup'
                      ? 'اضغط على الخريطة لتحديد نقطة الالتقاط'
                      : 'اضغط على الخريطة لتحديد الوجهة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton(
              onPressed: _useMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: FilledButton.icon(
              onPressed: pickup != null && destination != null ? _confirm : null,
              icon: const Icon(Icons.check),
              label: Text(
                locating
                    ? 'جاري تحديد موقعك...'
                    : pickup != null && destination != null
                        ? 'تأكيد المواقع'
                        : 'حدد الموقعين على الخريطة',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
