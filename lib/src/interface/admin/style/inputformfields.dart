import 'package:flutter/material.dart';

typedef StringCallback = void Function(String val);

class AdminInputFormField extends StatelessWidget {
  final String? hintText;
  final int? maxLine;
  final String? errorText;
  final TextEditingController? txtController;

  final StringCallback? callback;

  const AdminInputFormField({
    this.hintText,
    this.maxLine,
    this.errorText,
    this.txtController,
    this.callback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: txtController,
      decoration: InputDecoration(
        errorText: errorText,
        hintText: hintText,
        contentPadding: EdgeInsets.fromLTRB(20, 5, 20, 5),
        filled: true,
        hintStyle: TextStyle(color: Colors.grey),
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      maxLines: maxLine ?? 1,
      onChanged:
          callback == null
              ? null
              : (v) {
                callback!(v);
              },
    );
  }
}
