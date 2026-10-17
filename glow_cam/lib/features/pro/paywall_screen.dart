import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/theme.dart';
import 'pro_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  /// Opens the paywall; resolves to true if the user is Pro afterwards.
  static Future<bool> show(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const PaywallScreen()),
    );
    return context.mounted && ProScope.of(context).isPro;
  }

  @override
  Widget build(BuildContext context) {
    final pro = ProScope.of(context);
    if (pro.isPro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.workspace_premium, size: 72, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'GlowCam Pro',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'كل الفلاتر والخلفيات الاحترافية بدون حدود',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 28),
                const _Perk(icon: Icons.auto_awesome, text: 'فلاتر احترافية: كريمي، وردي، سينمائي، نيون، إشراقة…'),
                const _Perk(icon: Icons.wallpaper, text: 'خلفيات استوديو ومتدرجة وخلفية من صورك'),
                const _Perk(icon: Icons.face_retouching_natural, text: 'تجميل البشرة والإضاءة بجودة عالية'),
                const _Perk(icon: Icons.hd, text: 'حفظ بأعلى دقة بدون علامة مائية'),
                const Spacer(),
                if (pro.loading)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else if (!pro.storeAvailable || pro.products.isEmpty)
                  const Text(
                    'المتجر غير متاح حالياً. تأكد من اتصالك بالإنترنت وحسابك في المتجر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  )
                else
                  for (final p in pro.products) _PlanButton(product: p, busy: pro.purchasing),
                if (pro.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(pro.error!,
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.yellowAccent)),
                  ),
                TextButton(
                  onPressed: pro.storeAvailable ? pro.restore : null,
                  child: const Text('استعادة المشتريات', style: TextStyle(color: Colors.white)),
                ),
                if (kDebugMode)
                  TextButton(
                    onPressed: pro.debugUnlock,
                    child: const Text('تفعيل تجريبي (وضع التطوير فقط)',
                        style: TextStyle(color: Colors.white54)),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
          ],
        ),
      );
}

class _PlanButton extends StatelessWidget {
  const _PlanButton({required this.product, required this.busy});
  final ProductDetails product;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final yearly = product.id == ProService.yearlyId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: yearly ? Colors.white : Colors.white24,
          foregroundColor: yearly ? AppTheme.brand : Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: busy ? null : () => ProScope.of(context).buy(product),
        child: Text(
          '${yearly ? 'سنوي (الأوفر)' : 'شهري'} — ${product.price}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
