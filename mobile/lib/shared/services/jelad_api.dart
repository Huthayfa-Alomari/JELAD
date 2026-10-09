import 'package:supabase_flutter/supabase_flutter.dart';

class JeladApi {
  final SupabaseClient db;
  JeladApi(this.db);

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> args) async {
    final result = await db.rpc('create_job', params: args);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<dynamic> driverJobs() => db.rpc('get_driver_jobs');
  Future<dynamic> claimJob(String jobId) => db.rpc('claim_job', params: {'p_job_id': jobId});
  Future<dynamic> tracking(String jobId) => db.rpc('get_customer_job_tracking', params: {'p_job_id': jobId});
  Future<dynamic> cancelJob(String jobId, String reason) => db.rpc('cancel_customer_job', params: {'p_job_id': jobId, 'p_reason': reason});
  Future<dynamic> verifyPin(String jobId, String pin) => db.rpc('verify_trip_start_pin', params: {'p_job_id': jobId, 'p_pin': pin});
  Future<dynamic> driverTransition(String jobId, String action) => db.rpc('driver_job_transition', params: {'p_job_id': jobId, 'p_action': action});
  Future<dynamic> updatePresence(String status) => db.rpc('update_driver_presence', params: {'p_status': status});
  Future<dynamic> updateLocation(double lat, double lng) => db.rpc('update_driver_location', params: {'p_lat': lat, 'p_lng': lng});
}
