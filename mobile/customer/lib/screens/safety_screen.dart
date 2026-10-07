import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class CustomerSafetyScreen extends StatefulWidget { const CustomerSafetyScreen({super.key}); @override State<CustomerSafetyScreen> createState()=>_CustomerSafetyScreenState(); }
class _CustomerSafetyScreenState extends State<CustomerSafetyScreen>{ bool busy=false;
  Future<void> sos() async { setState(()=>busy=true); try{await SafetyService(Supabase.instance.client).sendSos();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل تنبيه الأمان')));}finally{if(mounted)setState(()=>busy=false);} }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مركز الأمان')),body:ListView(padding:const EdgeInsets.all(20),children:[FilledButton.icon(style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(64)),onPressed:busy?null:sos,icon:const Icon(Icons.sos),label:const Text('SOS')),const SizedBox(height:12),const Card(child:ListTile(leading:Icon(Icons.share),title:Text('مشاركة الرحلة'),subtitle:Text('شارك موقع الرحلة مع شخص موثوق'))),const Card(child:ListTile(leading:Icon(Icons.contact_phone),title:Text('جهات الاتصال الموثوقة'),subtitle:Text('إدارة جهات الطوارئ والتحقق منها')))]));
}
