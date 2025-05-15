import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/apiendpoint.dart';
import 'package:staff_pos_app/src/common/business/category.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/common/messages.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/form_widgets.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/interface/components/textformfields.dart';
import 'package:staff_pos_app/src/model/category_model.dart';
import 'package:staff_pos_app/src/model/menumodel.dart';
import 'package:staff_pos_app/src/model/menuvariationmodel.dart';
import 'package:staff_pos_app/src/model/variationbackstaffmodel.dart';

import 'package:staff_pos_app/src/common/globals.dart' as globals;
import 'package:staff_pos_app/src/http/webservice.dart';

// var txtAccountingController = TextEditingController();
// var txtMenuCountController = TextEditingController();
// var txtSetTimeController = TextEditingController();
// var txtSetAmountController = TextEditingController();
// var txtTableAmountController = TextEditingController();

class CategoryEdit extends StatefulWidget {
  final String companyId;
  final String? catId;
  const CategoryEdit({required this.companyId, this.catId, super.key});

  @override
  _CategoryEdit createState() => _CategoryEdit();
}

class _CategoryEdit extends State<CategoryEdit> {
  late Future<List> loadData;

  MenuModel? menu;

  String isAdmin = '0';
  List<MenuVariationModel> variationList = [];
  List<MenuModel> menuList = [];
  List<VariationBackStaffModel> vStaffList = [];
  List<CategoryModel> categories = [];

  var txtTitleController = TextEditingController();
  var txtCodeController = TextEditingController();
  var txtAliasController = TextEditingController();
  var txtCommentController = TextEditingController();
  var txtOrderNoController = TextEditingController();

  String? errTitle;
  String? errCode;
  String? errAlias;
  String? errComment;
  String? errOrderNo;

  String? catId;

  @override
  void initState() {
    super.initState();
    catId = widget.catId;
    loadData = loadInitData();
  }

  Future<List> loadInitData() async {
    if (catId == null) {
      return [];
    }

    CategoryModel category = await ClCategory().getCategory(context, catId);

    txtTitleController.text = category.name;
    txtCodeController.text = category.code;
    txtAliasController.text = category.alias;
    txtCommentController.text = category.description;
    txtOrderNoController.text = category.orderNo.toString();
    setState(() {});

    return [];
  }

  Future<void> saveData() async {
    FocusScope.of(context).requestFocus(FocusNode());

    bool isCheck = true;
    String? errTxtTitle;

    if (txtTitleController.text == '') {
      errTxtTitle = warningCommonInputRequire;
      isCheck = false;
    }
    setState(() {
      errTitle = errTxtTitle;
    });

    if (!isCheck) return;

    Dialogs().loaderDialogNormal(context);

    bool isSave = await ClCategory().save(context, {
      'company_id': widget.companyId,
      'category_id': catId ?? '',
      'name': txtTitleController.text,
      'code': txtCodeController.text,
      'alias': txtAliasController.text,
      'description': txtCommentController.text,
      'order_no': txtOrderNoController.text,
    });

    if (mounted) {
      Navigator.pop(context);
      if (isSave) {
        Navigator.pop(context);
      } else {
        Dialogs().infoDialog(context, errServerActionFail);
      }
    }
  }

  Future<void> deleteData() async {
    bool conf = await Dialogs().confirmDialog(context, qCommonDelete);

    if (!conf) return;

    if (mounted) {
      Dialogs().loaderDialogNormal(context);
      bool isDelete = await ClCategory().delete(context, catId);
      if (!mounted) return;
      Navigator.pop(context);

      if (isDelete) {
        Navigator.pop(context);
      } else {
        Dialogs().infoDialog(context, errServerActionFail);
      }
    }
  }

  Future<void> deleteVariation(String id) async {
    bool conf = await Dialogs().confirmDialog(context, qCommonDelete);

    if (!conf) return;
    if (mounted) {
      Dialogs().loaderDialogNormal(context);
      Map<dynamic, dynamic> results = {};
      await Webservice()
          .loadHttp(context, apiDeleteMenuVariationUrl, {'variation_id': id})
          .then((v) => results = v);

      if (mounted) {
        Navigator.pop(context);
        if (results['isDelete']) {
          setState(() {
            // loadData = loadMenuData();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    globals.appTitle = 'カテゴリ';
    return MainBodyWdiget(
      render: FutureBuilder<List>(
        future: loadData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _getBody();
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _getBody() {
    return Container(
      color: bodyColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [_getContent()]),
            ),
          ),
          _getBottomButton(),
        ],
      ),
    );
  }

  Widget _getContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
      child: Column(
        children: [
          RowLabelInput(
            label: 'カテゴリ名',
            renderWidget: TextInputNormal(
              multiLine: 1,
              controller: txtTitleController,
              errorText: errTitle,
            ),
          ),
          SizedBox(height: 8),
          RowLabelInput(
            label: '管理コード',
            renderWidget: TextInputNormal(
              multiLine: 1,
              controller: txtCodeController,
            ),
          ),
          SizedBox(height: 8),
          RowLabelInput(
            label: '略名',
            renderWidget: TextInputNormal(
              multiLine: 1,
              controller: txtAliasController,
            ),
          ),
          SizedBox(height: 8),
          RowLabelInput(
            label: '説明 ',
            labelPadding: 4,
            renderWidget: TextInputNormal(
              multiLine: 5,
              controller: txtCommentController,
            ),
          ),
          RowLabelInput(
            label: '表示順序',
            renderWidget: TextInputNormal(
              multiLine: 1,
              controller: txtOrderNoController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBottomButton() {
    return RowButtonGroup(
      widgets: [
        PrimaryButton(label: '保存', tapFunc: () => saveData()),
        SizedBox(width: 8),
        CancelButton(label: '戻る', tapFunc: () => Navigator.pop(context)),
        SizedBox(width: 8),
        DeleteButton(
          label: '削除',
          tapFunc: catId == null ? null : () => deleteData(),
        ),
      ],
    );
  }
}

class MenuEditVariationTile extends StatelessWidget {
  final MenuVariationModel item;
  final editFunc;
  final delFunc;
  const MenuEditVariationTile({
    required this.item,
    required this.editFunc,
    required this.delFunc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
        color: Color.fromARGB(255, 220, 220, 220),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 15),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 100,
                    child: Text('バリエーション名', style: TextStyle(fontSize: 12)),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(item.variationTitle),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 15),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 100,
                    child: Text('税抜価格', style: TextStyle(fontSize: 12)),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(item.variationPrice),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 15),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 100,
                    child: Text('バックスタッフ', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 30),
                  Flexible(
                    // padding: EdgeInsets.only(left: 30),
                    child: Column(
                      children: [
                        item.staffName == null
                            ? Text('')
                            : Text(item.staffName!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 15),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 100,
                    child: Text('バック金額', style: TextStyle(fontSize: 12)),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(item.variationAmount!),
                  ),
                ],
              ),
            ),
            RowButtonGroup(
              bgColor: Colors.transparent,
              widgets: [
                Expanded(child: Container()),
                PrimaryButton(label: '変更', tapFunc: editFunc),
                SizedBox(width: 8),
                DeleteButton(label: '削除', tapFunc: delFunc),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
