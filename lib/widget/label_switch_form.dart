import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LabelSwitchForm extends FormField<bool> {
  final String? title;
  final String? moreButtonTitle;
  final bool required;
  final bool? value;
  final void Function(bool)? onChanged;

  LabelSwitchForm({
    super.key,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    this.moreButtonTitle,
    this.title,
    this.required = false,
    this.value,
    this.onChanged,
    bool? initialValue,
  }) : super(
         initialValue: value ?? initialValue ?? false,
         validator: (v) {
           if (required && (v ?? false) == false) {
             return '${title ?? ''}不能为空';
           }
           return null;
         },
         builder: (FormFieldState<bool> state) {
           return Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: Row(
               crossAxisAlignment: CrossAxisAlignment.center,
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
                       Padding(
                         padding: const EdgeInsets.only(left: 4.0),
                         child: Text(
                           '*',
                           style: TextStyle(
                             color: CupertinoColors.destructiveRed,
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                   ],
                 ),
                 Spacer(),
                 CupertinoSwitch(
                   value: state.value ?? false,
                   activeColor: Get.theme.colorScheme.primary,
                   onChanged: state.widget.enabled
                       ? (v) {
                           state.didChange(v);
                           onChanged?.call(v);
                           HapticFeedback.lightImpact();
                         }
                       : null,
                 ),
               ],
             ),
           );
         },
       );
}
