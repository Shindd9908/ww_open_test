import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class DrawAppScreen extends StatefulWidget {
  const DrawAppScreen({Key? key}) : super(key: key);

  @override
  State<DrawAppScreen> createState() => _DrawAppScreenState();
}

class _DrawAppScreenState extends State<DrawAppScreen> {
  List<List<Offset?>> allPoints = [[]];
  List<Color> colors = [Colors.black];
  Color selectedColor = Colors.black;

  List<List<PointWithStroke>> allStokeWidths = [[]];
  double strokeWidth = 5.0;

  GlobalKey globalKey = GlobalKey();

  List<Sticker> stickers = [
    Sticker(image: AssetImage('assets/stickers/angry.png')),
    Sticker(image: AssetImage('assets/stickers/cat.png')),
    Sticker(image: AssetImage('assets/stickers/corgi.png')),
    Sticker(image: AssetImage('assets/stickers/love.png')),
    Sticker(image: AssetImage('assets/stickers/mockery.png')),
  ];
  List<Sticker> selectedStickers = [];
  List<Offset> stickerOffsets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Draw App Example"),
        actions: [
          GestureDetector(
            onTap: () => _saveImage(),
            child: const Icon(Icons.save),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: globalKey,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              if (allPoints.isEmpty) {
                allPoints.add([]);
                colors.add(selectedColor);
              }
              allPoints.last.add(renderBox.globalToLocal(details.globalPosition));
              allStokeWidths.last.add(PointWithStroke(
                offset: renderBox.globalToLocal(details.globalPosition),
                strokeWidth: strokeWidth,
              ));
            });
          },
          onPanEnd: (details) {
            setState(() {
              allPoints.add([]);
              allStokeWidths.add([]);
              colors.add(selectedColor);
            });
          },
          child: Stack(
            children: [
              CustomPaint(
                painter: DrawPainter(allPoints: allPoints, colors: colors, allStokeWidths: allStokeWidths),
                size: Size.infinite,
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
                      }
                    },
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        print("Sticker position when dragged: ${details.globalPosition}");
                      },
                      child: Image(image: selectedStickers[i].image, width: 100.0, height: 100.0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            allPoints.clear();
            selectedStickers.clear();
          });
        },
        child: const Icon(Icons.clear),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ColorButton(Colors.black, onSelectColor),
            ColorButton(Colors.red, onSelectColor),
            ColorButton(Colors.blue, onSelectColor),
            ColorButton(Colors.green, onSelectColor),
            DropdownButton<double>(
              value: strokeWidth,
              onChanged: (double? newValue) {
                setState(() {
                  strokeWidth = newValue!;
                });
              },
              items: const <DropdownMenuItem<double>>[
                DropdownMenuItem<double>(
                  key: ValueKey('strokeWidth_1'),
                  value: 1.0,
                  child: Text('1.0'),
                ),
                DropdownMenuItem<double>(
                  key: ValueKey('strokeWidth_2'),
                  value: 3.0,
                  child: Text('3.0'),
                ),
                DropdownMenuItem<double>(
                  key: ValueKey('strokeWidth_3'),
                  value: 5.0,
                  child: Text('5.0'),
                ),
                // Add other DropdownMenuItem with unique ValueKey for each item
              ],
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
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
          ],
        ),
      ),
    );
  }

  void onSelectColor(Color color) {
    setState(() {
      selectedColor = color;
      colors[colors.length - 1] = selectedColor;
    });
  }

  void onDropSticker(Sticker droppedSticker, Offset position) {
    setState(() {
      //_stickerPosition = position;
      selectedStickers.add(droppedSticker);
    });
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

class ColorButton extends StatelessWidget {
  final Color color;
  final Function(Color) onSelect;

  const ColorButton(this.color, this.onSelect, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.circle),
      color: color,
      onPressed: () => onSelect(color),
    );
  }
}

class PointWithStroke {
  Offset? offset;
  double strokeWidth;

  PointWithStroke({this.offset, this.strokeWidth = 5.0});
}

class Sticker {
  final ImageProvider image;

  Sticker({required this.image});
}

class DrawPainter extends CustomPainter {
  final List<List<Offset?>> allPoints;
  final List<Color> colors;
  final List<List<PointWithStroke>> allStokeWidths;

  DrawPainter({required this.allPoints, required this.colors, required this.allStokeWidths});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (int i = 0; i < allPoints.length; i++) {
      if (i < colors.length && allPoints[i].isNotEmpty) {
        Paint paint = Paint()
          ..color = colors[i]
          ..strokeCap = StrokeCap.round
          ..strokeWidth = allStokeWidths[i].first.strokeWidth;

        for (int j = 0; j < allPoints[i].length - 1; j++) {
          if (allPoints[i][j] != null && allPoints[i][j + 1] != null) {
            canvas.drawLine(allPoints[i][j]!, allPoints[i][j + 1]!, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class StickerWidget extends StatelessWidget {
  final Sticker sticker;
  final Function(Sticker, Offset) onDrop;
  final Offset initialOffset;

  const StickerWidget({Key? key, required this.sticker, required this.onDrop, required this.initialOffset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Draggable<Sticker>(
      data: sticker,
      feedback: Image(image: sticker.image),
      childWhenDragging: Opacity(opacity: 0.5, child: Image(image: sticker.image)),
      child: Image(image: sticker.image),
      onDraggableCanceled: (velocity, offset) {
        onDrop(sticker, offset);
      },
    );
  }
}
