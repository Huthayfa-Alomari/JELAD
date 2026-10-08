import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String jobId;
  final double amount;
  const PaymentScreen({super.key, required this.jobId, required this.amount});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool busy = false;
  String? paymentId;
  String status = 'PENDING';

  Future<void> _startPayment() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) { _message('انتهت جلسة الدخول. سجّل الدخول مرة أخرى.'); return; }
    setState(() => busy = true);
    try {
      final response = await http.post(
        Uri.parse('https://jelad.vercel.app/api/payments/paytabs'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + session.accessToken},
        body: jsonEncode({'jobId': widget.jobId}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw StateError(data['error']?.toString() ?? 'تعذر بدء الدفع');
      paymentId = data['paymentId']?.toString();
      final redirect = data['redirectUrl']?.toString();
      if (redirect == null || redirect.isEmpty) throw StateError('لم يتم استلام رابط الدفع');
      final ok = await launchUrl(Uri.parse(redirect), mode: LaunchMode.externalApplication);
      if (!ok) throw StateError('تعذر فتح بوابة الدفع');
      if (mounted) setState(() => busy = false);
    } catch (e) { if (mounted) { setState(() => busy = false); _message(e.toString()); } }
  }

  Future<void> _checkPayment() async {
    setState(() => busy = true);
    try {
      final row = await Supabase.instance.client.from('payments').select('id,status,amount').eq('job_id', widget.jobId).eq('provider', 'PAYTABS').order('created_at', ascending: false).limit(1).maybeSingle();
      final next = row?['status']?.toString() ?? 'PENDING';
      if (!mounted) return;
      setState(() { status = next; paymentId = row?['id']?.toString() ?? paymentId; busy = false; });
      if (next == 'PAID') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CustomerTrackingScreen(jobId: widget.jobId)));
      } else {
        _message(next == 'FAILED' ? 'عملية الدفع لم تنجح. يمكنك المحاولة مرة أخرى.' : 'الدفع ما زال قيد المعالجة. اضغط تحقق بعد العودة من البوابة.');
      }
    } catch (e) { if (mounted) { setState(() => busy = false); _message('تعذر التحقق من حالة الدفع: ' + e.toString()); } }
  }

  void _message(String value) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الدفع')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('قيمة الرحلة'), subtitle: Text(widget.amount.toStringAsFixed(3) + ' JOD'))),
      const SizedBox(height: 16),
      const Text('سيتم فتح بوابة PayTabs الآمنة لإتمام الدفع. بعد العودة إلى التطبيق اضغط «تحقق من الدفع».', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: busy ? null : _startPayment, icon: const Icon(Icons.lock_outline), label: Text(busy ? 'جاري التحضير...' : 'الدفع الآن')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: busy ? null : _checkPayment, icon: const Icon(Icons.refresh), label: Text('تحقق من الدفع' + (paymentId == null ? '' : ' · ' + status))),
      const SizedBox(height: 12),
      Text('الحالة الحالية: ' + status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}