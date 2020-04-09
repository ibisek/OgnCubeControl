
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cube_control/firmware.dart';


class FirmwareManager {

  final String airfiledsFilePath = 'assets/res/airfields.json';

  FirmwareManager._privateConstructor();

  static final FirmwareManager instance = FirmwareManager._privateConstructor();

  static const String FW_DATA_URL = "https://raw.githubusercontent.com/ibisek/ognCubeReleases/master/releases/firmwares.json";
  static const String FIRMWARE_LIST_KEY = 'firmwares.json';

  List<Firmware> firmwares = List();

  factory FirmwareManager() {
    return instance;
  }

  /// Loads firmware list from local storage for offline use.
  /// @return list of @Firmwares
  Future<List<Firmware>>_popFirmwareList() async {
    firmwares.clear();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(FIRMWARE_LIST_KEY)) {
      String jsonStr = prefs.getString(FIRMWARE_LIST_KEY);
      dynamic j = json.decode(jsonStr);

      for (var item in j) {
        Firmware fw = Firmware.fromJson(item);
        firmwares.add(fw);
      }
    }

    return firmwares;
  }

  /// Saves firmware list to local storage for offline use.
  void _pushFirmwareList() async {
    if(firmwares.length > 0) {
      String jsonStr = json.encode(firmwares);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(FIRMWARE_LIST_KEY, jsonStr);
    }
  }

  Future<void> init() async {
    if(firmwares.length == 0) {
      await _popFirmwareList();
    }
  }

  /// @return key/filename for local storage
  String _getKey(Firmware fw) {
    return "firmware-${fw.filename}";
  }

  /// @return true if firmware bytes were successfully loaded from the local storage
  Future<bool> loadFirmwareBytes(Firmware fw) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String key = _getKey(fw);

    if (prefs.containsKey(key)) {
      String bytesEncoded = prefs.getString(key);
      fw.bytes = base64Decode(bytesEncoded);

      return true;
    }

    return false;
  }

  /// Downloads specified's firmware bin file from github.
  /// @param @Firmware
  Future<bool> _downloadFirmwareBinFile(Firmware fw) async {
    http.Response response;
    try {
      response = await http.get(fw.url);
    } catch (exception) {
      // nix
    }

    if (response != null && response.statusCode == 200) {
      fw.setBytes(response.bodyBytes);

      String key = _getKey(fw);
      String bytesEncoded = base64Encode(fw.bytes);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(key, bytesEncoded);

      fw.isStoredLocally = true;

      return true;
    }

    return false;
  }

  Future<bool> downloadFirmwareList() async {
    http.Response response;
    try {
      response = await http.get(FW_DATA_URL);
    } catch (exception) {
      // nix
    }

    if (response != null && response.statusCode == 200) {
      List jsonList = json.decode(response.body);

      firmwares.clear();

      while (jsonList.length > 0) {
        Map item = jsonList.removeAt(0);
        Firmware fw = Firmware.fromJson(item);
        firmwares.add(fw);
      }

      // order by date desc (most recent at the top):
      firmwares.sort((a, b) => b.timestamp - a.timestamp);

      // get the actual bin files:
      for (Firmware fw in firmwares) {
        bool res = await _downloadFirmwareBinFile(fw);
        if (res) fw.isStoredLocally = true;
      }

      _pushFirmwareList();  // store the list to the local storage

      return true;
    }

    return false;
  }
}