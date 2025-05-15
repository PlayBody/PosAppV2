// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:staff_pos_app/src/common/business/group.dart';
import 'package:staff_pos_app/src/common/business/shift_frame.dart';
import 'package:staff_pos_app/src/common/business/shift_frame_ticket.dart';
import 'package:staff_pos_app/src/common/business/staffs.dart';
import 'package:staff_pos_app/src/common/business/ticket.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions.dart';
import 'package:staff_pos_app/src/common/functions/datetimes.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/admin/users/admin_group_user.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/form_widgets.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/interface/components/textformfields.dart';
import 'package:staff_pos_app/src/interface/components/texts.dart';

import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/interface/components/timepicker.dart';
import 'package:staff_pos_app/src/model/groupmodel.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';
import 'package:staff_pos_app/src/model/shift_frame_model.dart';
import 'package:staff_pos_app/src/common/globals.dart' as globals;
import 'package:staff_pos_app/src/model/shift_frame_ticket_model.dart';
import 'package:staff_pos_app/src/model/stafflistmodel.dart';
import 'package:staff_pos_app/src/model/ticketmastermodel.dart';
import 'package:collection/collection.dart';

class ShiftFrameEdit extends StatefulWidget {
  final DateTime selection;
  final OrganModel organ;
  final int selMax;

  const ShiftFrameEdit({
    super.key,
    required this.selection,
    required this.organ,
    required this.selMax,
  });

  @override
  @override
  State<ShiftFrameEdit> createState() => _ShiftFrameEdit();
}

class _ShiftFrameEdit extends State<ShiftFrameEdit> {
  late Future<List> loadData;
  String organId = '';
  String? shiftFrameId;
  String fromTime = '';
  String toTime = '';
  String? sCount;
  TextEditingController txtComment = TextEditingController();
  bool isFrameMode = false;
  List<TicketMasterModel> masterTickets = [];
  List<ShiftFrameTicketModel> frameTickets = [];
  String? staffId;

  List<GroupModel> groups = [];
  List<String> activeGroups = [];

  List<StaffListModel> staffs = [];

  @override
  void initState() {
    super.initState();
    organId = widget.organ.organId;
    isFrameMode = widget.organ.isNoReserveType == constCheckinReserveShift;
    loadData = loadShift();
  }

  Future<List> loadShift() async {
    List<ShiftFrameModel> shiftFrames = await ClShiftFrame()
        .loadActiveShiftFrames(
          context,
          organId,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.selection),
        );

    if (shiftFrames.isNotEmpty) {
      ShiftFrameModel sfm = shiftFrames.first;
      fromTime = DateTimes().convertTimeFromDateTime(sfm.fromTime);
      toTime = DateTimes().convertTimeFromDateTime(sfm.toTime);
      shiftFrameId = sfm.id;
      sCount = sfm.count.toString();
      txtComment.text = sfm.comment ?? '';
      staffId = sfm.staffId;
    } else {
      fromTime = DateTimes().convertTimeFromDateTime(widget.selection);
      toTime = DateTimes().convertTimeFromDateTimeAddHour(widget.selection, 1);
    }

    List<ShiftFrameTicketModel> tickets = [];
    if (shiftFrameId != null) {
      activeGroups = await ClShiftFrame().loadShiftFrameGroups(
        context,
        shiftFrameId!,
      );

      tickets = await ClShiftFrameTickets().loadShiftFrameTickets(context, {
        'shift_frame_id': shiftFrameId,
      });
    }

    masterTickets = await ClTicket().loadMasterTicket(
      context,
      globals.companyId,
    );
    for (TicketMasterModel me in masterTickets) {
      ShiftFrameTicketModel? st = tickets.firstWhereOrNull(
        (element) => element.ticketId == me.id,
      );

      frameTickets.add(
        ShiftFrameTicketModel.fromJson({
          'id': '',
          'shift_frame_id': '',
          'ticket_id': me.id,
          'count': st == null ? 0 : st.count,
          'ticket_name': me.ticketName,
        }),
      );
    }
    staffs = await ClStaff().loadStaffs(context, {'organ_id': organId});

