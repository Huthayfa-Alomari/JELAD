import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'screens/driver_jobs_screen.dart';
import 'screens/driver_safety_screen.dart';
import 'screens/driver_auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseReady =
      AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty;

  if (supabaseReady) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(JeladDriverApp(supabaseReady: supabaseReady));
}

class JeladDriverApp extends StatefulWidget {
  final bool supabaseReady;
  const JeladDriverApp({super.key, required this.supabaseReady});

  @override
  State<JeladDriverApp> createState() => _JeladDriverAppState();
}

class _JeladDriverAppState extends State<JeladDriverApp> {
  bool online = false;

  Future<void> _login() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DriverAuthScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.supabaseReady) {
      return const MaterialApp(
        title: 'JELAD Driver',
        debugShowCheckedModeBanner: false,
        home: _SupabaseConfigurationScreen(),
      );
    }

    final signedIn = Supabase.instance.client.auth.currentUser != null;
    return MaterialApp(
      title: 'JELAD Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('JELAD Driver'),
          actions: [
            if (signedIn)
              IconButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) setState(() { online = false; });
                },
                icon: const Icon(Icons.logout),
              ),
          ],
        ),
        body: !signedIn
            ? Center(
                child: FilledButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login),
                  label: const Text('دخول السائق عبر OTP'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('مركز السائق', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('الرحلات، الملاحة، GPS وSafety Box في مكان واحد.'),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('متاح للرحلات'),
                    subtitle: Text(online ? 'أنت متاح الآن' : 'أنت غير متاح'),
                    value: online,
                    onChanged: (value) async {
                      setState(() => online = value);
                      try {
                        await JeladApi(Supabase.instance.client).updatePresence(value ? 'ONLINE' : 'OFFLINE');
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر تغيير الحالة: $e')),
                          );
                        }
                      }
                    },
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: const Text('الطلبات والرحلات'),
                      subtitle: const Text('استلام الرحلات وإدارة الرحلة الحالية'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverJobsScreen()),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text('Safety Box'),
                      subtitle: const Text('GPS · SOS · Device Health'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverSafetyScreen()),
                      ),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.verified_user_outlined),
                      title: Text('التحقق والهوية'),
                      subtitle: Text('لا يمكن للسائق غير الموثق استلام الرحلات'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SupabaseConfigurationScreen extends StatelessWidget {
  const _SupabaseConfigurationScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'يلزم إعداد الاتصال بالخادم',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'لم يتم تضمين إعدادات Supabase في نسخة التطبيق. '
                'أعد بناء التطبيق باستخدام SUPABASE_URL و'
                'SUPABASE_PUBLISHABLE_KEY.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
