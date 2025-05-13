import 'package:staff_pos_app/src/common/apiendpoint.dart';
import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/model/shift_frame_ticket_model.dart';

class ClShiftFrameTickets {
  Future<List<ShiftFrameTicketModel>> loadShiftFrameTickets(
      context, dynamic param) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadShiftFrameTickets, param).then((v) => {results = v});

    List<ShiftFrameTicketModel> tickets = [];
    if (results['is_result']) {
      for (var item in results['data']) {
        tickets.add(ShiftFrameTicketModel.fromJson(item));
      }
    }

    return tickets;
  }
}
