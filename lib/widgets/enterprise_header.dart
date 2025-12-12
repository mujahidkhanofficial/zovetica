import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class EnterpriseHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final Widget? flexibleContent;
  final bool pinned;
  final bool floating;
  final PreferredSizeWidget? bottom;

  const EnterpriseHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.expandedHeight = 120.0,
    this.flexibleContent,
    this.pinned = true,
    this.floating = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: leading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
          child: SafeArea(
            bottom: false, // Don't add bottom padding
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (actions != null) const SizedBox(height: 40), // Space for actions row
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(230),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (flexibleContent != null) ...[
                    const SizedBox(height: 16),
                    flexibleContent!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
