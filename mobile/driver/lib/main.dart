import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'screens/driver_jobs_screen.dart';
import 'screens/driver_safety_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }
  runApp(const JeladDriverApp());
}
class JeladDriverApp extends StatefulWidget { const JeladDriverApp({super.key}); @override State<JeladDriverApp> createState()=>_JeladDriverAppState(); }
class _JeladDriverAppState extends State<JeladDriverApp> { bool online=false; @override Widget build(BuildContext context)=>MaterialApp(title:'JELAD Driver',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true),home:Scaffold(appBar:AppBar(title:const Text('JELAD Driver')),body:ListView(padding:const EdgeInsets.all(20),children:[
const Text('مركز السائق',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
SwitchListTile(title:const Text('متاح للرحلات'),value:online,onChanged:(v)async{setState(()=>online=v);if(Supabase.instance.client.auth.currentUser!=null){await JeladApi(Supabase.instance.client).updatePresence(v?'ONLINE':'OFFLINE');}}),
Card(child:ListTile(leading:const Icon(Icons.route),title:const Text('الطلبات والرحلات'),subtitle:const Text('قبول الرحلات وإدارة الرحلة الحالية'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const DriverJobsScreen())))),
Card(child:ListTile(leading:const Icon(Icons.shield_outlined),title:const Text('Safety Box'),subtitle:const Text('GPS · SOS · Device Health'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const DriverSafetyScreen())))),
const Card(child:ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('التحقق والهوية'),subtitle:Text('حالة التحقق من السائق والمركبة'))),
])); } }
