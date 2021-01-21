
import 'dart:typed_data';
import 'package:cube_control/btManager.dart';


class CubeInterface {

  static const String CMD_LS = '\$CMDLS\n';
  static const String CMD_RST = '\$CMDRST\n';
  static const String CMD_CAT_LOGBOOK = '\$CMDCAT;logbook.csv\n';

  CubeInterface._privateConstructor();
  static final CubeInterface instance = CubeInterface._privateConstructor();

  factory CubeInterface() {
    return instance;
  }

  String _ognIdStr;
  int _ognId;

  String getOgnIdStr() {
    if(_ognIdStr == null) {
      String btDeviceName = BTManager().selectedDevice.name.toUpperCase();
      RegExp re = new RegExp(r'([A-Z0-9]{6})');
      var match = re.firstMatch(btDeviceName);
      _ognIdStr = btDeviceName.substring(match.start, match.end);
      _ognId = int.parse(_ognIdStr, radix: 16); // HEX str id to int
    }

    return _ognIdStr;
  }

  int getOgnId() {
    if(_ognIdStr == null) {
      getOgnIdStr();
    }

    return _ognId;
  }

  /// Sends a COMMAND to unit and awaits for EXPECTed string in the line.
  /// @param cmd: command either as String or Uint8List
  /// @param expect: a string to expect in the response line
  /// @param timeout: optional, default 400ms
  /// @param wrapBy: optional, line termination char
  Future<String> query(dynamic cmd, String expect, {int timeout = 60000, String wrapBy='\n'}) async {
    BTManager btm = BTManager();

    if (cmd != null) { // just wait for the response when cmd == null
      if (cmd is String) btm.writeStr(cmd);
      else if (cmd is Uint8List) btm.writeBytes(cmd);
      else {
        print("[ERROR] Wrong CMD argument type!");
        return null;
      }
    }

    btm.clearBuffer();

    int startTs = DateTime.now().millisecond;
    String response;
    do {
      response = await btm.readUntil(wrapBy);
    } while(response.indexOf(expect) < 0 || (DateTime.now().millisecond - startTs) > timeout);

    return response;
  }

}