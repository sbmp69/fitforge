import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../models/food_scan_result.dart';
import '../../services/api_service.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String? _loadingMessage;
  FoodScanResult? _result;
  File? _selectedImage;

  late AnimationController _animController;
  late Animation<double> _meterAnimation;

  final List<String> _quickSuggestions = [
    '2 Aloo Parathas with Butter & Dahi',
    'Chicken Biryani with Raita',
    '1 Scoop Whey in 250ml Milk',
    'Masala Dosa with Sambar',
    'Oatmeal with Banana & Almonds',
    'Paneer Butter Masala with 2 Roti',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _meterAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
        _analyzeImage(_selectedImage!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera/gallery: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _loadingMessage = 'Scanning image with AI vision...';
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      final result = await _api.scanFood(
        imageBase64: base64String,
        mimeType: 'image/jpeg',
        localImagePath: imageFile.path,
        text: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
        _animController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze food: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _analyzeText([String? presetText]) async {
    final query = presetText ?? _textController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name or dish to scan.')),
      );
      return;
    }

    if (presetText != null) {
      _textController.text = presetText;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _loading = true;
      _selectedImage = null;
      _loadingMessage = 'Calculating calories, macros & health score...';
    });

    try {
      final result = await _api.scanFood(text: query);

      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
        _animController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to calculate nutrition: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _result = null;
      _selectedImage = null;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'AI Food Scanner',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Scan Another',
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro Banner
              _buildIntroCard(),
              const SizedBox(height: 16),

              // Search & Upload Section
              _buildInputSection(),
              const SizedBox(height: 20),

              // Loading State
              if (_loading) _buildLoadingCard(),

              // Results Section
              if (!_loading && _result != null) _buildResultSection(_result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Nutrition & Health Meter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Snap a photo or type any dish. See exact calories, macros, and our BMI-style Healthiness gauge.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _analyzeText(),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2 Paneer Roti with Dahi...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _loading ? null : () => _analyzeText(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Analyze',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider with "OR SNAP FOOD PHOTO"
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR SNAP FOOD PHOTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),

          const SizedBox(height: 14),

          // Camera & Gallery Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.primary),
                  label: const Text(
                    'Camera',
                    style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 20, color: AppColors.primary),
                  label: const Text(
                    'Gallery',
                    style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.background,
                  ),
                ),
              ),
            ],
          ),

          // Quick Suggestion Chips
          const SizedBox(height: 16),
          const Text(
            'Quick Try Dishes:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((dish) {
              return InkWell(
                onTap: _loading ? null : () => _analyzeText(dish),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    dish,
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            _loadingMessage ?? 'Analyzing nutritional profile...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textHeader),
          ),
          const SizedBox(height: 6),
          const Text(
            'Estimating ingredients, macros, and health index...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(FoodScanResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview (if user took a photo)
        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                        SizedBox(width: 4),
                        Text('AI Vision Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Header Title Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      result.foodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeader,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildHealthBadge(result),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.scale_rounded, size: 15, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Portion: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeader,
                          ),
                          children: [
                            TextSpan(
                              text: result.portionSize,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: AppColors.textBody,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // THE BMI-STYLE HEALTHINESS METER
        _buildHealthMeterGauge(result),

        const SizedBox(height: 14),

        // MACRONUTRIENT CARDS (Calories, Protein, Carbs, Fat, Fiber)
        _buildMacroGrid(result),

        const SizedBox(height: 14),

        // AI COACH VERDICT CARD
        _buildCoachVerdictCard(result),

        const SizedBox(height: 14),

        // INGREDIENTS LIST
        if (result.ingredients.isNotEmpty) ...[
          _buildIngredientsCard(result),
          const SizedBox(height: 14),
        ],

        // PROS & CONS CARD
        if (result.pros.isNotEmpty || result.cons.isNotEmpty) ...[
          _buildProsConsCard(result),
          const SizedBox(height: 14),
        ],

        // LOG ACTION BUTTON
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logged ${result.foodName} (${result.calories} kcal) to today\'s intake!'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
          label: const Text(
            'Log to Today\'s Meals',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHealthBadge(FoodScanResult result) {
    Color bg;
    Color textColor;
    String label;

    if (result.healthScore >= 70) {
      bg = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      label = 'Healthy';
    } else if (result.healthScore >= 45) {
      bg = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFF57F17);
      label = 'Moderate';
    } else {
      bg = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
      label = 'Cheat Meal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildHealthMeterGauge(FoodScanResult result) {
    Color meterColor;
    Color meterBgColor;
    if (result.healthScore >= 70) {
      meterColor = const Color(0xFF2E7D32);
      meterBgColor = const Color(0xFFE8F5E9);
    } else if (result.healthScore >= 45) {
      meterColor = const Color(0xFFE65100);
      meterBgColor = const Color(0xFFFFF8E1);
    } else {
      meterColor = const Color(0xFFC62828);
      meterBgColor = const Color(0xFFFFEBEE);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Food Healthiness Meter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeader,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: meterBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: meterColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${result.healthScore} / 100',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: meterColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Like a BMI scale: Red (High Calorie/Processed) -> Yellow (Moderate) -> Green (Clean)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 18),

          // The Dynamic Meter Bar with Pointer
          AnimatedBuilder(
            animation: _meterAnimation,
            builder: (context, child) {
              final double clampedScore = (result.healthScore / 100.0).clamp(0.0, 1.0);
              final double animatedScore = clampedScore * _meterAnimation.value;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final double trackWidth = constraints.maxWidth;
                  const double pointerWidth = 46.0;
                  final double leftOffset = (trackWidth * animatedScore - (pointerWidth / 2))
                      .clamp(0.0, trackWidth - pointerWidth);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Score Pointer Bubble with Down Arrow
                      Container(
                        margin: EdgeInsets.only(left: leftOffset),
                        width: pointerWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: meterColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: meterColor.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${(result.healthScore * _meterAnimation.value).round()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: meterColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),

                      // Gradient Meter Track
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE53935), // Red (Unhealthy / Deep Fried / Ultra Processed)
                                  Color(0xFFFFA726), // Amber
                                  Color(0xFFFDD835), // Yellow (Moderate)
                                  Color(0xFF66BB6A), // Light Green
                                  Color(0xFF2E7D32), // Forest Green (Healthy / Lean / High Fiber)
                                ],
                                stops: [0.0, 0.35, 0.50, 0.70, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          // Dot marker on the track
                          Positioned(
                            left: (trackWidth * animatedScore - 5).clamp(2.0, trackWidth - 12.0),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black45, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Zone Labels below meter
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔴 0-44\nCheat / Dense',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFC62828)),
              ),
              Text(
                '🟡 45-69\nModerate Energy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFF57F17)),
              ),
              Text(
                '🟢 70-100\nClean & Nutritious',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroGrid(FoodScanResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                title: 'Calories',
                value: '${result.calories}',
                unit: 'kcal',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF7043),
                bgColor: const Color(0xFFFFF3E0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                title: 'Protein',
                value: '${result.proteinG}',
                unit: 'g',
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.primary,
                bgColor: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                title: 'Carbs',
                value: '${result.carbsG}',
                unit: 'g',
                icon: Icons.grass_rounded,
                iconColor: const Color(0xFFFFA000),
                bgColor: const Color(0xFFFFF8E1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                title: 'Fat',
                value: '${result.fatG}',
                unit: 'g',
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFE91E63),
                bgColor: const Color(0xFFFCE4EC),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                title: 'Fiber',
                value: '${result.fiberG}',
                unit: 'g',
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF43A047),
                bgColor: const Color(0xFFE8F5E9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                RichText(
                  text: TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeader,
                    ),
                    children: [
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachVerdictCard(FoodScanResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Coach Verdict & Smart Swaps',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.coachVerdict,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textHeader,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard(FoodScanResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected Ingredients',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textHeader),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.ingredients.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12, color: AppColors.textBody, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProsConsCard(FoodScanResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.pros.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                SizedBox(width: 6),
                Text('Nutritional Highlights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 6),
            ...result.pros.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $p', style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
              ),
            ),
          ],
          if (result.pros.isNotEmpty && result.cons.isNotEmpty) const SizedBox(height: 12),
          if (result.cons.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 16),
                SizedBox(width: 6),
                Text('Keep In Mind', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100))),
              ],
            ),
            const SizedBox(height: 6),
            ...result.cons.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $c', style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
