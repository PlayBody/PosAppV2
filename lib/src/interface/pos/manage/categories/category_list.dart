import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/common/business/category.dart';
import 'package:staff_pos_app/src/common/business/company.dart';
import 'package:staff_pos_app/src/common/business/menu.dart';
import 'package:staff_pos_app/src/common/business/organ.dart';
import 'package:staff_pos_app/src/common/const.dart';
import 'package:staff_pos_app/src/common/dialogs.dart';
import 'package:staff_pos_app/src/interface/components/buttons.dart';
import 'package:staff_pos_app/src/interface/components/dropdowns.dart';
import 'package:staff_pos_app/src/interface/components/form_widgets.dart';
import 'package:staff_pos_app/src/interface/components/loadwidgets.dart';
import 'package:staff_pos_app/src/interface/pos/manage/categories/category_edit.dart';
import 'package:staff_pos_app/src/interface/pos/manage/menus/menuedit.dart';
import 'package:staff_pos_app/src/model/category_model.dart';
import 'package:staff_pos_app/src/model/companymodel.dart';
import 'package:staff_pos_app/src/model/menumodel.dart';
import 'package:staff_pos_app/src/model/organmodel.dart';

import 'package:staff_pos_app/src/common/globals.dart' as globals;

var txtAccountingController = TextEditingController();
var txtMenuCountController = TextEditingController();
var txtSetTimeController = TextEditingController();
var txtSetAmountController = TextEditingController();
var txtTableAmountController = TextEditingController();

class CategoryList extends StatefulWidget {
  final String? organId;
  const CategoryList({this.organId, Key? key}) : super(key: key);

  @override
  _CategoryList createState() => _CategoryList();
}

class _CategoryList extends State<CategoryList> {
  late Future<List> loadData;
  String isAdmin = '0';
  List<MenuModel> menuList = [];
  List<CategoryModel> categories = [];
  String? selOrganId;
  String? selCompanyId;

  List<OrganModel> organList = [];
  List<CompanyModel> companyList = [];

  @override
  void initState() {
    super.initState();
    selOrganId = widget.organId;
    loadData = loadInitData();
  }

  Future<List<CategoryModel>> loadInitData() async {
    companyList = await ClCompany().loadCompanyList(context);
    if (selCompanyId == null) selCompanyId = companyList.first.companyId;

    if (globals.auth < constAuthSystem) selCompanyId = globals.companyId;

    organList = await ClOrgan().loadOrganList(context, selCompanyId!, '');
    categories = await ClCategory().getCategoryList(context, selCompanyId);
    print(categories);
    setState(() {});
    return categories;
  }

  Future<void> refreshLoad() async {
    Dialogs().loaderDialogNormal(context);
    await loadInitData();
    Navigator.pop(context);
  }

  Future<void> exchangeMenuSort(moveId, targetId) async {
    Dialogs().loaderDialogNormal(context);
    await ClMenu().exchangeMenuSort(context, moveId, targetId);

    refreshLoad();
    Navigator.pop(context);
  }

  Future<void> onCategoryEdit(String? catId) async {
    // globals.editMenuId = _menuId;
    await Navigator.push(context, MaterialPageRoute(builder: (_) {
      return CategoryEdit(
        catId: catId,
        companyId: selCompanyId!,
      );
    }));
    refreshLoad();
  }

  void onOrganChange(String? _organId) {
    selOrganId = _organId;
    refreshLoad();
  }

  void onCompanyChange(String _companyId) {
    selCompanyId = _companyId;
    selOrganId = null;
    refreshLoad();
  }

  @override
  Widget build(BuildContext context) {
    globals.appTitle = 'カテゴリー管理';
    return MainBodyWdiget(
      render: FutureBuilder<List>(
          future: loadData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _getBodyContents();
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return Center(child: CircularProgressIndicator());
          }),
    );
  }

  Widget _getBodyContents() {
    return Container(
      color: bodyColor,
      child: Column(children: [
        if (globals.auth == constAuthSystem) _getTopCompanies(),
        Expanded(
            child: SingleChildScrollView(
                child: Column(
                    children: [...categories.map((e) => _getCategoryContent(e))]))),
        RowButtonGroup(widgets: [
          PrimaryButton(label: '新規登録', tapFunc: () => onCategoryEdit(null))
        ])
      ]),
    );
  }

  Widget _getTopCompanies() {
    return Container(
      padding: EdgeInsets.all(20),
      child: DropDownModelSelect(
          value: selCompanyId,
          items: [
            ...companyList.map((e) => DropdownMenuItem(
                child: Text(e.companyName), value: e.companyId))
          ],
          tapFunc: (v) => onCompanyChange(v.toString())),
    );
  }

  // Widget _getCategoryRow(e) {
  //   return LongPressDraggable(
  //     data: e.menuId,
  //     child: DragTarget(
  //         builder: (context, candidateData, rejectedData) =>
  //             _getCategoryContent(e),
  //         onAccept: (menuId) => exchangeMenuSort(menuId, e.menuId)),
  //     feedback: Container(
  //       color: Colors.grey.withOpacity(0.3),
  //       child: Text(e.menuTitle,
  //           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
  //     ),
  //   );
  // }

  Widget _getCategoryContent(CategoryModel e) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        child: Row(children: [
          Expanded(
              child: Text(e.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          WhiteButton(tapFunc: () => onCategoryEdit(e.id), label: '変更')
        ]));
  }
}
