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
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final address = TextEditingController();
  final experience = TextEditingController();
  final imagePicker = ImagePicker();
  String? selectedGender;
  String? experienceLength;
  final selectedSkills = <String>{};
  final selectedDays = <String>{};
  TimeOfDay? availableFrom;
  TimeOfDay? availableUntil;
  String? profilePhoto;
  String? idDocument;
  String? profilePhotoName;
  String? idDocumentName;
  bool submitted = false;

  static const skillOptions = [
    'Home Cleaning',
    'Deep Cleaning',
    'Office Cleaning',
    'Bathroom Cleaning',
    'Kitchen Cleaning',
    'Carpet Cleaning',
    'Sofa Cleaning',
    'Window Cleaning',
  ];
  static const weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    for (final controller in [
      name,
      email,
      phone,
      password,
      confirmPassword,
      address,
      experience,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start
          ? (availableFrom ?? const TimeOfDay(hour: 8, minute: 0))
          : (availableUntil ?? const TimeOfDay(hour: 17, minute: 0)),
      helpText: start ? 'SELECT START TIME' : 'SELECT END TIME',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        availableFrom = picked;
      } else {
        availableUntil = picked;
      }
    });
  }

  Future<void> _pickDocument({required bool profile}) async {
    final picked = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final mimeType = picked.mimeType ?? 'image/jpeg';
    if (!mounted) return;
    setState(() {
      final encoded = 'data:$mimeType;base64,${base64Encode(bytes)}';
      if (profile) {
        profilePhoto = encoded;
        profilePhotoName = picked.name;
      } else {
        idDocument = encoded;
        idDocumentName = picked.name;
      }
    });
  }

  String? _selectionError() {
    if (selectedGender == null) return 'Select your gender.';
    if (experienceLength == null) return 'Select your experience level.';
    if (selectedSkills.isEmpty) return 'Select at least one cleaning skill.';
    if (selectedDays.isEmpty) return 'Select at least one available day.';
    if (availableFrom == null || availableUntil == null) {
      return 'Select your available start and end time.';
    }
    final start = availableFrom!.hour * 60 + availableFrom!.minute;
    final end = availableUntil!.hour * 60 + availableUntil!.minute;
    if (end <= start) return 'End time must be later than start time.';
    if (profilePhoto == null) return 'Choose a profile picture.';
    if (idDocument == null) return 'Choose an ID card image.';
    return null;
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
                                  controller: password,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  validator: Validators.password,
                                  obscureText: true,
                                  canToggleObscure: true,
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: confirmPassword,
                                  label: 'Confirm password',
                                  icon: Icons.verified_user_outlined,
                                  validator: (value) =>
                                      Validators.confirmPassword(
                                        value,
                                        password.text,
                                      ),
                                  obscureText: true,
                                  canToggleObscure: true,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedGender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    hintText: 'Select male or female',
                                    prefixIcon: Icon(Icons.wc_rounded),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => selectedGender = value),
                                  validator: (value) => value == null
                                      ? 'Please select your gender'
                                      : null,
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
                                DropdownButtonFormField<String>(
                                  initialValue: experienceLength,
                                  decoration: const InputDecoration(
                                    labelText: 'Cleaning experience',
                                    hintText: 'Select years of experience',
                                    prefixIcon: Icon(
                                      Icons.work_history_outlined,
                                    ),
                                  ),
                                  items:
                                      const [
                                            'Less than 1 year',
                                            '1–2 years',
                                            '3–5 years',
                                            'More than 5 years',
                                          ]
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) =>
                                      setState(() => experienceLength = value),
                                  validator: (value) => value == null
                                      ? 'Please select your experience'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                _LoginTextField(
                                  controller: experience,
                                  label: 'Describe your work experience',
                                  icon: Icons.description_outlined,
                                  validator: (value) {
                                    final required = Validators.required(
                                      value,
                                      'Experience details',
                                    );
                                    if (required != null) return required;
                                    return value!.trim().length < 20
                                        ? 'Please add at least 20 characters'
                                        : null;
                                  },
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 12),
                                _CleanerMultiSelectField(
                                  label: 'Cleaning skills',
                                  helper: 'Select all services you can perform',
                                  icon: Icons.cleaning_services_outlined,
                                  options: skillOptions,
                                  selected: selectedSkills,
                                  onToggle: (value) => setState(() {
                                    selectedSkills.contains(value)
                                        ? selectedSkills.remove(value)
                                        : selectedSkills.add(value);
                                  }),
                                ),
                                const SizedBox(height: 12),
                                _CleanerMultiSelectField(
                                  label: 'Available working days',
                                  helper: 'Choose the days you can really work',
                                  icon: Icons.calendar_month_outlined,
                                  options: weekDays,
                                  selected: selectedDays,
                                  compactLabels: true,
                                  onToggle: (value) => setState(() {
                                    selectedDays.contains(value)
                                        ? selectedDays.remove(value)
                                        : selectedDays.add(value);
                                  }),
                                ),
                                const SizedBox(height: 12),
                                _CleanerTimeRangeField(
                                  from: availableFrom,
                                  until: availableUntil,
                                  onFrom: () => _pickTime(start: true),
                                  onUntil: () => _pickTime(start: false),
                                ),
                                const SizedBox(height: 12),
                                _CleanerFilePickerField(
                                  label: 'Profile picture',
                                  helper: 'Use a clear photo of your face',
                                  icon: Icons.add_a_photo_outlined,
                                  value: profilePhoto,
                                  fileName: profilePhotoName,
                                  onPick: () => _pickDocument(profile: true),
                                ),
                                const SizedBox(height: 12),
                                _CleanerFilePickerField(
                                  label: 'ID card or document',
                                  helper:
                                      'Upload a clear image for verification',
                                  icon: Icons.badge_outlined,
                                  value: idDocument,
                                  fileName: idDocumentName,
                                  onPick: () => _pickDocument(profile: false),
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
                                      final selectionError = _selectionError();
                                      if (selectionError != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(selectionError),
                                          ),
                                        );
                                        return;
                                      }
                                      try {
                                        await provider.submitCleanerApplication(
                                          CleanerApplicationModel(
                                            fullName: name.text.trim(),
                                            email: email.text.trim(),
                                            phone: phone.text.trim(),
                                            gender: selectedGender!,
                                            address: address.text.trim(),
                                            workExperience:
                                                '$experienceLength — ${experience.text.trim()}',
                                            skills: selectedSkills.join(', '),
                                            availableDays: weekDays
                                                .where(selectedDays.contains)
                                                .join(', '),
                                            availableTime:
                                                '${availableFrom!.format(context)} – ${availableUntil!.format(context)}',
                                            password: password.text,
                                            profilePhoto: profilePhoto!,
                                            idDocument: idDocument!,
                                          ),
                                        );
                                        if (context.mounted) {
                                          setState(() => submitted = true);
                                        }
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              error.toString().replaceFirst(
                                                'AppException: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
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

class _CleanerMultiSelectField extends StatelessWidget {
  const _CleanerMultiSelectField({
    required this.label,
    required this.helper,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.compactLabels = false,
  });

  final String label;
  final String helper;
  final IconData icon;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool compactLabels;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected.isEmpty ? AppColors.border : AppColors.primary,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    helper,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected.isNotEmpty)
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text(
                  '${selected.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(compactLabels ? option.substring(0, 3) : option),
                tooltip: option,
                selected: selected.contains(option),
                showCheckmark: true,
                onSelected: (_) => onToggle(option),
                selectedColor: const Color(0xFFDCEEFF),
                checkmarkColor: AppColors.primaryDark,
                side: BorderSide(
                  color: selected.contains(option)
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _CleanerTimeRangeField extends StatelessWidget {
  const _CleanerTimeRangeField({
    required this.from,
    required this.until,
    required this.onFrom,
    required this.onUntil,
  });

  final TimeOfDay? from;
  final TimeOfDay? until;
  final VoidCallback onFrom;
  final VoidCallback onUntil;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 20,
              color: AppColors.primaryDark,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Available working time',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the earliest start and latest finish time',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _CleanerTimeButton(
                label: 'From',
                value: from?.format(context) ?? 'Start time',
                onTap: onFrom,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, size: 17),
            ),
            Expanded(
              child: _CleanerTimeButton(
                label: 'Until',
                value: until?.format(context) ?? 'End time',
                onTap: onUntil,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CleanerTimeButton extends StatelessWidget {
  const _CleanerTimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _CleanerFilePickerField extends StatelessWidget {
  const _CleanerFilePickerField({
    required this.label,
    required this.helper,
    required this.icon,
    required this.value,
    required this.fileName,
    required this.onPick,
  });

  final String label;
  final String helper;
  final IconData icon;
  final String? value;
  final String? fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    Uint8List? preview;
    if (value?.startsWith('data:') == true) {
      try {
        preview = base64Decode(value!.split(',').last);
      } catch (_) {}
    }
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: value == null
              ? const Color(0xFFF8FAFC)
              : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value == null ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: preview == null
                  ? Icon(icon, color: AppColors.primaryDark, size: 25)
                  : Image.memory(preview, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fileName ?? helper,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              value == null
                  ? Icons.upload_file_rounded
                  : Icons.check_circle_rounded,
              color: value == null ? AppColors.primary : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
