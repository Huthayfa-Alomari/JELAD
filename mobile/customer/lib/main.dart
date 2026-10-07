import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('JELAD')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('كيف تريد التنقل اليوم؟', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      const _Action('🚗', 'JELAD Ride', 'اطلب رحلة'),
      const _Action('📦', 'JELAD Delivery', 'أرسل طلباً'),
      const _Action('🚚', 'JELAD Cargo', 'شحن ونقل'),
      const SizedBox(height: 20),
      const Card(child: ListTile(leading: Icon(Icons.shield_outlined), title: Text('مركز الأمان'), subtitle: Text('SOS · مشاركة الرحلة · جهات موثوقة'))),
    ]),
  );
}

class _Action extends StatelessWidget {
  final String icon, title, subtitle;
  const _Action(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 28)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
