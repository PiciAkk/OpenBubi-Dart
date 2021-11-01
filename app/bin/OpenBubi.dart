import 'package:OpenBubi/openbubi.dart' as openbubi;
import 'dart:convert';

Future<void> main(List<String> arguments) async {
  // itt BubiUser típussal is létrehozhattam volna ezt az instance-et
  var Budapest = openbubi.BubiMap();
  // itt 'new' keywordöt is használhattam volna, de így egyszerűbb :D
  var geocode = openbubi.geoCode();
  // a json.decode()-dal json objectet csinálhatnék egy stringből
  var helpers = openbubi.BubiHelpers();
  print(await helpers.readNew(12988));
}
