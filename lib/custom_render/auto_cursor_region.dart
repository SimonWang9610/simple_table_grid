import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef MouseCursorCallback = MouseCursor Function(Offset? relativeOffset);

class AutoCursorWidget extends SingleChildRenderObjectWidget {
  final MouseCursorCallback? onPointerCallback;

  const AutoCursorWidget({
    super.key,
    required super.child,
    this.onPointerCallback,
  });

  @override
  RenderAutoCursorObject createRenderObject(BuildContext context) {
    return RenderAutoCursorObject(onPointerCallback: onPointerCallback);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderAutoCursorObject renderObject,
  ) {
    renderObject.onPointerCallback = onPointerCallback;
  }
}

class RenderAutoCursorObject extends RenderProxyBoxWithHitTestBehavior
    implements MouseTrackerAnnotation {
  RenderAutoCursorObject({
    required MouseCursorCallback? onPointerCallback,
    RenderBox? child,
    bool validForMouseTracker = true,
  })  : _onPointerCallback = onPointerCallback,
        _validForMouseTracker = validForMouseTracker {
    _currentCursor = onPointerCallback?.call(null) ?? MouseCursor.defer;
  }

  late MouseCursor _currentCursor;

  @override
  MouseCursor get cursor => _currentCursor;

  MouseCursorCallback? _onPointerCallback;
  set onPointerCallback(MouseCursorCallback? value) {
    if (_onPointerCallback == value) return;
    _onPointerCallback = value;
    _currentCursor = value?.call(null) ?? MouseCursor.defer;
  }

  void _update(Offset pointerPosition, {bool isExit = false}) {
    final localOffset = globalToLocal(pointerPosition);

    final x = localOffset.dx / size.width;
    final y = localOffset.dy / size.height;

    final relativeOffset = Offset(x, y);

    final newCursor =
        _onPointerCallback?.call(!isExit ? relativeOffset : null) ??
            MouseCursor.defer;

    if (newCursor != _currentCursor) {
      print('Cursor changed: $newCursor');
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
