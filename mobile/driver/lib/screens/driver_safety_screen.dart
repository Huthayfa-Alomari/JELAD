import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class DriverSafetyScreen extends StatefulWidget { const DriverSafetyScreen({super.key}); @override State<DriverSafetyScreen> createState()=>_DriverSafetyScreenState(); }
class _DriverSafetyScreenState extends State<DriverSafetyScreen>{ bool busy=false;
  Future<void> sos() async {setState(()=>busy=true);try{await SafetyService(Supabase.instance.client).sendSos();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل تنبيه الأمان')));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Safety Box')),body:ListView(padding:const EdgeInsets.all(20),children:[FilledButton.icon(onPressed:busy?null:sos,icon:const Icon(Icons.sos),label:const Text('SOS')),const Card(child:ListTile(title:Text('GPS'),subtitle:Text('سيتم ربط الموقع المستمر مع Safety Box'))),const Card(child:ListTile(title:Text('Device Health'),subtitle:Text('GPS · IMU · Camera · Tamper')))]));
}
