import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/business/orders.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/dlgentering.dart';
import 'package:staff_pos_app/src/interface/pos/accounting/tabledetail.dart';
import 'package:staff_pos_app/src/model/order_model.dart';
import '../../../common/globals.dart' as globals;

class Tables extends StatefulWidget {
  const Tables({super.key});

  @override
  State<Tables> createState() => _Tables();
}

class _Tables extends State<Tables> {
  late Future<List> loadData;
  List<OrderModel> tableList = [];
  List<OrderModel> currentRequestTableList = [];
  String posAmount = '0';
  bool isSeatChangeMode = false;
  bool isCombineMode = false;
  OrderModel? firstSelectedSeat;
  OrderModel? secondSelectedSeat;

  @override
  void initState() {
    super.initState();
    loadData = loadTables();
  }

  void resetModes() {
    setState(() {
      isSeatChangeMode = false;
      isCombineMode = false;
      firstSelectedSeat = null;
      secondSelectedSeat = null;
    });
  }

  Widget _buildConfirmationDialog(bool isSwap) {
    return AlertDialog(
      title: Text(
        isSwap ? '席の交換を確認' : '注文の合算を確認',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwap ? '以下の席の情報を交換します：' : '以下の席の注文を合算します：',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            FutureBuilder<OrderModel?>(
              future: ClOrder().loadOrderInfo(
                context,
                firstSelectedSeat!.orderId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                return _buildSeatInfoCard(
                  '席1',
                  snapshot.data ?? firstSelectedSeat!,
                  isSwap ? '交換先' : '合算先',
                );
              },
            ),
            SizedBox(height: 10),
            FutureBuilder<OrderModel?>(
              future: ClOrder().loadOrderInfo(
                context,
                secondSelectedSeat!.orderId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                return _buildSeatInfoCard(
                  '席2',
                  snapshot.data ?? secondSelectedSeat!,
                  isSwap ? '交換先' : '合算元',
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              isSwap
                  ? '※ 両方の席の情報（注文内容、人数情報など）が交換されます。'
                  : '※ 席2の注文内容が席1に追加され、席2は空席になります。',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          label: '確認',
          tapFunc: () {
            Navigator.of(context).pop(true);
          },
        ),
        TextButton(
          child: Text('キャンセル'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
      ],
    );
  }

  Widget _buildSeatInfoCard(String title, OrderModel seat, String resultLabel) {
    bool isEmpty = seat.status == constOrderStatusNone;

    // Calculate flow time
    String flowTime = '';
    if (seat.flowTime > 0) {
      int flowH = seat.flowTime ~/ 60;
      int flowM = seat.flowTime % 60;
      flowTime = '${flowH < 10 ? '0' : ''}$flowH 時間  ';
      flowTime += '${flowM < 10 ? '0' : ''}$flowM 分';
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$title: ${seat.seatno}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isEmpty ? '空席' : resultLabel,
                  style: TextStyle(
                    color: isEmpty ? Colors.grey : Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (isEmpty)
            Text('現在空席です', style: TextStyle(fontSize: 14, color: Colors.grey))
          else ...[
            Text('テーブル名: ${seat.tableTitle}', style: TextStyle(fontSize: 14)),
            if (seat.amount > 0)
              Text(
                '合計金額: ¥${seat.amount.toString()}',
                style: TextStyle(fontSize: 14),
              ),
            if (int.parse(seat.userCount) > 0)
              Text('人数: ${seat.userCount}名', style: TextStyle(fontSize: 14)),
            if (flowTime.isNotEmpty)
              Text('利用時間: $flowTime', style: TextStyle(fontSize: 14)),
            if (seat.menus.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                '注文内容:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              ...seat.menus.map(
                (menu) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '・${menu.menuTitle} x ${menu.quantity}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> handleSeatSelection(OrderModel selectedSeat) async {
    if (!isSeatChangeMode && !isCombineMode) {
      // Normal mode - just open table details
      await pushTableDetail(selectedSeat.orderId, selectedSeat.seatno);
      return;
    }

    // In combine mode, prevent selecting empty seats
    if (isCombineMode && selectedSeat.status == constOrderStatusNone) {
      return;
    }

    // Check if the clicked seat is already selected
    if (firstSelectedSeat?.seatno == selectedSeat.seatno) {
      setState(() {
        firstSelectedSeat = null;
      });
      return;
    }
    if (secondSelectedSeat?.seatno == selectedSeat.seatno) {
      setState(() {
        secondSelectedSeat = null;
      });
      return;
    }
    // In seat change mode, prevent selecting second empty seat if first is empty
    if (isSeatChangeMode &&
        selectedSeat.status == constOrderStatusNone &&
        firstSelectedSeat?.status == constOrderStatusNone) {
      if (mounted) {
        Dialogs().infoDialog(context, '空席同士の交換はできません。');
      }
      return;
    }

    if (firstSelectedSeat == null) {
      setState(() {
        firstSelectedSeat = selectedSeat;
      });
      return;
    }

    if (secondSelectedSeat == null) {
      setState(() {
        secondSelectedSeat = selectedSeat;
      });

      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _buildConfirmationDialog(isSeatChangeMode),
      );

      if (confirmed != true) {
        // User cancelled, reset selection
        setState(() {
          secondSelectedSeat = null;
        });
        return;
      }

      if (isSeatChangeMode) {
        if (mounted) {
          bool result = await ClOrder().swapSeats(
            context,
            firstSelectedSeat!.orderId,
            secondSelectedSeat!.orderId,
            firstSelectedSeat!.seatno,
            secondSelectedSeat!.seatno,
          );
          if (!result) {
            if (mounted) {
              Dialogs().infoDialog(context, '席の交換に失敗しました。');
              return;
            }
          }
        }
      } else if (isCombineMode) {
        if (mounted) {
          bool result = await ClOrder().combineSeats(
            context,
            firstSelectedSeat!.orderId,
            secondSelectedSeat!.orderId,
          );
          if (!result) {
            if (mounted) {
              Dialogs().infoDialog(context, '注文の合算に失敗しました。');
              return;
            }
          }
        }
      }

      // Reset modes and reload tables
      resetModes();
      await loadTables();
    }
  }

  void toggleSeatChangeMode() {
    setState(() {
      isSeatChangeMode = !isSeatChangeMode;
      isCombineMode = false;
      firstSelectedSeat = null;
      secondSelectedSeat = null;
    });
  }

  void toggleCombineMode() {
    setState(() {
      isCombineMode = !isCombineMode;
      isSeatChangeMode = false;
      firstSelectedSeat = null;
      secondSelectedSeat = null;
    });
  }

  Future<void> currentOrderAccept(OrderModel currentOrder) async {
    Navigator.of(context).pop();
    Dialogs().loaderDialogNormal(context);
    await ClOrder().acceptOrderRequestTables(
      context,
      currentOrder.orderId,
      globals.staffId,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return DlgEntering(
              userId: currentOrder.userId,
              orderId: currentOrder.orderId,
              tablePosition: currentOrder.seatno,
            );
          },
        ),
      );
    }
    if (mounted) {
      Dialogs().loaderDialogNormal(context);
      await loadTables();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<List> loadTables() async {
    tableList = [];
    tableList = await ClOrder().loadOrganTables(
      context,
      globals.organId,
      globals.staffId,
    );
    currentRequestTableList = [];
    if (mounted) {
      currentRequestTableList = await ClOrder().loadCureentRequestTables(
        context,
        globals.organId,
        globals.staffId,
      );
    }
    for (var item in currentRequestTableList) {
      if (item.userName != '' && mounted) {
        showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('${globals.loginName}さんをご指名のお客様を対応しますか？'),
                actions: [
                  TextButton(
                    child: const Text('はい'),
                    onPressed: () => {currentOrderAccept(item)},
                  ),
                  TextButton(
                    child: const Text('いいえ'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    }
    if (mounted) {
      setState(() {});
    }
    return tableList;
  }

  Future<void> pushTableDetail(orderId, position) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return TableDetail(orderId: orderId, tablePosition: position);
        },
      ),
    );

    loadTables();
  }

  Future<void> updateTitle(String title, position) async {
    Navigator.of(context).pop();
    if (title == '') return;

    bool isUpdate = await ClOrder().updateTableTitle(
      context,
      globals.organId,
      position,
      title,
    );
    if (isUpdate) {
      loadTables();
    } else {
      if (mounted) {
        Dialogs().infoDialog(context, errServerActionFail);
      }
    }
  }

  void titleChangeDialog(String txtInputTitle, String position) {
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
                onPressed: () => {updateTitle(controller.text, position)},
              ),
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    globals.appTitle = '注文・会計';
    return MainBodyWdiget(
      render: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: FutureBuilder<List>(
              future: loadData,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _getBodyContent(orientation);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                // By default, show a loading spinner.
                return CircularProgressIndicator();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _getModeButton(String label, bool isActive, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.grey : Color(0xff117fc1),
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(label, style: btnTxtStyle1),
      ),
    );
  }

  Widget _getBodyContent(orientation) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              if (!isSeatChangeMode && !isCombineMode)
                Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: DeleteColButton(
                    label: '入店お断り',
                    tapFunc: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            return DlgEntering(
                              isReject: true,
                              tablePosition: 'widget.tableId',
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (!isCombineMode)
                _getModeButton(
                  isSeatChangeMode ? '席変更 解除' : '席変更',
                  isSeatChangeMode,
                  toggleSeatChangeMode,
                ),
              if (!isSeatChangeMode)
                _getModeButton(
                  isCombineMode ? '合算 解除' : '合算',
                  isCombineMode,
                  toggleCombineMode,
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  GridView.count(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding:
                        globals.isWideScreen
                            ? EdgeInsets.fromLTRB(150, 0, 120, 20)
                            : EdgeInsets.fromLTRB(40, 0, 40, 20),
                    crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
                    crossAxisSpacing: globals.isWideScreen ? 60 : 15,
                    mainAxisSpacing: globals.isWideScreen ? 30 : 25,
                    childAspectRatio: 0.95,
                    children: [
                      ...tableList.map((d) => _getTableItemContent(d)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // if (globals.auth > AUTH_STAFF)
          //   Container(
          //     height: 60,
          //     padding: EdgeInsets.only(top: 10, bottom: 10),
          //     child: Column(
          //       children: <Widget>[
          //         Container(
          //           child: Text(
          //             'レジ現金残高    ￥' + Funcs().currencyFormat(posAmount),
          //             style: TextStyle(
          //                 fontSize: 22,
          //                 color: Colors.white,
          //                 fontWeight: FontWeight.bold),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _getTableItemContent(OrderModel item) {
    return Stack(
      children: [
        Positioned.fill(
          left: 10,
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onLongPress: () => titleChangeDialog(item.tableTitle, item.seatno),
            child: _getTableItemButton(item),
          ),
        ),
        Positioned(right: 0, bottom: 0, child: _getItemPlusMark(item)),
      ],
    );
  }

  Widget _getTableItemButton(OrderModel item) {
    bool isSelected =
        (isSeatChangeMode || isCombineMode) &&
        (firstSelectedSeat?.seatno == item.seatno ||
            secondSelectedSeat?.seatno == item.seatno);

    return ElevatedButton(
      onPressed: () => handleSeatSelection(item),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side:
              isSelected
                  ? BorderSide(color: Colors.blue, width: 3)
                  : BorderSide.none,
        ),
        elevation: isSelected ? 4 : 0,
        backgroundColor:
            isSelected
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
        foregroundColor:
            (item.status == constOrderStatusTableStart ||
                    item.status == constOrderStatusTableEnd)
                ? Color.fromRGBO(255, 137, 155, 1)
                : (item.status == constOrderStatusReserveApply
                    ? Color(0xFF00856a)
                    : Color.fromRGBO(24, 100, 123, 1)),
        textStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        children: [
          Expanded(child: Container()),
          Text(
            item.seatno,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: EdgeInsets.only(bottom: 8),
            margin: EdgeInsets.symmetric(
              vertical: globals.isWideScreen ? 28 : 16,
            ),
            child: Column(
              children: [
                Text(
                  item.tableTitle,
                  style: TextStyle(fontSize: globals.isWideScreen ? 32 : 20),
                ),
                if (item.status != constOrderStatusReserveApply)
                  Text(
                    item.staffName,
                    style: TextStyle(fontSize: globals.isWideScreen ? 24 : 14),
                  ),
                if (item.status == constOrderStatusReserveApply)
                  Text(
                    item.userName,
                    style: TextStyle(fontSize: globals.isWideScreen ? 24 : 14),
                  ),
              ],
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Widget _getItemPlusMark(OrderModel item) {
    return Container(
      width: globals.isWideScreen ? 60 : 45,
      height: globals.isWideScreen ? 60 : 45,
      decoration: BoxDecoration(
        color:
            (item.status == constOrderStatusTableStart ||
                    item.status == constOrderStatusTableEnd)
                ? Color.fromRGBO(255, 137, 155, 1)
                : (item.status == constOrderStatusReserveApply
                    ? Color(0xFF00856a)
                    : Color.fromRGBO(24, 100, 123, 1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        (item.status == constOrderStatusTableStart ||
                item.status == constOrderStatusTableEnd)
            ? Icons.check
            : (item.status == constOrderStatusReserveApply
                ? Icons.lock_clock
                : Icons.add),
        size: 28,
        color: Colors.white,
      ),
    );
  }
}
