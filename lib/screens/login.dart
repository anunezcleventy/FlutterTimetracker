import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentPrice = 1;

  _showDialog() {
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Text("Current price: $_currentPrice \$"),
      ),
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(Icons.attach_money),
        onPressed: _showDialog,
      ),
    );
  }
}
