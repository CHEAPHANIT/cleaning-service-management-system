part of '../screens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const route = '/register';
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7FB),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _LoginHeader(
            title: 'Create account',
            subtitle:
                'Start booking trusted cleaning services with your customer profile.',
            chips: [
              (Icons.person_add_alt_1_outlined, 'Customer'),
              (Icons.lock_outline_rounded, 'Secure'),
              (Icons.event_available_outlined, 'Book fast'),
            ],
          ),
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
                            'Customer details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Use an active email and phone number for booking updates.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LoginTextField(
                            controller: name,
                            label: 'Full name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                Validators.required(v, 'Full name'),
                          ),
                          const SizedBox(height: 12),
                          _LoginTextField(
                            controller: email,
                            label: 'Email address',
                            icon: Icons.mail_outline_rounded,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _LoginTextField(
                            controller: phone,
                            label: 'Phone number',
                            icon: Icons.phone_outlined,
                            validator: Validators.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _LoginTextField(
                            controller: password,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            validator: Validators.password,
                            obscureText: true,
                            canToggleObscure: true,
                          ),
                          const SizedBox(height: 12),
                          _LoginTextField(
                            controller: confirm,
                            label: 'Confirm password',
                            icon: Icons.verified_user_outlined,
                            validator: (v) =>
                                Validators.confirmPassword(v, password.text),
                            obscureText: true,
                            canToggleObscure: true,
                          ),
                          const SizedBox(height: 18),
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => Column(
                              children: [
                                if (auth.error != null) ErrorText(auth.error!),
                                CustomButton(
                                  label: 'Create Account',
                                  icon: Icons.person_add_alt_1_rounded,
                                  loading: auth.loading,
                                  onPressed: () async {
                                    if (!form.currentState!.validate()) return;
                                    final ok = await auth.register(
                                      name.text.trim(),
                                      email.text.trim(),
                                      phone.text.trim(),
                                      password.text,
                                    );
                                    if (ok && context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        CustomerDashboardRoute.route,
                                        (_) => false,
                                      );
                                    }
                                  },
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
                    label: 'Already have an account? Log in',
                    icon: Icons.login_rounded,
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      LoginScreen.route,
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
