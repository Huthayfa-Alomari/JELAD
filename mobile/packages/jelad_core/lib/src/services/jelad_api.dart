import 'package:supabase_flutter/supabase_flutter.dart';

class JeladApi {
  final SupabaseClient db;
  JeladApi(this.db);
  Future<dynamic> createJob(Map<String,dynamic> args)=>db.rpc('create_job',params:args);
  Future<dynamic> driverJobs()=>db.rpc('get_driver_jobs');
  Future<dynamic> claimJob(String id)=>db.rpc('claim_job',params:{'p_job_id':id});
  Future<dynamic> tracking(String id)=>db.rpc('get_customer_job_tracking',params:{'p_job_id':id});
  Future<dynamic> cancelJob(String id,String reason)=>db.rpc('cancel_customer_job',params:{'p_job_id':id,'p_reason':reason});
  Future<dynamic> verifyPin(String id,String pin)=>db.rpc('verify_trip_start_pin',params:{'p_job_id':id,'p_pin':pin});
  Future<dynamic> driverTransition(String id,String action)=>db.rpc('driver_job_transition',params:{'p_job_id':id,'p_action':action});
  Future<dynamic> updatePresence(String status)=>db.rpc('update_driver_presence',params:{'p_status':status});
  Future<dynamic> updateLocation(double lat,double lng)=>db.rpc('update_driver_location',params:{'p_lat':lat,'p_lng':lng});
}
