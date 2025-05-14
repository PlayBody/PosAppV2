import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/interface/style/textstyles.dart';

class CheckNomal extends StatelessWidget {
  final String label;
  final double? scale;
  final bool value;
  final Function(bool?)? tapFunc;
  const CheckNomal({
    required this.label,
    required this.value,
    this.scale,
    this.tapFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Color(0xffbebebe), // Your color
          ),
          child: Transform.scale(
            scale: scale == null ? 1 : scale!,
            child: Checkbox(
              activeColor: Color(0xff117fc1),
              value: value,
              splashRadius: 3,
              onChanged: tapFunc,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(left: 8),
          child: Text(label, style: bodyTextStyle),
        ),
      ],
    );
  }
}
