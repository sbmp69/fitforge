import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.bolt, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Unlock Your Full Potential with FitForge PRO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(Icons.fitness_center, 'Unlimited AI Workout Generations'),
            const SizedBox(height: 20),
            _buildFeatureRow(Icons.restaurant, 'Unlimited AI Meal Plans'),
            const SizedBox(height: 20),
            _buildFeatureRow(Icons.chat_bubble, '24/7 Access to AI Fitness Coach'),
            const SizedBox(height: 20),
            _buildFeatureRow(Icons.trending_up, 'Advanced Progress Analytics'),
            const SizedBox(height: 48),
            _buildPriceButton(
              context: context,
              title: 'Yearly Plan (Best Value)',
              price: '\$79.99 / year',
              isPopular: true,
              onTap: () {
                // Mock purchase
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchasing is disabled in testing mode.')),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPriceButton(
              context: context,
              title: 'Monthly Plan',
              price: '\$9.99 / month',
              isPopular: false,
              onTap: () {
                // Mock purchase
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchasing is disabled in testing mode.')),
                );
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Restore Purchases',
                style: TextStyle(color: AppColors.slate400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
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
          color: isPopular ? AppColors.primary.withOpacity(0.1) : AppColors.navy700,
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.navy700,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(color: AppColors.navy900, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(color: AppColors.slate300, fontSize: 14),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.slate400, size: 16),
          ],
        ),
      ),
    );
  }
}
