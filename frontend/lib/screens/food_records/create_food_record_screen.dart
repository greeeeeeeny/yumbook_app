import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/services/supabase/supabase_storage_service.dart';
import 'package:yumbook_app/state/food_record_store.dart';

import 'restaurant_picker_screen.dart';

class CreateFoodRecordScreen extends StatefulWidget {
  /// 있으면 edit 모드, 없으면 create 모드.
  final FoodRecord? initialRecord;

  const CreateFoodRecordScreen({super.key, this.initialRecord});

  @override
  State<CreateFoodRecordScreen> createState() => _CreateFoodRecordScreenState();
}

class _CreateFoodRecordScreenState extends State<CreateFoodRecordScreen> {
  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _primary = Color(0xFFD45425);

  final _formKey = GlobalKey<FormState>();
  final _menuController = TextEditingController();
  final _reviewController = TextEditingController();
  final _restaurantNameController = TextEditingController();

  int? _restaurantId;
  double _rating = 4.0;
  DateTime? _visitedAt;
  bool _isPublic = true;
  bool _isSaving = false;

  /// 서버에 이미 업로드된 이미지 (edit 모드 진입 시 채워짐). 수정 가능 = 삭제만.
  final List<FoodRecordImage> _existingImages = [];

  /// 새로 picker 로 추가한 이미지. 저장 시 Storage 업로드 필요.
  final List<_PendingImage> _newImages = [];

  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    if (initial != null) {
      _restaurantId = initial.restaurantId;
      _restaurantNameController.text = initial.restaurantName;
      _menuController.text = initial.menuName;
      _reviewController.text = initial.review;
      _rating = initial.rating;
      _visitedAt = initial.visitedAt;
      _isPublic = initial.isPublic;
      _existingImages.addAll(initial.images);
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _reviewController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  Future<void> _pickRestaurant() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RestaurantPickerScreen()),
    );
    if (selected == null) return;
    setState(() {
      _restaurantId = int.tryParse(selected.id);
      _restaurantNameController.text = selected.name;
    });
  }

  Future<void> _pickVisitedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitedAt ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _visitedAt = picked);
    }
  }

  Future<void> _addImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _newImages.add(_PendingImage(name: file.name, bytes: bytes));
    });
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImages.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final mergedImages = <FoodRecordImage>[];
      var order = 0;
      for (final existing in _existingImages) {
        mergedImages.add(
          FoodRecordImage(
            id: existing.id,
            imageUrl: existing.imageUrl,
            order: order++,
          ),
        );
      }
      for (final pending in _newImages) {
        final url = await SupabaseStorageService.uploadFoodRecordImage(
          bytes: pending.bytes,
          originalName: pending.name,
        );
        mergedImages.add(FoodRecordImage(imageUrl: url, order: order++));
      }

      final initial = widget.initialRecord;
      final record = FoodRecord(
        id: initial?.id,
        userId: initial?.userId,
        restaurantId: _restaurantId,
        restaurantName: _restaurantNameController.text.trim(),
        menuName: _menuController.text.trim(),
        rating: _rating,
        review: _reviewController.text.trim(),
        visitedAt: _visitedAt,
        isPublic: _isPublic,
        images: mergedImages,
      );

      final saved = _isEditMode
          ? await FoodRecordStore.instance.updateRecord(record)
          : await FoodRecordStore.instance.createRecord(record);

      if (!mounted) return;
      Navigator.pop<FoodRecord>(context, saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textDark,
        title: Text(
          _isEditMode ? 'Edit record' : 'New record',
          style: const TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: _primary,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('Restaurant'),
              _RestaurantField(
                controller: _restaurantNameController,
                onPick: _pickRestaurant,
                hasLinkedRestaurant: _restaurantId != null,
              ),
              const SizedBox(height: 20),

              _SectionLabel('Menu'),
              TextFormField(
                controller: _menuController,
                style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14),
                decoration: _inputDecoration('e.g. Tonkatsu set'),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Rating'),
              _RatingPicker(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Visited date'),
              InkWell(
                onTap: _pickVisitedAt,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 18, color: _textMuted),
                      const SizedBox(width: 8),
                      Text(
                        _visitedAt == null
                            ? 'Pick date'
                            : DateFormat('yyyy-MM-dd').format(_visitedAt!),
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: _visitedAt == null ? _textMuted : _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Review'),
              TextFormField(
                controller: _reviewController,
                style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14),
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecoration('How was it?'),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Photos'),
              _PhotoStrip(
                existingImages: _existingImages,
                newImages: _newImages,
                onAdd: _addImage,
                onRemoveExisting: _removeExistingImage,
                onRemoveNew: _removeNewImage,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Switch.adaptive(
                    value: _isPublic,
                    activeColor: _primary,
                    onChanged: (v) => setState(() => _isPublic = v),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPublic ? 'Public' : 'Private',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: _textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textMuted, fontFamily: 'Pretendard'),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _textDark),
      ),
    );
  }
}

class _PendingImage {
  final String name;
  final Uint8List bytes;
  _PendingImage({required this.name, required this.bytes});
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF383838),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

class _RestaurantField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPick;
  final bool hasLinkedRestaurant;

  const _RestaurantField({
    required this.controller,
    required this.onPick,
    required this.hasLinkedRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14),
            decoration: InputDecoration(
              hintText: hasLinkedRestaurant
                  ? 'Linked'
                  : 'Type or pick from list',
              hintStyle: const TextStyle(color: _CreateFoodRecordScreenState._textMuted),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: Icon(
                hasLinkedRestaurant
                    ? Icons.link
                    : Icons.restaurant_outlined,
                color: _CreateFoodRecordScreenState._textMuted,
                size: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: _CreateFoodRecordScreenState._border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: _CreateFoodRecordScreenState._textDark),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onPick,
          style: OutlinedButton.styleFrom(
            side:
                const BorderSide(color: _CreateFoodRecordScreenState._border),
            foregroundColor: _CreateFoodRecordScreenState._textDark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Pick',
            style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = value >= star - 0.25;
        final half = !filled && value >= star - 0.75;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () => onChanged(star.toDouble()),
          icon: Icon(
            half
                ? Icons.star_half_rounded
                : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
            color: _CreateFoodRecordScreenState._primary,
            size: 32,
          ),
        );
      })
        ..add(const SizedBox(width: 8))
        ..add(
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: _CreateFoodRecordScreenState._textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<FoodRecordImage> existingImages;
  final List<_PendingImage> newImages;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  const _PhotoStrip({
    required this.existingImages,
    required this.newImages,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final total = existingImages.length + newImages.length;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == total) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _CreateFoodRecordScreenState._border,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: _CreateFoodRecordScreenState._textMuted,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: _CreateFoodRecordScreenState._textMuted,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (index < existingImages.length) {
            final img = existingImages[index];
            return _PhotoTile(
              onRemove: () => onRemoveExisting(index),
              child: Image.network(
                img.imageUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 96,
                  height: 96,
                  color: const Color(0xFFEAEAEA),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 18,
                    color: _CreateFoodRecordScreenState._textMuted,
                  ),
                ),
              ),
            );
          }

          final pending = newImages[index - existingImages.length];
          return _PhotoTile(
            onRemove: () => onRemoveNew(index - existingImages.length),
            child: Image.memory(
              pending.bytes,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _PhotoTile({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
