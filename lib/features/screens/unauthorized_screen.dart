part of '../screens.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});
  static const route = '/unauthorized';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('403')),
    body: EmptyStateWidget(
      title: 'Access denied',
      message: 'This page is not available for your account role.',
      icon: Icons.lock_outline,
    ),
  );
}
