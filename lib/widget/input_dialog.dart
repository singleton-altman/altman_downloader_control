import 'package:flutter/material.dart';

/// 美化的对话框组件
/// 用于替换原生 AlertDialog，提供更现代的设计风格
class MSDialog extends StatelessWidget {
  const MSDialog({
    super.key,
    this.title,
    this.titleIcon,
    this.content,
    this.actions,
    this.maxWidth = 400,
  });

  final String? title;
  final IconData? titleIcon;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            if (title != null || titleIcon != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          titleIcon,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // 内容区域
            if (content != null)
              Flexible(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    title != null ? 16 : 24,
                    24,
                    actions != null && actions!.isNotEmpty ? 16 : 24,
                  ),
                  child: content!,
                ),
              ),

            // 操作按钮区域
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...actions!.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: action,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 美化的确认对话框
class MSConfirmDialog extends StatelessWidget {
  const MSConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.confirmColor,
    this.icon,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColorFinal =
        confirmColor ??
        (isDestructive ? theme.colorScheme.error : theme.colorScheme.primary);

    return MSDialog(
      title: title,
      titleIcon: icon,
      content: isDestructive
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
      actions: [
        _MSDialogButton(
          text: cancelText,
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          style: _MSDialogButtonStyle.secondary,
        ),
        _MSDialogButton(
          text: confirmText,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: _MSDialogButtonStyle.primary,
          color: confirmColorFinal,
        ),
      ],
    );
  }
}

/// 美化的输入对话框
class MSInputDialog extends StatefulWidget {
  const MSInputDialog({
    super.key,
    required this.title,
    this.hintText,
    this.labelText,
    this.initialValue,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.icon,
    this.onConfirm,
    this.onCancel,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = true,
  });

  final String title;
  final String? hintText;
  final String? labelText;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final ValueChanged<String>? onConfirm;
  final VoidCallback? onCancel;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;

  @override
  State<MSInputDialog> createState() => _MSInputDialogState();
}

class _MSInputDialogState extends State<MSInputDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_validateInput);
    _isValid = widget.initialValue?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isValid) {
        setState(() {
          _isValid = true;
        });
      }
    } else {
      if (_isValid) {
        setState(() {
          _isValid = false;
        });
      }
    }
  }

  void _handleConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text);
      widget.onConfirm?.call(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MSDialog(
      title: widget.title,
      titleIcon: widget.icon,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              controller: _controller,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: widget.validator,
            ),
          ],
        ),
      ),
      actions: [
        _MSDialogButton(
          text: widget.cancelText,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel?.call();
          },
          style: _MSDialogButtonStyle.secondary,
        ),
        _MSDialogButton(
          text: widget.confirmText,
          onPressed: _isValid ? _handleConfirm : null,
          style: _MSDialogButtonStyle.primary,
        ),
      ],
    );
  }
}

/// 对话框按钮样式
enum _MSDialogButtonStyle { primary, secondary }

/// 美化的对话框按钮
class _MSDialogButton extends StatelessWidget {
  const _MSDialogButton({
    required this.text,
    required this.onPressed,
    required this.style,
    this.color,
  });

  final String text;
  final VoidCallback? onPressed;
  final _MSDialogButtonStyle style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = style == _MSDialogButtonStyle.primary;
    final buttonColor = color ?? theme.colorScheme.primary;

    if (isPrimary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: onPressed != null ? buttonColor : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      );
    }
  }
}

/// 显示美化的确认对话框
Future<bool?> showMSConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确认',
  String cancelText = '取消',
  Color? confirmColor,
  IconData? icon,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => MSConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      icon: icon,
      isDestructive: isDestructive,
    ),
  );
}

/// 显示美化的输入对话框
Future<String?> showMSInputDialog(
  BuildContext context, {
  required String title,
  String? hintText,
  String? labelText,
  String? initialValue,
  String confirmText = '确定',
  String cancelText = '取消',
  IconData? icon,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool autofocus = true,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => MSInputDialog(
      title: title,
      hintText: hintText,
      labelText: labelText,
      initialValue: initialValue,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
    ),
  );
}
