import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jelad_core/jelad_core.dart';

class CustomerAuthScreen extends StatefulWidget { const CustomerAuthScreen({super.key}); @override State<CustomerAuthScreen> createState()=>_CustomerAuthScreenState(); }
class _CustomerAuthScreenState extends State<CustomerAuthScreen>{
  final phone=TextEditingController(), otp=TextEditingController(); bool sent=false,busy=false;
  Future<void> submit() async { setState(()=>busy=true); try { final a=AuthService(Supabase.instance.client); if(!sent){await a.sendOtp(phone.text.trim());setState(()=>sent=true);}else{await a.verifyOtp(phone.text.trim(),otp.text.trim());if(mounted)Navigator.pop(context);}} finally{if(mounted)setState(()=>busy=false);} }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تسجيل الدخول')),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(sent?'أدخل رمز التحقق':'رقم الهاتف',style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:16),TextField(controller:sent?otp:phone,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:sent?'OTP':'رقم الهاتف',border:const OutlineInputBorder())),const SizedBox(height:16),FilledButton(onPressed:busy?null:submit,child:Text(sent?'تحقق':'إرسال الرمز'))]));}
}
