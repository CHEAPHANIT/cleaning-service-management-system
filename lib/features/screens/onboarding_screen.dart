part of '../screens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const route = '/onboarding';
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;
  final pages = const [
    (
      'Professional Cleaning Service',
      'Book trusted cleaners for your home, office, or apartment.',
      Icons.verified_user_outlined,
    ),
    (
      'Easy Booking',
      'Choose service, date, time, and location in a few steps.',
      Icons.event_available_outlined,
    ),
    (
      'Track Your Service',
      'Follow your booking status from pending to completed.',
      Icons.timeline_outlined,
    ),
  ];

  Future<void> finish() async {
    await context.read<AuthProvider>().completeOnboarding();
    if (mounted) Navigator.pushReplacementNamed(context, LoginScreen.route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: finish, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(pages[i].$3, size: 120, color: AppColors.primary),
                    const SizedBox(height: 36),
                    Text(
                      pages[i].$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pages[i].$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => Container(
                width: index == i ? 26 : 8,
                height: 8,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: index == i ? AppColors.primary : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              label: index == pages.length - 1 ? 'Get Started' : 'Next',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => index == pages.length - 1
                  ? finish()
                  : controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
