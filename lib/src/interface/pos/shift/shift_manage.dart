import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_pos_app/src/common/business/company.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/business/shift.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions/datetimes.dart';
import 'package:staff_pos_app/src/common/functions/shift_auto.dart';
import 'package:staff_pos_app/src/common/functions/shifts.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/form_widgets.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/interface/components/texts.dart';
import 'package:staff_pos_app/src/interface/pos/shift/shift_detail.dart';
import 'package:staff_pos_app/src/interface/style/style_const.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';
import 'package:staff_pos_app/src/model/shift_manage_model.dart';
import 'package:staff_pos_app/src/model/shift_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'dart:math';

import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/globals.dart' as globals;

import '../../../common/business/epark.dart';

class ShiftManage extends StatefulWidget {
  final String initOrgan;
  final DateTime initDate;
  const ShiftManage({required this.initOrgan, required this.initDate, super.key});

  @override
  State<ShiftManage> createState() => _ShiftManage();
}

class _ShiftManage extends State<ShiftManage> {
  late Future<List> loadData;
  bool isHideBannerBar = false;
  int viewFromHour = 0;
  int viewToHour = 24;
  int showTimeDuring = 15;

  String? selOrganId;
  List<OrganModel> organList = [];
  List<ShiftManageModel> datas = [];
  List<Appointment> appointments = <Appointment>[];

  DateTime? fromDetail;
  DateTime? toDetail;

