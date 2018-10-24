import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


void main() {
  runApp(MaterialApp(home: HomePage()));
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //
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

    return Scaffold(
      appBar: AppBar(title: const Text('Infinite ListView')),
      body: InfiniteListView.builder(itemBuilder: itemBuilder),
    );
  }
}

//////////////////////////////////////////////////////////////////

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
