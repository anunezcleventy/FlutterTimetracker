import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Created by Marcin Szałek

///NumberPicker is a widget designed to pick a number between #minValue and #maxValue
class NumberPicker extends StatelessWidget {
  ///height of every list element
  static const double DEFAULT_ITEM_EXTENT = 50.0;

  ///width of list view
  static const double DEFUALT_LISTVIEW_WIDTH = 100.0;

  ///constructor for integer number picker
  NumberPicker.integer({
    Key key,
    @required int initialValue,
    @required this.minValue,
    @required this.maxValue,
    @required this.onChanged,
    this.itemExtent = DEFAULT_ITEM_EXTENT,
    this.listViewWidth = DEFUALT_LISTVIEW_WIDTH,
    this.step = 1,
  })
      : assert(initialValue != null),
        assert(minValue != null),
        assert(maxValue != null),
        assert(maxValue > minValue),
        assert(initialValue >= minValue && initialValue <= maxValue),
        assert(step > 0),
        selectedIntValue = initialValue,
        selectedDecimalValue = -1,
        intScrollController = new ScrollController(
          initialScrollOffset: (initialValue - minValue) ~/ step * itemExtent,
        ),
        _listViewHeight = 3 * itemExtent,
        super(key: key);

  ///called when selected value changes
  final ValueChanged<num> onChanged;

  ///min value user can pick
  final int minValue;

  ///max value user can pick
  final int maxValue;

  ///height of every list element in pixels
  final double itemExtent;

  ///view will always contain only 3 elements of list in pixels
  final double _listViewHeight;

  ///width of list view in pixels
  final double listViewWidth;

  ///ScrollController used for integer list
  final ScrollController intScrollController;

  ///Currently selected integer value
  final int selectedIntValue;

  ///Currently selected decimal value
  final int selectedDecimalValue;

  ///Step between elements. Only for integer datePicker
  ///Examples:
  /// if step is 100 the following elements may be 100, 200, 300...
  /// if min=0, max=6, step=3, then items will be 0, 3 and 6
  /// if min=0, max=5, step=3, then items will be 0 and 3.
  final int step;

  //
  //----------------------------- PUBLIC ------------------------------
  //

  animateInt(int valueToSelect) {
    int diff = valueToSelect - minValue;
    int index = diff ~/ step;
    _animate(intScrollController, index * itemExtent);
  }

  //
  //----------------------------- VIEWS -----------------------------
  //

