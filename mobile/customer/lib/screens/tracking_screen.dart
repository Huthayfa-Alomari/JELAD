import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String jobId;
  const CustomerTrackingScreen({super.key, required this.jobId});
  @override State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  StreamSubscription? jobSub;
  StreamSubscription? locationSub;
  Map<String, dynamic>? tracking;
  Map<String, dynamic>? liveLocation;
  List<LatLng> route = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    final realtime = RealtimeService(Supabase.instance.client);
    jobSub = realtime.jobStream(widget.jobId).listen((_) => _load());
    locationSub = realtime.liveLocationStream(widget.jobId).listen((value) {
      if (mounted) setState(() => liveLocation = value);
    });
  }

  Future<void> _load() async {
    try {
      final value = await JeladApi(Supabase.instance.client).tracking(widget.jobId);
      if (!mounted) return;
      final data = Map<String, dynamic>.from(value as Map);
      setState(() { tracking = data; loading = false; error = null; });
      await _loadRoute(data);
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _loadRoute(Map<String, dynamic> data) async {
    final pickup = _point(data['pickup']);
    final destination = _point(data['destination']);
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
      final coordinates = (geometry?['coordinates'] as List?)
              ?.map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()))
              .toList() ??
          [];
      if (mounted) setState(() => route = coordinates);
    } catch (_) {}
  }

  LatLng? _point(dynamic value) {
    if (value is! Map) return null;
    final lat = (value['latitude'] as num?)?.toDouble();
    final lng = (value['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  void dispose() {
    jobSub?.cancel();
    locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _point(tracking?['pickup']);
    final destination = _point(tracking?['destination']);
    final driver = liveLocation == null ? _point(tracking?['driver']) : _point(liveLocation);
    final status = (tracking?['job']?['status'] ?? 'REQUESTED').toString();

    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تتبع الرحلة')),
        body: Center(child: Text('تعذر تحميل الرحلة\n$error')),
      );
    }

    final center = driver ?? pickup ?? destination ?? const LatLng(31.9539, 35.9106);

    return Scaffold(
      appBar: AppBar(title: const Text('رحلتي')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.jelad.customer',
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
                    if (driver != null)
                      Marker(point: driver, width: 54, height: 54, child: const Icon(Icons.directions_car, size: 42)),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.local_taxi),
                title: Text(_statusLabel(status)),
                subtitle: Text(
                  tracking?['driver'] == null
                      ? 'جاري البحث عن سائق مناسب'
                      : 'السائق متصل ويمكن متابعة موقعه مباشرة',
                ),
                trailing: status == 'COMPLETED' ? const Icon(Icons.check_circle) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'REQUESTED': return 'تم استلام الطلب';
      case 'SEARCHING': return 'جاري البحث عن سائق';
      case 'ASSIGNED': return 'تم تعيين السائق';
      case 'DRIVER_ARRIVING': return 'السائق في الطريق إليك';
      case 'IN_PROGRESS': return 'الرحلة بدأت';
      case 'COMPLETED': return 'اكتملت الرحلة';
      case 'CANCELLED': return 'تم إلغاء الرحلة';
      default: return status;
    }
  }
}
