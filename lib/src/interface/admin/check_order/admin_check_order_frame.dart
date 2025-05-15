// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_pos_app/src/common/business/orders.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/model/check_shift_order_model.dart';

import 'package:staff_pos_app/src/model/organmodel.dart';
// import 'package:staff_pos_app/src/model/teachermodel.dart';
// import 'package:staff_pos_app/src/interface/admin/component/adminbutton.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../common/dialogs.dart';
import '../../../common/globals.dart' as globals;

class AdminCheckOrderFrame extends StatefulWidget {
  const AdminCheckOrderFrame({super.key});

  @override
  State<AdminCheckOrderFrame> createState() => _AdminCheckOrderFrame();
}

class _AdminCheckOrderFrame extends State<AdminCheckOrderFrame> {
  late Future<List> loadData;
  List<OrganModel> organs = [];
  String? organId;
  String? selectedDate;
  DateRangePickerController datePickerController = DateRangePickerController();

  List<CheckShiftOrderModel> orders = [];

  int _selectYear = DateTime.now().year;
  int _selectMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    loadData = loadInitData();
  }

  Future<List> loadInitData() async {
    organs = await ClOrgan().loadOrganHaveShiftMode(
      context,
      globals.companyId,
      globals.staffId,
    );

    if (organs.isEmpty) Navigator.pop(context);

    organId ??= organs.first.organId;

    setState(() {});
    return [];
  }

  void dateMove(type) {
    int tmpYear = _selectYear;
    int tmpMonth = _selectMonth;
    if (type == 'prev') {
      if (tmpMonth <= 1) {
        tmpMonth = 12;
        tmpYear = tmpYear - 1;
      } else {
        tmpMonth = tmpMonth - 1;
      }
    }
    if (type == 'next') {
      if (tmpMonth >= 12) {
        tmpMonth = 1;
        tmpYear = tmpYear + 1;
      } else {
        tmpMonth = tmpMonth + 1;
      }
    }

    _selectYear = tmpYear;
    _selectMonth = tmpMonth;
    datePickerController.displayDate = DateTime(_selectYear, _selectMonth);
    setState(() {});
  }

  Future<void> selectDate(DateTime d) async {
    selectedDate = DateFormat('yyyy-MM-dd').format(d);
    if (organId != null && selectedDate != null) {
      Dialogs().loaderDialogNormal(context);
      orders = await ClOrder().loadCheckOrders(context, organId, selectedDate);
      Navigator.pop(context);
    }
    setState(() {});
  }

  void viewChange(DateRangePickerViewChangedArgs arg) {
    if (arg.visibleDateRange.startDate == null) return;
    int tY = arg.visibleDateRange.startDate!.year;
    int tM = arg.visibleDateRange.startDate!.month;
    if (tY == _selectYear && tM == _selectMonth) return;
    _selectMonth = tM;
    _selectYear = tY;

    setState(() {});
  }

  Future<void> orderUpdate(
    CheckShiftOrderModel group,
    ChceckOrderUserModel user,
    isCheck,
  ) async {
    String status = isCheck ? constOrderStatusTableComplete : constReserveApply;
    Dialogs().loaderDialogNormal(context);
    bool isUpdate = false;
    if (user.orderId == '') {
      if (organId != null) {
        isUpdate = await ClOrder().insertOrder(context, {
          'organ_id': organId ?? '',
          'user_id': user.userId,
          'from_time': group.fromTime,
          'to_time': group.toTime,
          'shift_frame_id': group.frameId,
          'status': status,
        });
      }
      orders = await ClOrder().loadCheckOrders(context, organId, selectedDate);
      setState(() {});
    } else {
      // N??? >> bool isUpdate -> isUpdate
      isUpdate = await ClOrder().updateOrderStaus(
        context,
        user.orderId,
        status,
      );
    }
    Navigator.pop(context);
    if (isUpdate) {
      Dialogs().infoDialog(context, '変更しました。');
    }
  }

  @override
  Widget build(BuildContext context) {
    globals.adminAppTitle = '出席確認';
    return MainBodyWdiget(
      render: FutureBuilder<List>(
        future: loadData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _getDropDownOrgans(),
                          _getMonthNav(),
                          _getMothCalander(),
                          ...orders.map((e) => _getOrderContent(e)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _getDropDownOrgans() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButtonFormField(
        onChanged: (value) async {
          organId = value.toString();
          await loadInitData();
          // refreshLoad();
        },
        value: organId,
        items: [
          ...organs.map(
            (e) => DropdownMenuItem(value: e.organId, child: Text(e.organName)),
          ),
        ],
      ),
    );
  }

  Widget _getMonthNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Container()),
          TextButton(onPressed: () => dateMove('prev'), child: const Text('≪')),
          SizedBox(
            width: 150,
            child: Text(
              '$_selectYear年$_selectMonth月',
              style: const TextStyle(fontSize: 26),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(onPressed: () => dateMove('next'), child: Text('≫')),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Widget _getMothCalander() {
    // List<DateTime> ss = <DateTime>[DateTime.now().add(Duration(days: 4))];
    // ss.add(DateTime.parse('2023-09-15'));
    // ss.add(DateTime.parse('2023-09-12'));
    // ss.add(DateTime.parse('2023-09-13'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SfDateRangePicker(
        selectionMode: DateRangePickerSelectionMode.single,
        headerHeight: 0,
        monthViewSettings: const DateRangePickerMonthViewSettings(
          viewHeaderStyle: DateRangePickerViewHeaderStyle(
            textStyle: TextStyle(color: Colors.blue, fontSize: 18),
          ),
          weekendDays: [7],
        ),
        monthCellStyle: const DateRangePickerMonthCellStyle(
          textStyle: TextStyle(color: Colors.black, fontSize: 18),
          weekendTextStyle: TextStyle(color: Colors.red, fontSize: 18),
        ),
        selectionTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
        rangeTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
        controller: datePickerController,
        onSelectionChanged: (args) => selectDate(args.value),
        onViewChanged: (e) => viewChange(e),
      ),
    );
  }

  Widget _getOrderContent(CheckShiftOrderModel order) {
    return Container(
      color: const Color(0xfff9f9f9),
      alignment: Alignment.centerLeft,
      child: Column(
        children: [
          _getGroupTitle(order),
          ...order.users.map((e) => _getOrderItem(order, e)),
        ],
      ),
    );
  }

  Widget _getGroupTitle(CheckShiftOrderModel order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF117fc1), width: 3),
              ),
            ),
            padding: const EdgeInsets.only(top: 20, bottom: 20, left: 18),
            child: Text(
              '${order.showFromTime}~${order.showToTime} ${order.groupMemo}',
              style: organTitleStyle,
            ),
          ),
        ),
        Container(
          width: 120,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 3)),
          ),
        ),
      ],
    );
  }

  Widget _getOrderItem(group, ChceckOrderUserModel user) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffdfdfdf))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          children: [
            Text(user.userName, style: staffNameStyle),
            _getGroupMark(user.isGroup),
            Expanded(child: Container()),
            _getCheckLabel(group, user),
          ],
        ),
      ),
    );
  }

  Widget _getGroupMark(bool isGroup) {
    if (!isGroup) return Container();
    return Container(
      margin: const EdgeInsets.only(left: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: const Color(0xffffc600),
      ),
      child: const Text(
        'グループ所属',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _getCheckLabel(group, ChceckOrderUserModel user) {
    return SizedBox(
      width: 90,
      child: DropdownButtonFormField(
        value: user.isEnter,
        items: const [
          DropdownMenuItem(
            value: true,
            child: Text(
              '出席',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF919191),
              ),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(
              '未出席',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
        ),
        onChanged: (v) => orderUpdate(group, user, v),
      ),
    );
    //  Text(isCheck ? '出席済' : '未出席', style: style);
  }

  var organTitleStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF117fc1),
  );
  var organSettingStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    color: Color(0xFF919191),
  );
  var staffNameStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xff454545),
  );
}
