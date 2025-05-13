class ShiftFrameTicketModel {
  final String id;
  final String shiftFrameId;
  final String ticketId;
  String count;
  final String ticketName;

  ShiftFrameTicketModel({
    required this.id,
    required this.shiftFrameId,
    required this.ticketId,
    required this.count,
    required this.ticketName,
  });

  factory ShiftFrameTicketModel.fromJson(Map<String, dynamic> json) {
    return ShiftFrameTicketModel(
        id: json['id'].toString(),
        shiftFrameId: json['shift_frame_id'].toString(),
        ticketId: json['ticket_id'].toString(),
        count: json['count'].toString(),
        ticketName: json['ticket_name'] == null ? '' : json['ticket_name'].toString(),
    );
  }
}
