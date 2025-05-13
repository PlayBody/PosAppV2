import '../../http/webservice.dart';
import '../apiendpoint.dart';

class ClEpark {
  Future<bool> syncToEpark(context, organId, fromDate, toDate) async {
    Map<dynamic, dynamic> results = {};
    await Webservice()
        .loadHttp(context, apiSyncToEpark, {
          'organ_id': organId,
          'from_date': fromDate,
          'to_date': toDate,
        })
        .then((v) => {results = v});

    // print(results);
    if (results['is_load']) {
      return true;
    }

    return false;
  }
}
