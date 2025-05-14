import 'package:intl/intl.dart';
class CheckShiftOrderModel {
  final String frameId;
  final String fromTime;
  final String toTime;
  final String showFromTime;
  final String showToTime;
  final String groupMemo;
  final List<ChceckOrderUserModel> users;

  const CheckShiftOrderModel({
    required this.frameId,
    required this.showFromTime,
    required this.showToTime,
    required this.fromTime,
    required this.toTime,
    required this.groupMemo,
    required this.users,
  });

  factory CheckShiftOrderModel.fromJson(Map<String, dynamic> json) {
    List<ChceckOrderUserModel> users = [];
    for (var item in json['users']) {
      users.add(ChceckOrderUserModel.fromJson(item));
    }
    return CheckShiftOrderModel(
        frameId: json['group']['shift_frame_id'].toString(),
        showFromTime: DateFormat('HH:mm')
            .format(DateTime.parse(json['group']['from_time'])),
        showToTime: DateFormat('HH:mm')
            .format(DateTime.parse(json['group']['to_time'])),
        fromTime: DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.parse(json['group']['from_time'])),
        toTime: DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.parse(json['group']['to_time'])),
        groupMemo: json['group']['group_memo'] == ''
            ? 'メモなし'
            : json['group']['group_memo'],
        users: users);
  }
}

class ChceckOrderUserModel {
  final String orderId;
  final String userId;
  final String userName;
  final bool isGroup;
  final bool isEnter;

  const ChceckOrderUserModel(
      {required this.orderId,
      required this.userId,
      required this.userName,
      required this.isGroup,
      required this.isEnter});

  factory ChceckOrderUserModel.fromJson(Map<String, dynamic> json) {
    return ChceckOrderUserModel(
      orderId: json['order_id'].toString(),
      userId: json['user_id'],
      userName: json['user_name'],
      isGroup: json['is_group'],
      isEnter: json['is_enter'],
    );
  }
}
