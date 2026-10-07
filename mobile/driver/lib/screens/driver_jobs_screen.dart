import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'driver_trip_screen.dart';

class DriverJobsScreen extends StatefulWidget {
  const DriverJobsScreen({super.key});
  @override State<DriverJobsScreen> createState() => _DriverJobsScreenState();
}

class _DriverJobsScreenState extends State<DriverJobsScreen> {
  dynamic jobs;
  bool loading = true;
  String? claiming;

  Future<void> load() async {
    setState(() => loading = true);
    try {
      jobs = await JeladApi(Supabase.instance.client).driverJobs();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الطلبات: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _claim(String id) async {
    setState(() => claiming = id);
    try {
      await JeladApi(Supabase.instance.client).claimJob(id);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => DriverTripScreen(jobId: id)));
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر استلام الرحلة: $e')));
    } finally {
      if (mounted) setState(() => claiming = null);
    }
  }

  @override void initState() { super.initState(); load(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('طلبات JELAD')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (jobs is List && (jobs as List).isNotEmpty)
                  ...(jobs as List).map((j) {
                    final id = j['id'].toString();
                    final status = (j['status'] ?? '').toString();
                    final type = (j['type'] ?? 'RIDE').toString();
                    final active = status == 'ASSIGNED' || status == 'DRIVER_ARRIVING' || status == 'IN_PROGRESS';
                    return Card(
                      child: ListTile(
                        leading: Icon(active ? Icons.navigation : Icons.local_taxi),
                        title: Text(type == 'RIDE' ? 'رحلة ركوب' : type),
                        subtitle: Text('الحالة: $status'),
                        trailing: active
                            ? const Icon(Icons.chevron_right)
                            : FilledButton(
                                onPressed: claiming == id ? null : () => _claim(id),
                                child: Text(claiming == id ? '...' : 'استلام'),
                              ),
                        onTap: active ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverTripScreen(jobId: id))) : null,
                      ),
                    );
                  })
                else
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('لا توجد طلبات متاحة حاليًا')),
                  ),
              ],
            ),
          ),
  );
}
