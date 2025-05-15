import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/apiendpoint.dart';
import 'package:staff_pos_app/src/common/business/category.dart';
import 'package:staff_pos_app/src/common/business/menu.dart';
import 'package:staff_pos_app/src/common/business/orders.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/functions/pos_printers.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/layout/myappbar.dart';
import 'package:staff_pos_app/src/interface/layout/mydrawer.dart';
import 'package:staff_pos_app/src/interface/layout/subbottomnavi.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/dlgmenureserve.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/tabledetail.dart';
import 'package:staff_pos_app/src/model/category_model.dart';
import 'package:staff_pos_app/src/model/menuvariationmodel.dart';
import 'package:staff_pos_app/src/model/order_menu_model.dart';

import 'package:euc/jis.dart';
import 'package:staff_pos_app/src/model/order_model.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';

import '../../../common/functions.dart';
import '../../../common/globals.dart' as globals;
import '../../../http/webservice.dart';

import '../../../model/menumodel.dart';
import 'orderIndividual.dart';

class Order extends StatefulWidget {
  final String orderId;
  const Order({required this.orderId, super.key});

  @override
  _Order createState() => _Order();
}

class _Order extends State<Order> {
  late Future<List> loadData;
  String quantity = '';
  String organName = '';
  String tablePosition = '';

  List<MenuModel> menuList = [];
  OrderModel? order;
  List<CategoryModel> categories = [];
  String selCategory = "0";

  @override
  void initState() {
    super.initState();
    loadData = loadOrderData();
  }

  Future<List> loadUpdateCategoryData() async {
    menuList = await ClMenu().loadMenuList(context, {
      'organ_id': globals.organId,
      'category_id': selCategory == "0" ? "" : selCategory
    });

    setState(() {});
    return menuList;
  }

  Future<List> loadOrderData() async {
    OrganModel organ = await ClOrgan().loadOrganInfo(context, globals.organId);
    categories = await ClCategory().getCategoryList(context, organ.companyId);

    menuList = await ClMenu().loadMenuList(context, {
      'organ_id': globals.organId,
      'category_id': selCategory == "0" ? "" : selCategory
    });

    order = await ClOrder().loadOrderInfo(context, widget.orderId);
    globals.orderMenus = [];
    globals.pendingOrderMenus = [];
    if (order != null) {
      globals.pendingOrderMenus = order?.menus ?? [];
      tablePosition = Funcs().extractNumber(order?.tableTitle ?? '');
    }
    organName = organ.organName;
    // Map<dynamic, dynamic> results = {};
    // await Webservice().loadHttp(context, apiLoadOrderMenusUrl, {
    //   'organ_id': globals.organId,
    //   'table_id': widget.orderId
    // }).then((v) => {results = v});

    // if (results['isLoad']) {
    //   menuList = [];

    //   for (var item in results['menus']) {
    //     menuList.add(MenuModel.fromJson(item));
    //   }

    //   globals.orderReserveMenus = [];

    //   for (var item in results['table_menus']) {
    //     globals.orderReserveMenus.add(MenuReserveModel.fromJson(item));
    //   }
    // }

    // OrganModel _organ = await ClOrgan().loadOrganInfo(context, globals.organId);
    // organName = _organ.organName;

    // Map<dynamic, dynamic> tableResults = {};
    // await Webservice().loadHttp(context, apiLoadTableDetailUrl, {
    //   'organ_id': globals.organId,
    //   'table_id': widget.orderId
    // }).then((value) => tableResults = value);
    // tablePosition = tableResults['table']['position'] == null
    //     ? ''
    //     : tableResults['table']['position'];

    // order = await ClOrder().loadOrderInfo(context, widget.orderId);
    setState(() {});
    return menuList;
  }

