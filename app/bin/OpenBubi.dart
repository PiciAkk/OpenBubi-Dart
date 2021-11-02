import 'package:OpenBubi/openbubi.dart' as openbubi;
import 'dart:convert';

Future<void> main(List<String> arguments) async {
  // itt BubiUser típussal is létrehozhattam volna ezt az instance-et
  var Budapest = openbubi.BubiMap();
  // itt 'new' keywordöt is használhattam volna, de így egyszerűbb :D
  // a json.decode()-dal json objectet csinálhatnék egy stringből
  var nearestStation = await Budapest.getNearestStationByAddress("Budapest, Lánchíd");
  var counter = await Budapest.countBikesOnStation(nearestStation);
  print("There are $counter bikes on the nearest station to Lánchíd ($nearestStation)");
}
