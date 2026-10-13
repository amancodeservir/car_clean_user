import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../utils/constants.dart';

enum _AuthStep { welcome, signIn, signUp, forgot }

class LoginSignupCard extends StatefulWidget {
  const LoginSignupCard({
    super.key,
    this.onSuccess,
    this.initialStep,
    this.showClose = false,
    this.onClose,
  });

  final VoidCallback? onSuccess;
  final String? initialStep;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  State<LoginSignupCard> createState() => _LoginSignupCardState();
}

class _LoginSignupCardState extends State<LoginSignupCard> {
  final _formKey = GlobalKey<FormState>();
  _AuthStep _step = _AuthStep.welcome;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _remember = false;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _forgotEmail = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStep == 'signIn') {
      _step = _AuthStep.signIn;
    } else if (widget.initialStep == 'signUp') {
      _step = _AuthStep.signUp;
    }
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('ccp_remember_email');
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() {
      _email.text = saved;
      _remember = true;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _code.dispose();
    _forgotEmail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final bool ok;
    if (_step == _AuthStep.signIn) {
      ok = await auth.login(
        _email.text.trim(),
        _password.text,
        code: auth.otpPending ? _code.text.trim() : '',
      );
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        if (_remember) {
          await prefs.setString('ccp_remember_email', _email.text.trim());
        } else {
          await prefs.remove('ccp_remember_email');
        }
        widget.onSuccess?.call();
      }
    } else {
      final name = '${_first.text.trim()} ${_last.text.trim()}'.trim();
      ok = await auth.register(name, _email.text.trim(), _phone.text.trim(), _password.text);
      if (ok) {
        widget.onSuccess?.call();
      }
    }
    if (!ok && !auth.otpPending && auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  void _go(_AuthStep step) {
    setState(() => _step = step);
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (ok) {
      widget.onSuccess?.call();
      return;
    }
    if (!ok && !auth.otpPending && auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  Future<void> _signInWithApple() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithApple();
    if (ok) {
      widget.onSuccess?.call();
      return;
    }
    if (!ok && !auth.otpPending && auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EFFF), Color(0xFFF5F8FD), Colors.white],
          stops: [0, 0.38, 0.72],
        ),
      ),
      child: SafeArea(
        child: switch (_step) {
          _AuthStep.welcome => _Welcome(
              showClose: widget.showClose,
              onClose: widget.onClose,
              onEmail: () => _go(_AuthStep.signIn),
              onSignIn: () => _go(_AuthStep.signIn),
              onGoogle: () {
                _signInWithGoogle();
              },
              onApple: () {
                _signInWithApple();
              },
            ),
          _AuthStep.forgot => _Forgot(
              email: _forgotEmail,
              onBack: () => _go(_AuthStep.signIn),
            ),
          _ => Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _go(_AuthStep.welcome),
                        icon: const Icon(Icons.chevron_left, color: AppConstants.ink, size: 28),
                      ),
                      if (widget.showClose)
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close, color: AppConstants.ink, size: 24),
                        ),
                    ],
                  ),
                  const _LogoMark(),
                  const SizedBox(height: 18),
                  Text(
                    _step == _AuthStep.signIn ? 'Sign in' : 'Sign up',
                    textAlign: TextAlign.center,
                    style: AppType.display.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step == _AuthStep.signIn
                        ? 'Sign in to book a cleaner car at your doorstep'
                        : 'Create your Car Clean Plus account',
                    textAlign: TextAlign.center,
                    style: AppType.body,
                  ),
                  const SizedBox(height: 22),
                  if (_step == _AuthStep.signUp) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _field(_first, 'First name', required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_last, 'Last name', required: true)),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  _field(_email, 'Email', required: true, keyboard: TextInputType.emailAddress, email: true),
                  const SizedBox(height: 14),
                  if (_step == _AuthStep.signUp) ...[
                    _phoneField(),
                    const SizedBox(height: 14),
                  ],
                  if (_step == _AuthStep.signUp)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            _password,
                            'Password',
                            required: true,
                            secret: true,
                            hidden: _hidePassword,
                            onToggle: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _confirm,
                            'Confirm',
                            required: true,
                            secret: true,
                            hidden: _hideConfirm,
                            onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                            match: _password,
                          ),
                        ),
                      ],
                    )
                  else
                    _field(
                      _password,
                      'Password',
                      required: true,
                      secret: true,
                      hidden: _hidePassword,
                      onToggle: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  if (_step == _AuthStep.signIn && auth.otpPending) ...[
                    const SizedBox(height: 14),
                    Text(
                      auth.error ?? 'Enter the code sent to your email',
                      style: AppType.label,
                    ),
                    const SizedBox(height: 8),
                    _field(_code, 'Email code', required: true, keyboard: TextInputType.number),
                  ],
                  if (_step == _AuthStep.signIn) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _remember,
                            activeColor: AppConstants.signal,
                            side: const BorderSide(color: Colors.black),
                            onChanged: (value) => setState(() => _remember = value ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Remember me', style: AppType.label),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            _forgotEmail.text = _email.text;
                            _go(_AuthStep.forgot);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.mute,
                            textStyle: AppType.body.copyWith(fontWeight: FontWeight.w500),
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: auth.isLoading
                        ? ''
                        : _step == _AuthStep.signIn
                            ? (auth.otpPending ? 'Confirm code' : 'Sign in')
                            : 'Sign up',
                    loading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _submit,
                  ),
                  if (_step == _AuthStep.signUp) ...[
                    const SizedBox(height: 16),
                    const _OrDivider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: const _GoogleMark(),
                            onPressed: () {
                              _signInWithGoogle();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            icon: const Icon(Icons.apple, size: 20, color: AppConstants.ink),
                            onPressed: () {
                              _signInWithApple();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () => _go(_step == _AuthStep.signIn ? _AuthStep.signUp : _AuthStep.signIn),
                      child: Text.rich(
                        TextSpan(
                          style: AppType.body.copyWith(fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                              text: _step == _AuthStep.signIn
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                            ),
                            TextSpan(
                              text: _step == _AuthStep.signIn ? 'Sign up' : 'Sign in',
                              style: const TextStyle(color: AppConstants.signal, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text.rich(
          TextSpan(
            style: AppType.label,
            children: const [
              TextSpan(text: 'Phone number'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('Phone number').copyWith(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Text('+91', style: TextStyle(fontWeight: FontWeight.w700, color: AppConstants.ink)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
            if (digits.length < 10) return 'Enter a 10 digit phone';
            return null;
          },
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    bool secret = false,
    bool hidden = true,
    TextInputType? keyboard,
    VoidCallback? onToggle,
    TextEditingController? match,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: AppType.label,
            children: [
              TextSpan(text: label),
              if (required) const TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: secret && hidden,
          keyboardType: keyboard,
          decoration: _inputDecoration(label).copyWith(
            suffixIcon: secret
                ? IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'Required';
            if (email && !text.contains('@')) return 'Enter a valid email';
            if (match != null && text != match.text) return 'Does not match';
            if (label == 'Email code' && text.length < 6) return 'Enter the 6 digit code';
            return null;
          },
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppConstants.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppConstants.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppConstants.signal, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.onEmail,
    required this.onSignIn,
    required this.onGoogle,
    required this.onApple,
    this.showClose = false,
    this.onClose,
  });

  final VoidCallback onEmail;
  final VoidCallback onSignIn;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      child: Column(
        children: [
          if (showClose)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppConstants.ink, size: 24),
              ),
            ),
          const Spacer(),
          const _LogoMark(),
          const SizedBox(height: 28),
          Text(
            'Welcome to\nCar Clean Plus',
            textAlign: TextAlign.center,
            style: AppType.display.copyWith(fontWeight: FontWeight.w800, height: 1.12),
          ),
          const SizedBox(height: 8),
          Text(
            'A cleaner car, at your doorstep.',
            textAlign: TextAlign.center,
            style: AppType.body,
          ),
          const SizedBox(height: 36),
          _PrimaryButton(label: 'Continue with Email', onPressed: onEmail),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          _SocialButton(label: 'Continue with Google', icon: const _GoogleMark(), onPressed: onGoogle),
          const SizedBox(height: 12),
          _SocialButton(
            label: 'Continue with Apple',
            icon: const Icon(Icons.apple, size: 22, color: AppConstants.ink),
            onPressed: onApple,
          ),
          const Spacer(),
          TextButton(
            onPressed: onSignIn,
            child: Text.rich(
              TextSpan(
                style: AppType.label,
                children: [
                  const TextSpan(text: 'Have an account? '),
                  TextSpan(
                    text: 'Sign in',
                    style: AppType.label.copyWith(color: AppConstants.signal, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Forgot extends StatefulWidget {
  const _Forgot({required this.email, required this.onBack});

  final TextEditingController email;
  final VoidCallback onBack;

  @override
  State<_Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<_Forgot> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.chevron_left, color: AppConstants.ink, size: 28),
          ),
        ),
        const _LogoMark(),
        const SizedBox(height: 18),
        Text(
          'Reset password',
          textAlign: TextAlign.center,
          style: AppType.display.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your registered email. If an account exists, we will send a reset link.',
          textAlign: TextAlign.center,
          style: AppType.body,
        ),
        const SizedBox(height: 24),
        if (_sent)
          Column(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 42),
              const SizedBox(height: 10),
              const Text('Check your inbox', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _PrimaryButton(label: 'Back to sign in', onPressed: widget.onBack),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: AppType.label,
                  children: const [
                    TextSpan(text: 'Email'),
                    TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: widget.email,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'Send reset link',
                onPressed: () {
                  if (!widget.email.text.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid email')),
                    );
                    return;
                  }
                  setState(() => _sent = true);
                },
              ),
            ],
          ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppConstants.signal,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x472563EB), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.local_car_wash_outlined, color: Colors.white, size: 32),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.signal,
          disabledBackgroundColor: const Color(0xFF93C5FD),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppType.title.copyWith(color: Colors.white),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.ink,
          side: const BorderSide(color: AppConstants.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppType.title.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppConstants.line, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or'),
        ),
        Expanded(child: Divider(color: AppConstants.line, thickness: 1)),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: AppType.title.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
