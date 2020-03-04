import 'package:cube_control/btManager.dart';
import 'package:cube_control/logbookPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cube_control/firmware.dart';
import 'package:cube_control/firmwareUpdatePage.dart';
import 'package:cube_control/deviceListPage.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';


void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OGN Cube Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Available Firmwares'),
      routes: <String, WidgetBuilder>{
        FirmwareUpdatePage.routeName: (BuildContext context) =>
            FirmwareUpdatePage(title: 'Firmware Upload'),
        DeviceListPage.routeName: (BuildContext context) =>
            DeviceListPage(title: 'Paired Devices'),
        LogbookPage.routeName: (BuildContext context) =>
            LogbookPage(title: 'Logbook'),

      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List firmwares = List();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadFirmwareList();
  }

  // Observes the app state. Detects application shutdown.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (BTManager().isConnected()) BTManager().disconnect();
    }
  }

  Widget getProgressDialog() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          //LinearProgressIndicator(),
          Text('\nChecking on available firmwares..'),
        ],
      ),
    );
  }

  Widget getRow(int i) {
    Row row = Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(left: 4, right: 10), //all(8),
          child: Icon(firmwares[i].isStoredLocally
              ? Icons.sd_storage
              : Icons.cloud_queue),
        ),
        Expanded(
          child: Html(
            data: "${firmwares[i].type} | <b>${firmwares[i].date}</b><br>${firmwares[i].title}",
          ),
        ),
        Icon(Icons.keyboard_arrow_right), //cloud_download | save_alt
      ],
    );

    Container c = Container(
      padding: const EdgeInsets.all(8),
      height: 50,
      child: row,
    );

    return c;
  }

  ListView getListView(BuildContext context) {
    return ListView.separated(
      itemCount: firmwares.length,
      itemBuilder: (BuildContext context, int index) {
        return new GestureDetector(
          onTap: () => onListItemTap(index),
          onLongPress: () => onListItemLongPress(index),
          child: getRow(index),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget getBody() {
    if (firmwares.length == 0)
      return getProgressDialog();
    else
      return getListView(context);
  }

  onListItemTap(index) {
    Navigator.of(context)
        .pushNamed(FirmwareUpdatePage.routeName, arguments: firmwares[index]);
  }

  void onListItemLongPress(index) async {
    String typeCaption;
    switch(firmwares[index].type) {
      case 'TOW':
        typeCaption = "tow planes";
        break;
      case 'UAV':
        typeCaption = "UAVs";
        break;
      case 'GLD':
        typeCaption = "gliders";
        break;
    }

    await showDialog<String> (
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Firmware details'),
          children: <Widget>[
            Container(
            padding: const EdgeInsets.only(left: 10, right: 10), //all(8),
            child: Html(
              data: """
                <table>
                  <tr>
                    <td>Release date:</td>
                    <td colspan='2'>${firmwares[index].date}</td>
                  </tr>
                  <tr>
                    <td>Intended for:</td>
                    <td colspan='2'>$typeCaption</td>
                  </tr>
                  <tr>
                    <td>Title:</td>
                    <td colspan='2'>${firmwares[index].title}</td>
                  </tr>
                  <tr>
                    <td style='vertical-align:top;'>Description:</td>
                    <td colspan='2'>${firmwares[index].notes}</td>
                  </tr>
                  <tr>
                    <td>File size:</td>
                    <td colspan='2'>${firmwares[index].len} bytes</td>
                  </tr>
                </table>
              """,
              ),
            ),
          ],
        );
      }
    );
  }

  void clearFirmwareList() {
    setState(() {
      firmwares.clear();
    });
  }

  loadFirmwareList() async {
    clearFirmwareList();

    String dataURL =
        "https://raw.githubusercontent.com/ibisek/ognCubeReleases/master/releases/firmwares.json";

    http.Response response;
    try {
      response = await http.get(dataURL);
    } catch (exception) {
      // nix
    }

    if (response != null && response.statusCode == 200) {
      setState(() {
        List jsonList = json.decode(response.body);
        while (jsonList.length > 0) {
          Map item = jsonList.removeAt(0);
          Firmware fw = Firmware.fromJson(item);
          firmwares.add(fw);

          fw.getTs(); // just to set the TS in the instance
        }

        // order by date desc (most recent at the top):
        firmwares.sort((a, b) => b.timestamp - a.timestamp);
      });
    } else {
      Fluttertoast.showToast(
        msg: "Can not load firmware list.\nAre you online?",
        toastLength: Toast.LENGTH_LONG,
      );

      // throw Exception('Failed to load firmware list');
    }
  }

  void onHelpIconClick(context) async {
//    Scaffold.of(context).showSnackBar(SnackBar(
//      content: Text("Long press the items to view details"),
//      ),
//    );

    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: "Long press the items to view details",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
    );
  }

  void launchUrl() async {
    const url = 'https://ogn.ibisek.com';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw "Could not launch '$url'";
    }
  }

  Widget getDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'OGN Cube Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings_bluetooth),
            title: Text('Paired devices'),
            onTap: () {
              Navigator.of(context).pushNamed(DeviceListPage.routeName);
            },
          ),
          ListTile(
            leading: Icon(Icons.system_update_alt),
            title: Text('Firmware updates'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            }, // close the drawer
          ),
//          ListTile(
//            leading: FlutterLogo(size: 40.0),
//            title: Text('My OGN Cubes'),
//            subtitle: Text('Select active bluetooth connection'),
//          ),
          ListTile(
            leading: Icon(Icons.library_books),
            title: Text('Logbook'),
            enabled: true,
            onTap: () {
              Navigator.of(context).pushNamed(LogbookPage.routeName);
            },
          ),
//          ListTile(
//            leading: Icon(Icons.flight),
//            title: Text('Flights'),
//            enabled: false,
//          ),
//          ListTile(
//            leading: Image(
//              image: AssetImage('assets/images/settings.png '),
//            ),
//            title: Text('Settings'),
//            enabled: false,
//          ),
//          ListTile(
//            leading: Icon(Icons.move_to_inbox), //gesture
//            title: Text('Tracker configuration'),
//            enabled: false,
//            onTap: launchUrl,
//          ),
          ListTile(
            leading: Icon(Icons.launch), //gesture
            title: Text('News & updates'),
            enabled: true,
            onTap: launchUrl,
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app), //gesture
            title: Text('Exit'),
            enabled: true,
            onTap: () { exit(0); },
//            onTap: () {SystemChannels.platform.invokeMethod('SystemNavigator.pop'); },
    ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Builder(  // this is here to get the right 'context' for the onPressed action
          builder: (context) =>
            Center(
              child:
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'instructions',
                onPressed: () => onHelpIconClick(context),
              ),
            ),
          ),
        ],
      ),
      drawer: getDrawer(),
      body: getBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: loadFirmwareList,
        tooltip: 'Reload',
        child: Icon(Icons.cached),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
