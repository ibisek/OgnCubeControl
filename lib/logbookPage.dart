
import 'package:cube_control/btManager.dart';
import 'package:cube_control/cubeInterface.dart';
import 'package:cube_control/logBook.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cube_control/deviceListPage.dart';
import 'package:intl/intl.dart';
import 'airfieldManager.dart';

class LogbookPage extends StatefulWidget {
  LogbookPage({Key key, this.title}) : super(key: key);

  static const routeName = '/logbook';

  final String title;

  @override
  _LogbookPageState createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  List logbookEntries = List();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    loadLogbookFromDb();
  }

  Widget getProgressDialog() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          //LinearProgressIndicator(),
          Text('\nDownloading data from the CUBE..'),
        ],
      ),
    );
  }

  Widget getAccInfo(LogbookEntry e) {
    Text text;
    if (e.acc.length != 0)
      text = Text(
          "min/max acc\nX <${e.acc[0].toStringAsFixed(1)}; ${e.acc[1].toStringAsFixed(1)}>\nY <${e.acc[2].toStringAsFixed(1)}; ${e.acc[3].toStringAsFixed(1)}>\nZ <${e.acc[4].toStringAsFixed(1)}; ${e.acc[5].toStringAsFixed(1)}>");
    else
      text = Text('\nNo ACC data.');

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: text,
          ),
        ],
      ),
    );
  }

  Widget getRow(int i) {
    DateFormat dateFormat = new DateFormat('EEEE d.M.y');
    DateFormat timeFormat = new DateFormat('HH:mm');
    LogbookEntry e = logbookEntries[i];

    Row row = Row(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(left: 4, right: 4), //all(8),
                  child: Text(
                    "${dateFormat.format(e.takeOff)}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(left: 4, right: 4), //all(8),
                  child: Icon(Icons.flight_takeoff),
                ),
                Text(
                  "${timeFormat.format(e.takeOff)} ${e.takeOffLocationCode}",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(left: 4, right: 4), //all(8),
                  child: Icon(Icons.flight_land),
                ),
                Text(
                  "${timeFormat.format(e.landing)} ${e.landingLocationCode}",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                e.getDurationFormatted(),
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
//        Container(
//          padding: const EdgeInsets.only(left: 4, right: 4), //all(8),
//          child: Icon(Icons.more_vert),
//        ),
        Column(
          children: <Widget>[getAccInfo(e)],
        ),
      ],
    );

    Container c = Container(
//      padding: const EdgeInsets.all(8),
      height: 70,
      child: row,
    );

    return c;
  }

  ListView getListView(BuildContext context) {
    return ListView.separated(
      itemCount: logbookEntries.length,
      itemBuilder: (BuildContext context, int index) {
        return new GestureDetector(
          onTap: () => onListItemTap(index),
          child: getRow(index),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget getBody() {
    if (busy)
      return getProgressDialog();
    else
      return getListView(context);
  }

  onListItemTap(index) {
    //TODO zzz
//    Navigator.of(context)
//        .pushNamed(FirmwareUpdatePage.routeName, arguments: firmwares[index]);
  }

  loadLogbookFromDb() async {
    // TODO load from local storage
  }

  void onDownloadIconClick(context) async {
    if (busy) return;

    AirfieldManager().init();
    await BTManager().refresh();

    if (!BTManager().btEnabled || !BTManager().btAvailable) {
      Fluttertoast.showToast(
        msg: "Enable bluetooth!",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (BTManager().selectedIndex < 0 || BTManager().selectedDevice == null) {
      Navigator.of(context).pushNamed(DeviceListPage.routeName);
    }

    if (!BTManager().isConnected()) {
      bool res = await BTManager().connectTo(BTManager().selectedDevice);
      if (!res) {
        Fluttertoast.showToast(
          msg:
              "Logbook readout from\n'${BTManager().selectedDevice.name}' failed!",
          toastLength: Toast.LENGTH_SHORT,
        );
        return;
      }
    }

    // read file 'logbook.csv' from the tracker:
    String resp = await CubeInterface().query(
        CubeInterface.CMD_CAT_LOGBOOK, "\$FILE;logbook.csv;",
        delayMs: 500); // $FILE;logbook.csv;....*CRC\n
    if (resp == null) {
      Fluttertoast.showToast(
        msg: "File 'logbook.csv' is empty or SD card not present!'",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() {
      busy = true;
    });

    // $FILE;logbook.csv;74616B656F66664 .. B312E39390A*39
    String fileContentHex = resp.split(';')[2].split('*')[0];
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < fileContentHex.length - 1; i += 2) {
      String hex = "${fileContentHex[i]}${fileContentHex[i + 1]}";
      int x = int.parse(hex, radix: 16); // from HEX string to in
      String c = String.fromCharCode(x); // from int to char
      sb.write(c);
    }

    DateFormat df =
        new DateFormat("dd-MM-yyyy HH:mm:ss"); // silly there is no other way..
    List<String> lines = sb.toString().split('\n');
    for (String line in lines) {
      List<String> items = line.split(';');
      if (items.length < 10) continue;

      String takeoffDate = items[0];
      String takeoffTime = items[1];
      String takeoffLatStr = items[2];
      String takeoffLonStr = items[3];
      String landingDate = items[4];
      String landingTime = items[5];
      String landingLatStr = items[6];
      String landingLonStr = items[7];
//      String hours = items[8];
//      String minutes = items[9];

      List<double> acc =
          List(); // recorded min-max accelerations (if available)
      if (items.length == 16)
        for (int i = 10; i < 16; i++) {
          acc.add(double.parse(items[i]));
        }

      String ognId = CubeInterface().getOgnIdStr();

      DateTime takeOff, landing;
      try {
        takeOff = df.parse(
            "${takeoffDate.substring(0, 2)}-${takeoffDate.substring(2, 4)}-20${takeoffDate.substring(4, 6)} ${takeoffTime.substring(0, 2)}:${takeoffTime.substring(2, 4)}:${takeoffTime.substring(4, 6)}}");
        landing = df.parse(
            "${landingDate.substring(0, 2)}-${landingDate.substring(2, 4)}-20${landingDate.substring(4, 6)} ${landingTime.substring(0, 2)}:${landingTime.substring(2, 4)}:${landingTime.substring(4, 6)}}");
      } catch (ex) {
        continue;
      }

      double takeOffLat = double.parse(takeoffLatStr);
      double takeOffLon = double.parse(takeoffLonStr);
      double landingLat = double.parse(landingLatStr);
      double landingLon = double.parse(landingLonStr);

      LogbookEntry e = new LogbookEntry(ognId, takeOff, landing, takeOffLat, takeOffLon, landingLat, landingLon);
      e.acc = acc;
      if (logbookEntries.indexOf(e) < 0) logbookEntries.add(e);
    }

    logbookEntries.sort((a, b) => b.compareTo(a));

    // TODO save to local storage

    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Builder(
            // this is here to get the right 'context' for the onPressed action
            builder: (context) => Center(
              child: IconButton(
                icon: const Icon(Icons.file_download), // cached
                tooltip: 'download data from tracker',
                onPressed: () => onDownloadIconClick(context),
              ),
            ),
          ),
        ],
      ),
      body: getBody(),
    );
  }
}