  String showFromDate = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)));
  String showToDate = DateFormat('yyyy-MM-dd').format(DateTime.now()
      .add(Duration(days: DateTime.daysPerWeek - DateTime.now().weekday)));
  bool isLock = false;
  bool isSyncEpark = false;

  @override
  void initState() {
    super.initState();
    selOrganId = widget.initOrgan;

    showFromDate = DateFormat('yyyy-MM-dd').format(
        widget.initDate.subtract(Duration(days: widget.initDate.weekday - 1)));
    showToDate = DateFormat('yyyy-MM-dd').format(widget.initDate
        .add(Duration(days: DateTime.daysPerWeek - widget.initDate.weekday)));

    loadData = loadInitData();
  }

  Future<List> loadInitData() async {
    organList = await ClOrgan().loadOrganList(context, '', globals.staffId);
    selOrganId ??= organList.first.organId;

    datas = await ClShift().loadShiftManage(
        context, selOrganId, '$showFromDate 00:00:00', '$showToDate 23:59:59');

    List<ShiftModel> shifts = await ClShift().loadShifts(context, {
      'organ_id': selOrganId,
      'from_time': '$showFromDate 00:00:00',
      'to_time': '$showToDate 23:59:59',
    });

    isSyncEpark = await ClCompany().isSyncEpark(context, selOrganId, '');

    for (int i = 0; i < datas.length; i++) {
      ShiftManageModel m = datas[i];
      m.shifts.clear();
      m.apply = 0;
      m.shift = 0;

      int stTime = m.fromTime.hour * 60 + m.fromTime.minute;
      int enTime = m.toTime.hour * 60 + m.toTime.minute;
      List<int> signs = List.generate(max(enTime, stTime), (index) => 0);
      for (var s in globals.saveShiftFromAutoControl) {
        if (s.shiftType == constShiftApply ||
            s.shiftType == constShiftMeApply) {
          if(s.fromTime.day == m.fromTime.day){
            int stCheckTime = s.fromTime.hour * 60 + s.fromTime.minute;
            int enCheckTime = s.toTime.hour * 60 + s.toTime.minute;
            for(int cc = max(stCheckTime, stTime); cc < min(enCheckTime, enTime); cc++){
              signs[cc]++;
            }
          }
          // if ((s.fromTime.compareTo(m.fromTime) <= 0 &&
          //         s.toTime.compareTo(m.toTime) >= 0) ||
          //     (s.fromTime.compareTo(m.fromTime) >= 0 &&
          //         s.toTime.compareTo(m.toTime) <= 0)) {
          //   m.apply++;
          // }
        }
      }

      for (int j = 0; j < shifts.length; j++) {
        ShiftModel s = shifts[j];
        // Check is in shiftFromAuto?
        bool bCheck = false;
        for (var k in globals.saveShiftFromAutoControl) {
          if (s.staffId == k.staffId && s.fromTime.day == k.fromTime.day) {
            bCheck = true;
            break;
          }
        }
        if (bCheck) {
          continue;
        }

        if ((s.shiftType == constShiftApply ||
                s.shiftType == constShiftMeApply) &&
            s.fromTime.compareTo(s.toTime) < 0) {

          if(s.fromTime.day == m.fromTime.day){
            int stCheckTime = s.fromTime.hour * 60 + s.fromTime.minute;
            int enCheckTime = s.toTime.hour * 60 + s.toTime.minute;
            for(int cc = max(stCheckTime, stTime); cc < min(enCheckTime, enTime); cc++){
              signs[cc]++;
            }
          }

          // if ((s.fromTime.compareTo(m.fromTime) <= 0 &&
          //         s.toTime.compareTo(m.toTime) >= 0) ||
          //     (s.fromTime.compareTo(m.fromTime) >= 0 &&
          //         s.toTime.compareTo(m.toTime) <= 0)) {
          //   m.apply++;
          // }
        }
      }
      int apply = 1000;
      for(int cc = stTime; cc < enTime; cc++){
        apply = min(signs[cc], apply);
      }
      if(apply == 1000){
        m.apply = 0;
      } else {
        m.apply = apply;
      }
      // if(m.apply > m.count){
      //   m.apply = m.count;
      // }
    }
    
    appointments = FuncShifts().getAppoinsFromManageList(datas);

    var minMaxHour = await ClOrgan().loadOrganShiftMinMaxHour(
        context, selOrganId!, showFromDate, showToDate);

    viewFromHour = int.parse(minMaxHour['start'].toString());
    viewToHour = int.parse(minMaxHour['end'].toString());

    isLock = await ClShift()
        .loadShiftLock(context, selOrganId!, showFromDate, showToDate);

    setState(() {});
    return [];
  }

  Future<void> onChangeCalander(DateTime date) async {
    String from = DateFormat('yyyy-MM-dd')
        .format(date.subtract(Duration(days: date.weekday - 1)));
    String to = DateFormat('yyyy-MM-dd').format(
        date.add(Duration(days: DateTime.daysPerWeek - date.weekday)));
    if (from == showFromDate) return;
    showFromDate = from;
    showToDate = to;

    refreshLoad();
  }

  void loadChangeData() {
    // appointments = FuncShifts().getAppoinsFromManageList(datas);
    refreshLoad();
    // setState(() {});
  }

  void onChangeOrgan(String organId) {
    selOrganId = organId;
    refreshLoad();
  }

  Future<void> onTapSave() async {
    bool isSave = false;

    Dialogs().loaderDialogNormal(context);
    if (globals.saveShiftFromAutoControl.isNotEmpty) {
      int i = 0, j = 0;
      int len = globals.saveShiftFromAutoControl.length;
      for (i = 0; i < len; i++) {
        ShiftModel m1 = globals.saveShiftFromAutoControl[i];
        if ((m1.deleted ?? 0) == 0) {
          continue;
        }
        for (j = i + 1; j < len; j++) {
          ShiftModel m2 = globals.saveShiftFromAutoControl[j];
          if (m2.staffId != m1.staffId ||
              m2.fromTime.weekday != m1.fromTime.weekday) {
            continue;
          }
          if (m2.shiftType == constShiftRequest) {
            m1.metaRefShiftId = m2.shiftId;
            m1.fromTime = m1.fromTime.compareTo(m2.fromTime) > 0
                ? m1.fromTime
                : m2.fromTime;
            m1.toTime =
                m1.toTime.compareTo(m2.toTime) < 0 ? m1.toTime : m2.toTime;
            break;
          }
        }
      }
      for (ShiftModel element in globals.saveShiftFromAutoControl) {
        isSave = await ClShift().forceSaveShift(
            context,
            element.staffId,
            element.organId,
            element.shiftId,
            element.fromTime.toString(),
            element.toTime.toString(),
            element.metaType ?? element.shiftType,
            "${element.deleted ?? 0}",
            element.metaRefShiftId ?? "0");
      }
      if (isSave) {
        globals.saveShiftFromAutoControl = [];
      }
    }

    if (isSave) {
      refreshLoad();
      setState(() {});
    }
    Navigator.pop(context);
    // refreshLoad();
  }

  Future<void> onTapAuto() async {
    if (selOrganId == null) return;
    Dialogs().loaderDialogNormal(context);

    await ShiftHelper().autoShiftSet(
        context, selOrganId, '$showFromDate 00:00:00', '$showToDate 23:59:59');
    Navigator.pop(context);

    loadChangeData();
  }

  Future<void> refreshLoad() async {
    Dialogs().loaderDialogNormal(context);
    await loadInitData();
    Navigator.pop(context);
  }

  void onChangeCalanderDuring(v) {
    showTimeDuring = int.parse(v);
    setState(() {});
  }

  Future<void> onTapAppoints(calendarTapDetails) async {
    if (calendarTapDetails.appointments != null) {
      fromDetail = calendarTapDetails.appointments![0].startTime;
      toDetail = calendarTapDetails.appointments![0].endTime;
      if (fromDetail == null || toDetail == null) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) {
        // return ShiftDetailPannel(
        //     shiftCount: calendarTapDetails.appointments![0].notes,
        //     organId: selOrganId!,
        //     from: fromDetail!,
        //     to: toDetail!);
        return ShiftDetail(
          shiftCount: calendarTapDetails.appointments![0].notes,
          organId: selOrganId!,
          from: fromDetail!,
          to: toDetail!,
        );
      }));
      loadChangeData();
    } else {
      fromDetail = toDetail = null;
    }
  }

  void onLongTapCalander(v) {
    print('long');
  }

  Future<void> sendRequestNotification() async {
    if (selOrganId == null) return;
    bool conf = await Dialogs().confirmDialog(context, 'シフト入力を促しますか？');
    if (!conf) return;

    Dialogs().loaderDialogNormal(context);
    bool isSend = await ClShift()
        .sendRequestInput(context, selOrganId!, showFromDate, showToDate);

    Navigator.pop(context);

    if (isSend) {
      Dialogs().infoDialog(context, 'シフト入力を要請しました。');
    } else {
      Dialogs().infoDialog(context, errServerActionFail);
    }
  }

  Future<void> sendEpark() async {
    if (selOrganId == null) return;
    bool conf = await Dialogs().confirmDialog(context, 'Eparkに同期しますか？');
    if (!conf) return;

    Dialogs().loaderDialogNormal(context);
    bool isResult = await ClEpark()
         .syncToEpark(context, selOrganId!, showFromDate, showToDate);
    Navigator.pop(context);
    if(isResult){
      Dialogs().infoDialog(context, '同期を完了しました。');  
    }else{
      Dialogs().infoDialog(context, '同期プロセスにエラーが発生しました。');  
    }

    // if (isSend) {
    //   Dialogs().infoDialog(context, 'シフト入力を要請しました。');
    // } else {
    //   Dialogs().infoDialog(context, errServerActionFail);
    // }
  }

  Future<void> lockUpdate(bool isLock) async {
    Dialogs().loaderDialogNormal(context);
    bool isUpdate = await ClShift().updateShiftLock(
        context, selOrganId!, showFromDate, showToDate, isLock);
    Navigator.pop(context);

    if (!isUpdate) {
      Dialogs().infoDialog(context, errServerActionFail);
      return;
    }

    refreshLoad();
  }

  @override
  Widget build(BuildContext context) {
    globals.appTitle = 'シフト管理';
    return MainBodyWdiget(
        fullScreenButton: _fullScreenContent(),
        fullscreenTop: 60,
        isFullScreen: isHideBannerBar,
        render: LoadBodyWdiget(
          loadData: loadData,
          render: _getBodyContent(),
        ));
  }

  Widget _fullScreenContent() {
    return Column(children: [
      FullScreenButton(icon: Icons.refresh, tapFunc: () => refreshLoad()),
      FullScreenButton(
        icon: isHideBannerBar ? Icons.fullscreen_exit : Icons.fullscreen,
        tapFunc: () {
          isHideBannerBar = !isHideBannerBar;
          setState(() {});
        },
      )
    ]);
  }

  Widget _getBodyContent() {
    return Container(
      color: bodyColor,
      child: Column(
        children: [
          _getTopContent(),
          Expanded(child: _getCalendar()),
          _getLockContent(),
          _getBottomButtons()
        ],
      ),
    );
  }

  Widget _getTopContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 0, 5),
      child: Row(children: [
        Expanded(
            child: SubHeaderText(
                label: DateTimes().convertJPYMFromString(showFromDate))),
        InputLeftText(label: '店名', rPadding: 8, width: 60),
        Flexible(
            child: DropDownModelSelect(
                value: selOrganId,
                items: [
                  ...organList.map((e) => DropdownMenuItem(
                      value: e.organId,
                      child: Text(e.organName)))
                ],
                tapFunc: (v) => onChangeOrgan(v))),
        PopupMenuButton(
            onSelected: (v) => onChangeCalanderDuring(v),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                      value: '15',
                      child: Text('15分間間隔で表示', style: TextStyle(fontSize: 12))),
                  PopupMenuItem<String>(
                      value: '30',
                      child: Text('30分間間隔で表示', style: TextStyle(fontSize: 12))),
                  PopupMenuItem<String>(
                      value: '60',
                      child: Text('60分間間隔で表示', style: TextStyle(fontSize: 12))),
                ]),
      ]),
    );
  }

  Widget _getCalendar() {
    return SfCalendar(
      initialDisplayDate: widget.initDate,
      initialSelectedDate: widget.initDate,
      firstDayOfWeek: 1,
      view: CalendarView.week,
      headerHeight: 0,
      selectionDecoration: timeSlotSelectDecoration,
      timeSlotViewSettings: TimeSlotViewSettings(
          startHour: viewFromHour.toDouble(),
          endHour: viewToHour.toDouble(),
          timeIntervalHeight: timeSlotCellHeight.toDouble(),
          dayFormat: 'EEE',
          timeInterval: Duration(minutes: showTimeDuring),
          timeFormat: 'H:mm',
          timeTextStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.5),
          )),
      appointmentTextStyle: apppointmentsTextStyle,
      // specialRegions: regions,
      onLongPress: (d) => onLongTapCalander(d.date),
      onViewChanged: (d) => onChangeCalander(d.visibleDates[1]),
      dataSource: _AppointmentDataSource(appointments),
      onTap: (CalendarTapDetails calendarTapDetails) =>
          onTapAppoints(calendarTapDetails),
    );
  }

  Widget _getLockContent() {
    return Row(
      children: [
        const SizedBox(width: 8),
        WhiteButton(label: '入力要請', tapFunc: () => sendRequestNotification()),
        // SizedBox(width: 8),
        // WhiteButton(label: '詳細を見る', tapFunc: () => pushShiftDay()),
        Expanded(child: Container()),
        Text('ロック', style: btnTxtStyle),
        Switch(
          value: isLock,
          onChanged: (v) => lockUpdate(v),
          activeTrackColor: Colors.lightGreenAccent,
          activeColor: Colors.green,
        ),
        if(isSyncEpark)
          IconWhiteButton(icon:Icons.sync,  tapFunc: () => sendEpark()),
        const SizedBox(width: 20)
      ],
    );
  }

  Widget _getBottomButtons() {
    return RowButtonGroup(widgets: [
      PrimaryButton(
          label: '保存',
          tapFunc: globals.saveShiftFromAutoControl.isNotEmpty
              ? () => onTapSave()
              : null),
      const SizedBox(width: 8),
      PrimaryButton(label: '自動調整', tapFunc: () => onTapAuto()),
      const SizedBox(width: 8),
      CancelButton(
          label: '戻る',
          tapFunc: () async {
            if (globals.saveShiftFromAutoControl.isNotEmpty) {
              bool conf = await Dialogs()
                  .confirmDialog(context, '変更されたシフト内容は無視されます。\nそれでも大丈夫ですか?');
              if (!conf) return;
            }
            globals.saveShiftFromAutoControl = [];
            Navigator.pop(context);
          }),
    ]);
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class ShiftSumModel {
  final String fromTime;
  final String toTime;
  final String count;
  final String shiftCount;

  const ShiftSumModel(
      {required this.fromTime,
      required this.toTime,
      required this.count,
      required this.shiftCount});

  // factory ShiftSumModel.fromJson(Map<String, dynamic> json) {
  //   return ShiftSumModel(
  //     fromTime: json['data']['title'],
  //     toTime: json['ischeck'],
  //     count: json['position'].toString(),
  //     shiftCount: json['position'].toString(),
  //   );
  // }
}
