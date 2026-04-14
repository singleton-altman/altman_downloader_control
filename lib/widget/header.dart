import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MSDefaultHeader extends StatelessWidget {
  const MSDefaultHeader({
    super.key,
    this.title,
    this.subTitle,
    this.onTapMore,
    this.titleStyle,
    this.subTitleStyle,
    this.useSectionStyle = false,
    this.showLeadingAccent = true,
    this.accentColor,
    this.showMoreAsIcon = true,
    this.moreText,
    this.padding,
    this.withBackground = false,
    this.showBottomDivider = false,
  });
  final String? title;
  final String? subTitle;
  final VoidCallback? onTapMore;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final bool useSectionStyle;
  final bool showLeadingAccent;
  final Color? accentColor;
  final bool showMoreAsIcon;
  final String? moreText;
  final EdgeInsets? padding;
  final bool withBackground;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final bool isSection = useSectionStyle;
    final EdgeInsets contentPadding =
        padding ??
        (isSection
            ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0));
    final Color accent = accentColor ?? Theme.of(context).colorScheme.primary;

    final Color? bgColor = withBackground
        ? Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3)
        : null;

    final Widget row = Row(
      children: [
        if (showLeadingAccent)
          Container(
            width: 3,
            height: 18,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        if (title != null)
          Expanded(
            child: Text(
              title!,
              style:
                  titleStyle ??
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        if (subTitle != null)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Text(
              subTitle!,
              style:
                  subTitleStyle ??
                  Get.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        if (onTapMore != null)
          (showMoreAsIcon
              ? TextButton.icon(
                  onPressed: onTapMore,
                  icon: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    moreText ?? '更多',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: onTapMore,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    moreText ?? '查看更多',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
      ],
    );

    return Container(
      padding: contentPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: withBackground ? BorderRadius.circular(10) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          if (showBottomDivider)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Divider(
                height: 1,
                thickness: 0.3,
                color: Theme.of(
                  context,
                ).dividerColor.withValues(alpha: withBackground ? 0.4 : 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
