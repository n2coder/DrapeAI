import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:style_ai/core/constants/app_constants.dart';
import 'package:style_ai/core/services/api_service.dart';
import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/core/theme/app_theme_mode.dart';
import 'package:style_ai/core/theme/theme_provider.dart';
import 'package:style_ai/features/auth/providers/auth_provider.dart';
import 'package:style_ai/features/recommendation/providers/recommendation_provider.dart';
import 'package:style_ai/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:style_ai/features/wardrobe/screens/wardrobe_screen.dart';
import 'package:style_ai/widgets/common/loading_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('user_city');
      ref.read(recommendationProvider.notifier).fetchTodayRecommendation(
        city: city,
      );
      ref.read(wardrobeProvider.notifier).fetchItems();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  String _getUserInitial(AuthState authState) {
    final phone = authState.phoneNumber ?? '';
    if (phone.isEmpty) return 'U';
    return phone[phone.length > 1 ? phone.length - 2 : 0].toUpperCase();
  }

  String _getWeatherEmoji(String? condition) {
    if (condition == null) return '🌤';
    final c = condition.toLowerCase();
    if (c.contains('rain')) return '🌧';
    if (c.contains('cloud')) return '⛅';
    if (c.contains('clear') || c.contains('sunny')) return '☀️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('thunder')) return '⛈';
    if (c.contains('fog') || c.contains('mist')) return '🌫';
    return '🌤';
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recommendationProvider);
    final wardrobeState = ref.watch(wardrobeProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final accentLight = accent.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 0: Home
          SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Header ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  authState.phoneNumber != null
                                      ? 'My Style'
                                      : 'DrapeAI',
                                  style: TextStyle(
                                    fontFamily: 'DM Serif Display',
                                    fontSize: 30,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showProfileMenu(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getUserInitial(authState),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Stats Row ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          _StatCard(
                            value: wardrobeState.isLoading
                                ? '—'
                                : '${wardrobeState.items.length}',
                            label: 'Items',
                            accent: true,
                            accentColor: accent,
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: recState.savedOutfits.isNotEmpty
                                ? '${recState.savedOutfits.length}'
                                : '—',
                            label: 'Outfits',
                            accent: false,
                            accentColor: accent,
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: wardrobeState.items
                                    .where((i) => i.isEnhanced)
                                    .length
                                    .toString(),
                            label: 'AI Enhanced',
                            accent: false,
                            accentColor: accent,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Weather Card ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _buildWeatherCard(recState, theme, accent, accentLight),
                    ),
                  ),

                  // ── Today's Picks ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: "Today's Picks",
                      action: recState.currentOutfit != null ? 'See all' : null,
                      onAction: () => context.push('/outfit-result'),
                      theme: theme,
                      accent: accent,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildOutfitScroll(recState, theme, accent),
                  ),

                  // ── Occasion ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Occasion',
                      theme: theme,
                      accent: accent,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildOccasionPills(recState, theme, accent),
                  ),

                  // ── My Wardrobe ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'My Wardrobe',
                      action: 'Manage',
                      onAction: () => setState(() => _selectedIndex = 1),
                      theme: theme,
                      accent: accent,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildWardrobeGrid(wardrobeState, theme, accent, context),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
          // Tab 1: Wardrobe
          const WardrobeScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme, accent),
    );
  }

  // ── Weather ─────────────────────────────────────────────────────────────────

  Widget _buildWeatherCard(
    RecommendationState recState,
    ThemeData theme,
    Color accent,
    Color accentLight,
  ) {
    if (recState.isWeatherLoading) {
      return const ShimmerBox(height: 80, borderRadius: 24);
    }
    final weather = recState.weather;
    if (weather == null) {
      return GestureDetector(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final city = prefs.getString('user_city') ?? 'Delhi';
          ref
              .read(recommendationProvider.notifier)
              .fetchTodayRecommendation(city: city);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Text('🌤', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Tap to load weather',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: accent, size: 20),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            _getWeatherEmoji(weather.condition),
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.temperatureCelsius,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  weather.cityName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              weather.contextDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Outfit Scroll ────────────────────────────────────────────────────────────

  Widget _buildOutfitScroll(
    RecommendationState recState,
    ThemeData theme,
    Color accent,
  ) {
    if (recState.isLoading) {
      return SizedBox(
        height: 220,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const ShimmerBox(width: 155, height: 210, borderRadius: 24),
            const SizedBox(width: 14),
            const ShimmerBox(width: 155, height: 210, borderRadius: 24),
          ],
        ),
      );
    }

    final outfit = recState.currentOutfit;
    if (outfit == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildEmptyOutfitCard(theme, accent),
      );
    }

    final gradients = [
      [const Color(0xFFFDF1EE), const Color(0xFFFAD5CB)],
      [const Color(0xFFEEF4FD), const Color(0xFFCCDCF5)],
      [const Color(0xFFEEFDF4), const Color(0xFFCDF5DC)],
    ];

    final List<Map<String, String>> cards = [
      {
        'emoji': '👔',
        'label': outfit.occasion,
        'pct': '${outfit.scorePercentage}%',
        'best': 'true',
      },
      {'emoji': '🧥', 'label': 'Casual Style', 'pct': '88%', 'best': 'false'},
      {'emoji': '👗', 'label': 'Evening Look', 'pct': '81%', 'best': 'false'},
    ];

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final card = cards[i];
          final grad = gradients[i % gradients.length];
          return GestureDetector(
            onTap: () => context.push('/outfit-result'),
            child: _OutfitScrollCard(
              emoji: card['emoji']!,
              label: card['label']!,
              percentage: card['pct']!,
              isBest: card['best'] == 'true',
              gradientColors: grad,
              accent: accent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOutfitCard(ThemeData theme, Color accent) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined, size: 40, color: accent),
            const SizedBox(height: 10),
            Text('Add wardrobe items', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'We need tops, bottoms & footwear',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => context.go('/wardrobe'),
              child: const Text('Go to Wardrobe'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Occasion Pills ───────────────────────────────────────────────────────────

  Widget _buildOccasionPills(
    RecommendationState recState,
    ThemeData theme,
    Color accent,
  ) {
    final occasions = ['All', ...AppConstants.occasionTypes.take(6)];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: occasions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final occ = occasions[i];
          final isActive = occ == 'All'
              ? recState.selectedOccasion == null
              : recState.selectedOccasion == occ;
          return GestureDetector(
            onTap: () {
              if (occ == 'All') {
                ref
                    .read(recommendationProvider.notifier)
                    .fetchTodayRecommendation();
              } else {
                ref
                    .read(recommendationProvider.notifier)
                    .fetchRecommendationByOccasion(occ);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.dividerColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                occ,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? (theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Wardrobe Grid ────────────────────────────────────────────────────────────

  Widget _buildWardrobeGrid(
    WardrobeState wardrobeState,
    ThemeData theme,
    Color accent,
    BuildContext context,
  ) {
    final counts = wardrobeState.categoryCounts;
    final topCategories = [
      ('👔', 'Top'),
      ('👖', 'Bottom'),
      ('👟', 'Footwear'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          ...topCategories.map((cat) {
            final count = counts[cat.$2] ?? 0;
            final isNew = count > 0 &&
                wardrobeState.items
                    .where((i) => i.category == cat.$2)
                    .any((i) => i.isEnhanced);
            return _WardrobeCard(
              emoji: cat.$1,
              name: cat.$2,
              count: count,
              showNewBadge: isNew,
              theme: theme,
              accent: accent,
              onTap: () => setState(() => _selectedIndex = 1),
            );
          }),
          // Add Item card
          GestureDetector(
            onTap: () => context.push('/add-clothing'),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.dividerColor, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, color: accent, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Item',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────────

  Widget _buildBottomNav(ThemeData theme, Color accent) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: _selectedIndex == 0,
                accent: accent,
                theme: theme,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.checkroom_outlined,
                activeIcon: Icons.checkroom_rounded,
                label: 'Wardrobe',
                isActive: _selectedIndex == 1,
                accent: accent,
                theme: theme,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              // FAB
              GestureDetector(
                onTap: () => context.push('/occasion'),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.event_outlined,
                activeIcon: Icons.event_rounded,
                label: 'Outfits',
                isActive: _selectedIndex == 2,
                accent: accent,
                theme: theme,
                onTap: () => context.push('/occasion'),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: false,
                accent: accent,
                theme: theme,
                onTap: () => _showProfileMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile Menu ─────────────────────────────────────────────────────────────

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currentTheme = ref.watch(themeProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: AppThemeMode.values.map((mode) {
                        final isActive = currentTheme == mode;
                        return GestureDetector(
                          onTap: () {
                            ref.read(themeProvider.notifier).setTheme(mode);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isActive ? 2 : 1,
                              ),
                              color: _themePreviewColor(mode),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _themeEmoji(mode),
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  mode.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _themeTextColor(mode),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isActive) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 16,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Edit Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditProfileDialog(context);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded,
                        color: AppTheme.errorColor),
                    title: const Text('Sign Out',
                        style: TextStyle(color: AppTheme.errorColor)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).signOut();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) async {
    // Load current profile from backend
    Map<String, dynamic> profile = {};
    try {
      final result = await ApiService().getUserProfile();
      profile = (result['data'] as Map<String, dynamic>?) ?? result;
    } catch (_) {}

    if (!context.mounted) return;

    final nameController = TextEditingController(text: profile['name'] as String? ?? '');
    final cityController = TextEditingController(text: profile['city'] as String? ?? '');
    String? selectedGender = profile['gender'] as String?;
    String? selectedAgeRange = profile['age_range'] as String?;
    final currentStyles = List<String>.from(profile['style_preferences'] as List? ?? []);

    const genderOptions = ['male', 'female', 'other', 'prefer_not_to_say'];
    const ageOptions = ['13-17', '18-24', '25-34', '35-44', '45-54', '55+'];
    const styleOptions = ['casual', 'ethnic', 'formal', 'urban', 'streetwear', 'bohemian', 'minimalist', 'sporty'];

    String formatLabel(String s) => s.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile', style: Theme.of(sheetCtx).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  // Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // City
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined), border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined), border: OutlineInputBorder()),
                    items: genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(formatLabel(g)))).toList(),
                    onChanged: (v) => setSheetState(() => selectedGender = v),
                  ),
                  const SizedBox(height: 16),

                  // Age Range
                  DropdownButtonFormField<String>(
                    value: selectedAgeRange,
                    decoration: const InputDecoration(labelText: 'Age Range', prefixIcon: Icon(Icons.calendar_today_outlined), border: OutlineInputBorder()),
                    items: ageOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setSheetState(() => selectedAgeRange = v),
                  ),
                  const SizedBox(height: 16),

                  // Style Preferences
                  Text('Style Preferences (max 2)', style: Theme.of(sheetCtx).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: styleOptions.map((s) {
                      final selected = currentStyles.contains(s);
                      return FilterChip(
                        label: Text(formatLabel(s)),
                        selected: selected,
                        onSelected: (_) => setSheetState(() {
                          if (selected) {
                            currentStyles.remove(s);
                          } else if (currentStyles.length < 2) {
                            currentStyles.add(s);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final updates = <String, dynamic>{};
                        final name = nameController.text.trim();
                        final city = cityController.text.trim();
                        if (name.isNotEmpty) updates['name'] = name;
                        if (city.isNotEmpty) updates['city'] = city;
                        if (selectedGender != null) updates['gender'] = selectedGender;
                        if (selectedAgeRange != null) updates['age_range'] = selectedAgeRange;
                        if (currentStyles.isNotEmpty) updates['style_preferences'] = currentStyles;

                        if (updates.isEmpty) { Navigator.pop(sheetCtx); return; }

                        try {
                          await ApiService().updateUserProfile(updates);
                          if (city.isNotEmpty) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('user_city', city);
                            if (mounted) {
                              ref.read(recommendationProvider.notifier).fetchTodayRecommendation(city: city);
                            }
                          }
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        } catch (e) {
                          if (sheetCtx.mounted) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              SnackBar(content: Text('Failed to save: $e'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _themePreviewColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.blanc:
        return const Color(0xFFFAFAFA);
      case AppThemeMode.obsidian:
        return const Color(0xFF0A0A0A);
      case AppThemeMode.neonPulse:
        return const Color(0xFF0A0A18);
      case AppThemeMode.vogue:
        return const Color(0xFFF8F5F0);
    }
  }

  Color _themeTextColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.blanc:
        return const Color(0xFF111111);
      case AppThemeMode.obsidian:
        return const Color(0xFFC9A84C);
      case AppThemeMode.neonPulse:
        return const Color(0xFF9B5DE5);
      case AppThemeMode.vogue:
        return const Color(0xFFC8102E);
    }
  }

  String _themeEmoji(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.blanc:
        return '🤍';
      case AppThemeMode.obsidian:
        return '🖤';
      case AppThemeMode.neonPulse:
        return '💜';
      case AppThemeMode.vogue:
        return '🩸';
    }
  }
}

// ── Reusable Sub-Widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.theme,
    required this.accent,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final ThemeData theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Serif Display',
              fontSize: 22,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.accent,
    required this.accentColor,
    required this.theme,
  });

  final String value;
  final String label;
  final bool accent;
  final Color accentColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent ? accentColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: accent
              ? null
              : Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: accent
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: accent
                    ? Colors.white.withValues(alpha: 0.75)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitScrollCard extends StatelessWidget {
  const _OutfitScrollCard({
    required this.emoji,
    required this.label,
    required this.percentage,
    required this.isBest,
    required this.gradientColors,
    required this.accent,
  });

  final String emoji;
  final String label;
  final String percentage;
  final bool isBest;
  final List<Color> gradientColors;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pct = double.tryParse(percentage.replaceAll('%', '')) ?? 80.0;
    return Container(
      width: 155,
      height: 210,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          if (isBest)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'BEST',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Text(emoji, style: const TextStyle(fontSize: 60)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percentage match',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.black.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 3,
                    ),
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

class _WardrobeCard extends StatelessWidget {
  const _WardrobeCard({
    required this.emoji,
    required this.name,
    required this.count,
    required this.showNewBadge,
    required this.theme,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final int count;
  final bool showNewBadge;
  final ThemeData theme;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Stack(
          children: [
            if (showNewBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 38)),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.accent,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color accent;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive
                  ? accent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
