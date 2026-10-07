import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String jobId;
  const CustomerTrackingScreen({super.key, required this.jobId});
  @override State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  StreamSubscription? jobSub, locationSub;
  Map<String,dynamic>? job, location;
  @override void initState() {
    super.initState();
    final r = RealtimeService(Supabase.instance.client);
    jobSub = r.jobStream(widget.jobId).listen((rows) { if (rows.isNotEmpty && mounted) setState(() => job = rows.first); });
    locationSub = r.liveLocationStream(widget.jobId).listen((v) { if (mounted) setState(() => location = v); });
  }
  @override void dispose() { jobSub?.cancel(); locationSub?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final status = (job?['status'] ?? '—').toString();
    final lat = location?['latitude'];
    final lng = location?['longitude'];
    return Scaffold(appBar: AppBar(title: const Text('تتبع الرحلة')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: ListTile(leading: const Icon(Icons.trip_origin), title: Text('الحالة: $status'), subtitle: Text('السائق: ${(job?['driver_id'] ?? 'غير معين').toString()}'))),
      Card(child: ListTile(leading: const Icon(Icons.location_on), title: const Text('الموقع المباشر'), subtitle: Text(location == null ? 'بانتظار موقع السيارة' : '$lat, $lng'))),
      const Card(child: SizedBox(height: 300, child: Center(child: Text('خريطة الرحلة — سيتم ربط MapLibre/Maps في طبقة العرض')))),
      const Card(child: ListTile(leading: Icon(Icons.share), title: Text('مشاركة الرحلة'), subtitle: Text('رابط مشاركة آمن للرحلة'))),
    ]));
  }
}
