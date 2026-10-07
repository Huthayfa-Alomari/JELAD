import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/shared/config/app_config.dart';

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await Supabase.initialize(url:AppConfig.supabaseUrl,anonKey:AppConfig.supabaseAnonKey); runApp(const JeladDriverApp()); }
class JeladDriverApp extends StatelessWidget { const JeladDriverApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(title:'JELAD Driver',theme:ThemeData(useMaterial3:true),home:const DriverHome()); }
class DriverHome extends StatefulWidget { const DriverHome({super.key}); @override State<DriverHome> createState()=>_DriverHomeState(); }
class _DriverHomeState extends State<DriverHome> { bool online=false; @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('JELAD Driver')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('مركز السائق',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),SwitchListTile(title:const Text('متاح للرحلات'),value:online,onChanged:(v)=>setState(()=>online=v)),const Card(child:ListTile(leading:Icon(Icons.verified_user),title:Text('التحقق والهوية'),subtitle:Text('حالة التحقق من السائق والمركبة'))),const Card(child:ListTile(leading:Icon(Icons.route),title:Text('الرحلات'),subtitle:Text('الطلبات الحالية والرحلات النشطة'))),const Card(child:ListTile(leading:Icon(Icons.shield),title:Text('Safety Box'),subtitle:Text('GPS · SOS · Device Health')))])); }
}
