import 'package:supabase_flutter/supabase_flutter.dart';

class SafetyService {
  final SupabaseClient db;
  SafetyService(this.db);
  Future<dynamic> sendSos({String? jobId, double? latitude, double? longitude, String? note}) =>
      db.rpc('create_sos_incident', params: {'p_job_id': jobId, 'p_latitude': latitude, 'p_longitude': longitude, 'p_note': note});
  Future<dynamic> trustedContacts() => db.from('trusted_contacts').select().order('created_at');
}
