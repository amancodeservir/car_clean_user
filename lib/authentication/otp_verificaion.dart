import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _auth = AuthService();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final message = await _auth.requestOtp(
        _phone.text.trim(),
        email: _email.text.trim(),
      );
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final ok = await context.read<AuthProvider>().verifyOtp(
          _phone.text.trim(),
          _code.text.trim(),
          _name.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      final message = context.read<AuthProvider>().error ?? 'Could not sign in';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone code')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BrandIconWell(icon: Icons.sms_outlined),
          const SizedBox(height: 12),
          Text(
            'Sign in with a phone code',
            style: AppType.display.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'We send a 6 digit code to this number.',
            style: AppType.body.copyWith(color: AppConstants.mute),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(
              labelText: 'Mobile',
              prefixIcon: Icon(Icons.phone_outlined, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email for the code',
              prefixIcon: Icon(Icons.email_outlined, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          if (!_sent)
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name, if this number is new',
                prefixIcon: Icon(Icons.person_outline, size: 22),
              ),
            ),
          if (_sent)
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: const InputDecoration(
                labelText: '6 digit code',
                prefixIcon: Icon(Icons.password_outlined, size: 22),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : (_sent ? _verify : _send),
            icon: Icon(_sent ? Icons.login_outlined : Icons.sms_outlined, size: 20),
            label: Text(_sent ? 'Sign in' : 'Send code'),
          ),
        ],
      ),
    );
  }
}
