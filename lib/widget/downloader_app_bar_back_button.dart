import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloaderAppBarBackButton extends StatelessWidget {
  const DownloaderAppBarBackButton({
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_back_rounded,
    this.tooltip = '返回',
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  static const double leadingWidth = 56;
  static const double buttonSize = 44;
  static const double iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Center(
        child: IconButton(
          onPressed: onPressed ?? () => Get.back(),
          tooltip: tooltip,
          style: IconButton.styleFrom(
            foregroundColor: scheme.onSurface,
            backgroundColor: scheme.surfaceContainerHighest,
            minimumSize: const Size(buttonSize, buttonSize),
            maximumSize: const Size(buttonSize, buttonSize),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          icon: Icon(icon, size: iconSize, color: scheme.onSurface),
        ),
      ),
    );
  }
}
