import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:style_ai/core/constants/app_constants.dart';
import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/auth/providers/auth_provider.dart';
import 'package:style_ai/features/recommendation/models/outfit_model.dart';
import 'package:style_ai/features/recommendation/providers/recommendation_provider.dart';
import 'package:style_ai/widgets/common/loading_widget.dart';
import 'package:style_ai/widgets/common/outfit_card.dart';
import 'package:style_ai/widgets/common/primary_button.dart';

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
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recommendationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'StyleAI',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                        GestureDetector(
                          onTap: () {
                            _showProfileMenu(context);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Weather card
                    _buildWeatherCard(recState, theme),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Outfit',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (!recState.isLoading && recState.currentOutfit != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${recState.currentOutfit!.scorePercentage}% match',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Outfit card
                    if (recState.isLoading)
                      const ShimmerBox(height: 360, borderRadius: 20)
                    else if (recState.currentOutfit != null)
                      OutfitCard(
                        outfit: recState.currentOutfit!,
                        onTap: () => context.push('/outfit-result'),
                      )
                    else
                      _buildEmptyOutfitState(theme),
                    const SizedBox(height: 20),
                    // Action buttons
                    if (!recState.isLoading) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref
                                    .read(recommendationProvider.notifier)
                                    .tryAnother();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Try Another'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/occasion'),
                              icon: const Icon(Icons.event_rounded, size: 18),
                              label: const Text('By Occasion'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    // Quick occasions
                    Text('Quick Pick', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildOccasionChips(theme),
                    const SizedBox(height: 24),
                    // Style tip of the day
                    _buildStyleTip(theme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildWeatherCard(RecommendationState recState, ThemeData theme) {
    if (recState.isWeatherLoading) {
      return const ShimmerBox(height: 72, borderRadius: 14);
    }
    final weather = recState.weather;
    if (weather == null) {
      return GestureDetector(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final city = prefs.getString('user_city') ?? 'Mumbai';
          ref.read(recommendationProvider.notifier).fetchTodayRecommendation(
            city: city,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_cloudy_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Tap to load weather',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: AppTheme.warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.cityName,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${weather.temperatureCelsius} · ${weather.description}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              weather.contextDescription,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOutfitState(ThemeData theme) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.checkroom_outlined,
              size: 56,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Text('Add items to your wardrobe', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'We need at least a top, bottom & footwear',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/wardrobe'),
              child: const Text('Go to Wardrobe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccasionChips(ThemeData theme) {
    final recState = ref.watch(recommendationProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppConstants.occasionTypes.map((occasion) {
          final isSelected = recState.selectedOccasion == occasion;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref
                    .read(recommendationProvider.notifier)
                    .fetchRecommendationByOccasion(occasion);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : theme.dividerColor,
                  ),
                ),
                child: Text(
                  occasion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStyleTip(ThemeData theme) {
    const tips = [
      'Mix textures to add depth to neutral outfits.',
      'A belt can transform any casual look into a polished ensemble.',
      'When in doubt, go monochrome — it always works.',
      'Layer a denim jacket over anything for instant cool.',
    ];
    final tip = tips[DateTime.now().day % tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            AppTheme.secondaryColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style Tip of the Day',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(tip, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 0:
            break;
          case 1:
            context.go('/wardrobe');
          case 2:
            context.go('/occasion');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checkroom_outlined),
          activeIcon: Icon(Icons.checkroom_rounded),
          label: 'Wardrobe',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event_rounded),
          label: 'Occasion',
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Edit Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.errorColor),
              ),
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
  }
}
