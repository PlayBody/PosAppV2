import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/model/order_model.dart';
import '../../model/check_shift_order_model.dart';
import '../apiendpoint.dart';

class ClOrder {
  Future<List<OrderModel>> loadOrderList(context, param) async {
    Map<dynamic, dynamic> results = {};
    await Webservice()
        .loadHttp(context, apiLoadOrderList, param)
        .then((value) => results = value);

    List<OrderModel> orders = [];
    if (results['isLoad']) {
      for (var item in results['orders']) {
        orders.add(OrderModel.fromJson(item));
      }
    }

    return orders;
  }

  Future<List<String>> loadOrderUserIds(context, String staffId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadOrderUserIds,
        {'staff_id': staffId}).then((value) => results = value);

    List<String> userIds = [];
    if (results['isLoad']) {
      for (var item in results['userIds']) {
        userIds.add(item.toString());
      }
    }

    return userIds;
  }

  Future<bool> acceptOrderRequestTables(context, orderId, staffId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiAcceptCurrentOrder,
        {'order_id': orderId, 'staff_id': staffId}).then((v) => {results = v});

    if (results['isLoad']) {
      return true;
    }
    return false;
  }

  Future<List<OrderModel>> loadCureentRequestTables(
      context, organId, staffId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadCurrentOrganTables, {
      'organ_id': organId,
      'staff_id': staffId,
    }).then((v) => {results = v});

    List<OrderModel> tables = [];

    if (results['isLoad']) {
      for (var item in results['tables']) {
        tables.add(OrderModel.fromJson(item));
      }
    }
    return tables;
  }

  Future<List<OrderModel>> loadOrganTables(context, organId, staffId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadOrganTables, {
      'organ_id': organId,
      'staff_id': staffId,
    }).then((v) => {results = v});

    List<OrderModel> tables = [];

    if (results['isLoad']) {
      for (var item in results['tables']) {
        tables.add(OrderModel.fromJson(item));
      }
    }
    return tables;
  }

  Future<OrderModel?> loadOrderInfo(context, orderId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadOrderInfo, {
      'order_id': orderId,
    }).then((v) => {results = v});

    OrderModel? table;

    if (results['isLoad'] ?? false) {
      table = OrderModel.fromJson(results['order']);
    }
    return table;
  }

  Future<String> addOrder(context, param) async {
    Map<dynamic, dynamic> results = {};
    await Webservice()
        .loadHttp(context, apiAddOrder, param)
        .then((v) => {results = v});

    if (!results['isAdd']) {
      await Dialogs().waitDialog(context, results['message']);
      return '';
    }
    return results['order_id'].toString();
  }

  Future<bool> exitOrder(context, orderId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiExitOrder, {
      'order_id': orderId,
    }).then((v) => {results = v});

    return results['isUpdate'];
  }

  Future<bool> resetOrder(context, orderId, payMethod) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiResetOrder, {
      'order_id': orderId,
      'pay_method': payMethod,
    }).then((v) => {results = v});

    return results['isUpdate'];
  }

  Future<bool> updateOrder(context, updateData) async {
    Map<dynamic, dynamic> results = {};
    await Webservice()
        .loadHttp(context, apiUpdateOrder, updateData)
        .then((v) => {results = v});

    return results['isUpdate'];
  }

  Future<bool> applyReserveOrder(context, orderId, staffId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiApplyReserveOrder,
        {'order_id': orderId, 'staff_id': staffId}).then((v) => {results = v});

    return results['isUpdate'];
  }

  Future<bool> saveOrderMenus(context, orderId, param) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiSaveOrderMenus,
        {'order_id': orderId, 'data': param}).then((v) => {results = v});

    return results['isSave'];
  }

  Future<bool> deleteOrder(context, orderId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiDeleteOrder,
        {'order_id': orderId}).then((v) => {results = v});

    return results['isDelete'];
  }

  Future<bool> deleteOrderMenu(context, orderMenuId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiDeleteOrderMenu,
        {'order_menu_id': orderMenuId}).then((v) => {results = v});

    return results['isDelete'];
  }

  Future<bool> changeQuantityOrderMenu(context, orderMenuId, quantity) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiChangeQuantityOrderMenu,
        {'order_menu_id': orderMenuId, 'quantity': quantity}).then((v) => {results = v});

    return results['isUpdate'] ?? false;
  }

  Future<String> loadTableTitle(context, organId, position) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadTableTitle, {
      'organ_id': organId,
      'table_position': position,
    }).then((v) => {results = v});

    return results['table_name'];
  }

  Future<bool> updateTableTitle(context, organId, position, title) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiUpdateTableTitle, {
      'organ_id': organId,
      'table_position': position,
      'title': title,
    }).then((v) => {results = v});

    return results['isUpdate'];
  }

  Future<bool> rejectOrder(context, organId, userId) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiRejectOrder, {
      'organ_id': organId,
      'user_id': userId,
    }).then((v) => {results = v});

    if (!results['isSave']) {
      return false;
    }

    return true;
  }

  Future<List<CheckShiftOrderModel>> loadCheckOrders(
      context, organId, selectedDate) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadCheckShiftOrders, {
      'organ_id': organId,
      'select_date': selectedDate,
    }).then((v) => {results = v});
    List<CheckShiftOrderModel> orders = [];
    if (results['is_result']) {
      for (var item in results['data']) {
        orders.add(CheckShiftOrderModel.fromJson(item));
      }
    }

    return orders;
  }

  Future<bool> updateOrderStaus(context, orderId, status) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiUpdateOrderStatus,
        {'order_id': orderId, 'status': status}).then((v) => {results = v});

    return results['is_result'];
  }
  Future<bool> insertOrder(context, param) async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiInsertOrder,
        param).then((v) => {results = v});
    return results['is_result'];
  }
    
}
