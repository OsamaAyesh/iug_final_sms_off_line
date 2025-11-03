import 'package:app_mobile/core/resources/manager_icon_size.dart';
import 'package:flutter/material.dart';
import '../resources/manager_colors.dart';
import '../resources/manager_font_size.dart';
import '../resources/manager_height.dart';
import '../resources/manager_opacity.dart';
import '../resources/manager_radius.dart';
import '../resources/manager_styles.dart';
import '../resources/manager_width.dart';

class CustomAnimatedTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isPhoneNumber;
  final String? hintText;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;

  const CustomAnimatedTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isPhoneNumber = false,
    this.hintText,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<CustomAnimatedTextField> createState() => _CustomAnimatedTextFieldState();
}

class _CustomAnimatedTextFieldState extends State<CustomAnimatedTextField> {
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;
  bool obscurePassword = true;

  final List<Map<String, String>> countries = [
    {'flag': '🇵🇸', 'code': '+970', 'name': 'فلسطين'},
    {'flag': '🇮🇱', 'code': '+972', 'name': 'إسرائيل'},
  ];

  late Map<String, String> selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0];
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() => isFocused = _focusNode.hasFocus);
  }

  void _showCountrySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: countries.map((country) {
            return ListTile(
              leading: Text(country["flag"]!, style: const TextStyle(fontSize: 24)),
              title: Text(
                country["name"]!,
                style: getMediumTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: ManagerColors.black,
                ),
              ),
              trailing: Text(
                country["code"]!,
                style: getMediumTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: ManagerColors.primaryColor,
                ),
              ),
              onTap: () {
                setState(() => selectedCountry = country);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool shouldExpand = isFocused;
    bool hasText = widget.controller?.text.isNotEmpty ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
      width: double.infinity,
      height: shouldExpand ? ManagerHeight.h80 : ManagerHeight.h56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ManagerRadius.r6),
        color: ManagerColors.transparent,
        border: Border.all(
          color: isFocused
              ? ManagerColors.primaryColor.withOpacity(0.7)
              : ManagerColors.greyWithColor.withOpacity(ManagerOpacity.op0_3),
        ),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          if (isFocused || (!isFocused && !hasText))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: ManagerWidth.w4,
              top: shouldExpand
                  ? ManagerHeight.h4
                  : (ManagerHeight.h44 / 2) - (ManagerFontSize.s14 / 2),
              child: Text(
                widget.label,
                style: getRegularTextStyle(
                  fontSize: shouldExpand ? ManagerFontSize.s12 : ManagerFontSize.s14,
                  color: isFocused
                      ? ManagerColors.primaryColor
                      :widget.isPhoneNumber?ManagerColors.white: ManagerColors.greyWithColor,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.only(top: isFocused ? ManagerHeight.h14 : 0),
            child: Row(
              // textDirection: TextDirection.rtl,
              children: [
                /// إذا الحقل Phone Number
                if (widget.isPhoneNumber)
                  GestureDetector(
                    onTap: _showCountrySelector,
                    child: Row(
                      children: [
                        Text(selectedCountry["flag"]!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 4),
                        Text(
                          selectedCountry["code"]!,
                          style: getMediumTextStyle(
                            fontSize: ManagerFontSize.s14,
                            color: ManagerColors.black,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: Colors.grey),
                        SizedBox(width: ManagerWidth.w8),
                      ],
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode ?? _focusNode,
                    textAlign: TextAlign.right,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.isPassword ? obscurePassword : false,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: ManagerColors.black,
                    ),
                    cursorColor: ManagerColors.primaryColor,
                    onSubmitted: (_) {
                      if (widget.nextFocusNode != null) {
                        FocusScope.of(context)
                            .requestFocus(widget.nextFocusNode);
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),



                /// إذا Password
                if (widget.isPassword)
                  GestureDetector(
                    onTap: () => setState(() => obscurePassword = !obscurePassword),
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: ManagerWidth.w8, top: ManagerHeight.h4),
                      child: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: ManagerColors.greyWithColor,
                        size: ManagerIconSize.s16,
                      ),
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
