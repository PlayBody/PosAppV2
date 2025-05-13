// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/business/shift.dart';
import 'package:staff_pos_app/src/common/business/shift_frame.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions/shifts.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/interface/components/texts.dart';
import 'package:staff_pos_app/src/interface/pos/manage/shifts/shift_frame_edit.dart';
import 'package:staff_pos_app/src/interface/style/style_const.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';
import 'package:staff_pos_app/src/model/shift_frame_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/globals.dart' as globals;

class ShiftFrame extends StatefulWidget {
  const ShiftFrame({Key? key}) : super(key: key);

  @override
  State<ShiftFrame> createState() => _ShiftFrame();
}

class _ShiftFrame extends State<ShiftFrame> {
  late Future<List> loadData;
  String orderAmount = '';
  String dateYearValue = '2020';
  String dateMonthValue = '5';
  DateTime selectedDate = DateTime.now();

  List<TimeRegion> regions = <TimeRegion>[];
  List<Appointment> appointments = <Appointment>[];
  List<OrganModel> organList = [];

  String _fromDate = '';
  String _toDate = '';
  String? selOrganId;
  OrganModel? selOrgan;

  Color shiftColor = Colors.white;
  String shiftText = '';

  List<TimeRegion> selectRegions = <TimeRegion>[];

  int positionCount = 0;
  double selColor = 15;

  bool isHideBannerBar = false;
  int viewFromHour = 11;
  int viewToHour = 20;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    loadData = loadShiftData();
  }

  Future<List> loadShiftData() async {
    organList = await ClOrgan()
        .loadOrganList(context, globals.companyId, globals.staffId);
        
    selOrganId ??= globals.workOrganId;
    
    if (selOrganId == null && organList.isNotEmpty) {
      selOrganId = organList.first.organId;
    }
    if (selOrganId == null) return [];
    selOrgan = await ClOrgan().loadOrganInfo(context, selOrganId!);
    positionCount = selOrgan!.tableCount;

    _fromDate = DateFormat('yyyy-MM-dd').format(getDate(
        selectedDate.subtract(Duration(days: (selectedDate.weekday - 1)))));
    _toDate = DateFormat('yyyy-MM-dd').format(selectedDate
        .add(Duration(days: DateTime.daysPerWeek - selectedDate.weekday)));

    List<ShiftFrameModel> shiftFrames = await ClShiftFrame().loadShiftFrame(
        context, selOrganId!, _fromDate, _toDate);
        
    appointments = [];
    for (var item in shiftFrames) {
      appointments.add(Appointment(
        startTime: item.fromTime,
        endTime: item.toTime,
        subject: item.count.toString(),
        color:
            Color(FuncShifts().getLevelColorValue(item.count, positionCount)),
        startTimeZone: '',
        endTimeZone: '',
      ));
    }

    regions = [];
    if (!DateTime.parse('$_toDate 23:59:59').isBefore(DateTime.now())) {
      regions = await ClShift()
          .loadActiveShiftRegions(context, selOrganId!, _fromDate);
    }

    if (regions.isNotEmpty) {
      viewFromHour = 23;
      viewToHour = 0;
      for (var element in regions) {
        if (viewFromHour > element.startTime.hour) {
          viewFromHour = element.startTime.hour;
        }
        if (viewToHour < element.endTime.hour) {
          viewToHour = element.endTime.hour;
        }
      }
      // viewFromHour--;
      viewToHour++;
    }
    // if(viewFromHour < 0) viewFromHour++;
    if (viewToHour >= 24) viewToHour = 24;
    setState(() {});
    return regions;
  }

  Future<void> setCountShift(dateString) async {
    if (selOrgan == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return ShiftFrameEdit(
        selMax: positionCount,
        organ: selOrgan!,
        selection: dateString,
      );
    })).then((value) => setState(() {
          loadData = loadShiftData();
        }));
  }

  void changeViewCalander(date) {
    String cFromDate = DateFormat('yyyy-MM-dd')
        .format(getDate(date.subtract(Duration(days: date.weekday - 1))));

    if (cFromDate == _fromDate) return;

    selectedDate = date;
    loadData = loadShiftData();

    setState(() {});
  }

  Future<void> copyShiftCount() async {
    if (selOrganId == null) return;
    bool conf = await Dialogs().confirmDialog(context, 'シフト枠をコピーしますか？');
    if (!conf) return;

    Dialogs().loaderDialogNormal(context);
    bool isCopyComplete = await ClShiftFrame().copyShiftFrames(
        context,
        selOrganId!,
        _fromDate,
        _toDate);

    if (isCopyComplete) {
      await loadShiftData();
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      Dialogs().infoDialog(context, errServerActionFail);
    }
  }

  DateTime getDate(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    globals.appTitle = 'シフト枠設定';
    return MainBodyWdiget(
        fullScreenButton: Column(children: [
          FullScreenButton(
            icon: isHideBannerBar ? Icons.fullscreen_exit : Icons.fullscreen,
            tapFunc: () {
              isHideBannerBar = !isHideBannerBar;
              setState(() {});
            },
          )
        ]),
        isFullScreen: isHideBannerBar,
        render: FutureBuilder<List>(
          future: loadData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                color: bodyColor,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Column(
                  children: [
                    _getOrganDropDown(),
                    Expanded(child: _getCalendar())
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show a loading spinner.
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ));
  }

  var organLabelTextStyle =
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  Widget _getOrganDropDown() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 5, right: 10),
      child: Row(children: [
        const SizedBox(width: 16),
        const InputLeftText(label: '店名', rPadding: 8, width: 60),
        Expanded(
          child: DropDownModelSelect(
            value: selOrganId,
            items: [
              ...organList.map((e) =>
                  DropdownMenuItem(child: Text(e.organName), value: e.organId))
            ],
            tapFunc: (v) {
              selOrganId = v!.toString();
              loadShiftData();
              setState(() {});
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 5),
          child: PrimaryColButton(
            label: '前週コピー',
            tapFunc:
                DateTime.parse('$_toDate 23:59:59').isBefore(DateTime.now())
                    ? null
                    : () => copyShiftCount(),
          ),
        ),
      ]),
    );
  }

  Widget _getCalendar() {
    return SfCalendar(
      firstDayOfWeek: 1,
      view: CalendarView.week,
      cellBorderColor: timeSlotCellBorderColor,
      selectionDecoration: timeSlotSelectDecoration,
      timeSlotViewSettings: TimeSlotViewSettings(
          startHour: viewFromHour.toDouble(),
          endHour: viewToHour.toDouble(),
          timeIntervalHeight: timeSlotCellHeight.toDouble(),
          dayFormat: 'EEE',
          timeInterval: const Duration(minutes: 15),
          timeFormat: 'H:mm',
          timeTextStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.black.withOpacity(0.5),
          )),
      appointmentTextStyle: apppointmentsTextStyle,
      specialRegions: regions,
      dataSource: _AppointmentDataSource(appointments),
      onLongPress: (d) => setCountShift(d.date),
      onViewChanged: (d) => changeViewCalander(d.visibleDates[1]),
    );
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
