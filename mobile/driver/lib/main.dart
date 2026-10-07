import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }
  runApp(const JeladDriverApp());
}

class JeladDriverApp extends StatefulWidget {
  const JeladDriverApp({super.key});
  @override State<JeladDriverApp> createState() => _JeladDriverAppState();
}

class _JeladDriverAppState extends State<JeladDriverApp> {
  bool online = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JELAD Driver',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      appBar: AppBar(title: const Text('JELAD Driver')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('مركز السائق', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SwitchListTile(title: const Text('متاح للرحلات'), value: online, onChanged: (v) => setState(() => online = v)),
        const Card(child: ListTile(leading: Icon(Icons.verified_user_outlined), title: Text('التحقق والهوية'), subtitle: Text('حالة التحقق من السائق والمركبة'))),
        const Card(child: ListTile(leading: Icon(Icons.route), title: Text('الطلبات والرحلات'), subtitle: Text('قبول الرحلات وإدارة الرحلة الحالية'))),
        const Card(child: ListTile(leading: Icon(Icons.shield_outlined), title: Text('Safety Box'), subtitle: Text('GPS · SOS · Device Health'))),
      ]),
    ),
  );
}
