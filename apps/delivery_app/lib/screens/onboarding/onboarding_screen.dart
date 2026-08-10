import 'package:core/core.dart';

class DeliveryOnboardingScreen extends StatefulWidget {
  const DeliveryOnboardingScreen({super.key});

  @override
  State<DeliveryOnboardingScreen> createState() => _DeliveryOnboardingScreenState();
}

class _DeliveryOnboardingScreenState extends State<DeliveryOnboardingScreen> {
  void _onFinish() async {
    await OnboardingService.setOnboardingCompleted('delivery');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delivery_dining_rounded, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: 10),
                  const Text('GroceryGo Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                ],
              ),
              const Spacer(),

              // Image
              Container(
                height: MediaQuery.of(context).size.height * 0.38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/onboarding_delivery.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white54, size: 80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'Deliver & Earn Flexibly',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'Turn your vehicle into income. Accept nearby orders, follow optimized routes, and earn competitive payouts with daily payouts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
              ),
              const Spacer(),

              // Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start Delivering Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
