import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'screens/auth_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/booking_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }
  runApp(const JeladCustomerApp());
}

class JeladCustomerApp extends StatelessWidget {
  const JeladCustomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JELAD',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const CustomerHome(),
  );
}

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  Future<void> _openBooking(BuildContext context, String type) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerAuthScreen()));
      if (client.auth.currentUser == null || !context.mounted) return;
    }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(type: type)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('JELAD'),
      actions: [
        if (Supabase.instance.client.auth.currentUser != null)
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('كيف تريد التنقل اليوم؟', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('رحلة آمنة، تتبع حي، وحماية مدمجة.'),
        const SizedBox(height: 24),
        _Action('🚗', 'JELAD Ride', 'اطلب رحلة', () => _openBooking(context, 'RIDE')),
        _Action('📦', 'JELAD Delivery', 'أرسل طلباً', () => _openBooking(context, 'DELIVERY')),
        _Action('🚚', 'JELAD Cargo', 'شحن ونقل', () => _openBooking(context, 'CARGO')),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('مركز الأمان'),
            subtitle: const Text('SOS · مشاركة الرحلة · جهات موثوقة'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSafetyScreen())),
          ),
        ),
        if (Supabase.instance.client.auth.currentUser == null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.login),
              title: const Text('تسجيل الدخول'),
              subtitle: const Text('OTP عبر رقم الهاتف'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerAuthScreen())),
            ),
          ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Action(this.icon, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 28)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
