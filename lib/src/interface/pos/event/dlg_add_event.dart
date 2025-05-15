import 'package:intl/intl.dart';
import 'package:staff_pos_app/src/common/business/event.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/dialog_widgets.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/form_widgets.dart';
import 'package:staff_pos_app/src/interface/components/textformfields.dart';
import 'package:staff_pos_app/src/interface/components/texts.dart';
import 'package:staff_pos_app/src/interface/components/timepicker.dart';

import 'package:staff_pos_app/src/common/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/model/event_model.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';

class DlgAddEvent extends StatefulWidget {
  final DateTime selection;
  final String? eventId;

  const DlgAddEvent({super.key, required this.selection, this.eventId});

  @override
  State<DlgAddEvent> createState() => _DlgAddEvent();
}

class _DlgAddEvent extends State<DlgAddEvent> {
  var txtCommentController = TextEditingController();
  var txtUrlController = TextEditingController();

  String fromTime = '';
  String toTime = '';
  String selectDate = '';
  bool isAllOrgan = false;

  List<OrganModel> organs = [];
  String? organId;

  @override
  void initState() {
    super.initState();

    loadShift();
  }

  Future<void> loadShift() async {
    if (globals.auth > constAuthBoss) isAllOrgan = true;
    if (widget.eventId == null) {
      selectDate = DateFormat('yyyy-MM-dd').format(widget.selection);
      fromTime = DateFormat('HH:mm:ss').format(widget.selection);
      if (widget.selection.hour >= 22) {
        toTime = '23:59:59';
      } else {
        toTime = DateFormat(
          'HH:mm:ss',
        ).format(widget.selection.add(Duration(hours: 2)));
      }
    } else {
      EventModel event = await ClEvent().loadEventDetail(
        context,
        widget.eventId!,
      );
      selectDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(event.fromTime));
      fromTime = DateFormat('HH:mm:ss').format(DateTime.parse(event.fromTime));
      toTime = DateFormat('HH:mm:ss').format(DateTime.parse(event.toTime));
      organId = event.organId;
      txtCommentController.text = event.comment;
      txtUrlController.text = event.url;
    }

    if (mounted) {
      organs = await ClOrgan().loadOrganList(context, '', globals.staffId);
    }

    setState(() {});
  }

  Future<void> saveEvent() async {
    if (fromTime == '') return;
    if (toTime == '') return;

    Dialogs().loaderDialogNormal(context);
    await ClEvent().saveEvents(
      context,
      widget.eventId,
      organId,
      '$selectDate $fromTime',
      '$selectDate $toTime',
      txtCommentController.text,
      txtUrlController.text,
    );
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  Future<void> deleteEvent() async {
    if (widget.eventId == null) return;
    bool conf = await Dialogs().confirmDialog(context, qCommonDelete);
    if (!conf) return;

    if (!mounted) return;
    await ClEvent().deleteEvent(context, widget.eventId!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PushDialogs(
      render: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PosDlgHeaderText(label: 'イベントの追加'),
          PosDlgSubHeaderText(label: selectDate),
          _getTimeRow(),
          RowLabelInput(
            label: '実施店舗',
            renderWidget: DropDownModelSelect(
              value: organId,
              items: [
                DropdownMenuItem(value: '0', child: Text('全店舗')),
                ...organs.map(
                  (e) => DropdownMenuItem(
                    value: e.organId,
                    child: Text(e.organName),
                  ),
                ),
              ],
              tapFunc: (v) => organId = v,
            ),
          ),
          RowLabelInput(
            label: '内容',
            renderWidget: TextInputNormal(controller: txtCommentController),
          ),
          RowLabelInput(
            label: 'URL',
            renderWidget: TextInputNormal(controller: txtUrlController),
          ),
          SizedBox(height: 24),
          _getButtons(),
        ],
      ),
    );
  }

  Widget _getTimeRow() {
    return PosTimeRange(
      selectDate: selectDate,
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
    );
  }

  Widget _getButtons() {
    return Row(
      children: [
        PrimaryColButton(label: '保存する', tapFunc: () => saveEvent()),
        Container(width: 12),
        DeleteColButton(
          label: '削除',
          tapFunc: widget.eventId == null ? null : () => deleteEvent(),
        ),
        Container(width: 12),
        CancelColButton(
          label: 'キャンセル',
          tapFunc: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
