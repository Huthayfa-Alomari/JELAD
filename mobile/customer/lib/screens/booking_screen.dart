import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class BookingScreen extends StatefulWidget {
  final String type;
  const BookingScreen({super.key,this.type='RIDE'});
  @override State<BookingScreen> createState()=>_BookingScreenState();
}
class _BookingScreenState extends State<BookingScreen>{
  final pickup=TextEditingController(), destination=TextEditingController(), notes=TextEditingController();
  bool busy=false;
  Future<void> book() async {
    if(pickup.text.trim().isEmpty || destination.text.trim().isEmpty) return;
    setState(()=>busy=true);
    try {
      await JeladApi(Supabase.instance.client).createJob({
        'p_type': widget.type,
        'p_pickup_address': pickup.text.trim(),
        'p_pickup_lat': 0.0,
        'p_pickup_lng': 0.0,
        'p_destination_address': destination.text.trim(),
        'p_destination_lat': 0.0,
        'p_destination_lng': 0.0,
        'p_estimated_amount': 0,
        'p_notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء الطلب')));
    } finally { if(mounted)setState(()=>busy=false); }
  }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('طلب '+widget.type)),body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:pickup,decoration:const InputDecoration(labelText:'موقع الالتقاط',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:destination,decoration:const InputDecoration(labelText:'الوجهة',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'ملاحظات',border:OutlineInputBorder())),
    const SizedBox(height:20),FilledButton(onPressed:busy?null:book,child:Text(busy?'جاري الطلب...':'تأكيد الطلب')),
  ]));
}