  ///main widget
  @override
  Widget build(BuildContext context) {
    List<double> heights =
    new List<double>.generate(100, (i) => Random().nextInt(90).toDouble() + 45.0);

    var itemBuilder = (BuildContext context, int index) {
      return Card(
        child: Container(
          height: heights[index % 100],
          color: Colors.green,
          child: Center(
              child: MaterialButton(
                color: Colors.grey,
                child: Text('ITEM $index'),
                onPressed: () => print("PRESSED $index"),
              )),
        ),
      );
    };


    final ThemeData themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Infinite ListView')),
      body: InfiniteListView.builder(itemBuilder: itemBuilder),
    );
  }

  Widget _integerListView(ThemeData themeData) {
    TextStyle defaultStyle = themeData.textTheme.body1;
    TextStyle selectedStyle =
    themeData.textTheme.headline.copyWith(color: themeData.accentColor);

    int itemCount = (maxValue - minValue) ~/ step + 3;

    return new NotificationListener(
      child: new Container(
        height: _listViewHeight,
        width: listViewWidth,
        child: new ListView.builder(
          controller: intScrollController,
          itemExtent: itemExtent,
          itemCount: itemCount,
          cacheExtent: _calculateCacheExtent(itemCount),
          itemBuilder: (BuildContext context, int index) {
            final int value = _intValueFromIndex(index);

            //define special style for selected (middle) element
            final TextStyle itemStyle =
            value == selectedIntValue ? selectedStyle : defaultStyle;

            bool isExtra = index == 0 || index == itemCount - 1;

            return isExtra
                ? new Container() //empty first and last element
                : new Center(
              child: new Text(getTwoDigitsString(value.toString()), style: itemStyle),
            );
          },
        ),
      ),
      onNotification: _onIntegerNotification,
    );
  }

  getTwoDigitsString(String value) {
    if(value.length == 1){
      return "0" + value;
    }else{
      return value;
    }
  }

  //
  // ----------------------------- LOGIC -----------------------------
  //

  int _intValueFromIndex(int index) => minValue + (index - 1) * step;

  bool _onIntegerNotification(Notification notification) {
    if (notification is ScrollNotification) {
      //calculate
      int intIndexOfMiddleElement =
          (notification.metrics.pixels + _listViewHeight / 2) ~/ itemExtent;
      int intValueInTheMiddle = _intValueFromIndex(intIndexOfMiddleElement);
      intValueInTheMiddle = _normalizeIntegerMiddleValue(intValueInTheMiddle);

      if (_userStoppedScrolling(notification, intScrollController)) {
        //center selected value
        animateInt(intValueInTheMiddle);
      }

      //update selection
      if (intValueInTheMiddle != selectedIntValue) {
        onChanged(intValueInTheMiddle);
      }
    }
    return true;
  }

  ///There was a bug, when if there was small integer range, e.g. from 1 to 5,
  ///When user scrolled to the top, whole listview got displayed.
  ///To prevent this we are calculating cacheExtent by our own so it gets smaller if number of items is smaller
  double _calculateCacheExtent(int itemCount) {
    double cacheExtent = 250.0; //default cache extent
    if ((itemCount - 2) * DEFAULT_ITEM_EXTENT <= cacheExtent) {
      cacheExtent = ((itemCount - 3) * DEFAULT_ITEM_EXTENT);
    }
    return cacheExtent;
  }

  ///When overscroll occurs on iOS,
  ///we can end up with value not in the range between [minValue] and [maxValue]
  ///To avoid going out of range, we change values out of range to border values.
  int _normalizeMiddleValue(int valueInTheMiddle, int min, int max) {
    return math.max(math.min(valueInTheMiddle, max), min);
  }

  int _normalizeIntegerMiddleValue(int integerValueInTheMiddle) {
    //make sure that max is a multiple of step
    int max = (maxValue ~/ step) * step;
    return _normalizeMiddleValue(integerValueInTheMiddle, minValue, max);
  }

  ///indicates if user has stopped scrolling so we can center value in the middle
  bool _userStoppedScrolling(Notification notification,
      ScrollController scrollController) {
    return notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle &&
        scrollController.position.activity is! HoldScrollActivity;
  }

  ///scroll to selected value
  _animate(ScrollController scrollController, double value) {
    scrollController.animateTo(value,
        duration: new Duration(seconds: 1), curve: new ElasticOutCurve());
  }
}












class InfiniteListView extends StatefulWidget {
  //
  const InfiniteListView.builder({Key key, this.itemBuilder}) : super(key: key);

  final IndexedWidgetBuilder itemBuilder;

  @override
  _InfinitListViewState createState() => _InfinitListViewState();
}

class _UnboundedScrollPosition extends ScrollPositionWithSingleContext {
  _UnboundedScrollPosition({
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
    double initialPixels,
  }) : super(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    initialPixels: initialPixels,
  );

  @override
  double get minScrollExtent => double.negativeInfinity;

  /// There is a feedback-loop between aboveController and belowController. When one of them is
  /// being used, it controlls the other. However if they get out of sync, for timing reasons,
  /// the controlled one with try to controll the other, and the jump will stop the real controller.
  /// For this reason, we can't let one stop the other (idle and ballistics) in this situattion.
  void jumpToWithoutGoingIdleAndKeepingBallistic(double value) {
    if (pixels != value) {
      forcePixels(value);
    }
  }
}

class _UnboundedScrollController extends ScrollController {
  //
  _UnboundedScrollController({
    double initialScrollOffset = 0.0,
    keepScrollOffset = true,
    debugLabel,
  }) : super(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel);

