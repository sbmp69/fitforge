import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/theme.dart';

final Map<String, String> _globalAiImageMemoryCache = {};

class AiCachedImage extends StatefulWidget {
  final String name;
  final String category; // 'meal' or 'workout'
  final String fallbackUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;

  const AiCachedImage({
    super.key,
    required this.name,
    required this.category,
    required this.fallbackUrl,
    this.width = 50,
    this.height = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fallbackIcon = Icons.fitness_center,
  });

  @override
  State<AiCachedImage> createState() => _AiCachedImageState();
}

class _AiCachedImageState extends State<AiCachedImage> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AiCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final cacheKey = '${widget.category}_${widget.name.trim().toLowerCase()}';
    if (_globalAiImageMemoryCache.containsKey(cacheKey)) {
      _resolvedUrl = _globalAiImageMemoryCache[cacheKey];
      return;
    }

    _resolvedUrl = widget.fallbackUrl;

    ApiService().getCachedOrGeneratedImageUrl(
      name: widget.name,
      category: widget.category,
    ).then((url) {
      if (url != null && url.isNotEmpty && mounted) {
        _globalAiImageMemoryCache[cacheKey] = url;
        setState(() {
          _resolvedUrl = url;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl ?? widget.fallbackUrl;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.network(
        url,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.surface,
          child: Icon(widget.fallbackIcon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}
