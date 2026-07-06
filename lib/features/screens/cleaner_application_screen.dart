part of '../screens.dart';

class CleanerApplicationScreen extends StatefulWidget {
  const CleanerApplicationScreen({super.key});
  static const route = '/join-cleaner';

  @override
  State<CleanerApplicationScreen> createState() =>
      _CleanerApplicationScreenState();
}

class _CleanerApplicationScreenState extends State<CleanerApplicationScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final gender = TextEditingController();
  final address = TextEditingController();
  final experience = TextEditingController();
  final skills = TextEditingController();
  final days = TextEditingController();
  final time = TextEditingController();
  final profilePhoto = TextEditingController();
  final idDocument = TextEditingController();
  bool submitted = false;

  @override
  void dispose() {
    for (final controller in [
      name,
      email,
      phone,
      gender,
      address,
      experience,
      skills,
      days,
      time,
      profilePhoto,
      idDocument,
    ]) {
      controller.dispose();
    }
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
            title: 'Join as Cleaner',
            subtitle:
                'Share your experience, availability, and documents for review.',
            chips: [
              (Icons.assignment_ind_outlined, 'Application'),
              (Icons.cleaning_services_outlined, 'Cleaner'),
              (Icons.verified_user_outlined, 'Admin review'),
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
                    child: submitted
                        ? const EmptyStateWidget(
                            title: 'Application submitted',
                            message:
                                'Your cleaner account is pending admin approval.',
                            icon: Icons.hourglass_top_rounded,
                          )
                        : Form(
                            key: form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cleaner details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Use accurate details so admins can review your profile.',
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
                                  controller: phone,
                                  label: 'Phone number',
                                  icon: Icons.phone_outlined,
                                  validator: Validators.phone,
                                  keyboardType: TextInputType.phone,
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
                                  controller: gender,
                                  label: 'Gender',
                                  icon: Icons.wc_outlined,
                                  validator: (v) =>
                                      Validators.required(v, 'Gender'),
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: address,
                                  label: 'Address',
                                  icon: Icons.location_on_outlined,
                                  validator: (v) =>
                                      Validators.required(v, 'Address'),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: experience,
                                  label: 'Work experience',
                                  icon: Icons.work_outline_rounded,
                                  validator: (v) =>
                                      Validators.required(v, 'Work experience'),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: skills,
                                  label: 'Skills',
                                  icon: Icons.auto_awesome_outlined,
                                  validator: (v) =>
                                      Validators.required(v, 'Skills'),
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: days,
                                  label: 'Available working days',
                                  icon: Icons.calendar_month_outlined,
                                  validator: (v) => Validators.required(
                                    v,
                                    'Available working days',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: time,
                                  label: 'Available working time',
                                  icon: Icons.schedule_outlined,
                                  validator: (v) => Validators.required(
                                    v,
                                    'Available working time',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: profilePhoto,
                                  label: 'Profile photo URL or file name',
                                  icon: Icons.photo_camera_outlined,
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: idDocument,
                                  label: 'ID card/document URL or file name',
                                  icon: Icons.badge_outlined,
                                  validator: (v) => Validators.required(
                                    v,
                                    'ID card/document',
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Consumer<AdminDataProvider>(
                                  builder: (_, provider, __) => CustomButton(
                                    label: 'Submit Application',
                                    icon: Icons.send_outlined,
                                    loading: provider.loading,
                                    onPressed: () async {
                                      if (!form.currentState!.validate()) {
                                        return;
                                      }
                                      await provider.submitCleanerApplication(
                                        CleanerApplicationModel(
                                          fullName: name.text.trim(),
                                          email: email.text.trim(),
                                          phone: phone.text.trim(),
                                          gender: gender.text.trim(),
                                          address: address.text.trim(),
                                          workExperience: experience.text
                                              .trim(),
                                          skills: skills.text.trim(),
                                          availableDays: days.text.trim(),
                                          availableTime: time.text.trim(),
                                          profilePhoto: profilePhoto.text
                                              .trim(),
                                          idDocument: idDocument.text.trim(),
                                        ),
                                      );
                                      if (mounted) {
                                        setState(() => submitted = true);
                                      }
                                    },
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
