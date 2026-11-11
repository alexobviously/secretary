import 'package:elegant/elegant.dart' show Result;
import 'package:rest_client/rest_client.dart' as rc;

typedef AgePredictionResult = Result<AgePrediction, String>;

class const AgePrediction({
  required final String name,
  required final num age,
  required final num count,
}) {
  factory fromJson(Map<String, dynamic> json) =>
      AgePrediction(name: json['name'], age: json['age'], count: json['count']);

  @override
  String toString() => 'AgePrediction($name, $age, $count)';
}

Future<AgePredictionResult> getAge(String name) async {
  try {
    final req = rc.Request(url: 'https://api.agify.io/?name=$name');
    final resp = await rc.Client().execute(
      request: req,
      throwRestExceptions: false,
    );
    if (resp.statusCode != 200) return Result.error(resp.statusCode.toString());
    if (resp.body['age'] == null) {
      return Result.error('invalid_name');
    }
    return Result.ok(AgePrediction.fromJson(resp.body));
  } catch (e) {
    // print('Exception in getAge: $e');
    return Result.error('no_connection');
  }
}
