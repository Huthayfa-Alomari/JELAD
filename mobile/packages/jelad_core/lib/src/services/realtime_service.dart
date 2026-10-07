import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final SupabaseClient db;
  RealtimeService(this.db);

  Stream<List<Map<String,dynamic>>> jobStream(String jobId) {
    final controller=StreamController<List<Map<String,dynamic>>>();
    final channel=db.channel('jelad-job-$jobId');
    Future<void> load() async {
      final row=await db.from('jobs').select().eq('id',jobId).maybeSingle();
      if(row!=null&&!controller.isClosed) controller.add([Map<String,dynamic>.from(row)]);
    }
    channel.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'jobs',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'id',value:jobId),callback:(_)=>load()).subscribe();
    load();
    controller.onCancel=() async {await db.removeChannel(channel);await controller.close();};
    return controller.stream;
  }

  Stream<Map<String,dynamic>> liveLocationStream(String jobId) {
    final controller=StreamController<Map<String,dynamic>>();
    final channel=db.channel('jelad-live-location-$jobId');
    Future<void> load() async {
      final row=await db.from('trip_live_locations').select().eq('job_id',jobId).maybeSingle();
      if(row!=null&&!controller.isClosed) controller.add(Map<String,dynamic>.from(row));
    }
    channel.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'trip_live_locations',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'job_id',value:jobId),callback:(_)=>load()).subscribe();
    load();
    controller.onCancel=() async {await db.removeChannel(channel);await controller.close();};
    return controller.stream;
  }
}