  @override
  _UnboundedScrollPosition createScrollPosition(
      ScrollPhysics physics,
      ScrollContext context,
      ScrollPosition oldPosition,
      ) {
    return _UnboundedScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
    );
  }

  void jumpToWithoutGoingIdleAndKeepingBallistic(double value) {
    assert(positions.isNotEmpty, 'ScrollController not attached.');
    for (_UnboundedScrollPosition position in new List<ScrollPosition>.from(positions))
      position.jumpToWithoutGoingIdleAndKeepingBallistic(value);
  }
}

class _InfinitListViewState extends State<InfiniteListView> {
  //
  _UnboundedScrollController _positiveController;
  _UnboundedScrollController _negativeController;

  @override
  void initState() {
    super.initState();

    // Instantiate the negative and positive list positions, relative to one another.
    WidgetsBinding.instance.addPostFrameCallback((_) => _negativeController
        .jumpTo(-_negativeController.position.extentInside - _positiveController.position.pixels));

    _positiveController?.dispose();
    _negativeController?.dispose();
    _positiveController = _UnboundedScrollController(keepScrollOffset: false);
    _negativeController = _UnboundedScrollController();

    // ---

    // The POSITIVE list moves the NEGATIVE list, but only if the NEGATIVE list position would change.
    _positiveController.addListener(() {
      var newNegativePosition =
          -_negativeController.position.extentInside - _positiveController.position.pixels;
      var oldNegativePosition = _negativeController.position.pixels;

      if (newNegativePosition != oldNegativePosition) {
        _negativeController.jumpToWithoutGoingIdleAndKeepingBallistic(newNegativePosition);
      }
    });

    // ---

    // The NEGATIVE list moves the POSITIVE list, but only if the POSITIVE list position would change.
    _negativeController.addListener(() {
      var newBelowPosition =
          -_positiveController.position.extentInside - _negativeController.position.pixels;
      var oldBelowPosition = _positiveController.position.pixels;

      if (newBelowPosition != oldBelowPosition) {
        _positiveController.jumpToWithoutGoingIdleAndKeepingBallistic(newBelowPosition);
      }
    });
  }

  @override
  void dispose() {
    _positiveController.dispose();
    _negativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //
    var sliverList = SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        return widget.itemBuilder(context, -index - 1);
      }),
    );

    var negativeList = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _negativeController,
      reverse: true,
      slivers: [sliverList],
    );

    var positiveList = ListView.builder(
      controller: _positiveController,
      itemBuilder: (BuildContext context, int index) {
        return widget.itemBuilder(context, index);
      },
    );

    return Stack(
      children: <Widget>[
        negativeList,
        _ControlledIgnorePointer(
          child: positiveList,
          controller: _positiveController,
        ),
      ],
    );
  }
}

class _ControlledIgnorePointer extends SingleChildRenderObjectWidget {
  //
  final ScrollController controller;

  const _ControlledIgnorePointer({Key key, @required this.controller, Widget child})
      : assert(controller != null),
        super(key: key, child: child);

  @override
  _ControlledRenderIgnorePointer createRenderObject(BuildContext context) {
    return new _ControlledRenderIgnorePointer(controller: controller);
  }

  @override
  void updateRenderObject(BuildContext context, _ControlledRenderIgnorePointer renderObject) {
    renderObject..controller = controller;
  }
}

/// Render object that is invisible to hit testing in offsets that depend on the controller.
class _ControlledRenderIgnorePointer extends RenderProxyBox {
  _ControlledRenderIgnorePointer({RenderBox child, ScrollController controller})
      : _controller = controller,
        super(child) {
    assert(_controller != null);
  }

  ScrollController get controller => _controller;
  ScrollController _controller;
  set controller(ScrollController value) {
    assert(value != null);
    if (value == _controller) return;
    _controller = value;
  }

  @override
  bool hitTest(HitTestResult hitTestResult, {Offset position}) {
    bool ignore = -controller.position.pixels > position.dy;
    var boolResult = ignore ? false : super.hitTest(hitTestResult, position: position);
    return boolResult;
  }
}
