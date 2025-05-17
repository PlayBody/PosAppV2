import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_pos_app/src/common/business/orders.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';

import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions.dart';
import 'package:staff_pos_app/src/common/functions/pos_printers.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/interface/admin/users/admin_user_info.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/textformfields.dart';
import 'package:staff_pos_app/src/interface/layout/myappbar.dart';
import 'package:staff_pos_app/src/interface/layout/mydrawer.dart';
import 'package:staff_pos_app/src/interface/layout/subbottomnavi.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/dlg_order_from_change.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/dlgentering.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/order.dart';
import 'package:staff_pos_app/src/model/order_menu_model.dart';
import 'package:staff_pos_app/src/model/order_model.dart';
import '../../../common/apiendpoint.dart';
import '../../../common/globals.dart' as globals;
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/form_widgets.dart';

class TableDetail extends StatefulWidget {
  final String orderId;
  final String tablePosition;

  const TableDetail({
    required this.orderId,
    required this.tablePosition,
    super.key,
  });

  @override
  State<TableDetail> createState() => _TableDetail();
}

class _TableDetail extends State<TableDetail> {
  late Future<List> loadData;

  String? orderId;
  String tableTitle = '';
  String tableStartTime = '';
  String flowTime = '';
  String amount = '';
  String userCount = '1';
  String setNum = '1';
  bool isUseSet = false;
  String inputDateTime = "";
  String userName = '';
  String userId = '';

  String tableStatus = constOrderStatusNone;
  String tablePosition = '0';
  String tableAmount = '0';
  String setAmount = '0';
  String btnActionText = '';
  String? reserveUserId;
  var txtUserNameController = TextEditingController();
  bool isEditUserName = false;
  String? payMethod;

  List<OrderMenuModel> menuList = [];

  @override
  void initState() {
    globals.appTitle = '注文・会計';
    super.initState();
    orderId = widget.orderId;
    loadData = loadTableDetail();
  }

  Future<void> updateTitle(String title) async {
    Navigator.of(context).pop();
    if (title == '') return;

    bool isUpdate = await ClOrder().updateTableTitle(
      context,
      globals.organId,
      widget.tablePosition,
      title,
    );
    if (isUpdate) {
      tableTitle = title;
      setState(() {});
    } else {
      if (mounted) {
        Dialogs().infoDialog(context, errServerActionFail);
      }
    }
  }

