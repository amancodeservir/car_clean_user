import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../services/local_store.dart';
import '../../services/social_sign_in.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// After signing in, go back to where the person was heading. The router's
/// redirect is only a guard; it does not re-run for a pushed sign-in page.
void _continue(BuildContext context, String? from) {
  final target = from != null && from.startsWith('/') ? from : '/home';
  context.go(target);
}

String? _validEmail(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Enter a valid email';
  return null;
}

String? _validPassword(String? value) {
  if ((value ?? '').length < 6) return 'At least 6 characters';
  return null;
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE680), Color(0xFFFFF8DD), Colors.white],
            stops: [0, 0.32, 0.6],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Image.asset(Photos.logo, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 22),
              Text(title, style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(subtitle, style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: 26),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, this.label = 'Password', this.validator, this.onSubmit});

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onSubmit;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      autofillHints: const [AutofillHints.password],
      textInputAction: widget.onSubmit == null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) => widget.onSubmit?.call(),
      validator: widget.validator ?? _validPassword,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
        ),
      ),
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({this.from});

  final String? from;

  Future<void> _go(BuildContext context, Future<SocialCredential?> Function() provider) async {
    try {
      final signedIn = await context.read<AuthProvider>().signInWith(provider);
      if (signedIn && context.mounted) _continue(context, from);
    } catch (error) {
      if (context.mounted) showMessage(context, errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final apple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final busy = context.watch<AuthProvider>().busy;
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: AppText.small),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => _go(context, SocialSignIn.google),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('G', style: AppText.h3.copyWith(color: const Color(0xFF4285F4))),
                    const SizedBox(width: 8),
                    const Text('Google'),
                  ],
                ),
              ),
            ),
            if (apple) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _go(context, SocialSignIn.apple),
                  icon: const Icon(Icons.apple, size: 22),
                  label: const Text('Apple'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.from});

  final String? from;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    LocalStore.open().then((store) {
      final saved = store.rememberedEmail;
      if (saved != null && mounted && _email.text.isEmpty) setState(() => _email.text = saved);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final store = await LocalStore.open();
    await store.setRememberedEmail(_remember ? _email.text.trim() : null);
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().signIn(_email.text, _password.text);
      if (mounted) _continue(context, widget.from);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    }
  }

  String _withFrom(String path, [Map<String, String> extra = const {}]) {
    final query = {...extra, if (widget.from != null) 'from': widget.from!};
    return Uri(path: path, queryParameters: query.isEmpty ? null : query).toString();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return _AuthScaffold(
      title: 'Welcome back',
      subtitle: (widget.from ?? '').startsWith('/book')
          ? 'Sign in to continue your booking'
          : 'Sign in to book and track your washes',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: _validEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                _PasswordField(controller: _password, onSubmit: _submit, validator: (value) {
                  if ((value ?? '').isEmpty) return 'Enter your password';
                  return null;
                }),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Checkbox(value: _remember, onChanged: (value) => setState(() => _remember = value ?? false)),
            Expanded(
              child: Text('Remember email', style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TextButton(
              onPressed: () => context.push(_withFrom('/forgot', {'email': _email.text.trim()})),
              child: const Text('Forgot password?'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        PrimaryButton(label: 'Sign in', loading: busy, onPressed: _submit),
        const SizedBox(height: 22),
        _SocialButtons(from: widget.from),
        const SizedBox(height: 22),
        Center(
          child: TextButton(
            onPressed: () => context.pushReplacement(_withFrom('/signup')),
            child: Text.rich(
              TextSpan(
                text: "New to ${AppConfig.appName}? ",
                style: AppText.body,
                children: [TextSpan(text: 'Create account', style: AppText.bodyStrong)],
              ),
            ),
          ),
        ),
        if (widget.from == null)
          Center(
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: Text('Browse without signing in', style: AppText.small),
            ),
          ),
      ],
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.from});

  final String? from;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _referral = TextEditingController();
  bool _showReferral = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    try {
      await context.read<AuthProvider>().register(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
            referralCode: _referral.text,
          );
      if (mounted) _continue(context, widget.from);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return _AuthScaffold(
      title: 'Create your account',
      subtitle: 'Book doorstep washes, save your vehicles and track every wash',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value ?? '').trim().length < 2 ? 'Enter your name' : null,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: _validEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  validator: (value) => (value ?? '').length != 10 ? 'Enter a 10 digit mobile number' : null,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Padding(
                      padding: EdgeInsets.fromLTRB(14, 14, 6, 14),
                      child: Text('+91', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 12),
                _PasswordField(controller: _password, onSubmit: _submit),
                if (_showReferral) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referral,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Referral code (optional)',
                      prefixIcon: Icon(Icons.card_giftcard_rounded, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!_showReferral)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showReferral = true),
              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
              label: const Text('Have a referral code?'),
            ),
          ),
        const SizedBox(height: 10),
        PrimaryButton(label: 'Create account', loading: busy, onPressed: _submit),
        const SizedBox(height: 22),
        _SocialButtons(from: widget.from),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: () => context.pushReplacement(
              Uri(path: '/login', queryParameters: widget.from == null ? null : {'from': widget.from!}).toString(),
            ),
            child: Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: AppText.body,
                children: [TextSpan(text: 'Sign in', style: AppText.bodyStrong)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email, this.from});

  final String? email;
  final String? from;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email ?? '');
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_validEmail(_email.text) != null) {
      _form.currentState?.validate();
      return;
    }
    setState(() => _sending = true);
    try {
      final message = await context.read<AuthProvider>().forgotPassword(_email.text);
      if (!mounted) return;
      setState(() => _sent = true);
      showMessage(context, message);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reset() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      await context.read<AuthProvider>().resetPassword(
            email: _email.text,
            code: _code.text,
            password: _password.text,
          );
      if (!mounted) return;
      showMessage(context, 'Password changed. You are signed in.');
      _continue(context, widget.from);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return _AuthScaffold(
      title: 'Reset password',
      subtitle: _sent
          ? 'Enter the 6 digit code we emailed and choose a new password'
          : 'We will email you a 6 digit code to set a new password',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                enabled: !_sent,
                keyboardType: TextInputType.emailAddress,
                validator: _validEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                ),
              ),
              if (_sent) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  validator: (value) => (value ?? '').length != 6 ? 'Enter the 6 digit code' : null,
                  decoration: const InputDecoration(
                    labelText: '6 digit code',
                    prefixIcon: Icon(Icons.pin_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                _PasswordField(controller: _password, label: 'New password', onSubmit: _reset),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!_sent)
          PrimaryButton(label: 'Send code', loading: _sending, onPressed: _send)
        else ...[
          PrimaryButton(label: 'Set new password', loading: busy, onPressed: _reset),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _sending ? null : _send,
              child: const Text('Send the code again'),
            ),
          ),
        ],
      ],
    );
  }
}
