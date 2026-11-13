import 'package:flutter/material.dart';
import '../core/theme.dart';

final Map<String, String> _globalAiImageMemoryCache = {};
final Set<String> _failedCandidateUrls = {};

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
  bool _candidateFailed = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AiCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.fallbackUrl != widget.fallbackUrl) {
      _candidateFailed = false;
      _resolveImage();
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _resolveImage() {
    final cacheKey = '${widget.category}_${widget.name.trim().toLowerCase()}';
    if (_globalAiImageMemoryCache.containsKey(cacheKey)) {
      _resolvedUrl = _globalAiImageMemoryCache[cacheKey];
      return;
    }

    // If fallbackUrl is already a custom Supabase asset URL, use it directly
    if (widget.fallbackUrl.isNotEmpty && widget.fallbackUrl.contains('supabase.co')) {
      _resolvedUrl = widget.fallbackUrl;
      _globalAiImageMemoryCache[cacheKey] = widget.fallbackUrl;
      return;
    }

    final type = widget.category == 'workout' ? 'workouts' : 'meals';
    final slug = _slugify(widget.name);
    final candidateUrl =
        'https://fzjwsbtmsaghhujpvyde.supabase.co/storage/v1/object/public/ai-assets/$type/$slug.png';

    if (_failedCandidateUrls.contains(candidateUrl)) {
      _resolvedUrl = widget.fallbackUrl;
    } else {
      _resolvedUrl = candidateUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = (_candidateFailed || _resolvedUrl == null)
        ? widget.fallbackUrl
        : _resolvedUrl!;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.network(
        effectiveUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If the candidate Supabase URL failed to load (404/not yet generated),
          // fallback seamlessly to the curated fallback image without any AI API calls.
          if (!_candidateFailed && effectiveUrl != widget.fallbackUrl) {
            _failedCandidateUrls.add(effectiveUrl);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _candidateFailed = true;
                });
              }
            });
            return Image.network(
              widget.fallbackUrl,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                width: widget.width,
                height: widget.height,
                color: AppColors.surface,
                child: Icon(widget.fallbackIcon, color: AppColors.textSecondary, size: 20),
              ),
            );
          }
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surface,
            child: Icon(widget.fallbackIcon, color: AppColors.textSecondary, size: 20),
          );
        },
      ),
    );
  }
}
