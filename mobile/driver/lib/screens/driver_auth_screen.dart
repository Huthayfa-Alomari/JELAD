import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class DriverAuthScreen extends StatefulWidget {
  const DriverAuthScreen({super.key});
  @override State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  bool sent = false;
  bool busy = false;

  Future<void> submit() async {
    final value = sent ? otp.text.trim() : phone.text.trim();
    if (value.isEmpty) return;
    setState(() => busy = true);
    try {
      final auth = AuthService(Supabase.instance.client);
      if (!sent) {
        await auth.sendOtp(value);
        setState(() => sent = true);
      } else {
        await auth.verifyOtp(phone.text.trim(), value);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تسجيل الدخول: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('دخول السائق')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sent ? 'أدخل رمز التحقق' : 'رقم هاتف السائق', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: sent ? otp : phone,
            keyboardType: TextInputType.phone,
            maxLength: sent ? 6 : null,
            decoration: InputDecoration(
              labelText: sent ? 'OTP' : 'رقم الهاتف',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : submit,
            child: Text(busy ? '...' : sent ? 'تحقق' : 'إرسال الرمز'),
          ),
        ],
      ),
    ),
  );
}
