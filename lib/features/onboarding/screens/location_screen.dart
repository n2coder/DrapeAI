import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/onboarding/providers/onboarding_provider.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _cityController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  static const List<String> _popularCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Surat',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Faridabad',
    'Meerut',
    'Coimbatore',
    'Kochi',
    'Chandigarh',
    'New Delhi',
  ];

  @override
  void initState() {
    super.initState();
    final savedCity = ref.read(onboardingProvider).city;
    if (savedCity != null) {
      _cityController.text = savedCity;
    }
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _cityController.text.isEmpty) {
        setState(() {
          _suggestions = _popularCities.take(6).toList();
          _showSuggestions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _suggestions = _popularCities.take(6).toList();
        _showSuggestions = true;
      });
    } else {
      final filtered = _popularCities
          .where((c) => c.toLowerCase().startsWith(value.toLowerCase()))
          .take(5)
          .toList();
      setState(() {
        _suggestions = filtered;
        _showSuggestions = filtered.isNotEmpty;
      });
    }
    ref.read(onboardingProvider.notifier).setCity(value);
  }

  void _selectCity(String city) {
    _cityController.text = city;
    ref.read(onboardingProvider.notifier).setCity(city);
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you based?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll use your city for weather-based outfit suggestions',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _cityController,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          textCapitalization: TextCapitalization.words,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'e.g. Mumbai, Delhi, Bangalore',
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
            suffixIcon: _cityController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _cityController.clear();
                      ref.read(onboardingProvider.notifier).setCity('');
                      setState(() => _showSuggestions = false);
                    },
                  )
                : null,
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final city = entry.value;
                return Column(
                  children: [
                    InkWell(
                      onTap: () => _selectCity(city),
                      borderRadius: BorderRadius.only(
                        topLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                        topRight: index == 0 ? const Radius.circular(12) : Radius.zero,
                        bottomLeft: index == _suggestions.length - 1
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottomRight: index == _suggestions.length - 1
                            ? const Radius.circular(12)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_city_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 12),
                            Text(city, style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            )),
                          ],
                        ),
                      ),
                    ),
                    if (index < _suggestions.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Popular Cities',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularCities.take(8).map((city) {
            final isSelected = ref.watch(onboardingProvider).city == city;
            return GestureDetector(
              onTap: () => _selectCity(city),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : theme.dividerColor,
                  ),
                ),
                child: Text(
                  city,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
