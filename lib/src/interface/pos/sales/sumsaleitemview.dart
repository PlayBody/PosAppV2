import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/apiendpoint.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/functions.dart';
import 'package:staff_pos_app/src/interface/admin/users/admin_user_info.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/model/historymenumodel.dart';

import 'package:staff_pos_app/src/common/globals.dart' as globals;
import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/model/order_menu_model.dart';

class SumSaleItemView extends StatefulWidget {
  final String orderId;
  final String position;
  const SumSaleItemView(
      {required this.orderId, required this.position, super.key});

  @override
  _SumSaleItemView createState() => _SumSaleItemView();
}

class _SumSaleItemView extends State<SumSaleItemView> {
  late Future<List> loadData;

  String tablePosition = '';
  String startTime = '';
  String endTime = '';
  String userNick = '';
  String tableAmount = '';
  String tableChargeAmount = '';
  String setAmount = '';
  String userId = '';
  String userCnt = '1';
  String? serviceAmount;
  List<OrderMenuModel> menuList = [];

  @override
  void initState() {
    super.initState();
    loadData = loadSaleData();
  }

  @override
  Widget build(BuildContext context) {
    globals.appTitle = '売上詳細';
    return MainBodyWdiget(
      render: FutureBuilder<List>(
        future: loadData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              color: bodyColor,
              child: Column(
                children: [
                  Expanded(
                      child: SingleChildScrollView(
                          child: Container(
                              padding: EdgeInsets.all(30),
                              child: Column(
                                children: [
                                  SumSaleItemViewContentRow(
                                      label: 'お客様No.', val: widget.position),
                                  SumSaleItemViewContentRow(
                                      label: '席No.', val: tablePosition),
                                  SumSaleItemViewContentRow(
                                      label: '入店時間',
                                      val: '${startTime == ''
                                              ? ''
                                              : Funcs().getTimeFormatHHMM(
                                                  DateTime.parse(startTime))} ~ ${endTime == ''
                                              ? ''
                                              : Funcs().getTimeFormatHHMM(
                                                  DateTime.parse(endTime))}'),
                                  SumSaleItemViewContentRow(
                                      label: '人数',
                                      val: userCnt),
                                  Container(
                                    padding: EdgeInsets.only(bottom: 15),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 180,
                                          child: Text('代表者様名',
                                              style: TextStyle(fontSize: 22)),
                                        ),
                                        Container(
                                          child: Text(userNick,
                                              style: TextStyle(fontSize: 22)),
                                        ),
                                        if (userId != '1')
                                          IconButton(
                                              onPressed: () {
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (_) {
                                                  return AdminUserInfo(
                                                      userId: userId);
                                                }));
                                              },
                                              icon: Icon(Icons.link,
                                                  color: Colors.blue, size: 35))
                                      ],
                                    ),
                                  ),
                                  // SumSaleItemViewContentRow(
                                  //     label: '代表者様名', val: userNick),
                                  SumSaleItemViewContentRow(
                                      label: '売上', val: tableAmount),
                                  Container(
                                      padding:
                                          EdgeInsets.only(top: 30, bottom: 25),
                                      child: Text('注文内容内訳',
                                          style: TextStyle(fontSize: 32))),
                                  if (tableChargeAmount != '')
                                    SumSaleItemViewListRow(
                                      label: 'テーブルチャージ',
                                      val: tableChargeAmount,
                                    ),
                                  if (setAmount != '')
                                    SumSaleItemViewListRow(
                                      label: 'セット料金',
                                      val: setAmount,
                                    ),
                                  if (serviceAmount !=null)
                                    SumSaleItemViewListRow(
                                      label: 'サービス料',
                                      val: '￥${Funcs().currencyFormat(serviceAmount!)}',
                                    ),
                                  ...menuList.map((e) => SumSaleItemViewListRow(
                                        label: e.menuTitle,
                                        quantity: e.quantity,
                                        val: '￥${Funcs().currencyFormat(calculateMenuPrice(e))}',
                                      ))
                                ],
                              )))),
                  Container(
                      width: 150,
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: CancelColButton(
                        label: '戻る',
                        tapFunc: () {
                          Navigator.pop(context);
                        },
                      ))
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  String calculateMenuPrice(OrderMenuModel menu) {
    if (menu.menuPrice.isEmpty || menu.menuTax.isEmpty || menu.quantity.isEmpty) {
      return '0';
    }
    
    double price = double.tryParse(menu.menuPrice) ?? 0;
    double tax = double.tryParse(menu.menuTax) ?? 0;
    int quantity = int.tryParse(menu.quantity) ?? 1;
    
    int totalPrice = (price * (1 + tax / 100) * quantity).toInt();
    return totalPrice.toString();
  }

  Future<List> loadSaleData() async {
    Map<dynamic, dynamic> results = {};
    await Webservice().loadHttp(context, apiLoadSumSaleItemUrl,
        {'order_id': widget.orderId}).then((v) => {results = v});

    if (results['isLoad']) {
      var order = results['order'];
      tablePosition = order['table_position'].toString();
      userNick =
          results['user'] == null ? '' : results['user']['user_nick'] + '様';
      startTime = order['from_time'];
      endTime = order['to_time'];

      double orderAmount = order['amount'] == null ? 0 : double.tryParse(order['amount'].toString()) ?? 0;
      tableAmount = orderAmount > 0
          ? '￥${Funcs().currencyFormat(orderAmount.toInt().toString())}'
          : '';
          
      double chargeAmount = 0;
      if (order['charge_amount'] != null) {
        chargeAmount = double.tryParse(order['charge_amount'].toString()) ?? 0;
      }
      tableChargeAmount = chargeAmount == 0
          ? ''
          : '￥${Funcs().currencyFormat(chargeAmount.toInt().toString())}';
          
      double setAmountValue = 0;
      if (order['set_amount'] != null) {
        setAmountValue = double.tryParse(order['set_amount'].toString()) ?? 0;
      }
      setAmount = setAmountValue == 0
          ? ''
          : '￥${Funcs().currencyFormat(setAmountValue.toInt().toString())}';
          
      if (order['service_amount'] != null) serviceAmount = order['service_amount'].toString();

      userCnt = order['user_count'] == null ? '1' : order['user_count'].toString();
      menuList = [];
      for (var item in results['menus']) {
        menuList.add(OrderMenuModel.fromJson(item));
      }

      userId = order['user_id'] == null ? '1' : order['user_id'].toString();
    }
    return [];
  }
}

class SumSaleItemViewContentRow extends StatelessWidget {
  final String label;
  final String val;
  const SumSaleItemViewContentRow(
      {required this.label, required this.val, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: TextStyle(fontSize: 22)),
          ),
          Container(
            child: Text(val, style: TextStyle(fontSize: 22)),
          )
        ],
      ),
    );
  }
}

class SumSaleItemViewListRow extends StatelessWidget {
  final String label;
  final String? quantity;
  final String val;
  const SumSaleItemViewListRow(
      {required this.label, required this.val, this.quantity, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: quantity == null ? 200 : 150,
            child: Text(label, style: TextStyle(fontSize: 22)),
          ),
          if (quantity != null)
            Container(
              alignment: Alignment.centerRight,
              width: 50,
              child: Text('× ${quantity!}', style: TextStyle(fontSize: 22)),
            ),
          Expanded(
              child: Container(
            alignment: Alignment.centerRight,
            child: Text(val, style: TextStyle(fontSize: 22)),
          ))
        ],
      ),
    );
  }
}