  Future<void> reserveMenuAdd(item) async {
    Map<dynamic, dynamic> results = {};
    List<MenuVariationModel> variationList = [];
    Dialogs().loaderDialogNormal(context);
    await Webservice().loadHttp(context, apiLoadMenuVariationListUrl,
        {'menu_id': item.menuId}).then((v) => results = v);
    Navigator.pop(context);

    if (results['isLoad']) {
      for (var item in results['variations']) {
        variationList.add(MenuVariationModel.fromJson(item));
      }
    } else {
      return;
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return DlgMenuReserve(
            item: item,
            userId: order == null ? '0' : order!.userId,
            variationList: variationList,
          );
        }).then((_) {
      setState(() {
        globals.orderMenus.reversed;
      });
    });
  }

  Future<void> registerOrderMenu() async {
    // if (globals.auth == constAuthGuest) {
    try {
      dynamic printData = {};
      printData['organ_name'] = organName;
      printData['table_position'] = tablePosition;
      printData['menus'] = globals.orderMenus;
      await PosPrinters().ticketPrint(printData);
    } catch (e) {
      print('Error in print ticket: $e');
    }
    // }
    // return;
    List data = [];
    for (var e in globals.pendingOrderMenus) {
      data.add({
        'title': e.menuTitle,
        'price': e.menuPrice,
        'menu_tax': e.menuTax,
        'quantity': e.quantity,
        'menu_id': e.menuId,
        'variation_id': e.variationId,
        'use_tickets': e.useTickets,
      });
    }
    for (var e in globals.orderMenus) {
      if (data.any((element) =>
          element['menu_id'] == e.menuId &&
          element['variation_id'] == e.variationId)) {
        for (var element in data) {
          if (element['menu_id'] == e.menuId &&
              element['variation_id'] == e.variationId) {
            element['quantity'] =
                (int.parse(element['quantity']) + int.parse(e.quantity))
                    .toString();
          }
        }
        continue;
      }
      data.add({
        'title': e.menuTitle,
        'price': e.menuPrice,
        'menu_tax': e.menuTax,
        'quantity': e.quantity,
        'menu_id': e.menuId,
        'variation_id': e.variationId,
        'use_tickets': e.useTickets
      });
    }

    bool isSave = await ClOrder()
        .saveOrderMenus(context, widget.orderId, jsonEncode(data));

    if (isSave) {
      Navigator.pop(context);
    } else {
      Dialogs().infoDialog(context, errServerActionFail);
    }
  }

  Uint8List encode(String s) {
    return Uint8List.fromList(ShiftJIS().encode(s));
  }

  @override
  Widget build(BuildContext context) {
    globals.appTitle = '注文';
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: MyAppBar(),
        body: OrientationBuilder(builder: (context, orientation) {
          return FutureBuilder<List>(
            future: loadData,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Container(
                  padding: globals.isWideScreen
                      ? EdgeInsets.only(
                          top: orientation == Orientation.landscape ? 4 : 0,
                          left: 80,
                          right: 80,
                          bottom: 40)
                      : const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Column(children: [
                    _getCategoryContent(),
                    SizedBox(height: 8),
                    Flexible(
                        flex: orientation == Orientation.landscape ? 6 : 5,
                        child: SingleChildScrollView(
                          child: _getMenusColumn(orientation),
                        )),
                    Container(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Text(
                        '注文内容一覧',
                        style: tableDetailItemListTitle,
                      ),
                    ),
                    if (orientation == Orientation.portrait)
                      _getOrderMenusPortrait(),
                    if (orientation == Orientation.landscape)
                      _getOrderMenuLandscape(),
                  ]),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show a loading spinner.
              return const Center(child: CircularProgressIndicator());
            },
          );
        }),
        drawer: MyDrawer(),
        bottomNavigationBar: SubBottomNavi(),
      ),
    );
  }

  Widget _getMenusColumn(orientation) {
    return Column(
      children: <Widget>[
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: globals.isWideScreen
              ? const EdgeInsets.all(0)
              : const EdgeInsets.only(left: 30, right: 30),
          crossAxisCount: orientation == Orientation.landscape
              ? 4
              : globals.isWideScreen
                  ? 3
                  : 2,
          crossAxisSpacing: globals.isWideScreen ? 40 : 25,
          mainAxisSpacing: globals.isWideScreen ? 15 : 10,
          childAspectRatio: globals.isWideScreen ? 1.2 : 1.3,
          children: [
            ...menuList.map((e) => _getMenuItems(e)),
            if (globals.auth > constAuthGuest)
              GestureDetector(
                onTap: () async {
                  globals.orderInputSaveFlag = true;
                  txtIndividualAmountController.text = '0';

                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return const OrderIndividual();
                  })).then((_) => setState(() {
                        globals.orderMenus.reversed;
                      }));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                          alignment: Alignment.topRight,
                          height: 40,
                          child: Image.asset('images/icon_order_calculator.png',
                              scale: 1.8)),
                      Container(
                        alignment: Alignment.center,
                        child:
                            const Text('個別入力', style: TextStyle(fontSize: 18)),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _getOrderMenusPortrait() {
    return Flexible(
        flex: globals.isWideScreen ? 7 : 3,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...globals.orderMenus
                                .map((e) => _getOrderMenuItem(e)),
                          ],
                        ),
                      ))),
              Container(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints.tightFor(
                          width: globals.isWideScreen ? 350 : 250),
                      child: ElevatedButton(
                        onPressed: () {
                          registerOrderMenu();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(17, 127, 193, 1),
                            elevation: 0,
                            padding:
                                EdgeInsets.all(globals.isWideScreen ? 15 : 4),
                            textStyle: TextStyle(
                                fontSize: globals.isWideScreen ? 24 : 16,
                                fontWeight: FontWeight.bold)),
                        child: const Text('注文確定'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  Widget _getOrderMenuLandscape() {
    return Expanded(
        flex: globals.isWideScreen ? 7 : 3,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...globals.orderMenus
                                .map((e) => _getOrderMenuItem(e)),
                          ],
                        ),
                      ))),
              Container(
                padding: const EdgeInsets.only(
                    bottom: 40, top: 40, right: 20, left: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints.tightFor(width: 180),
                  child: ElevatedButton(
                    onPressed: () {
                      registerOrderMenu();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(17, 127, 193, 1),
                        elevation: 0,
                        minimumSize:
                            const Size(double.infinity, double.infinity),
                        // padding: EdgeInsets.all(max),
                        textStyle: TextStyle(
                            fontSize: globals.isWideScreen ? 24 : 16,
                            fontWeight: FontWeight.bold)),
                    child: const Text('注文確定'),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  Widget _getOrderMenuItem(e) {
    return OrderItemList(
      item: e,
      rowNm: globals.orderMenus.indexOf(e),
      onTap: () async {
        bool conf = await Dialogs().confirmDialog(context, qCommonDelete);
        if (conf) {
          setState(() {
            globals.orderMenus.remove(e);
          });
        }
      },
      onQuantityChanged: (OrderMenuModel item, String newQuantity) {
        setState(() {
          final index = globals.orderMenus.indexOf(item);
          if (index >= 0) {
            // Create a new OrderMenuModel with updated quantity
            final updatedItem = OrderMenuModel(
              id: item.id,
              menuTitle: item.menuTitle,
              quantity: newQuantity,
              menuPrice: item.menuPrice,
              menuTax: item.menuTax,
              menuId: item.menuId,
              variationId: item.variationId,
              useTickets: item.useTickets,
            );

            // Replace the item in the list
            globals.orderMenus[index] = updatedItem;
          }
        });
      },
    );
  }

  Widget _getMenuItems(e) {
    return GestureDetector(
      onTap: () async {
        reserveMenuAdd(e);
      },
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: Stack(
                children: [
                  // Positioned(
                  //     right: 0,
                  //     top: 0,
                  //     child: Image.asset(
                  //       'images/icon_order_calculator.png',
                  //       scale: globals.isWideScreen ? 1.1 : 1.8,
                  //     )),
                  Positioned.fill(
                    child: Container(
                        alignment: Alignment.center,
                        child: Text(e.menuTitle,
                            style: const TextStyle(fontSize: 14))),
                  )
                ],
              )),
              Container(
                padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                decoration: BoxDecoration(
                    color: const Color(0xff4ca1d2),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '¥ ${Funcs().currencyFormat(e.menuPrice)}-',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: globals.isWideScreen ? 32 : 16),
                ),
              )
            ],
          )),
    );
  }

  Widget _getCategoryContent() {
    return DropDownModelSelect(
        value: selCategory,
        items: [
          DropdownMenuItem(
              value: "0",
              child: Text('すべて',
                  style: TextStyle(
                    fontSize: 12,
                  ))),
          ...categories.map((c) => DropdownMenuItem(
              value: c.id.toString(),
              child: Text(c.name,
                  style: TextStyle(
                    fontSize: 12,
                  )))),
        ],
        tapFunc: (v) async {
          selCategory = v.toString();
          Dialogs().loaderDialogNormal(context);
          await loadUpdateCategoryData();
          Navigator.pop(context);
        });
  }
}