  Future<void> pushUserDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return AdminUserInfo(userId: userId);
        },
      ),
    );
  }

  Future<void> pushOrder() async {
    if (orderId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return Order(orderId: orderId!);
        },
      ),
    );

    loadTableDetail();
  }

  Future<List> loadTableDetail() async {
    isEditUserName = false;
    OrderModel? order;

    if (orderId != null) {
      order = await ClOrder().loadOrderInfo(context, orderId);
    }

    if (order != null) {
      tableTitle = order.tableTitle;
      inputDateTime = order.fromTime;
      tableStartTime = order.fromTime;
      int flowH = order.flowTime ~/ 60;
      int flowM = order.flowTime % 60;
      flowTime = '${flowH < 10 ? '0' : ''}$flowH 時間  ';
      flowTime += '${flowM < 10 ? '0' : ''}$flowM 分';
      amount = order.amount.toString();
      userCount = order.userCount.toString();
      tableStatus = order.status;
      userName = order.userInputName;
      userId = order.userId;
      menuList = order.menus;
      if (order.status == constOrderStatusReserveApply) {
        reserveUserId = order.userId;
      }

      payMethod = order.payMethod;
    } else {
      inputDateTime = '';
      tableStartTime = '';
      flowTime = '';
      amount = '';
      tableStatus = constOrderStatusNone;
      userName = '';
      menuList = [];
      if (mounted) {
        tableTitle = await ClOrder().loadTableTitle(
          context,
          globals.organId,
          widget.tablePosition,
        );
      }
    }
    if (tableStatus == constOrderStatusNone ||
        tableStatus == constOrderStatusReserveApply) {
      btnActionText = '入 店';
    }
    if (tableStatus == constOrderStatusTableStart) btnActionText = '清 算';
    if (tableStatus == constOrderStatusTableEnd) btnActionText = 'リセット';
    if (mounted) {
      setState(() {});
    }
    return [];
  }

  Future<bool> updateStatus() async {
    if (tableStatus == constOrderStatusTableStart) {
      bool conf = await Dialogs().confirmDialog(context, qTableExit);
      if (!conf) return false;
      if (mounted) {
        bool isUpdate = await ClOrder().exitOrder(context, orderId);
        if (isUpdate) refreshLoad();
      }
      return false;
    }
    if (tableStatus == constOrderStatusTableEnd) {
      bool conf = await Dialogs().confirmDialog(context, qTableReset);
      if (!conf) return false;
      if (mounted) {
        Dialogs().loaderDialogNormal(context);
      }
      dynamic printData = {
        'position': tablePosition,
        'user_count': userCount,
        'menus': menuList,
        'amount': amount,
        'table_amount': tableAmount,
        'set_amount': setAmount,
      };

      if (mounted) {
        await PosPrinters().receiptPrint(context, printData, globals.organId);
        if (mounted) {
          Navigator.pop(context);
        }
      }

      if (mounted) {
        payMethod ??= await Dialogs().selectDialog(
          context,
          'お支払い方法の選択',
          constPayMethod,
        );
      }
      if (payMethod == null) {
        return false;
      }
      if (mounted) {
        bool isUpdate = await ClOrder().resetOrder(context, orderId, payMethod);
        if (isUpdate) {
          orderId = null;
          refreshLoad();
        }
      }
    }

    return true;
  }

  Future<void> deleteTableMenu(String? id) async {
    if (id == null) return;
    bool conf = await Dialogs().confirmDialog(context, qCommonDelete);
    if (conf) {
      if (mounted) {
        Dialogs().loaderDialogNormal(context);
      }
      if (mounted) {
        bool isDelete = await ClOrder().deleteOrderMenu(context, id);
        if (mounted) {
          Navigator.pop(context);
        }
        if (isDelete) {
          setState(() {
            loadData = loadTableDetail();
          });
        } else {
          if (mounted) {
            Dialogs().infoDialog(context, '操作が失敗しました。');
          }
        }
      }
    }
  }

  Future<void> changeQuantityOrderMenu(String? id, String? quantity) async {
    if (id == null || quantity == null) return;
    bool isUpdate = await ClOrder().changeQuantityOrderMenu(
      context,
      id,
      quantity,
    );
    if (isUpdate) refreshLoad();
  }

  void titleChangeDialog(String txtInputTitle) {
    final controller = TextEditingController();

    controller.text = txtInputTitle;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: txtInputTitle.length,
    );

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(qChangeTitle),
            content: TextField(
              autofocus: true,
              // onChanged: (v) {
              //   titleNew = v;
              // },
              controller: controller,
              decoration: InputDecoration(hintText: hintInputTitle),
            ),
            actions: [
              TextButton(
                child: const Text('変更'),
                onPressed: () => {updateTitle(controller.text)},
              ),
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void timeChangeDialog() {
    DateTime date = DateTime.parse(inputDateTime.toString());

    var txthourController = TextEditingController();
    var txtminController = TextEditingController();

    txthourController.text = date.hour.toString();
    txtminController.text = date.minute.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DlgOrderFromChange(date: inputDateTime);
      },
    ).then((value) => updateStartTime(value));
  }

  Future<void> updateStartTime(updateTime) async {
    if (orderId == null) return;
    if (updateTime == null) return;
    bool isUpdate = await ClOrder().updateOrder(context, {
      'reserve_id': orderId,
      'from_time': updateTime,
    });
    if (isUpdate) refreshLoad();
  }

  Future<void> enteringOrgan() async {
    OrganModel organ = await ClOrgan().loadOrganInfo(context, globals.organId);
    if (organ.isNoReserveQR == constCheckinQROn) {
      if (mounted) {
        orderId = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return DlgEntering(
                userId: reserveUserId,
                orderId: orderId,
                tablePosition: widget.tablePosition,
              );
            },
          ),
        );
      }
    } else {
      String confString = await enteringDialog(
        reserveUserId != null ? qEnteringOrgan : qEnteringOrgan,
      );
      if (confString == '1') {
        await createOrder('1');
      } else if (confString == '3') {
        if (mounted) {
          await ClOrder().rejectOrder(context, globals.organId, '1');
        }
      }
    }
    refreshLoad();
    // if (mounted) setState(() {});
  }

  Future<String> enteringDialog(String message) async {
    isUseSet = await ClOrgan().isUseSetInTable(context, globals.organId);
    if (mounted) {
      final value = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(message),
                  ),
                  if (isUseSet)
                    RowLabelInput(
                      label: 'セット設定',
                      renderWidget: DropDownNumberSelect(
                        value: setNum,
                        max: 5,
                        tapFunc: (v) {
                          setState(() {
                            setNum = v;
                          });
                        },
                      ),
                    ),
                  SizedBox(height: 8),
                  if (isUseSet)
                    RowLabelInput(
                      label: '性別',
                      renderWidget: DropDownModelSelect(
                        value: '1',
                        items: [
                          DropdownMenuItem(value: '1', child: Text('男')),
                          DropdownMenuItem(value: '2', child: Text('女')),
                        ],
                        tapFunc: (v) {
                          setState(() {
                            setNum = v;
                          });
                        },
                      ),
                    ),
                  SizedBox(height: 8),
                  RowLabelInput(
                    label: '人数',
                    renderWidget: DropDownNumberSelect(
                      value: userCount,
                      max: 99,
                      tapFunc: (v) {
                        setState(() {
                          userCount = v.toString();
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('はい'),
                  onPressed: () => Navigator.of(context).pop('1'),
                ),
                TextButton(
                  child: const Text('いいえ'),
                  onPressed: () => Navigator.of(context).pop('2'),
                ),
              ],
            ),
      );
      return value ?? '2';
    }
    return '2';
  }

  Future<bool> createOrder(userId) async {
    String orderId = await ClOrder().addOrder(context, {
      'organ_id': globals.organId,
      'table_position': widget.tablePosition,
      'user_id': userId,
      'staff_id': globals.staffId,
      'user_count': userCount,
      'set_number': isUseSet ? setNum : '',
      'status': constOrderStatusTableStart,
    });
    if (orderId != '') {
      this.orderId = orderId;
      return true;
    }
    return false;
  }

  Future<void> updateOrderUserName(userName) async {
    Dialogs().loaderDialogNormal(context);
    await Webservice().loadHttp(context, apiUpdateOrderElement, {
      'id': orderId,
      'user_input_name': userName,
    });
    await loadTableDetail();
    Navigator.pop(context);
  }

  Future<void> updateUserCount(String count) async {
    if (orderId == null) return;
    Dialogs().loaderDialogNormal(context);
    bool success = await ClOrder().updateOrder(context, {
      'reserve_id': orderId,
      'user_count': count,
    });
    await loadTableDetail();
    Navigator.pop(context);
    if (!success) {
      Dialogs().infoDialog(context, '人数の更新に失敗しました');
    }
  }

  Future<void> refreshLoad() async {
    if (mounted) {
      Dialogs().loaderDialogNormal(context);
      await loadTableDetail();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: MyAppBar(),
        body: OrientationBuilder(
          builder: (context, orientation) {
            return FutureBuilder<List>(
              future: loadData,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    padding:
                        globals.isWideScreen
                            ? EdgeInsets.only(left: 120, right: 120)
                            : EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      children: [
                        _getTableInfoContent(orientation),
                        Container(
                          padding: EdgeInsets.only(top: 15, bottom: 15),
                          child: Text(
                            '注文履歴',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        if (orientation == Orientation.portrait)
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding:
                                          globals.isWideScreen
                                              ? EdgeInsets.only(
                                                top: 35,
                                                bottom: 35,
                                              )
                                              : EdgeInsets.only(
                                                top: 20,
                                                bottom: 20,
                                              ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            ...menuList.map(
                                              (e) => TableDetailItemList(
                                                item: e,
                                                rowNm: menuList.indexOf(e),
                                                onTap:
                                                    () =>
                                                        deleteTableMenu(e.id!),
                                                onQuantityChanged: (
                                                  OrderMenuModel item,
                                                  String newQuantity,
                                                ) {
                                                  changeQuantityOrderMenu(
                                                    e.id!,
                                                    newQuantity,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        globals.isWideScreen
                                            ? EdgeInsets.only(bottom: 35)
                                            : EdgeInsets.only(bottom: 15),
                                    child: Column(
                                      children: <Widget>[
                                        ConstrainedBox(
                                          constraints: BoxConstraints.tightFor(
                                            width:
                                                globals.isWideScreen
                                                    ? 350
                                                    : 250,
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                tableStatus ==
                                                            constOrderStatusNone ||
                                                        tableStatus ==
                                                            constOrderStatusReserveApply
                                                    ? () {
                                                      enteringOrgan();
                                                    }
                                                    : () {
                                                      updateStatus();
                                                    },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(
                                                17,
                                                127,
                                                193,
                                                1,
                                              ),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.all(4),
                                              textStyle: TextStyle(
                                                fontSize:
                                                    globals.isWideScreen
                                                        ? 24
                                                        : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: Text(btnActionText),
                                          ),
                                        ),
                                        Container(
                                          height: globals.isWideScreen ? 20 : 5,
                                        ),
                                        ConstrainedBox(
                                          constraints: BoxConstraints.tightFor(
                                            width:
                                                globals.isWideScreen
                                                    ? 350
                                                    : 250,
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                tableStatus ==
                                                        constOrderStatusTableStart //status == '0'
                                                    ? () => pushOrder()
                                                    : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(
                                                17,
                                                127,
                                                193,
                                                1,
                                              ),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.all(4),
                                              textStyle: TextStyle(
                                                fontSize:
                                                    globals.isWideScreen
                                                        ? 24
                                                        : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: Text('注 文'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (orientation == Orientation.landscape)
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding:
                                          globals.isWideScreen
                                              ? EdgeInsets.only(
                                                top: 35,
                                                bottom: 35,
                                              )
                                              : EdgeInsets.only(
                                                top: 20,
                                                bottom: 20,
                                              ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            ...menuList.map(
                                              (e) => TableDetailItemList(
                                                item: e,
                                                rowNm: menuList.indexOf(e),
                                                onTap:
                                                    () =>
                                                        deleteTableMenu(e.id!),
                                                onQuantityChanged: (
                                                  OrderMenuModel item,
                                                  String newQuantity,
                                                ) {
                                                  print(
                                                    'newQuantity: $newQuantity, ${e.id}',
                                                  );
                                                  changeQuantityOrderMenu(
                                                    e.id!,
                                                    newQuantity,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        globals.isWideScreen
                                            ? EdgeInsets.only(
                                              bottom: 35,
                                              left: 20,
                                              top: 30,
                                            )
                                            : EdgeInsets.only(
                                              bottom: 15,
                                              left: 10,
                                              top: 20,
                                            ),
                                    child: Column(
                                      children: <Widget>[
                                        ConstrainedBox(
                                          constraints: BoxConstraints.tightFor(
                                            width:
                                                globals.isWideScreen
                                                    ? 350
                                                    : 250,
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                tableStatus ==
                                                            constOrderStatusNone ||
                                                        tableStatus ==
                                                            constOrderStatusReserveApply
                                                    ? () {
                                                      enteringOrgan();
                                                    }
                                                    : () {
                                                      updateStatus();
                                                    },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(
                                                17,
                                                127,
                                                193,
                                                1,
                                              ),
                                              elevation: 0,
                                              padding: EdgeInsets.all(15),
                                              textStyle: TextStyle(
                                                fontSize:
                                                    globals.isWideScreen
                                                        ? 24
                                                        : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: Text(btnActionText),
                                          ),
                                        ),
                                        Container(
                                          height: globals.isWideScreen ? 20 : 5,
                                        ),
                                        ConstrainedBox(
                                          constraints: BoxConstraints.tightFor(
                                            width:
                                                globals.isWideScreen
                                                    ? 350
                                                    : 250,
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                tableStatus ==
                                                        constOrderStatusTableStart //status == '0'
                                                    ? () => pushOrder()
                                                    : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(
                                                17,
                                                127,
                                                193,
                                                1,
                                              ),
                                              elevation: 0,
                                              padding: EdgeInsets.all(
                                                globals.isWideScreen ? 15 : 4,
                                              ),
                                              textStyle: TextStyle(
                                                fontSize:
                                                    globals.isWideScreen
                                                        ? 24
                                                        : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: Text('注 文'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Expanded(),
                        Container(height: 15),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                // By default, show a loading spinner.
                return Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        drawer: MyDrawer(),
        bottomNavigationBar: SubBottomNavi(),
      ),
    );
  }

  Widget _getTableInfoContent(orientation) {
    return Container(
      margin:
          globals.isWideScreen
              ? EdgeInsets.only(
                top: orientation == Orientation.portrait ? 40 : 0,
              )
              : EdgeInsets.all(0),
      padding:
          globals.isWideScreen
              ? EdgeInsets.only(left: 40, right: 40, bottom: 12)
              : EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onLongPress:
                globals.auth < constAuthBoss
                    ? null
                    : () => titleChangeDialog(tableTitle),
            child: Container(
              padding: EdgeInsets.only(top: 8, bottom: 8, right: 12, left: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color.fromRGBO(17, 127, 193, 1),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tableTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(17, 127, 193, 1),
                        fontSize: globals.isWideScreen ? 32 : 20,
                      ),
                    ),
                  ),
                  Icon(Icons.edit, color: Colors.grey),
                ],
              ),
            ),
          ),
          Container(
            padding:
                globals.isWideScreen
                    ? EdgeInsets.only(
                      left: orientation == Orientation.portrait ? 40 : 150,
                      right: orientation == Orientation.portrait ? 40 : 150,
                      top: 20,
                    )
                    : EdgeInsets.only(left: 20, right: 20, top: 12),
            child: Row(
              children: [
                Container(
                  child: Text('お客様の名前', style: tableDetailhedaerLabelTextStyle),
                ),
                if (!isEditUserName)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(userName, style: tableDetailTimeStyle),
                    ),
                  ),
                if (isEditUserName)
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: TextInputNormal(controller: txtUserNameController),
                    ),
                  ),
                if (isEditUserName)
                  Container(
                    width: 40,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    child: IconWhiteButton(
                      color: primaryColor,
                      icon: Icons.save,
                      tapFunc:
                          () => updateOrderUserName(txtUserNameController.text),
                    ),
                  ),
                if (int.parse(tableStatus) > 0)
                  Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: IconWhiteButton(
                          icon: isEditUserName ? Icons.close : Icons.edit,
                          tapFunc: () {
                            isEditUserName = !isEditUserName;
                            txtUserNameController.text = userName;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 30,
                        child: IconWhiteButton(
                          icon: Icons.person,
                          tapFunc: () {
                            pushUserDetail();
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding:
                globals.isWideScreen
                    ? EdgeInsets.only(
                      left: orientation == Orientation.portrait ? 40 : 150,
                      right: orientation == Orientation.portrait ? 40 : 150,
                      top: 20,
                    )
                    : EdgeInsets.only(left: 20, right: 20, top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('入店時間', style: tableDetailhedaerLabelTextStyle),
                ),
                if (tableStartTime != '')
                  GestureDetector(
                    onLongPress:
                        globals.auth < constAuthBoss
                            ? null
                            : () => timeChangeDialog(),
                    child: Row(
                      children: [
                        _getInputTimeContent(
                          true,
                          DateFormat(
                            'MM',
                          ).format(DateTime.parse(tableStartTime)),
                        ),
                        _getInputTimeContent(false, '月'),
                        _getInputTimeContent(
                          true,
                          DateFormat(
                            'dd',
                          ).format(DateTime.parse(tableStartTime)),
                        ),
                        _getInputTimeContent(false, '日'),
                        _getInputTimeContent(
                          true,
                          DateFormat(
                            'HH',
                          ).format(DateTime.parse(tableStartTime)),
                        ),
                        _getInputTimeContent(false, '時'),
                        _getInputTimeContent(
                          true,
                          DateFormat(
                            'mm',
                          ).format(DateTime.parse(tableStartTime)),
                        ),
                        _getInputTimeContent(false, '分'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                globals.isWideScreen
                    ? EdgeInsets.only(
                      left: orientation == Orientation.portrait ? 40 : 150,
                      right: orientation == Orientation.portrait ? 40 : 150,
                      top: 20,
                    )
                    : EdgeInsets.only(left: 20, right: 20, top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('経過時間', style: tableDetailhedaerLabelTextStyle),
                ),
                if (flowTime != '')
                  Container(child: Text(flowTime, style: tableDetailTimeStyle)),
              ],
            ),
          ),
          Container(
            padding:
                globals.isWideScreen
                    ? EdgeInsets.only(
                      left: orientation == Orientation.portrait ? 40 : 150,
                      right: orientation == Orientation.portrait ? 40 : 150,
                      top: 20,
                    )
                    : EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text('現在のお会計', style: tableDetailhedaerLabelTextStyle),
                ),
                if (amount != '')
                  Container(
                    child: Text(
                      '¥ ${Funcs().currencyFormat(this.amount)}-',
                      style: tableDetailAllAmountStyle,
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(left: 12),
                  width: 32,
                  height: 32,
                  child: IconWhiteButton(
                    icon: Icons.refresh,
                    tapFunc: () => refreshLoad(),
                  ),
                ),
              ],
            ),
          ),
          // here the user count show logic.
          if (orderId != null && orderId != '')
            Container(
              padding:
                  globals.isWideScreen
                      ? EdgeInsets.only(
                        left: orientation == Orientation.portrait ? 40 : 150,
                        right: orientation == Orientation.portrait ? 40 : 150,
                        top: 20,
                      )
                      : EdgeInsets.only(left: 20, right: 20, top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('人数', style: tableDetailhedaerLabelTextStyle),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showUserCountEditDialog(context);
                    },
                    child: Container(
                      child: Row(
                        children: [
                          Text('$userCount 名', style: tableDetailTimeStyle),
                          SizedBox(width: 8),
                          Icon(Icons.edit, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (orderId != null && orderId != '')
            Container(
              padding:
                  globals.isWideScreen
                      ? EdgeInsets.only(
                        left: orientation == Orientation.portrait ? 40 : 150,
                        right: orientation == Orientation.portrait ? 40 : 150,
                        top: 20,
                      )
                      : EdgeInsets.only(left: 20, right: 20, top: 12),
              child: WhiteButton(
                label: '削除',
                tapFunc: () async {
                  if (await Dialogs().confirmDialog(context, "削除しますか？")) {
                    await ClOrder().deleteOrder(context, orderId);
                    orderId = null;
                    refreshLoad();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _getInputTimeContent(bool isTime, String str) {
    return Container(
      padding: EdgeInsets.only(left: 5),
      child: Text(
        str,
        style: isTime ? tableDetailTimeStyle : tableDetailTimeLabel,
      ),
    );
  }

  void _showUserCountEditDialog(BuildContext context) {
    // Store current value for reverting if needed
    String tempCount = userCount;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('人数を変更'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '人数を選択してください',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                DropDownNumberSelect(
                  value: tempCount,
                  max: 99,
                  hint: '人数を選択',
                  label: ' 名',
                  tapFunc: (value) {
                    tempCount = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                if (tempCount != '0') {
                  userCount = tempCount;
                  updateUserCount(userCount);
                  Navigator.of(context).pop();
                } else {
                  Dialogs().infoDialog(context, '人数を入力してください');
                }
              },
            ),
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class TableDetailItemList extends StatelessWidget {
  final item;
  final rowNm;
  final GestureTapCallback? onTap;
  final Function(OrderMenuModel, String)? onQuantityChanged;

  const TableDetailItemList({
    required this.item,
    required this.rowNm,
    this.onTap,
    this.onQuantityChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: rowNm % 2 == 1 ? Colors.white : Color.fromRGBO(238, 250, 255, 1),
      padding:
          globals.isWideScreen
              ? EdgeInsets.only(bottom: 8, left: 40, right: 40)
              : EdgeInsets.only(bottom: 8, left: 10, right: 10),
      child: Row(
        children: [
          Expanded(
            // padding: EdgeInsets.only(top: 12),
            // width: 180,
            child: Container(
              padding: EdgeInsets.only(top: 8, bottom: 0),
              child: Row(
                children: [
                  Expanded(
                    // width: 110,
                    child: Text(
                      item.menuTitle,
                      style: TextStyle(
                        fontSize: globals.isWideScreen ? 20 : 16,
                        color: Color.fromRGBO(70, 88, 134, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    ' × ',
                    style: TextStyle(
                      fontSize: globals.isWideScreen ? 20 : 16,
                      color: Color.fromRGBO(70, 88, 134, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showQuantityDialog(context, item);
                    },
                    child: Container(
                      width: 30,
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.quantity,
                        style: TextStyle(
                          fontSize: globals.isWideScreen ? 20 : 16,
                          color: Color.fromRGBO(70, 88, 134, 1),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 25),
          GestureDetector(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(top: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              width: 100,
              child: Text(
                'キャンセル',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(70, 88, 134, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, OrderMenuModel item) {
    String quantity = item.quantity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('数量変更'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.menuTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                DropDownNumberSelect(
                  value: quantity,
                  max: 50,
                  hint: '数量を選択',
                  tapFunc: (value) {
                    quantity = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                if (onQuantityChanged != null &&
                    quantity != item.quantity &&
                    quantity != '0') {
                  onQuantityChanged!(item, quantity);
                  Navigator.of(context).pop();
                } else {
                  Dialogs().infoDialog(context, '数量を入力してください');
                }
              },
            ),
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

const tableDetailhedaerLabelTextStyle = TextStyle(
  fontSize: 16,
  color: Color(0xff465886),
  fontWeight: FontWeight.bold,
);
const tableDetailTimeLabel = TextStyle(
  fontSize: 14,
  color: Color(0xff465886),
  fontWeight: FontWeight.bold,
);
const tableDetailTimeStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: Color(0xff073c5b),
);
const tableDetailAllAmountStyle = TextStyle(
  fontSize: 34,
  fontWeight: FontWeight.bold,
  color: Color(0xff073c5b),
);
var tableDetailItemListTitle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: globals.isWideScreen ? 26 : 18,
);
