import 'package:flutter/material.dart';

const double _kScrollbarThickness = 12.0;

class MyScrollbar extends StatefulWidget {
  final ScrollableWidgetBuilder builder;
  final ScrollController scrollController;

  const MyScrollbar({
    super.key,
    required this.scrollController,
    required this.builder,
  });

  @override
  MyScrollbarState createState() => MyScrollbarState();
}

class MyScrollbarState extends State<MyScrollbar> {
  late ScrollbarPainter _scrollbarPainter;
  late ScrollController _scrollController;
  Orientation? _orientation;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _updateScrollPainter(_scrollController.position);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollbarPainter = _buildMaterialScrollbarPainter();
  }

  @override
  void dispose() {
    _scrollbarPainter.dispose();
    super.dispose();
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: Colors.orange,
      textDirection: Directionality.of(context),
      thickness: _kScrollbarThickness,
      radius: const Radius.circular(20),
      fadeoutOpacityAnimation: const AlwaysStoppedAnimation<double>(1.0),
      padding: const EdgeInsets.only(top: 15, right: 15, bottom: 5, left: 5),
    );
  }

  bool _updateScrollPainter(ScrollMetrics position) {
    _scrollbarPainter.update(
      position,
      position.axisDirection,
    );
    return false;
  }

  @override
  void didUpdateWidget(MyScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrollController.hasClients) {
      _updateScrollPainter(_scrollController.position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_orientation != orientation) {
          _orientation = orientation;
          if (_scrollController.hasClients) {
            _updateScrollPainter(_scrollController.position);
          }
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_scrollController.hasClients) {
              return _updateScrollPainter(notification.metrics);
            }
            return false;
          },
          child: CustomPaint(
            painter: _scrollbarPainter,
            child: widget.builder(context, _scrollController),
          ),
        );
      },
    );
  }
}
