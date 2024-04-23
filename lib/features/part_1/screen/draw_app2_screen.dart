import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scribble/scribble.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:value_notifier_tools/value_notifier_tools.dart';
import 'package:ww_open_test/features/part_1/screen/widgets/color_button.dart';

class DrawAppScreen extends StatefulWidget {
  const DrawAppScreen({super.key});

  @override
  State<DrawAppScreen> createState() => _DrawAppScreenState();
}

class _DrawAppScreenState extends State<DrawAppScreen> {
  late ScribbleNotifier notifier;

  List<Sticker> selectedStickers = [];
  List<Offset> stickerOffsets = [];

  GlobalKey globalKey = GlobalKey();

  List<Sticker> stickers = [
    Sticker(image: AssetImage('assets/stickers/angry.png')),
    Sticker(image: AssetImage('assets/stickers/cat.png')),
    Sticker(image: AssetImage('assets/stickers/corgi.png')),
    Sticker(image: AssetImage('assets/stickers/love.png')),
    Sticker(image: AssetImage('assets/stickers/mockery.png')),
  ];

  @override
  void initState() {
    notifier = ScribbleNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Draw App"),
        actions: _buildActions(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: globalKey,
              child: Card(
                clipBehavior: Clip.hardEdge,
                margin: EdgeInsets.zero,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: Stack(
                  children: [
                    Scribble(
                      notifier: notifier,
                      drawPen: true,
                    ),
                    for (var i = 0; i < selectedStickers.length; i++)
                    // Trong phần build của _DrawAppScreenState
                      Positioned(
                        left: stickerOffsets.isEmpty ? 150.0 : stickerOffsets[i].dx,
                        top: stickerOffsets.isEmpty ? 150.0 : stickerOffsets[i].dy,
                        child: Draggable<Sticker>(
                          data: selectedStickers[i],
                          feedback: Image(image: selectedStickers[i].image, width: 100.0, height: 100.0),
                          childWhenDragging: Container(), // Ẩn sticker khi đang kéo
                          onDraggableCanceled: (velocity, offset) {
                            if (stickerOffsets.length > i) {
                              double roundedX = offset.dx.roundToDouble();
                              double roundedY = offset.dy.roundToDouble();
                              setState(() {
                                stickerOffsets[i] = Offset(roundedX, roundedY); // Cập nhật vị trí mới cho sticker
                              });
                              print("Sticker position when dragged2: ${stickerOffsets[i]}");
                            }
                          },
                          child: Image(image: selectedStickers[i].image, width: 100.0, height: 100.0),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStrokeToolbar(context),
                    _buildColorToolbar(context),
                  ],
                ),
                const VerticalDivider(width: 10),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: stickers.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    selectedStickers.add(stickers[index]); // Thêm sticker vào danh sách đã chọn
                                    stickerOffsets.add(const Offset(100.0, 100.0)); // Thêm một Offset mặc định cho sticker mới
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image(image: stickers[index].image, width: 50.0, height: 50.0),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.sticky_note_2),
                ),
                //const Expanded(child: SizedBox()),
                //_buildPointerModeSwitcher(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(context) {
    return [
      ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, value, child) => IconButton(
          icon: child as Icon,
          tooltip: "Undo",
          onPressed: notifier.canUndo ? notifier.undo : null,
        ),
        child: const Icon(Icons.undo),
      ),
      ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, value, child) => IconButton(
          icon: child as Icon,
          tooltip: "Redo",
          onPressed: notifier.canRedo ? notifier.redo : null,
        ),
        child: const Icon(Icons.redo),
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: "Clear",
        onPressed: notifier.clear,
      ),
      IconButton(
        icon: const Icon(Icons.image),
        tooltip: "Show PNG Image",
        onPressed: () => _saveImage(),
      ),
    ];
  }

  Widget _buildColorToolbar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildColorButton(context, color: Colors.black),
        _buildColorButton(context, color: Colors.red),
        _buildColorButton(context, color: Colors.green),
        _buildColorButton(context, color: Colors.blue),
        _buildColorButton(context, color: Colors.yellow),
      ],
    );
  }

  Widget _buildColorButton(
      BuildContext context, {
        required Color color,
      }) {
    return ValueListenableBuilder(
      valueListenable: notifier.select((value) => value is Drawing && value.selectedColor == color.value),
      builder: (context, value, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ColorButton(
          color: color,
          isActive: value,
          onPressed: () => notifier.setColor(color),
        ),
      ),
    );
  }

  Widget _buildStrokeToolbar(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, state, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (final w in notifier.widths)
            _buildStrokeButton(
              context,
              strokeWidth: w,
              state: state,
            ),
        ],
      ),
    );
  }

  Widget _buildStrokeButton(
      BuildContext context, {
        required double strokeWidth,
        required ScribbleState state,
      }) {
    final selected = state.selectedWidth == strokeWidth;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        elevation: selected ? 4 : 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => notifier.setStrokeWidth(strokeWidth),
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: kThemeAnimationDuration,
            width: strokeWidth * 2,
            height: strokeWidth * 2,
            decoration: BoxDecoration(
                color: state.map(
                  drawing: (s) => Color(s.selectedColor),
                  erasing: (_) => Colors.transparent,
                ),
                border: state.map(
                  drawing: (_) => null,
                  erasing: (_) => Border.all(width: 1),
                ),
                borderRadius: BorderRadius.circular(50.0)),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    try {
      RenderRepaintBoundary? boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      ui.Image image = await boundary!.toImage(pixelRatio: 3.0);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();

      await ImageGallerySaver.saveImage(pngBytes!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image saved to gallery!')));
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving image!')));
    }
  }

}

class Sticker {
  final ImageProvider image;

  Sticker({required this.image});
}
