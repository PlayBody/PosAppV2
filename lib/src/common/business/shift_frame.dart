import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/apiendpoint.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/model/shift_frame_model.dart';

class ClShiftFrame {
  Future<List<ShiftFrameModel>> loadShiftFrame(
      context, String organId, String fromDate, String toDate) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadShiftFrames, {
      'organ_id': organId,
      'from_date': fromDate,
      'to_date': toDate,
    }).then((v) => {results = v});

    List<ShiftFrameModel> shiftFrames = [];
    if (results['is_load']) {
      for (var item in results['data']) {
        shiftFrames.add(ShiftFrameModel.fromJson(item));
      }
    }

    return shiftFrames;
  }

  Future<List<String>> loadShiftFrameGroups(
      context, String shiftFrameId) async {
    Map<dynamic, dynamic> results = {};

    await Webservice().loadHttp(context, apiLoadFrameGroups,
        {'shift_frame_id': shiftFrameId}).then((v) => {results = v});

    List<String> groups = [];
    if (results['is_result']) {
      for (var item in results['data']) {
        groups.add(item);
      }
    }
    return groups;
  }

  Future<bool> saveShiftFrame(context, dynamic param) async {
    Map<dynamic, dynamic> results = {};

    await Webservice()
        .loadHttp(context, apiSaveShiftFrame, param)
        .then((v) => {results = v});
    Navigator.of(context).pop();
    if (!results['is_result']) {
      if (results['err'] == 'active_err') {
        Dialogs().infoDialog(context, errShiftTimeActiveErr);
        return false;
      } else if (results['err'] == 'duplicate_err') {
        Dialogs().infoDialog(context, errShiftTimeDuplicateErr);
        return false;
      } else {
        Dialogs().infoDialog(context, errServerActionFail);
        return false;
      }
    }

    return results['is_result'];
  }

  Future<bool> deleteShiftFrame(context, String shiftFrameId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiDeleteFrame,
        {'shift_frame_id': shiftFrameId}).then((v) => {results = v});

    if (results['is_result'] == null) return false;
    return results['is_result'];
  }

  Future<List<ShiftFrameModel>> loadActiveShiftFrames(
      context, String organId, String selectedTime) async {
    Map<dynamic, dynamic> results = {};

    await Webservice().loadHttp(context, apiLoadActiveFrames, {
      'organ_id': organId,
      'selected_time': selectedTime
    }).then((v) => {results = v});

    List<ShiftFrameModel> shiftFrames = [];
    if (results['is_result']) {
      for (var item in results['data']) {
        shiftFrames.add(ShiftFrameModel.fromJson(item));
      }
    }
    return shiftFrames;
  }

  Future<bool> copyShiftFrames(
      context, String organId, String fromDate, String toDate) async {

    log(fromDate);
    log(toDate);
    Map<dynamic, dynamic> results = {};

    await Webservice().loadHttp(context, apiCopyShiftFrames, {
      'organ_id': organId,
      'from_date': fromDate,
      'to_date': toDate
    }).then((value) => results = value);

    if (results['is_result'] == null) return false;
    return results['is_result'];
  }
}
