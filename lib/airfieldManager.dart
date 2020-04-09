
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cube_control/gpsMath.dart';


class AirfieldRecord {
  String code;
  double lat, lon;        // [deg]
  double latRad, lonRad;  // [rad]

  AirfieldRecord(Map m) {
    code = m['code'];
    lat = m['lat'];
    lon = m['lon'];

    latRad = GpsMath.toRadians(lat);
    lonRad = GpsMath.toRadians(lon);
  }
}

class AirfieldManager {

  final String airfieldsFilePath = 'assets/res/airfields.json';

  AirfieldManager._privateConstructor();

  static final AirfieldManager instance = AirfieldManager._privateConstructor();

  List<AirfieldRecord> airfields = List();

  factory AirfieldManager() {
    return instance;
  }

  Future<String> _getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<List<AirfieldRecord>>_loadAirfields() async {
    String jsonStr = await _getFileData(airfieldsFilePath);
    List jsonList = json.decode(jsonStr);

    airfields.clear();

    for (Map item in jsonList) {
      AirfieldRecord rec = AirfieldRecord(item);
      airfields.add(rec);
    }
  }

  void init() async {
    if(airfields.length == 0)
      await _loadAirfields();
  }

  String getNearest(double lat, double lon) {
    double minDist = double.maxFinite;
    String code = "?";

    double latRad = GpsMath.toRadians(lat);
    double lonRad = GpsMath.toRadians(lon);

    for (AirfieldRecord rec in airfields) {
      double dist = GpsMath.getDistanceInKm(latRad, lonRad, rec.latRad, rec.lonRad);
      if (dist < minDist) {
        minDist = dist;
        code = rec.code;
      }
    }

    return code;
  }

}