class OrderItemList extends StatelessWidget {
  final item;
  final rowNm;
  final GestureTapCallback? onTap;
  final Function(OrderMenuModel, String)? onQuantityChanged;

  const OrderItemList(
      {required this.item,
      required this.rowNm,
      this.onTap,
      this.onQuantityChanged,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: rowNm % 2 == 1
            ? Colors.white
            : const Color.fromRGBO(238, 250, 255, 1),
        padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
        child: Row(
          children: [
            Expanded(
                // padding: EdgeInsets.only(top: 12),
                // width: 180,
                child: Container(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    // width: 110,
                    child: Text(item.menuTitle,
                        style: TextStyle(
                            fontSize: globals.isWideScreen ? 20 : 16,
                            color: Color.fromRGBO(70, 88, 134, 1),
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(' × ',
                      style: TextStyle(
                          fontSize: 16,
                          color: Color.fromRGBO(70, 88, 134, 1),
                          fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () async {
                      if (onQuantityChanged == null) return;

                      String selQuantity = item.quantity;
                      final value = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('数量を変更'),
                          content: SizedBox(
                            height: 90,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                DropDownNumberSelect(
                                  value: selQuantity,
                                  max: 50,
                                  tapFunc: (v) {
                                    selQuantity = v;
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("確定"),
                              onPressed: () =>
                                  Navigator.of(context).pop(selQuantity),
                            ),
                            TextButton(
                              child: const Text("キャンセル"),
                              onPressed: () => Navigator.of(context).pop(null),
                            ),
                          ],
                        ),
                      );

                      if (value != null && value != item.quantity) {
                        // Call the callback to update the quantity
                        onQuantityChanged!(item, value);
                      }
                    },
                    child: Container(
                      width: 60,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(item.quantity,
                          style: TextStyle(
                              fontSize: globals.isWideScreen ? 20 : 16,
                              color: Color.fromRGBO(70, 88, 134, 1),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )),
            Container(width: globals.isWideScreen ? 80 : 25),
            GestureDetector(
              onTap: onTap,
              child: Container(
                  margin: EdgeInsets.only(top: 10),
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  width: 100,
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(70, 88, 134, 1),
                        fontWeight: FontWeight.bold),
                  )),
            ),
          ],
        ));
  }
}
