import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../widgets/ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().user?.name ?? '');
  late final _phone = TextEditingController(text: context.read<AuthProvider>().user?.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(name: _name.text, phone: _phone.text);
      if (!mounted) return;
      showMessage(context, 'Profile saved');
      context.pop();
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value ?? '').trim().length < 2 ? 'Enter your name' : null,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (value) => (value ?? '').isNotEmpty && value!.length != 10 ? 'Enter a 10 digit mobile number' : null,
              decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
