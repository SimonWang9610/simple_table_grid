import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef MouseCursorCallback = MouseCursor Function(Offset? relativeOffset);
typedef PointerMoveCallback = void Function(Offset pointerPosition, bool isEnd);

class AutoCursorWidget extends SingleChildRenderObjectWidget {
  final MouseCursorCallback? onHover;
  final PointerMoveCallback? onMove;

  const AutoCursorWidget({
    super.key,
    required super.child,
    this.onHover,
    this.onMove,
  });

  @override
  RenderAutoCursorObject createRenderObject(BuildContext context) {
    return RenderAutoCursorObject(onMove: onMove, onHover: onHover);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderAutoCursorObject renderObject,
  ) {
    renderObject
      ..onMove = onMove
      ..onHover = onHover;
  }
}

class RenderAutoCursorObject extends RenderProxyBoxWithHitTestBehavior
    implements MouseTrackerAnnotation {
  RenderAutoCursorObject({
    required MouseCursorCallback? onHover,
    required PointerMoveCallback? onMove,
    RenderBox? child,
    bool validForMouseTracker = true,
  })  : _onMove = onMove,
        _onHover = onHover,
        _validForMouseTracker = validForMouseTracker {
    _currentCursor = onHover?.call(null) ?? MouseCursor.defer;
  }

  late MouseCursor _currentCursor;

  @override
  MouseCursor get cursor => _currentCursor;

  PointerMoveCallback? _onMove;
  set onMove(PointerMoveCallback? value) {
    if (_onMove == value) return;
    _onMove = value;
  }

  MouseCursorCallback? _onHover;
  set onHover(MouseCursorCallback? value) {
    if (_onHover == value) return;
    _onHover = value;
    _currentCursor = value?.call(null) ?? MouseCursor.defer;
  }

  void _update(Offset pointerPosition, {bool isExit = false}) {
    final localOffset = globalToLocal(pointerPosition);

    final x = localOffset.dx / size.width;
    final y = localOffset.dy / size.height;

    final relativeOffset = Offset(x, y);

    final newCursor =
        _onHover?.call(!isExit ? relativeOffset : null) ?? MouseCursor.defer;

    if (newCursor != _currentCursor) {
      _currentCursor = newCursor;
      markNeedsPaint();
    }
  }

  @override
  PointerEnterEventListener get onEnter => _onPointerEnter;

  @override
  PointerExitEventListener get onExit => _onPointerExit;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    // print("Handling event: $event");

    _reportEvent(event);

    if (event is PointerHoverEvent) {
      _onPointerHover(event);
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    _update(event.position);
  }

  void _onPointerExit(PointerExitEvent event) {
    _update(event.position, isExit: true);
  }

  void _onPointerEnter(PointerEnterEvent event) {
    _update(event.position);
  }

  void _reportEvent(PointerEvent event) {
    if (event is PointerMoveEvent || event is PointerDownEvent) {
      _onMove?.call(event.delta, false);
    } else if (event is PointerUpEvent) {
      _onMove?.call(event.delta, true);
    }
  }

  @override
  bool get validForMouseTracker => _validForMouseTracker;
  bool _validForMouseTracker;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _validForMouseTracker = true;
  }

  @override
  void detach() {
    // It's possible that the renderObject be detached during mouse events
    // dispatching, set the [MouseTrackerAnnotation.validForMouseTracker] false to prevent
    // the callbacks from being called.
    _validForMouseTracker = false;
    super.detach();
  }
}
