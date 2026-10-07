import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'location_picker_screen.dart';
import 'tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final String type;
  const BookingScreen({super.key, this.type = 'RIDE'});
  @override State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  PickedLocation? pickup;
  PickedLocation? destination;
  final notes = TextEditingController();
  bool busy = false;
  Map<String, dynamic>? quote;

  Future<void> _pickLocations() async {
    final result = await Navigator.push<List<PickedLocation>>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        initialPickup: pickup, initialDestination: destination,
      )),
    );
    if (result != null && result.length == 2) {
      setState(() { pickup = result[0]; destination = result[1]; quote = null; });
      try {
        final q = await JeladApi(Supabase.instance.client).quoteFare(type: widget.type, pickupLat: pickup!.latitude, pickupLng: pickup!.longitude, destinationLat: destination!.latitude, destinationLng: destination!.longitude);
        if (mounted) setState(() => quote = Map<String, dynamic>.from(q as Map));
      } catch (_) {}
    }
  }

  Future<void> _book() async {
    if (pickup == null || destination == null) {
      await _pickLocations();
      return;
    }
    setState(() => busy = true);
    try {
      final row = await JeladApi(Supabase.instance.client).createJob({
        'p_type': widget.type,
        'p_pickup_address': pickup!.label,
        'p_pickup_lat': pickup!.latitude,
        'p_pickup_lng': pickup!.longitude,
        'p_destination_address': destination!.label,
        'p_destination_lat': destination!.latitude,
        'p_destination_lng': destination!.longitude,
        'p_estimated_amount': (quote?['amount'] as num?)?.toDouble() ?? 0,
        'p_notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      });
      final jobId = row is Map ? row['id']?.toString() : null;
      if (jobId == null || jobId.isEmpty) throw StateError('لم يتم إرجاع رقم الرحلة');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CustomerTrackingScreen(jobId: jobId)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء الطلب: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override void dispose() { notes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('طلب \${widget.type}')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('المواقع'),
            subtitle: Text(pickup == null || destination == null
                ? 'حدد نقطة الالتقاط والوجهة من الخريطة'
                : 'تم تحديد نقطتي الالتقاط والوجهة'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickLocations,
          ),
        ),
        const SizedBox(height: 12),
        if (pickup != null) _LocationTile(icon: Icons.trip_origin, title: 'الالتقاط', location: pickup!),
        if (destination != null) _LocationTile(icon: Icons.location_on, title: 'الوجهة', location: destination!),
        const SizedBox(height: 12),
        TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'ملاحظات للسائق', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        if (quote != null)
          Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: Text('السعر التقديري: ${quote!['amount']} JOD'), subtitle: Text('${quote!['distance_km']} كم · ${quote!['estimated_minutes']} دقيقة'))),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : _book,
          icon: const Icon(Icons.local_taxi),
          label: Text(busy ? 'جاري إرسال الطلب...' : 'اطلب JELAD'),
        ),
      ],
    ),
  );
}

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final PickedLocation location;
  const _LocationTile({required this.icon, required this.title, required this.location});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('\${location.label}\n\${location.latitude.toStringAsFixed(6)}, \${location.longitude.toStringAsFixed(6)}'),
    ),
  );
}
