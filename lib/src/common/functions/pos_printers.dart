import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:euc/jis.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_beep_plus/flutter_beep_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart';
import 'package:staff_pos_app/src/common/business/company.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/functions.dart';
import 'package:staff_pos_app/src/model/companymodel.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';

import '../apiendpoint.dart';
import '../const.dart';
import '../../common/globals.dart' as globals;

class PosPrinters {
  late Socket _socket;
  late Generator generator;
  Future<bool> isConnect(String ip, String port) async {
    bool isConnected = false;

    final profile = await CapabilityProfile.load();
    generator = Generator(PaperSize.mm80, profile);

    try {
      _socket = await Socket.connect(
        ip,
        int.parse(port),
        timeout: const Duration(seconds: 5),
      );
      _socket.add(generator.reset());
      Fluttertoast.showToast(msg: "Printer connection success");
      isConnected = true;
    } catch (e) {
      Fluttertoast.showToast(msg: "Printer connection fail");
    }

    return isConnected;
  }

  Future<void> testPrinter(ip, port) async {
    await saveIPandPort(ip, port);

    bool isConnected = await isConnect(ip, port);
    if (isConnected) {
      // await receiptPrint('s');
      _socket.destroy();
    }
  }

  Future<void> saveIPandPort(ip, port) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('printer_ip', ip);
    prefs.setString('printer_port', port);
  }

  Future<Generator> loadPrinter() async {
    return generator;
  }

  // Future<void> testFeature() async {
  //   final profile = await CapabilityProfile.load();
  //   generator = Generator(PaperSize.mm80, profile);
  //   final ByteData data = await rootBundle.load('images/receipt_img1.png');
  //   final Uint8List bytes = data.buffer.asUint8List();
  //   final image = decodeImage(bytes);
  //   if (image != null) {
  //     final grayImage = grayscale(image);
  //     List<int> result = generator.image(grayImage);
  //     print(result);
  //   }
  // }

  Future<void> ticketPrint(printData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var printerIP =
        prefs.getString('printer_ip') == null
            ? '172.20.106.72'
            : prefs.getString('printer_ip')!;
    var printerPort =
        prefs.getString('printer_port') == null
            ? '9100'
            : prefs.getString('printer_port')!;
    if (printerIP == '' || printerPort == '') {
      Fluttertoast.showToast(msg: 'プリンタを設定してください。');
      return;
    }

    bool isConnected = await isConnect(printerIP, printerPort);
    if (isConnected) {
      try {
        await runPrintTicket(printData);
      } catch (e) {
        Fluttertoast.showToast(msg: "ticketPrint error $e");
      }
      _socket.destroy();
      await Future.delayed(const Duration(milliseconds: 500), () => null);
    }
  }

  Future<void> runPrintTicket(printData) async {
    FlutterBeepPlus().playSysSound(
      AndroidSoundID.TONE_CDMA_CALL_SIGNAL_ISDN_PING_RING,
    );

    _socket.add(
      generator.textEncoded(
        Uint8List.fromList(encodeToJapanese(printData['organ_name'])),
        styles: const PosStyles(
          width: PosTextSize.size2,
          height: PosTextSize.size2,
          align: PosAlign.center,
        ),
      ),
    );

    _socket.add(generator.emptyLines(1));
    await _socket.flush();

    _socket.add(
      generator.row([
        PosColumn(
          textEncoded: Uint8List.fromList(encodeToJapanese('席')),
          styles: const PosStyles(align: PosAlign.right),
          width: 2,
        ),
        PosColumn(
          text: '  ${printData['table_position']}  ',
          width: 2,
          styles: const PosStyles(align: PosAlign.left, underline: true),
        ),
        PosColumn(
          text: DateFormat('MM/dd HH:mm').format(DateTime.now()),
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    await _socket.flush();

    _socket.add(generator.hr());
    _socket.add(
      generator.row([
        PosColumn(
          text: 'No',
          width: 1,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          textEncoded: Uint8List.fromList(encodeToJapanese('メニュー名')),
          width: 5,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          textEncoded: Uint8List.fromList(encodeToJapanese('単価')),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          textEncoded: Uint8List.fromList(encodeToJapanese('数量')),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          textEncoded: Uint8List.fromList(encodeToJapanese('金額')),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    await _socket.flush();

    _socket.add(generator.hr());
    int i = 0;
    int sum = 0;
    printData['menus'].forEach((e) {
      i++;
      int menuPrice = 0;
      try {
        menuPrice = int.parse(e.menuPrice);
      } catch (ex) {
        menuPrice = double.parse(e.menuPrice).toInt();
      }
      String menuTitle = e.menuTitle;
      if(menuTitle.length > 8) {
        menuTitle = menuTitle.substring(0, 8);
      }

      _socket.add(
        generator.row([
          PosColumn(
            text: i.toString(),
            width: 1,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            textEncoded: Uint8List.fromList(encodeToJapanese(menuTitle)),
            width: 5,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: Funcs().currencyFormat("$menuPrice"),
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: e.quantity,
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: Funcs().currencyFormat(
              (menuPrice * int.parse(e.quantity)).toString(),
            ),
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      sum += menuPrice * int.parse(e.quantity);
    });
    await _socket.flush();

    _socket.add(generator.hr());

    _socket.add(
      generator.textEncoded(
        Uint8List.fromList(
          encodeToJapanese('合計 : ￥${Funcs().currencyFormat(sum.toString())}-'),
        ),
        styles: const PosStyles(align: PosAlign.right),
      ),
    );

    _socket.add(generator.hr(ch: '='));
    await _socket.flush();

    _socket.add(generator.feed(2));
    _socket.add(generator.cut());
    await _socket.flush();
    // return bytes;
  }

  Future<void> receiptPrint(context, printData, organId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var printerIP =
        prefs.getString('printer_ip') == null
            ? '172.20.106.72'
            : prefs.getString('printer_ip')!;
    var printerPort =
        prefs.getString('printer_port') == null
            ? '9100'
            : prefs.getString('printer_port')!;
    if (printerIP == '' || printerPort == '') {
      //Fluttertoast.showToast(msg: 'プリンタを設定してください。');
      return;
    }

    bool isConnected = await isConnect(printerIP, printerPort);
    if (isConnected) {
      try {
        await runReceiptPrint(context, printData, organId);
      } catch (e) {
        Fluttertoast.showToast(msg: "runReceiptPrint error $e");
      }
      _socket.destroy();
      await Future.delayed(const Duration(milliseconds: 500), () => null);
    }
  }

  Future<void> runReceiptPrint(context, printData, organId) async {
    String organName = '';
    String organAddress = '';
    String organTel = '';
    String organPrintOrder = '00001';
    String logoUrl = '';
    bool isServiceTax = false;
    double serviceTax = 1;
    if (organId != '') {
      OrganModel organ = await ClOrgan().loadOrganInfo(context, organId);
      organName = organ.organName;
      organAddress = organ.organAddress;
      organTel = organ.organPhone;
      organPrintOrder = await ClOrgan().loadPrintOrder(
        context,
        organId,
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      if (organ.printLogoUrl != null) {
        logoUrl = apiPrintLogoUrl + organ.printLogoUrl!;
      }

      if (organ.isServiceTax != "" && organ.isServiceTax == "1") {
        isServiceTax = true;
        serviceTax = 1 + (int.parse(organ.serviceTax!) / 100).toDouble();
      }
    }

    CompanyModel company = await ClCompany().loadCompanyPrintInfo(
      context,
      globals.companyId,
    );
    String receiptNum = company.companyReceiptNumber;
    String companyPrintOrder = '0000${company.companyPrintOrder}';

    if (logoUrl != '') {
      final ByteData data = await NetworkAssetBundle(
        Uri.parse(logoUrl),
      ).load(logoUrl);

      final Uint8List bytes = data.buffer.asUint8List();
      final image = decodeImage(bytes);

      if (image != null) _socket.add(generator.image(image));
    }

    _socket.add(generator.feed(1));
    _socket.add(
      generator.textEncoded(
        encodeToJapanese(organName),
        styles: const PosStyles(
          align: PosAlign.center,
          underline: true,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      ),
    );
    _socket.add(generator.feed(2));
    _socket.add(
      generator.textEncoded(
        encodeToJapanese('領  収  書'),
        styles: const PosStyles(
          align: PosAlign.center,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      ),
    );
    _socket.add(generator.feed(2));
    await _socket.flush();

    String str = '                                                    ';

    _socket.add(
      generator.textEncoded(
        encodeToJapanese(('$str様').substring(('$str様').length - 22)),
        styles: const PosStyles(
          underline: true,
          align: PosAlign.center,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      ),
    );
    _socket.add(generator.feed(1));

    String tmpam = '$str￥${Funcs().currencyFormat(printData['amount'])}-';
    _socket.add(
      generator.textEncoded(
        encodeToJapanese(tmpam.substring(tmpam.length - 22)),
        styles: const PosStyles(
          underline: true,
          align: PosAlign.center,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      ),
    );
    await _socket.flush();

    // _socket.add(generator.row([
    //   PosColumn(textEncoded: encodeToJapanese('     (うち消費税額'), width: 6),
    //   PosColumn(
    //       textEncoded: encodeToJapanese('￥' + '87' + ')     '),
    //       width: 6,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]));
    _socket.add(generator.feed(1));
    _socket.add(
      generator.textEncoded(encodeToJapanese('上記          として領収致しました。')),
    );
    _socket.add(generator.feed(1));
    await _socket.flush();

    if (Platform.isAndroid) {
      try {
        final ByteData data = await rootBundle.load('images/receipt_img1.png');
        final Uint8List bytes = data.buffer.asUint8List();
        final image = decodeImage(bytes);
        if (image != null) {
          final grayImage = grayscale(image);
          _socket.add(generator.image(grayImage));
          await _socket.flush();
        }
      } catch (e) {
        print('Error processing image: $e');
      }
    } else {
      _socket.add(
        generator.textEncoded(
          encodeToJapanese('┌─────┐'),
          styles: PosStyles(align: PosAlign.center),
        ),
      );
      _socket.add(
        generator.textEncoded(
          encodeToJapanese('│ ￥50,000 │'),
          styles: PosStyles(align: PosAlign.center),
        ),
      );
      _socket.add(
        generator.textEncoded(
          encodeToJapanese('│  末満印  │'),
          styles: PosStyles(align: PosAlign.center),
        ),
      );
      _socket.add(
        generator.textEncoded(
          encodeToJapanese('│  紙不要  │'),
          styles: PosStyles(align: PosAlign.center),
        ),
      );
      _socket.add(
        generator.textEncoded(
          encodeToJapanese('└─────┘'),
          styles: PosStyles(align: PosAlign.center),
        ),
      );
    }

    _socket.add(generator.feed(1));
    _socket.add(generator.textEncoded(encodeToJapanese('★保管上のお願い')));
    _socket.add(
      generator.textEncoded(encodeToJapanese('財布等で保管頂く場合、印刷面を内側に折って保管願います。')),
    );
    _socket.add(generator.feed(1));
    _socket.add(generator.textEncoded(encodeToJapanese(organName)));
    _socket.add(generator.textEncoded(encodeToJapanese(organAddress)));
    _socket.add(generator.text('TEL$organTel'));
    _socket.add(generator.textEncoded(encodeToJapanese('登録番号：$receiptNum')));
    _socket.add(generator.feed(1));
    await _socket.flush();

    _socket.add(
      generator.row([
        PosColumn(
          textEncoded: encodeToJapanese(
            '${DateFormat('y年M月d日').format(DateTime.now())}(${weekAry.elementAt(DateTime.now().weekday - 1)})',
          ),
          width: 8,
        ),
        PosColumn(
          text: DateFormat('HH:mm:ss').format(DateTime.now()),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    _socket.add(
      generator.text(
        'No.$organPrintOrder',
        styles: const PosStyles(align: PosAlign.right),
      ),
    );

    _socket.add(
      generator.row([
        PosColumn(
          textEncoded: encodeToJapanese('席：${printData['position']}'),
          width: 8,
        ),
        PosColumn(
          textEncoded: encodeToJapanese(printData['user_count'] + '名'),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    _socket.add(generator.textEncoded(encodeToJapanese('※は軽減税率対象商品')));
    _socket.add(generator.feed(1));
    await _socket.flush();

    int sum = 0;
    int cnt = 0;
    if (int.parse(printData['table_amount']) > 0) {
      _socket.add(
        generator.row([
          PosColumn(textEncoded: encodeToJapanese('入店料金'), width: 8),
          PosColumn(
            textEncoded: encodeToJapanese(
              '￥${Funcs().currencyFormat(printData['table_amount'])}',
            ),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      cnt++;
      sum += int.parse(printData['table_amount']);
    }
    await _socket.flush();

    if (int.parse(printData['set_amount']) > 0) {
      _socket.add(
        generator.row([
          PosColumn(textEncoded: encodeToJapanese('延長料金'), width: 8),
          PosColumn(
            textEncoded: encodeToJapanese(
              '￥${Funcs().currencyFormat(printData['set_amount'])}',
            ),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      sum += int.parse(printData['set_amount']);
      cnt++;
    }

    for (var item in printData['menus']) {
      double taxRate =
          (1 + (item.menuTax == '' ? 0 : (int.parse(item.menuTax) / 100)))
              .toDouble();
      String am =
          (double.parse(item.menuPrice).toInt() *
                  taxRate *
                  int.parse(item.quantity))
              .toInt()
              .toString();
      String menuTitle = item.menuTitle;
      if (menuTitle.length > 15) {
        menuTitle = menuTitle.substring(0, 15);
      }
      _socket.add(
        generator.row([
          PosColumn(textEncoded: encodeToJapanese(menuTitle), width: 9),
          PosColumn(
            textEncoded: encodeToJapanese('￥${Funcs().currencyFormat(am)}'),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      cnt++;
      sum +=
          (double.parse(item.menuPrice).toInt() *
                  taxRate *
                  int.parse(item.quantity))
              .toInt();
    }

    await _socket.flush();
    if (isServiceTax && serviceTax > 1) {
      _socket.add(
        generator.row([
          PosColumn(textEncoded: encodeToJapanese('サービス料'), width: 8),
          PosColumn(
            textEncoded: encodeToJapanese(
              '￥${Funcs().currencyFormat((sum * serviceTax).toInt().toString())}',
            ),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    _socket.add(generator.hr());
    _socket.add(
      generator.row([
        PosColumn(textEncoded: encodeToJapanese('内税 10%'), width: 4),
        PosColumn(
          textEncoded: encodeToJapanese('(￥${sum - sum ~/ 11})'),
          width: 4,
        ),
        PosColumn(
          textEncoded: encodeToJapanese('￥${sum ~/ 11}'),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    _socket.add(generator.hr());
    _socket.add(
      generator.row([
        PosColumn(textEncoded: encodeToJapanese('合計 $cnt点'), width: 8),
        PosColumn(
          textEncoded: encodeToJapanese(
            '￥${Funcs().currencyFormat(sum.toString())}',
          ),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    // _socket.add(generator.row([
    //   PosColumn(
    //       textEncoded: encodeToJapanese('電子マネー'),
    //       width: 8,
    //       styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
    //   PosColumn(
    //       textEncoded: encodeToJapanese('￥' + '960'),
    //       width: 4,
    //       styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)),
    // ]));
    // _socket.add(generator.row([
    //   PosColumn(textEncoded: encodeToJapanese('お釣'), width: 8),
    //   PosColumn(
    //       textEncoded: encodeToJapanese('￥' + '0'),
    //       width: 4,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]));
    String globalLoginName = globals.loginName;
    if(globalLoginName.length > 7) {
      globalLoginName = globalLoginName.substring(0, 7);
    }
    _socket.add(generator.feed(1));
    _socket.add(
      generator.row([
        PosColumn(
          textEncoded: encodeToJapanese('扱：$globalLoginName'),
          width: 6,
        ),
        PosColumn(
          text: 'No.$companyPrintOrder',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    _socket.add(generator.feed(2));
    _socket.add(generator.cut());
    await _socket.flush();
  }
  // void encodedKanji(String s, bool isLineAfter,
  //     {PosStyles styles = const PosStyles()}) {
  //   _socket.add(generator.setStyles(styles, isKanji: true));
  //   _socket.add(generator.rawBytes([28, 38], isKanji: true));
  //   _socket.add(generator.rawBytes(ShiftJIS().encode(s), isKanji: true));
  //   if (isLineAfter) _socket.add(generator.emptyLines(1));
  // }

  Uint8List encodeToJapanese(String s) {
    List<int> bytes = [];
    bytes += generator.rawBytes([28, 38], isKanji: true);
    bytes += generator.rawBytes(ShiftJIS().encode(s), isKanji: true);
    return Uint8List.fromList(bytes);
  }
}
