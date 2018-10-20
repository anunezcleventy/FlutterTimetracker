import 'package:flutter/material.dart';
import 'package:business_timetracker/widgets/numberpicker.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin{
  int _currentHour = roundToQuarterHour();
  int _currentMinute = roundToQuarterMinute();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new NumberPicker.integer(
              minValue: 0,
              maxValue: 24,
              initialValue: _currentHour,
              isQuarter: false,
              onChanged: (hour) {
                setState(() {
                  _currentHour = hour;
                });
              },
            ),
            new Text(" : "),
            new NumberPicker.integer(
              minValue: 0,
              maxValue: 3,
              initialValue: _currentMinute,
              isQuarter: true,
              onChanged: (minute) {
                setState(() {
                  _currentMinute = minute;
                });
              },
            ),
          ],
        ),
      ),
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(Icons.attach_money),
        onPressed: () => true
      ),
    );
  }

  static roundToQuarterHour() {
    var minute = 15;
    var hour = new DateTime.now().hour;
    if(minute > 45 && ((((minute/15).round()) * 15) % 60) == 0){
      return hour + 1;
    }else {
      return hour;
    }
  }

  static roundToQuarterMinute() {
    var minute = new DateTime.now().minute;
    var quarters = ["00", "15", "30", "45"];
    minute = (((minute/15).round()) * 15) % 60;
    var minuteString = minute.toString().length == 1 ? "0" + minute.toString() : minute.toString();
    return quarters.indexOf(minuteString);

  }
}
