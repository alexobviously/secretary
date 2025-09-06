import 'package:elegant/elegant.dart' show Result;
import 'package:rest_client/rest_client.dart' as rc;

typedef TimeResult = Result<DateTime, String>;

Future<TimeResult> getTime(
  String timeZone, {
  Duration timeTravel = Duration.zero,
}) async {
  try {
    final req = rc.Request(
        url: 'https://timeapi.io/api/Time/current/zone?timeZone=$timeZone');
    final resp = await rc.Client().execute(
      request: req,
      throwRestExceptions: false,
    );
    if (resp.statusCode != 200) {
      return Result.error('${resp.statusCode.toString()}: ${resp.body}');
    }
    return Result.ok(DateTime.parse(resp.body['dateTime']).add(timeTravel));
  } catch (e) {
    print('error: $e');
    return Result.error('no_connection');
  }
}
