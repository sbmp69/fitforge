import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme.dart';
import '../../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await SubscriptionService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isLoading = true);
    final success = await SubscriptionService.purchasePackage(package);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(); // Go back after successful purchase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to FitForge PRO!'), backgroundColor: AppColors.primary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed or cancelled.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.bolt, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Unlock Your Full Potential with FitForge PRO',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(Icons.fitness_center, 'Unlimited AI Workout Generations'),
            const SizedBox(height: 20),
            _buildFeatureRow(Icons.restaurant, 'Unlimited AI Meal Plans'),
            const SizedBox(height: 20),
            _buildFeatureRow(Icons.chat_bubble, '24/7 Access to AI Fitness Coach'),
            const SizedBox(height: 48),
            if (_offerings != null && _offerings!.current != null)
              ..._offerings!.current!.availablePackages.map((package) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildPriceButton(
                    context: context,
                    title: package.storeProduct.title,
                    price: package.storeProduct.priceString,
                    isPopular: package.packageType == PackageType.annual,
                    onTap: () => _purchasePackage(package),
                  ),
                );
              }).toList()
            else
              const Text('No subscription packages available right now.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceButton({
    required BuildContext context,
    required String title,
    required String price,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPopular ? AppColors.primary.withOpacity(0.1) : AppColors.navy800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.navy700,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: isPopular ? AppColors.primary : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isPopular)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text('BEST VALUE', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ),
              ],
            ),
            Text(price, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
