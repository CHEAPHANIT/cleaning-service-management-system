part of '../screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7FB),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _LoginHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDE6EE)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF168BDB,
                          ).withValues(alpha: 0.10),
                          blurRadius: 26,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Access your bookings, jobs, or admin tools.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LoginTextField(
                            controller: email,
                            label: 'Email address',
                            icon: Icons.mail_outline_rounded,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _LoginTextField(
                            controller: password,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            validator: Validators.required,
                            obscureText: true,
                            canToggleObscure: true,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                ForgotPasswordScreen.route,
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => Column(
                              children: [
                                if (auth.error != null) ErrorText(auth.error!),
                                CustomButton(
                                  label: 'Log In',
                                  icon: Icons.login_rounded,
                                  loading: auth.loading,
                                  onPressed: () async {
                                    if (!form.currentState!.validate()) return;
                                    final ok = await auth.login(
                                      email.text.trim(),
                                      password.text,
                                    );
                                    if (ok && context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        dashboardRouteForRole(auth.user!.role),
                                        (_) => false,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 18),
                                _SocialAuthSection(
                                  actionText: 'sign in',
                                  loading: auth.loading,
                                  onGoogle: () => _continueWithSocial(
                                    context,
                                    auth.loginWithGoogle,
                                  ),
                                  onFacebook: () => _continueWithSocial(
                                    context,
                                    auth.loginWithFacebook,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LoginFooterAction(
                    label: 'Create customer account',
                    icon: Icons.person_add_alt_1_outlined,
                    onPressed: () =>
                        Navigator.pushNamed(context, RegisterScreen.route),
                  ),
                  const SizedBox(height: 10),
                  _LoginFooterAction(
                    label: 'Apply to join as cleaner',
                    icon: Icons.assignment_ind_outlined,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      CleanerApplicationScreen.route,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _continueWithSocial(
  BuildContext context,
  Future<bool> Function() action,
) async {
  final ok = await action();
  if (!ok || !context.mounted) return;
  final auth = context.read<AuthProvider>();
  Navigator.pushNamedAndRemoveUntil(
    context,
    dashboardRouteForRole(auth.user!.role),
    (_) => false,
  );
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    this.title = 'Welcome back',
    this.subtitle =
        'Book trusted cleaners, manage jobs, and keep every service moving.',
    this.chips = const [
      (Icons.verified_outlined, 'Verified'),
      (Icons.schedule_outlined, 'On-time'),
      (Icons.shield_outlined, 'Role secure'),
    ],
  });

  final String title;
  final String subtitle;
  final List<(IconData, String)> chips;

  @override
  Widget build(BuildContext context) => Container(
    height: 260,
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 44),
    decoration: const BoxDecoration(
      color: Color(0xFF0F8CDB),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      image: DecorationImage(
        image: NetworkImage(DemoImages.hero),
        fit: BoxFit.cover,
        opacity: 0.22,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _AppLogoMark(size: 44),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Color(0xFFEAF6FF), height: 1.35),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              _LoginTrustChip(icon: chip.$1, label: chip.$2),
          ],
        ),
      ],
    ),
  );
}

class _LoginTrustChip extends StatelessWidget {
  const _LoginTrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.canToggleObscure = false,
    this.maxLines = 1,
    this.iconColor,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool canToggleObscure;
  final int maxLines;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => _AuthTextFormField(
    controller: controller,
    label: label,
    icon: icon,
    validator: validator,
    keyboardType: keyboardType,
    obscureText: obscureText,
    canToggleObscure: canToggleObscure,
    maxLines: maxLines,
    iconColor: iconColor,
  );
}

class _AuthTextFormField extends StatefulWidget {
  const _AuthTextFormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    required this.canToggleObscure,
    required this.maxLines,
    this.iconColor,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool canToggleObscure;
  final int maxLines;
  final Color? iconColor;

  @override
  State<_AuthTextFormField> createState() => _AuthTextFormFieldState();
}

class _AuthTextFormFieldState extends State<_AuthTextFormField> {
  late bool hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1 && !widget.obscureText;
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: widget.canToggleObscure ? hidden : widget.obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textAlignVertical: multiline ? TextAlignVertical.top : null,
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: multiline,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 48,
        ),
        prefixIcon: multiline
            ? Align(
                alignment: Alignment.topCenter,
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Icon(widget.icon, size: 20, color: widget.iconColor),
                ),
              )
            : Icon(widget.icon, size: 20, color: widget.iconColor),
        suffixIcon: widget.canToggleObscure
            ? IconButton(
                tooltip: hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _LoginFooterAction extends StatelessWidget {
  const _LoginFooterAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    ),
  );
}

class _SocialAuthSection extends StatelessWidget {
  const _SocialAuthSection({
    required this.actionText,
    required this.onGoogle,
    required this.onFacebook,
    this.loading = false,
  });

  final String actionText;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final bool loading;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Or $actionText with',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SocialLogoButton(
            tooltip: 'Continue with Google',
            label: 'G',
            color: const Color(0xFF4285F4),
            onPressed: loading ? null : onGoogle,
          ),
          const SizedBox(width: 12),
          _SocialLogoButton(
            tooltip: 'Continue with Facebook',
            label: 'f',
            color: const Color(0xFF1877F2),
            onPressed: loading ? null : onFacebook,
          ),
        ],
      ),
    ],
  );
}

class _SocialLogoButton extends StatelessWidget {
  const _SocialLogoButton({
    required this.tooltip,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 58,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: label == 'f' ? 25 : 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    ),
  );
}
