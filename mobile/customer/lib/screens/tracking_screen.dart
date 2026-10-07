import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class CustomerTrackingScreen extends StatefulWidget { final String jobId; const CustomerTrackingScreen({super.key,required this.jobId}); @override State<CustomerTrackingScreen> createState()=>_CustomerTrackingScreenState(); }
class _CustomerTrackingScreenState extends State<CustomerTrackingScreen>{dynamic data;bool loading=true;
Future<void> load()async{setState(()=>loading=true);try{data=await JeladApi(Supabase.instance.client).tracking(widget.jobId);}finally{if(mounted)setState(()=>loading=false);}}
@override void initState(){super.initState();load();}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تتبع الرحلة')),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
Card(child:ListTile(title:Text('الحالة: '+(data?['status']??'').toString()),subtitle:Text('السائق: '+(data?['driver_name']??'غير معين').toString()))),
const Card(child:SizedBox(height:320,child:Center(child:Text('خريطة التتبع — سيتم ربط MapLibre/Maps هنا')))),
FilledButton.icon(onPressed:load,icon:const Icon(Icons.refresh),label:const Text('تحديث الموقع')),
]));
}
