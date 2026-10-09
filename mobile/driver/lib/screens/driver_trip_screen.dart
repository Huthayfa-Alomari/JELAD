import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class DriverTripScreen extends StatefulWidget {
  final String jobId;
  const DriverTripScreen({super.key, required this.jobId});
  @override State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  StreamSubscription<Position>? gpsSub;
  Map<String, dynamic>? details;
  List<LatLng> route = [];
  LatLng? driverPoint;
  bool busy = false;
  bool loading = true;
  bool pinVerified = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    _startGps();
  }

  Future<void> _load() async {
    try {
      final value = await JeladApi(Supabase.instance.client).driverTracking(widget.jobId);
      if (!mounted) return;
      setState(() { details = Map<String, dynamic>.from(value as Map); loading = false; error = null; });
      await _loadRoute();
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _loadRoute() async {
    final pickup = _point(details?['pickup']);
    final destination = _point(details?['destination']);
    if (pickup == null || destination == null) return;
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/\${pickup.longitude},\${pickup.latitude};\${destination.longitude},\${destination.latitude}',
        {'overview': 'full', 'geometries': 'geojson'},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final geometry = (routes.first as Map)['geometry'] as Map?;
      final coords = (geometry?['coordinates'] as List?)
              ?.map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()))
              .toList() ??
          [];
      if (mounted) setState(() => route = coords);
    } catch (_) {}
  }

  LatLng? _point(dynamic value) {
    if (value is! Map) return null;
    final lat = (value['latitude'] as num?)?.toDouble();
    final lng = (value['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<void> _startGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    final current = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => driverPoint = LatLng(current.latitude, current.longitude));

    gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      final point = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => driverPoint = point);
      final api = JeladApi(Supabase.instance.client);
      api.updateLocation(position.latitude, position.longitude);
      api.updateLiveTripLocation(widget.jobId, position.latitude, position.longitude);
    });
  }

  Future<void> _arrived() async => _transition('ARRIVED');

  Future<void> _startTrip() async {
    if (!pinVerified) {
      final controller = TextEditingController();
      final pin = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('رمز بدء الرحلة'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'أدخل PIN العميل'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تحقق')),
          ],
        ),
      );
      controller.dispose();
      if (pin == null || pin.isEmpty) return;
      setState(() => busy = true);
      try {
        await JeladApi(Supabase.instance.client).verifyPin(widget.jobId, pin);
        if (mounted) setState(() => pinVerified = true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN غير صحيح: $e')));
        if (mounted) setState(() => busy = false);
        return;
      }
      if (mounted) setState(() => busy = false);
    }
    await _transition('START');
  }

  Future<void> _transition(String action) async {
    setState(() => busy = true);
    try {
      await JeladApi(Supabase.instance.client).driverTransition(widget.jobId, action);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_actionLabel(action))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    gpsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) {
      return Scaffold(appBar: AppBar(title: const Text('الرحلة')), body: Center(child: Text('تعذر تحميل الرحلة\n$error')));
    }

    final status = (details?['job']?['status'] ?? 'ASSIGNED').toString();
    final pickup = _point(details?['pickup']);
    final destination = _point(details?['destination']);
    final center = driverPoint ?? pickup ?? destination ?? const LatLng(31.9539, 35.9106);

    return Scaffold(
      appBar: AppBar(title: const Text('الرحلة الحالية')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.jelad.driver',
                  maxZoom: 19,
                ),
                if (route.isNotEmpty)
                  PolylineLayer(polylines: [Polyline(points: route, strokeWidth: 5)]),
                MarkerLayer(
                  markers: [
                    if (pickup != null)
                      Marker(point: pickup, width: 48, height: 48, child: const Icon(Icons.trip_origin, size: 38)),
                    if (destination != null)
                      Marker(point: destination, width: 48, height: 48, child: const Icon(Icons.location_on, size: 42)),
                    if (driverPoint != null)
                      Marker(point: driverPoint!, width: 54, height: 54, child: const Icon(Icons.navigation, size: 42)),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      title: Text(_statusLabel(status)),
                      subtitle: const Text('GPS يعمل أثناء الرحلة لإرسال الموقع الحي'),
                    ),
                  ),
                  if (status == 'ASSIGNED')
                    FilledButton.icon(
                      onPressed: busy ? null : _arrived,
                      icon: const Icon(Icons.location_on),
                      label: const Text('وصلت إلى نقطة الالتقاط'),
                    ),
                  if (status == 'DRIVER_ARRIVING')
                    FilledButton.icon(
                      onPressed: busy ? null : _startTrip,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(pinVerified ? 'بدء الرحلة' : 'تحقق من PIN وابدأ'),
                    ),
                  if (status == 'IN_PROGRESS')
                    FilledButton.icon(
                      onPressed: busy ? null : () => _transition('COMPLETE'),
                      icon: const Icon(Icons.check),
                      label: const Text('إنهاء الرحلة'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ASSIGNED': return 'تم استلام الرحلة';
      case 'DRIVER_ARRIVING': return 'في الطريق إلى العميل';
      case 'IN_PROGRESS': return 'الرحلة جارية';
      case 'COMPLETED': return 'اكتملت الرحلة';
      default: return status;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'ARRIVED': return 'تم تسجيل الوصول إلى نقطة الالتقاط';
      case 'START': return 'بدأت الرحلة';
      case 'COMPLETE': return 'تم إنهاء الرحلة';
      default: return action;
    }
  }
}
