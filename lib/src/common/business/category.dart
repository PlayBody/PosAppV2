import 'package:staff_pos_app/src/http/webservice.dart';
import 'package:staff_pos_app/src/model/category_model.dart';
import '../apiendpoint.dart';

class ClCategory {
  Future<List<CategoryModel>> getCategoryList(context, companyId) async {
    Map<dynamic, dynamic> results = {};

    await Webservice().loadHttp(context, apiGetCategories, {
      'company_id': companyId,
    }).then((v) => {results = v});
    List<CategoryModel> data = [];
    if (results['is_result']){
      for (var item in results['data']) {
        data.add(CategoryModel.fromJson(item));
      }
    }
    return data;

  }

  Future<CategoryModel> getCategory(context, id) async {
    Map<dynamic, dynamic> results = {};

    await Webservice().loadHttp(context, apiGetCategory, {
      'category_id': id,
    }).then((v) => {results = v});

    return CategoryModel.fromJson(results['data']);
  }

  
  Future<bool> save(context, param) async {
    Map<dynamic, dynamic> results = {};

    await Webservice()
        .loadHttp(context, apiSaveCategory, param)
        .then((v) => {results = v});
    if (results['is_result']) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> delete(context, id) async {
    Map<dynamic, dynamic> results = {};
    
    await Webservice()
        .loadHttp(context, apiDeleteCategory, {'category_id': id})
        .then((v) => {results = v});
    if (results['is_result']) {
      return true;
    } else {
      return false;
    }
  }
}