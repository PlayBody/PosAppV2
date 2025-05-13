import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:staff_pos_app/src/common/apiendpoint.dart';
import 'package:staff_pos_app/src/common/business/common.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/dialog_widgets.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/texts.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';

import '../common/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DlgAttendance extends StatefulWidget {
  final List<OrganModel> organList;
  const DlgAttendance({required this.organList, Key? key}) : super(key: key);

  @override
  State<DlgAttendance> createState() => _DlgAttendance();
}

class _DlgAttendance extends State<DlgAttendance> {
  String? selOrganId;

  Future<void> attendance() async {
    if (selOrganId == null) return;

    Dialogs().loaderDialogNormal(context);

    // LocationPermission permission = await Geolocator.checkPermission();

    // if (permission == LocationPermission.denied) {
    // if (Platform.isAndroid) {
    //   bool? isAllow = await _showAlertDialog(context);
    //   if (isAllow != null && isAllow) {
    //     await checkLocaionAndAttendance();
    //   } else {
    //     Navigator.of(context).pop();
    //   }
    // } else {
    await checkLocaionAndAttendance();
    // }
    // } else {
    //   await checkLocaionAndAttendance();
    // }
  }

  Future<bool?> _showAlertDialog(BuildContext context) {
    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('このアプリは、出勤操作時に従業員の位置を確認するために位置測定権限を使用します。'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            /// This parameter indicates this action is the default,
            /// and turns the action's text to bold text.
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context, false);
//              await checkLocaionAndAttendance();
            },
            child: const Text('Deny'),
          ),
          CupertinoDialogAction(
            /// This parameter indicates the action would perform
            /// a destructive action such as deletion, and turns
            /// the action's text color to red.
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> checkLocaionAndAttendance() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      Navigator.of(context).pop();
      return Future.error('Location Not Available');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    Map<dynamic, dynamic> organResults = {};
    await Webservice().loadHttp(context, apiLoadOrganInfo,
        {'organ_id': selOrganId}).then((value) => organResults = value);
    Navigator.pop(context);

    if (organResults['is_result']) {
      var organLat = organResults['data']['lat'] ?? '0';
      var organLon = organResults['data']['lon'] ?? '0';
      if (double.tryParse(organLat) == null) organLat = '0';
      if (double.tryParse(organLon) == null) organLon = '0';
      int distance = Funcs().clacDistance(
          LatLng(position.latitude, position.longitude),
          LatLng(double.parse(organLat), double.parse(organLon)));
      print(LatLng(position.latitude, position.longitude));
      int organDistance = organResults['data']['distance'] == null
          ? 0
          : int.parse(organResults['data']['distance']);
      if (distance > organDistance) {
        Dialogs().infoDialog(context, '選択した店舗と現在位置が異なります');
        return;
      }
    } else {
      Dialogs().infoDialog(context, '店舗の位置情報を確認することができません。');
    }

    bool isAttend = await ClCommon()
        .updateAttend(context, globals.staffId, selOrganId, '1');

    if (isAttend) {
      Navigator.of(context).pop();
    } else {
      Dialogs().infoDialog(context, errServerActionFail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PushDialogs(
        render: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PosDlgHeaderText(label: qAttendanceActive),
        DropDownModelSelect(items: [
          ...widget.organList.map((e) =>
              DropdownMenuItem(value: e.organId, child: Text(e.organName)))
        ], tapFunc: (v) => selOrganId = v.toString()),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: Container()),
            PrimaryColButton(label: '出勤', tapFunc: () => attendance()),
            const SizedBox(width: 12),
            CancelColButton(
                label: 'キャンセル', tapFunc: () => Navigator.of(context).pop()),
          ],
        ),
      ],
    ));
  }
}
