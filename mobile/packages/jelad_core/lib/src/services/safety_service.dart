import 'package:supabase_flutter/supabase_flutter.dart';

class SafetyService {
  final SupabaseClient db;
  SafetyService(this.db);

  Future<dynamic> sendSos({String? jobId, String? description}) {
    return db.rpc('create_sos_incident', params: {
      'p_job_id': jobId,
      'p_description': description,
    });
  }

  Future<List<Map<String,dynamic>>> trustedContacts() async {
    final rows = await db.from('trusted_contacts').select().order('created_at');
    return List<Map<String,dynamic>>.from(rows);
  }
}
