import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as custom_picker;

class PosTimePicker extends StatelessWidget {
  final String date;
  final Function(DateTime)? confFunc;
  const PosTimePicker({required this.date, required this.confFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: <Widget>[
          // height: 60.0,
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
            ),
            onPressed: () {
              DatePicker.showTimePicker(
                context,
                theme: custom_picker.DatePickerTheme(
                  backgroundColor: Colors.black,
                  itemStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  cancelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  doneStyle: TextStyle(
                    color: Colors.blue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  containerHeight: 320.0,
                  titleHeight: 62,
                ),
                locale: LocaleType.jp,
                showSecondsColumn: false,
                showTitleActions: true,
                onConfirm: confFunc,
                currentTime: DateTime.parse('2000-01-01 $date'),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    date,
                    style: TextStyle(color: Colors.black, fontSize: 17.0),
                  ),
                ],
              ),
            ),
            // color: Colors.white,
          ),

          // datetime()
        ],
      ),
    );
  }
}

class PosTimeRange extends StatelessWidget {
  final String selectDate;
  final String fromTime;
  final String toTime;
  final dynamic confFromFunc;
  final dynamic confToFunc;
  const PosTimeRange({
    required this.selectDate,
    required this.fromTime,
    required this.toTime,
    required this.confFromFunc,
    required this.confToFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container()),
        PosTimePicker(date: fromTime, confFunc: confFromFunc),
        SizedBox(width: 4, child: Text('~')),
        PosTimePicker(date: toTime, confFunc: confToFunc),
        Expanded(child: Container()),
      ],
    );
  }
}