    groups = await ClGroup().loadGroupList(context, widget.organ.companyId);
    setState(() {});
    return [];
  }

  Future<void> saveShift() async {
    if (sCount == null) {
      Dialogs().infoDialog(context, 'シフト枠を選択します。');
      return;
    }

    String selectDate = DateFormat('yyyy-MM-dd').format(widget.selection);
    String fromStrTime = '$selectDate $fromTime';
    String toStrTime =
        '$selectDate ${toTime == '24:00:00' ? '23:59:59' : toTime}';

    if (DateTime.parse(toStrTime).isBefore(DateTime.parse(fromStrTime))) {
      Dialogs().infoDialog(context, 'シフト枠を正確に入力してください。');
      return;
    }

    Dialogs().loaderDialogNormal(context);

    List<dynamic> paramTickets = [];
    for (var element in frameTickets) {
      paramTickets.add({'ticket_id': element.ticketId, 'count': element.count});
    }

    dynamic param = {
      'organ_id': organId,
      'shift_frame_id': shiftFrameId ?? '',
      'from_time': fromStrTime,
      'to_time': toStrTime,
      'count': sCount,
      'comment': txtComment.text,
      'staff_id': staffId ?? '',
      'groups': jsonEncode(activeGroups).toString(),
      'tickets': jsonEncode(paramTickets).toString(),
    };
    print('---------------------------------');
    print(param);
    bool isUpdate = await ClShiftFrame().saveShiftFrame(context, param);

    if (isUpdate) {
      Navigator.of(context).pop();
    }
  }

  Future<void> deleteShift() async {
    if (shiftFrameId == null) {
      Navigator.of(context).pop();
      return;
    }
    bool isDelete = await ClShiftFrame().deleteShiftFrame(
      context,
      shiftFrameId!,
    );
    if (isDelete) {
      Navigator.of(context).pop();
    } else {
      Dialogs().infoDialog(context, errServerActionFail);
    }
  }

  void refreshLoad() {
    globals.companyId = '';
    Dialogs().loaderDialogNormal(context);
    loadData = loadShift();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MainBodyWdiget(
      render: FutureBuilder<List>(
        future: loadData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              color: bodyColor,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _getMainColumnContents(),
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

  Widget _getMainColumnContents() {
    return Column(
      children: [
        const SizedBox(height: 20),
        RowLabelInput(
          hMargin: 20,
          label: '日付',
          renderWidget: Text(DateFormat('yyyy-MM-dd').format(widget.selection)),
        ),
        _getTimeRow(),
        RowLabelInput(
          hMargin: 20,
          label: 'シフト枠',
          renderWidget: DropDownNumberSelect(
            value: sCount,
            max: widget.selMax,
            tapFunc: (v) => sCount = v!.toString(),
          ),
        ),
        if (isFrameMode)
          RowLabelInput(
            hMargin: 20,
            label: 'メモ',
            renderWidget: TextInputNormal(controller: txtComment, multiLine: 3),
          ),
        const SizedBox(height: 12),
        if (isFrameMode)
          Container(
            child: Column(
              children: [
                RowLabelInput(
                  hMargin: 20,
                  labelWidth: 180,
                  label: 'スタッフ',
                  renderWidget: DropDownModelSelect(
                    value: staffId,
                    items: [
                      DropdownMenuItem(value: null, child: Text('選択なし')),
                      ...staffs.map(
                        (e) => DropdownMenuItem(
                          value: e.staffId,
                          child: Text(e.staffNick),
                        ),
                      ),
                    ],
                    tapFunc: (v) => {staffId = v},
                  ),
                ),
                SizedBox(height: 12),
                RowLabelInput(
                  hMargin: 20,
                  labelWidth: 180,
                  label: '消費チケット',
                  renderWidget: Container(),
                ),
                ...frameTickets.map(
                  (e) => RowLabelInput(
                    hMargin: 20,
                    labelWidth: 160,
                    label: e.ticketName,
                    renderWidget: DropDownNumberSelect(
                      value: e.count,
                      min: 0,
                      max: 50,
                      tapFunc: (v) => e.count = v.toString(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        if (isFrameMode)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            alignment: Alignment.centerLeft,
            child: const InputLeftText(label: 'グループ接続', width: 150),
          ),
        if (isFrameMode) ...groups.map((e) => _getGroupRowContent(e)),
        const SizedBox(height: 36),
        _getButtons(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _getTimeRow() {
    return RowLabelInput(
      hMargin: 20,
      labelWidth: 60,
      label: '時間',
      renderWidget: PosTimeRange(
        selectDate: DateFormat('yyyy-MM-dd').format(widget.selection),
        fromTime: fromTime,
        toTime: toTime,
        confFromFunc: (date) {
          fromTime = Funcs().getDurationTime(date);
          setState(() {});
        },
        confToFunc: (date) {
          toTime = Funcs().getDurationTime(date);
          setState(() {});
        },
      ),
    );
  }

  Widget _getButtons() {
    return Row(
      children: [
        const SizedBox(width: 20),
        PrimaryColButton(label: '保存する', tapFunc: () => saveShift()),
        const SizedBox(width: 12),
        DeleteColButton(
          label: '削除',
          tapFunc: shiftFrameId == null ? null : () => deleteShift(),
        ),
        const SizedBox(width: 12),
        CancelButton(label: 'キャンセル', tapFunc: () => Navigator.pop(context)),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _getGroupRowContent(GroupModel group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return AdminGroupUser(
                groupId: group.groupId,
                companyId: widget.organ.companyId,
              );
            },
          ),
        ).then((value) => refreshLoad());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              Checkbox(
                value: activeGroups.contains(group.groupId),
                onChanged: (v) {
                  if (v == null) return;
                  if (v && !activeGroups.contains(group.groupId)) {
                    activeGroups.add(group.groupId);
                  }
                  if (!v && activeGroups.contains(group.groupId)) {
                    activeGroups.remove(group.groupId);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(width: 4),
              Text(group.groupName),
              Expanded(child: Container()),
              Text('(${group.userCnt ?? ''})'),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
