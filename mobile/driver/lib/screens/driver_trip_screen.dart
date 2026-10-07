import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class DriverTripScreen extends StatefulWidget { final String jobId; const DriverTripScreen({super.key,required this.jobId}); @override State<DriverTripScreen> createState()=>_DriverTripScreenState(); }
class _DriverTripScreenState extends State<DriverTripScreen>{bool busy=false; StreamSubscription<Position>? gpsSub;
@override void initState(){super.initState(); _startGps();}
Future<void> _startGps() async { if(!await Geolocator.isLocationServiceEnabled()) return; var p=await Geolocator.checkPermission(); if(p==LocationPermission.denied) p=await Geolocator.requestPermission(); if(p==LocationPermission.denied||p==LocationPermission.deniedForever)return; gpsSub=Geolocator.getPositionStream(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,distanceFilter:10)).listen((p){JeladApi(Supabase.instance.client).updateLocation(p.latitude,p.longitude);JeladApi(Supabase.instance.client).updateLiveTripLocation(widget.jobId,p.latitude,p.longitude);});}
@override void dispose(){gpsSub?.cancel();super.dispose();}
Future<void> action(String value)async{setState(()=>busy=true);try{await JeladApi(Supabase.instance.client).driverTransition(widget.jobId,value);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم تنفيذ: '+value)));}finally{if(mounted)setState(()=>busy=false);}}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('الرحلة الحالية')),body:ListView(padding:const EdgeInsets.all(20),children:[
const Card(child:ListTile(leading:Icon(Icons.navigation),title:Text('تفاصيل الرحلة'),subtitle:Text('الموقع والوجهة والعميل'))),
FilledButton(onPressed:busy?null:()=>action('ARRIVED'),child:const Text('وصلت إلى نقطة الالتقاط')),
FilledButton(onPressed:busy?null:()=>action('START'),child:const Text('بدء الرحلة')),
FilledButton(onPressed:busy?null:()=>action('COMPLETE'),child:const Text('إنهاء الرحلة')),
]));
}
