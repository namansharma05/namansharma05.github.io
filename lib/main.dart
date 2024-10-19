import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            // Widget going to be build when dragging item.
            builder: (e) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// Item being dragged
  T? _draggingItem;

  /// [Offset] of item being dragged
  Offset? draggedItemOffset = const Offset(0, 0);

  /// Top right [Offset] of dock container
  Offset? containerTopRight;

  /// Bottom left [Offset] of dock container
  Offset? containerBottomLeft;

  // Dock container key
  late final GlobalKey _containerKey = GlobalKey();

  int draggedIndex = -1;
  late int _originalIndex;
  late bool _itemRemoved;

  @override
  void initState() {
    super.initState();
    // Ensure the widget tree is fully built before accessing the RenderBox
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findOffsets();
    });
  }

  void _findOffsets() {
    // Access the container's RenderBox after the layout is built
    final RenderBox renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox;

    // Calculate the positions of the topRightCorner and bottomLeftCorner
    final Offset topRightOffset =
        renderBox.localToGlobal(Offset(renderBox.size.width, 0));
    final Offset bottomLeftOffset =
        renderBox.localToGlobal(Offset(0, renderBox.size.height));

    setState(() {
      containerTopRight = topRightOffset;
      containerBottomLeft = bottomLeftOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return MouseRegion(
            onEnter: (_) {
              if (_draggingItem != null && _draggingItem != item) {
                setState(() {
                  draggedIndex = _items.indexOf(_draggingItem!);
                  _items.removeAt(draggedIndex);
                  _items.insert(index, _draggingItem!);
                });
              }
            },
            child: Draggable<T>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: widget.builder(item),
              ),
              onDragStarted: () {
                setState(() {
                  _draggingItem = item;
                  _originalIndex = _items.indexOf(_draggingItem!);
                  _itemRemoved =
                      false; // flag to track if item has been removed
                });
              },
              onDragUpdate: (details) {
                setState(() {
                  draggedItemOffset = details.globalPosition;
                  bool isOutsideDock = draggedItemOffset!.dx >
                          containerTopRight!.dx ||
                      draggedItemOffset!.dx < containerBottomLeft!.dx ||
                      draggedItemOffset!.dy < containerTopRight!.dy ||
                      draggedItemOffset!.dy >
                          containerBottomLeft!
                              .dy; // flag to check if dragged item is outside the dock container

                  if (!_itemRemoved &&
                      _items.contains(_draggingItem!) &&
                      isOutsideDock) {
                    _items.remove(_draggingItem!);
                    _itemRemoved = true;
                  } else if (_itemRemoved && !isOutsideDock) {
                    int insertIndex = _originalIndex < _items.length
                        ? _originalIndex
                        : _items.length;
                    _items.insert(insertIndex, _draggingItem!);
                    _itemRemoved = false;
                  }
                });
              },
              onDragEnd: (_) {
                setState(() {
                  if (_itemRemoved) {
                    int insertIndex = _originalIndex < _items.length
                        ? _originalIndex
                        : _items.length;
                    _items.insert(insertIndex, _draggingItem!);
                    _itemRemoved = false;
                  }

                  // Resetting the dragging item
                  _draggingItem = null;
                  _originalIndex = -1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      Colors.primaries[item.hashCode % Colors.primaries.length],
                ),
                child:
                    Center(child: Icon(item as IconData, color: Colors.white)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
