import 'dart:async';
import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/geocoding_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class FloatingSearchBar extends StatefulWidget {
  final Function(Destination) onDestinationSelected;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  const FloatingSearchBar({
    super.key,
    required this.onDestinationSelected,
    this.onClear,
    this.focusNode,
  });

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;
  bool _createdInternalFocusNode = false;
  Timer? _debounceTimer;

  List<Destination> _searchResults = [];
  bool _isLoading = false;
  bool _isExpanded = false;

  final GeocodingService _geocodingService = GeocodingService();

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _createdInternalFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isExpanded = _focusNode.hasFocus;
      if (_isExpanded && _searchResults.isEmpty && _controller.text.isEmpty) {
        _searchResults = _geocodingService.getPopularLandmarks();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    if (_createdInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = _geocodingService.getPopularLandmarks();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await _geocodingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _searchResults.clear();
      _isExpanded = false;
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Floating Input Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.roundedLg,
            boxShadow: AppColors.floatingShadow,
            border: Border.all(
              color: _isExpanded ? AppColors.primary : AppColors.divider,
              width: _isExpanded ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Where do you want to go?',
                      hintStyle: AppTypography.subtitle,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else if (_controller.text.isNotEmpty || _isExpanded)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: _clearSearch,
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
        ),

        // Search Results Dropdown Overlay
        if (_isExpanded && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppColors.floatingShadow,
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.roundedLg,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.divider,
                  indent: 48,
                ),
                itemBuilder: (context, index) {
                  final destination = _searchResults[index];
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(209, 250, 229, 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      destination.title,
                      style: AppTypography.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      destination.address,
                      style: AppTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _controller.text = destination.title;
                      _focusNode.unfocus();
                      setState(() => _isExpanded = false);
                      widget.onDestinationSelected(destination);
                    },
                  ),
                );
              },
              ),
            ),
          ),
      ],
    );
  }
}
