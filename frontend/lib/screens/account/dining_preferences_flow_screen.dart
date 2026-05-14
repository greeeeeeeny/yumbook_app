import 'package:flutter/material.dart';
import 'package:yumbook_app/models/dining_preferences.dart';

class DiningPreferencesFlowScreen extends StatefulWidget {
  final int initialStep;
  final DiningPreferences? initialData;

  const DiningPreferencesFlowScreen({
    super.key,
    this.initialStep = 0,
    this.initialData,
  });

  @override
  State<DiningPreferencesFlowScreen> createState() =>
      _DiningPreferencesFlowScreenState();
}

class _DiningPreferencesFlowScreenState
    extends State<DiningPreferencesFlowScreen> {
  static const Color _orange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF383838);
  static const Color _textLight = Color(0xFFB4B4B4);
  static const Color _chipBorder = Color(0xFFC8C8C8);
  static const Color _chipBg = Color(0xFFF3F3F3);

  late int _step;
  late DiningPreferences _data;
  late TextEditingController _notesController;

  final List<String> _cuisineOptions = const [
    'Korean',
    'Japanese',
    'Chinese',
    'Italian',
    'French',
    'American',
    'Asian Fusion',
    'Southeast Asian',
    'Middle Eastern',
    'Mexican / Latin',
    'Vegetarian / Vegan',
  ];

  final List<String> _diningOptions = const [
    'Casual dining',
    'Fine dining',
    'Trendy',
    'Quiet & relaxed',
    'Local favorites',
    'Lively & social',
    'Romantic',
    'Family-friendly',
    'Chef’s counter',
    'Outdoor seating',
    'Open kitchen',
  ];

  final List<String> _restrictionOptions = const [
    'No restrictions',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-free',
    'Dairy-free',
    'Nut allergy',
    'Shellfish allergy',
    'Halal',
    'Kosher',
  ];

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _data = widget.initialData ?? const DiningPreferences();
    _notesController = TextEditingController(text: _data.additionalNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleItem(List<String> currentList, String value, Function(List<String>) setter) {
    final updated = List<String>.from(currentList);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    setter(updated);
  }

  void _next() {
    if (_step < 3) {
      setState(() {
        _step++;
      });
      return;
    }

    final result = _data.copyWith(
      additionalNotes: _notesController.text.trim(),
    );

    Navigator.pop(context, result);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step--;
    });
  }

  double get _progress => (_step + 1) / 4;

  String get _title {
    switch (_step) {
      case 0:
        return 'What cuisines\ndo you enjoy most?';
      case 1:
        return 'What kind of dining\nexperience do you prefer?';
      case 2:
        return 'Do you have any dietary\nrestrictions?';
      case 3:
        return 'What other aversions,\nrestrictions, or notes\nwould you add?';
      default:
        return '';
    }
  }

  String? get _subtitle {
    if (_step == 3) return null;
    return '(Select all that apply)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: _textDark,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE5E5EA),
                      valueColor: const AlwaysStoppedAnimation(_orange),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _title,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (_subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _subtitle!,
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _buildStepContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_step == 3 ? 'Save' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildChipWrap(
          options: _cuisineOptions,
          selected: _data.favoriteCuisines,
          onToggle: (value) {
            _toggleItem(_data.favoriteCuisines, value, (updated) {
              setState(() {
                _data = _data.copyWith(favoriteCuisines: updated);
              });
            });
          },
        );
      case 1:
        return _buildChipWrap(
          options: _diningOptions,
          selected: _data.diningStyles,
          onToggle: (value) {
            _toggleItem(_data.diningStyles, value, (updated) {
              setState(() {
                _data = _data.copyWith(diningStyles: updated);
              });
            });
          },
        );
      case 2:
        return _buildChipWrap(
          options: _restrictionOptions,
          selected: _data.dietaryRestrictions,
          onToggle: (value) {
            _toggleItem(_data.dietaryRestrictions, value, (updated) {
              setState(() {
                _data = _data.copyWith(dietaryRestrictions: updated);
              });
            });
          },
        );
      case 3:
        return TextField(
          controller: _notesController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: '“No spicy food, please”\n“Allergic to peanuts”',
            hintStyle: const TextStyle(
              color: _textLight,
              fontSize: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _textLight, width: 0.7),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _orange),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChipWrap({
    required List<String> options,
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selected.contains(option);

        return GestureDetector(
          onTap: () => onToggle(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFEFE8) : _chipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _orange : _chipBorder,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}