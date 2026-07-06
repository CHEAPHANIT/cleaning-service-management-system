part of '../screens.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  static const route = '/forgot';
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: AuthScaffold(
      children: [
        Form(
          key: form,
          child: CustomTextField(
            controller: email,
            label: 'Email',
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => Column(
            children: [
              if (auth.error != null) ErrorText(auth.error!),
              CustomButton(
                label: 'Send reset email',
                icon: Icons.mark_email_read_outlined,
                loading: auth.loading,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final ok = await auth.resetPassword(email.text.trim());
                  if (ok && context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent.'),
                      ),
                    );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
