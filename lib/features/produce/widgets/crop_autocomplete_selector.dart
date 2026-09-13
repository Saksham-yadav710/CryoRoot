import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/crop_profile.dart';
import 'add_custom_crop_dialog.dart';

/// A typeahead autocomplete dropdown selector for 70+ vegetables & crops.
///
/// Features:
/// - Real-time letter-by-letter predictive filtering.
/// - Searches across name, category, and regional/botanical aliases.
/// - Instant dropdown overlay showing temperature, humidity, and shelf life.
/// - One-tap 'Add custom vegetable & fetch conditions' action.
class CropAutocompleteSelector extends StatefulWidget {
  final List<CropProfile> cropProfiles;
  final CropProfile? selectedCrop;
  final ValueChanged<CropProfile> onCropSelected;

  const CropAutocompleteSelector({
    super.key,
    required this.cropProfiles,
    required this.selectedCrop,
    required this.onCropSelected,
  });

  @override
  State<CropAutocompleteSelector> createState() =>
      _CropAutocompleteSelectorState();
}

class _CropAutocompleteSelectorState extends State<CropAutocompleteSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedCrop != null) {
      _searchController.text = widget.selectedCrop!.name;
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openDropdown();
      } else {
        // Small delay to allow tap on dropdown item
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            _closeDropdown();
          }
        });
      }
    });

    _searchController.addListener(() {
      final text = _searchController.text;
      if (text != _query) {
        setState(() {
          _query = text;
        });
        _updateOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CropAutocompleteSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCrop != oldWidget.selectedCrop &&
        widget.selectedCrop != null) {
      if (_searchController.text != widget.selectedCrop!.name) {
        _searchController.text = widget.selectedCrop!.name;
      }
    }
  }

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CropProfile> get _filteredCrops {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.cropProfiles;
    }

    return widget.cropProfiles.where((crop) {
      if (crop.name.toLowerCase().contains(q)) return true;
      if (crop.category.toLowerCase().contains(q)) return true;
      for (final alias in crop.aliases) {
        if (alias.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  void _openDropdown() {
    if (_isOpen) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _selectCrop(CropProfile crop) {
    _searchController.text = crop.name;
    widget.onCropSelected(crop);
    _closeDropdown();
    _focusNode.unfocus();
  }

  Future<void> _addNewVegetable(String typedName) async {
    _closeDropdown();
    _focusNode.unfocus();

    final newCrop = await AddCustomCropDialog.show(
      context,
      typedName.isNotEmpty ? typedName : 'New Vegetable',
    );

    if (newCrop != null) {
      _selectCrop(newCrop);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        final matches = _filteredCrops;
        final hasExactMatch = matches.any(
          (c) => c.name.toLowerCase() == _query.trim().toLowerCase(),
        );

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 6),
            child: Material(
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 340),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header showing results count
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        color: AppColors.background,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _query.isEmpty
                                    ? 'ALL AVAILABLE VEGETABLES (${matches.length})'
                                    : 'MATCHING CROPS (${matches.length})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_query.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Filtered by "$_query"',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),

                      // Filtered List
                      Flexible(
                        child: matches.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off,
                                        size: 36,
                                        color: AppColors.textSecondary),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No crop found matching "$_query"',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'You can add it and fetch cold-storage conditions in real time!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: matches.length,
                                separatorBuilder: (ctx, i) => const Divider(
                                  height: 1,
                                  color: AppColors.borderSubtle,
                                ),
                                itemBuilder: (ctx, index) {
                                  final crop = matches[index];
                                  final isSelected =
                                      widget.selectedCrop?.id == crop.id;

                                  return InkWell(
                                    onTap: () => _selectCrop(crop),
                                    child: Container(
                                      color: isSelected
                                          ? AppColors.primaryContainer
                                              .withValues(alpha: 0.35)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer
                                                  .withValues(alpha: 0.35),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(crop.iconEmoji,
                                                style: const TextStyle(
                                                    fontSize: 20)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        crop.name,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (crop.isCustom)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .secondaryContainer,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Text(
                                                          'CUSTOM',
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: AppColors
                                                                .secondary,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 2,
                                                  children: [
                                                    Text(
                                                      crop.category,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      '• Temp: ${crop.tempRangeFormatted}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            AppColors.secondary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      '• RH: ${crop.humidityRangeFormatted}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle,
                                                color: AppColors.primary,
                                                size: 20),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Bottom "Add Custom Crop" Button
                      if (!hasExactMatch || _query.isNotEmpty) ...[
                        const Divider(height: 1, color: AppColors.border),
                        InkWell(
                          onTap: () => _addNewVegetable(_query),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            color: AppColors.primaryContainer
                                .withValues(alpha: 0.4),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _query.trim().isNotEmpty
                                            ? 'Add "${_query.trim()}" as new vegetable'
                                            : 'Add custom vegetable / crop',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        'Fetch required cold storage conditions real-time',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'FETCH LIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Search or Select Vegetable / Crop',
          hintText: 'Type letters: Tomato, Potato, Spinach, Methi...',
          prefixIcon: widget.selectedCrop != null
              ? Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    widget.selectedCrop!.iconEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                )
              : const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _openDropdown();
                  },
                ),
              IconButton(
                icon: Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  if (_isOpen) {
                    _closeDropdown();
                  } else {
                    _focusNode.requestFocus();
                    _openDropdown();
                  }
                },
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        onTap: _openDropdown,
      ),
    );
  }
}
