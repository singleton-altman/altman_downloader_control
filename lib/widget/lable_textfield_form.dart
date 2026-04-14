import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LabelTextFieldForm extends FormField<String> {
  final String? title;
  final String? moreButtonTitle;
  final bool required;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final String? hintText;
  final String? tip;
  final FocusNode? focusNode;
  final String? Function(String?)? validator1;
  final void Function(String)? errorCallback;
  final List<TextInputFormatter>? inputFormatters;
  final TipPosition tipPosition;
  final void Function(String?)? onChanged;
  final VoidCallback? onTapMore;
  final Widget? suffixIcon;
  final Widget? headerTrailing;
  LabelTextFieldForm({
    super.key,
    super.initialValue,
    this.validator1,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    this.moreButtonTitle,
    this.onTapMore,
    this.title,
    this.required = false,
    this.controller,
    this.textInputAction,
    this.maxLines = 1,
    this.obscureText = false,
    this.hintText,
    this.tip,
    this.keyboardType,
    this.focusNode,
    this.errorCallback,
    this.inputFormatters,
    this.tipPosition = TipPosition.bottom,
    this.onChanged,
    this.suffixIcon,
    this.headerTrailing,
  }) : super(
         builder: (FormFieldState<String> state) {
           return Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Row(
                   children: [
                     Text(
                       title ?? '',
                       style: Get.textTheme.bodyLarge?.copyWith(
                         fontSize: 15,
                         fontWeight: FontWeight.w500,
                         color: Get.theme.colorScheme.onSurface,
                       ),
                     ),
                     if (required)
                       Text(
                         '*',
                         style: TextStyle(
                           color: CupertinoColors.destructiveRed,
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                         ),
                       ),

                     //  Padding(
                     //    padding: const EdgeInsets.only(left: 8.0),
                     //    child: Tooltip(
                     //      message: tip ?? title,
                     //      enableFeedback: true,
                     //      triggerMode: TooltipTriggerMode.tap,
                     //      margin: const EdgeInsets.symmetric(horizontal: 30),
                     //      decoration: BoxDecoration(
                     //        color: Colors.black87,
                     //        borderRadius: BorderRadius.circular(8),
                     //      ),
                     //      child: Container(
                     //        padding: const EdgeInsets.all(4),
                     //        decoration: BoxDecoration(
                     //          color: Get.theme.colorScheme.primary.withValues(
                     //            alpha: 0.1,
                     //          ),
                     //          borderRadius: BorderRadius.circular(12),
                     //        ),
                     //        child: Icon(
                     //          Icons.info_outline,
                     //          color: Get.theme.colorScheme.primary,
                     //          size: 16,
                     //        ),
                     //      ),
                     //    ),
                     //  ),
                     Spacer(),
                     headerTrailing ?? SizedBox.shrink(),
                   ],
                 ),
                 const SizedBox(height: 12),
                 TextFormField(
                   style: Get.textTheme.bodyMedium?.copyWith(
                     fontSize: 15,
                     color: Get.theme.colorScheme.onSurface,
                   ),
                   initialValue: initialValue,
                   controller: controller,
                   focusNode: focusNode,
                   enabled: enabled,
                   textInputAction: textInputAction,
                   keyboardType: keyboardType,
                   inputFormatters: inputFormatters,
                   maxLines: maxLines,
                   obscureText: obscureText,
                   textAlignVertical: TextAlignVertical.center,
                   decoration: InputDecoration(
                     isCollapsed: false,
                     isDense: true,
                     filled: true,
                     fillColor: enabled
                         ? (state.hasError
                               ? CupertinoColors.destructiveRed.withValues(
                                   alpha: 0.05,
                                 )
                               : Get.theme.colorScheme.surfaceContainer
                                     .withValues(alpha: 0.3))
                         : Get.theme.colorScheme.surfaceContainer.withValues(
                             alpha: 0.1,
                           ),
                     errorText: state.hasError ? state.errorText : null,
                     errorStyle: TextStyle(
                       color: CupertinoColors.destructiveRed,
                       fontSize: 12,
                       fontWeight: FontWeight.w500,
                     ),
                     border: state.hasError
                         ? OutlineInputBorder(
                             borderSide: BorderSide(
                               color: CupertinoColors.destructiveRed.withValues(
                                 alpha: 0.3,
                               ),
                               width: 1.5,
                             ),
                             borderRadius: BorderRadius.circular(12),
                           )
                         : null,
                     focusedBorder: OutlineInputBorder(
                       borderSide: BorderSide(
                         color: Get.theme.colorScheme.primary,
                         width: 1,
                       ),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     enabledBorder: OutlineInputBorder(
                       borderSide: BorderSide(
                         color: CupertinoColors.systemGrey4.withValues(
                           alpha: 0.5,
                         ),
                         width: 1,
                       ),
                       borderRadius: BorderRadius.circular(12),
                     ),

                     disabledBorder: OutlineInputBorder(
                       borderSide: BorderSide(
                         color: Get.theme.colorScheme.outline.withValues(
                           alpha: 0.2,
                         ),
                         width: 1,
                       ),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     hintText: hintText,
                     hintStyle: Get.textTheme.bodyMedium?.copyWith(
                       color: Get.theme.colorScheme.onSurfaceVariant.withValues(
                         alpha: 0.6,
                       ),
                       fontSize: 15,
                     ),
                     contentPadding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 16,
                     ),
                     suffixIcon: suffixIcon,
                     prefixIcon: required && (controller?.text ?? '').isEmpty
                         ? Container(
                             margin: const EdgeInsets.only(left: 8),
                             child: Icon(
                               Icons.new_releases_outlined,
                               color: CupertinoColors.destructiveRed.withValues(
                                 alpha: 0.7,
                               ),
                               size: 16,
                             ),
                           )
                         : null,
                   ),
                   onChanged: (value) {
                     state.didChange(value);
                     if (onChanged != null) {
                       onChanged(value);
                     }
                   },
                   onTap: () {
                     // 添加点击反馈
                     if (enabled) {
                       HapticFeedback.lightImpact();
                     }
                   },
                 ),
                 if (state.hasError) ...[
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 12,
                       vertical: 8,
                     ),
                     decoration: BoxDecoration(
                       color: CupertinoColors.destructiveRed.withValues(
                         alpha: 0.1,
                       ),
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(
                         color: CupertinoColors.destructiveRed.withValues(
                           alpha: 0.2,
                         ),
                         width: 1,
                       ),
                     ),
                     child: Row(
                       children: [
                         Icon(
                           Icons.error_outline,
                           color: CupertinoColors.destructiveRed,
                           size: 16,
                         ),
                         const SizedBox(width: 8),
                         Expanded(
                           child: Text(
                             state.errorText ?? '',
                             style: TextStyle(
                               color: CupertinoColors.destructiveRed,
                               fontSize: 12,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],
                 const SizedBox(height: 4),
               ],
             ),
           );
         },
         validator: (value) {
           String? errorText;
           if (required && validator1 == null) {
             if (controller != null) {
               value = controller.text;
             }
             if (value?.isEmpty ?? true) {
               errorText = '${title ?? ''}不能为空';
             }
           }
           if (validator1 != null) {
             errorText = validator1(value);
           }
           if (errorText != null && errorCallback != null) {
             errorCallback(errorText);
           }
           return errorText;
         },
       );
}

enum TipPosition { top, bottom }
