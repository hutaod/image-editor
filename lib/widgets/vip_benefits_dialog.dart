import 'package:flutter/material.dart';
import '../services/revenue_cat_service.dart';
import '../l10n/app_localizations.dart';

/// 会员权益弹窗组件
class VipBenefitsDialog extends StatefulWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onRestore;
  final RevenueCatService? revenueCatService;
  final String? title;
  final String? description;

  const VipBenefitsDialog({
    super.key,
    this.onUpgrade,
    this.onRestore,
    this.revenueCatService,
    this.title,
    this.description,
  });

  @override
  State<VipBenefitsDialog> createState() => _VipBenefitsDialogState();
}

class _VipBenefitsDialogState extends State<VipBenefitsDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title ?? l10n.vipDialogTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 描述信息
              if (widget.description != null) ...[
                Text(
                  widget.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 会员特权
              _buildBenefitItem(
                context,
                Icons.visibility_off,
                l10n.unlimitedHideEventsTitle,
                l10n.unlimitedHideEventsDesc,
              ),

              const SizedBox(height: 24),

              // 操作按钮
              Row(
                children: [
                  if (widget.onRestore != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onRestore,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          l10n.restorePurchases,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        l10n.upgradeNow,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
