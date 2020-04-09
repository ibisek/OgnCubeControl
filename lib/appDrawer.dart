
import 'dart:io';

import 'package:cube_control/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cube_control/logbookPage.dart';
import 'package:cube_control/deviceListPage.dart';


void launchUrl() async {
  const url = 'https://ogn.ibisek.com';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw "Could not launch '$url'";
  }
}

Widget getAppDrawer(BuildContext context) {
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
          selected: context.widget is MyHomePage,
          onTap: () {
//            Navigator.pop(context);
            Navigator.of(context).pushNamed(MyHomePage.routeName);
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
          selected: context.widget is LogbookPage,
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
