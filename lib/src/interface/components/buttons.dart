import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/functions/datetimes.dart';

var btnTxtStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

var btnTxtStyle1 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  letterSpacing: -1,
);

//----degine complete ----------
class PrimaryButton extends StatelessWidget {
  final String label;
  final Function()? tapFunc;
  const PrimaryButton({required this.label, required this.tapFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff117fc1),
          foregroundColor: Colors.white,
        ),
        onPressed: tapFunc,
        child: Text(label, style: btnTxtStyle),
      ),
    );
  }
}

class PrimaryColButton extends StatelessWidget {
  final String label;
  final Function()? tapFunc;
  const PrimaryColButton({
    required this.label,
    required this.tapFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff117fc1),
        foregroundColor: Colors.white,
      ),
      onPressed: tapFunc,
      child: Text(label, style: btnTxtStyle1),
    );
  }
}

class CancelButton extends StatelessWidget {
  final String label;
  final Function() tapFunc;
  const CancelButton({required this.label, required this.tapFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff868686),
          foregroundColor: Colors.white,
        ),
        onPressed: tapFunc,
        child: Text(label, style: btnTxtStyle),
      ),
    );
  }
}

class CancelColButton extends StatelessWidget {
  final String label;
  final Function() tapFunc;
  const CancelColButton({
    required this.label,
    required this.tapFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff868686),
        foregroundColor: Colors.white,
      ),
      onPressed: tapFunc,
      child: Text(label, style: btnTxtStyle1),
    );
  }
}

class DeleteButton extends StatelessWidget {
  final String label;
  final Function()? tapFunc;
  const DeleteButton({required this.label, required this.tapFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xffee385a),
          foregroundColor: Colors.white,
        ),
        onPressed: tapFunc,
        child: Text(label, style: btnTxtStyle),
      ),
    );
  }
}

class DeleteColButton extends StatelessWidget {
  final String label;
  final Function()? tapFunc;
  const DeleteColButton({
    required this.label,
    required this.tapFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xffee385a),
        foregroundColor: Colors.white,
      ),
      onPressed: tapFunc,
      child: Text(label, style: btnTxtStyle1),
    );
  }
}

class WhiteButton extends StatelessWidget {
  final String label;
  final Icon? icon;
  final GestureTapCallback? tapFunc;
  const WhiteButton({required this.label, this.icon, this.tapFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xffe3e3e3),
        foregroundColor: const Color(0xff454545),
      ),
      onPressed: tapFunc,
      child:
          icon == null
              ? Text(label, style: btnTxtStyle)
              : Row(children: [icon!, Text(label, style: btnTxtStyle)]),
    );
  }
}

class LabelButton extends StatelessWidget {
  final String label;
  final Function()? tapFunc;
  final Color? color;
  const LabelButton({required this.label, this.tapFunc, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Color(0xffe3e3e3),
        foregroundColor: color == null ? Color(0xff454545) : Colors.white,
        padding: EdgeInsets.all(0),
        visualDensity: VisualDensity(vertical: -3),
      ),
      onPressed: tapFunc,
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class IconWhiteButton extends StatelessWidget {
  final IconData icon;
  final Color? backColor;
  final Color? color;
  final Function() tapFunc;
  const IconWhiteButton({
    required this.icon,
    required this.tapFunc,
    this.color,
    this.backColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backColor ?? const Color(0xffe3e3e3),
        foregroundColor: const Color(0xff454545),
        padding: EdgeInsets.all(0),
        visualDensity: VisualDensity(vertical: -3),
      ),
      onPressed: tapFunc,
      child: Icon(icon, color: color ?? Colors.grey, size: 18),
    );
  }
}

class FullScreenButton extends StatelessWidget {
  final IconData icon;
  final Function() tapFunc;
  const FullScreenButton({
    required this.icon,
    required this.tapFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tapFunc,
      child: Icon(icon, color: Colors.grey, size: 32),
    );
  }
}

class DatepickerIconBtn extends StatelessWidget {
  final Function() tapFunc;
  const DatepickerIconBtn({required this.tapFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tapFunc,
      child: Icon(Icons.calendar_today_sharp, color: Colors.blue, size: 20),
    );
  }
}

class PosDatepicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function() tapFunc;
  const PosDatepicker({
    required this.selectedDate,
    required this.tapFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          DateTimes().convertJPYMDFromDateTime(selectedDate, isFull: true),
          style: TextStyle(fontSize: 16),
        ),
        DatepickerIconBtn(tapFunc: tapFunc),
      ],
    );
  }
}
