import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient db;
  AuthService(this.db);
  Future<void> sendOtp(String phone) => db.auth.signInWithOtp(phone: phone);
  Future<void> verifyOtp(String phone, String token) async { await db.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms); }
  Future<void> signOut() => db.auth.signOut();
  User? get user => db.auth.currentUser;
}
