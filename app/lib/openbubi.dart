import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:collection';

class geoCode {
  forward(String location) async {
    var baseURL = "https://nominatim.openstreetmap.org/search";
    var requestURL = Uri.parse("$baseURL?q=$location&format=json");
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(requestURL);
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    var parsedOutput = json.decode(output)[0];
    return parsedOutput;
  }
  reverse(double lat, double lon) async {
    var baseURL = "https://nominatim.openstreetmap.org/reverse";
    var requestURL = Uri.parse("$baseURL?lat=$lat&lon=$lon&format=json");
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(requestURL);
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    return output;
  }
}
class BubiUser {
  var pin;
  var mobile;
  BubiUser(String mobile, String pin) {
    // a constructorban (sehol) nem muszáj az argumentumok típusát specifikálni
    this.mobile = mobile;
    this.pin = pin;
  }
  info() async {
    var url = Uri.parse("https://api-budapest.nextbike.net/api/login.json");
    var data = {
      "mobile": this.mobile,
      "pin": this.pin,
      "apikey": "Bbx3nGP291xEtDmq",
      "show_errors": "1",
      "domain": "bh"
    };
    var httpClient = HttpClient();
    var request = await httpClient.postUrl(url);
    request.headers.set("content-type", "application/json");
    request.add(utf8.encode(json.encode(data)));
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    return output;
  }
  getScreenName() async {
    return json.decode(await this.info())["user"]["screen_name"];
  }
  getLoginKey() async {
    return json.decode(await this.info())["user"]["loginkey"];
  }
  callOtherEndpoint(String endpoint, Map userData) async {
    var baseURL = "https://api-budapest.nextbike.net";
    var requestURL = Uri.parse("$baseURL$endpoint");
    var dataToPost = userData;
    dataToPost["apikey"] = "Bbx3nGP291xEtDmq";
    dataToPost["loginkey"] = await this.getLoginKey();
    dataToPost["show_errors"] = "1";
    dataToPost["domain"] = "bh";
    var httpClient = HttpClient();
    var request = await httpClient.postUrl(requestURL);
    request.headers.set("content-type", "application/json");
    request.add(utf8.encode(json.encode(dataToPost)));
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    return output;
  }
  rentBike(int bikeNumber) async {
    return await this.callOtherEndpoint("/api/rent.json", {"bike": bikeNumber.toString()});
  }
  getRentals() async {
    return await this.callOtherEndpoint("/api/rentals.json", {});
  }
  getClosedRentals() async {
    return json.encode(json.decode(await this.getRentals())["closed_rentals"]);
  }
  getActiveRentals() async {
    return await this.callOtherEndpoint("/api/getOpenRentals.json", {});
  }
  getPaymentLinks() async {
    return await this.callOtherEndpoint('/api/getPaymentLinks.json', {});
  }
  getSubscriptionInfo() async {
    // return info about current subscription
  }
  getSubscriptionType() async {
    // get subscription type
  }
  getEndOfSubscription() async {
    // get end of subscription
  }
  moreInfo() async {
    return await this.callOtherEndpoint("/api/getUserDetails.json", {});
  }
  getRentalDetails() async {
    return await this.callOtherEndpoint("/api/getRentalDetails.json", {});
  }
}
class BubiMap {
  listAllStations() async {
    // a függvénynél használhatnék dynamic típust is
    var url = Uri.parse("https://futar.bkk.hu/api/query/v1/ws/otp/api/where/bicycle-rental.json?key=bkk-web&version=4");
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(url);
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    return output;
  }
  listAllBikes() async {
    var url = Uri.parse("https://api-budapest.nextbike.net/maps/nextbike-live.json?domains=bh");
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(url);
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    return output;
  }
  listAllBikesFormatted() async {
    return json.encode(json.decode(await this.listAllBikes())["countries"][0]["cities"][0]["places"]);
  }
  listAllStationsFormatted() async {
    return json.encode(json.decode(await this.listAllStations())["data"]["list"]);
  }
  getNearestStations(double lat, double lon) async {
    var stations = json.decode(await this.listAllStationsFormatted());
    var differences = {};
    for (var i = 0; i < stations.length; i++) {
      var currentStation = stations[i];
      var difference = pow(sqrt((currentStation["lat"] - lat).abs()), 2) + pow(sqrt((currentStation["lon"] - lon).abs()), 2);
      differences[currentStation["name"]] = difference;
    }
    var sortedDifferences = SplayTreeMap.from(differences, (key1, key2) => differences[key1].compareTo(differences[key2]));
    return json.encode(sortedDifferences);
  }
  getNearestStation(double lat, double lon) async {
    return json.decode((await this.getNearestStations(lat, lon))).keys.elementAt(0);
  }
  getNearestStationByAddress(String address) async {
    var location = await geoCode().forward(address);
    var lat = double.parse(location["lat"]);
    var lon = double.parse(location["lon"]);
    return this.getNearestStation(lat, lon);
  }
  listAllBikesOnStation(String stationName) async {
    var stations = json.decode(await this.listAllBikesFormatted());
    for (var i = 0; i < stations.length; i++) {
      var currentStation = stations[i];
      var currentStationName = currentStation["name"].substring(5);
      if (currentStationName == stationName) {
        try {
          return json.encode(currentStation["bike_list"]);
        } catch(e) {
          return "No bikes in station";
        }
      }
    }
  }
  countBikesOnStation(String stationName) async {
    return json.decode(await this.listAllBikesOnStation(stationName)).length;
  }
  getCoordinatesOfStation(String stationName) async {
    var stations = json.decode(await this.listAllStationsFormatted());
    for (var i = 0; i < stations.length; i++) {
      var currentStation = stations[i];
      var currentStationName = currentStation["name"];
      if (currentStationName == stationName) {
        var coordinates = {};
        coordinates["lat"] = currentStation["lat"];
        coordinates["lon"] = currentStation["lon"];
        return json.encode(coordinates);
      }
    }
  }
}
class BubiHelpers {
  register() async {
    var output = "Coming soon...";
    return output;
  }
  pinReset(String mobile) async {
    var output = "Coming soon...";
    return output;
  }
  getNews() async {
    var url = Uri.parse("https://api-budapest.nextbike.net/api/getNews.json");
    var data = {
      "fallback_domain": "bh",
      "language": "hu",
      "apikey": "Bbx3nGP291xEtDmq",
      "show_errors": "1",
      "domain": "bh"
    };
    var httpClient = HttpClient();
    var request = await httpClient.postUrl(url);
    request.headers.set("content-type", "application/json");
    request.add(utf8.encode(json.encode(data)));
    var response = await request.close();
    var output = await response.transform(utf8.decoder).join();
    httpClient.close();
    return output;
  }
  getNewsFormatted() async {
    return json.encode(json.decode(await this.getNews())["news_collection"]);
  }
  readNew(int uid) async {
    var news = json.decode(await this.getNewsFormatted());
    for (var i = 0; i < news.length; i++) {
      var currentNew = news[i];
      if (currentNew["uid"] == uid) {
        var url = Uri.parse(currentNew["url_webview"]);
        var httpClient = HttpClient();
        var request = await httpClient.getUrl(url);
        var response = await request.close();
        var output = await response.transform(utf8.decoder).join();
        httpClient.close();
        return output;
      }
    }
  }
}
