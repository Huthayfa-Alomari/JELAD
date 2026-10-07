import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'driver_trip_screen.dart';

class DriverJobsScreen extends StatefulWidget { const DriverJobsScreen({super.key}); @override State<DriverJobsScreen> createState()=>_DriverJobsScreenState(); }
class _DriverJobsScreenState extends State<DriverJobsScreen>{ dynamic jobs; bool loading=true;
  Future<void> load() async {setState(()=>loading=true);try{jobs=await JeladApi(Supabase.instance.client).driverJobs();}finally{if(mounted)setState(()=>loading=false);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('الطلبات المتاحة')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(children:[if(jobs is List && jobs.isNotEmpty)...(jobs as List).map((j)=>Card(child:ListTile(title:Text('رحلة '+(j['id']??'').toString()),subtitle:Text((j['job_type']??'RIDE').toString()+' · '+(j['status']??'').toString()),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DriverTripScreen(jobId:j['id'].toString()))))) else const Padding(padding:EdgeInsets.all(24),child:Text('لا توجد طلبات متاحة حاليًا'))])));
}
