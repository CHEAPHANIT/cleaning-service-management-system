part of '../screens.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key, this.inShell = false});
  static const route = '/services';
  final bool inShell;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final list = provider.filtered;
    return Scaffold(
      appBar: inShell
          ? null
          : AppBar(
              leading: BackButton(
                style: IconButton.styleFrom(foregroundColor: AppColors.text),
              ),
              title: const Text('Services'),
            ),
      body: RefreshIndicator(
        onRefresh: provider.loadServices,
        child: Column(
          children: [
            if (inShell)
              const SafeArea(child: SectionHeader(title: 'Services')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search for Service',
                      ),
                      onChanged: provider.updateSearch,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.tune_outlined),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: provider.categories.map((category) {
                  final selected = provider.category == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        serviceCategoryIcon(category),
                        size: 16,
                        color: selected ? Colors.white : AppColors.primaryDark,
                      ),
                      label: Text(category),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      onSelected: (_) => provider.updateCategory(category),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: DropdownButtonFormField(
                initialValue: provider.sort,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.sort_outlined),
                  labelText: 'Sort services',
                ),
                items: const ['Popular', 'Price', 'Rating']
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text('Sort by $e')),
                    )
                    .toList(),
                onChanged: (v) => provider.updateSort(v!),
              ),
            ),
            Expanded(
              child: provider.loading
                  ? const LoadingWidget()
                  : provider.error != null
                  ? ErrorView(
                      message: provider.error!,
                      onRetry: provider.loadServices,
                    )
                  : list.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No services found',
                      message: 'Try another search or category.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .78,
                          ),
                      itemCount: list.length,
                      itemBuilder: (_, index) {
                        final service = list[index];
                        return ServiceGridCard(
                          service: service,
                          favorite: favoriteProvider.isFavorite(service.id),
                          onFavorite: () => requireLogin(
                            context,
                            () => favoriteProvider.toggle(userId!, service),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            ServiceDetailScreen.route,
                            arguments: service,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});
  static const route = '/service-detail';

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as ServiceModel;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final galleryImages = _serviceGalleryImages(service);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(service.name),
        actions: [
          IconButton(
            tooltip: 'Save service',
            onPressed: () => requireLogin(
              context,
              () => favoriteProvider.toggle(userId!, service),
            ),
            icon: Icon(
              favoriteProvider.isFavorite(service.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favoriteProvider.isFavorite(service.id)
                  ? AppColors.danger
                  : AppColors.text,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
        children: [
          _ServiceDetailHero(service: service),
          const SizedBox(height: 16),
          Row(
            children: [
              _ServiceMetricPill(
                icon: Icons.schedule_outlined,
                label: '${service.durationMinutes} min',
              ),
              const SizedBox(width: 8),
              _ServiceMetricPill(
                icon: Icons.star_rounded,
                iconColor: AppColors.accent,
                label: '${service.rating} rating',
              ),
              const SizedBox(width: 8),
              const _ServiceMetricPill(
                icon: Icons.verified_outlined,
                label: 'Verified',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ServiceDetailTabs(
            selectedIndex: selectedTab,
            onSelected: (index) => setState(() => selectedTab = index),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: switch (selectedTab) {
              0 => _ServiceAboutView(service: service),
              1 => _ServiceGalleryView(images: galleryImages),
              _ => _ServiceReviewView(rating: service.rating),
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      money(service.basePrice),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: CustomButton(
                  label: 'Book Now',
                  icon: Icons.event_available,
                  onPressed: () => requireLogin(
                    context,
                    () => Navigator.pushNamed(
                      context,
                      BookingFormScreen.route,
                      arguments: service,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDetailHero extends StatelessWidget {
  const _ServiceDetailHero({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Stack(
      children: [
        Image.network(
          service.imageUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 250,
            color: const Color(0xFFEAF6FF),
            child: const Center(
              child: Icon(
                Icons.cleaning_services_outlined,
                color: AppColors.primary,
                size: 54,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.56),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Professional Cleaning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Phnom Penh',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ServiceMetricPill extends StatelessWidget {
  const _ServiceMetricPill({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ServiceDetailTabs extends StatelessWidget {
  const _ServiceDetailTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.info_outline, 'About'),
      (Icons.photo_library_outlined, 'Gallery'),
      (Icons.reviews_outlined, 'Review'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selectedIndex == index
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[index].$1,
                        color: selectedIndex == index
                            ? AppColors.primary
                            : AppColors.muted,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index].$2,
                        style: TextStyle(
                          color: selectedIndex == index
                              ? AppColors.primaryDark
                              : AppColors.muted,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceAboutView extends StatelessWidget {
  const _ServiceAboutView({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('about'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ServiceSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            const _ServiceProviderTile(),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _ServiceSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Included Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'Dusting',
                        'Floor cleaning',
                        'Bathroom cleaning',
                        'Kitchen cleaning',
                        'Window wiping',
                        'Trash removal',
                      ]
                      .map(
                        (task) => Chip(
                          avatar: const Icon(Icons.check_circle, size: 16),
                          label: Text(task),
                          backgroundColor: const Color(0xFFEAF6FF),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Excluded Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pest control, heavy furniture moving, and outdoor garden cleaning are not included.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ServiceProviderTile extends StatelessWidget {
  const _ServiceProviderTile();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundImage: NetworkImage(DemoImages.cleaner),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jenny Wilson',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'Certified service provider',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Message provider',
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'Call provider',
          onPressed: () {},
          icon: const Icon(Icons.call_outlined),
        ),
      ],
    ),
  );
}

class _ServiceGalleryView extends StatelessWidget {
  const _ServiceGalleryView({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('gallery'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Service Gallery',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      const Text(
        'Preview rooms, surfaces, and finishing details from CleanPro service sessions.',
        style: TextStyle(color: AppColors.muted, height: 1.45),
      ),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: .9,
        ),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFEAF6FF),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.44),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'View ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ServiceReviewView extends StatelessWidget {
  const _ServiceReviewView({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('review'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ServiceSectionCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Customers love the punctual cleaners, clear pricing, and careful finishing touches.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const _ServiceReviewCard(
        name: 'Sokha Lim',
        date: '2 days ago',
        text:
            'The cleaner arrived on time, handled the kitchen carefully, and left the floors spotless.',
      ),
      const SizedBox(height: 10),
      const _ServiceReviewCard(
        name: 'Maya Chen',
        date: 'Last week',
        text:
            'Easy booking and very tidy work. I liked that the price was clear before confirming.',
      ),
      const SizedBox(height: 10),
      const _ServiceReviewCard(
        name: 'Dara Kim',
        date: 'May 2026',
        text:
            'Good attention to corners and windows. I would book the same service again.',
      ),
    ],
  );
}

class _ServiceReviewCard extends StatelessWidget {
  const _ServiceReviewCard({
    required this.name,
    required this.date,
    required this.text,
  });

  final String name;
  final String date;
  final String text;

  @override
  Widget build(BuildContext context) => _ServiceSectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF6FF),
              child: Text(
                name.characters.first,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (_) => const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    ),
  );
}

class _ServiceSectionCard extends StatelessWidget {
  const _ServiceSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

List<String> _serviceGalleryImages(ServiceModel service) => [
  service.imageUrl,
  DemoImages.home,
  DemoImages.deep,
  DemoImages.office,
  DemoImages.sofa,
  DemoImages.carpet,
];
