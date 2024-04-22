import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class DrawAppScreen extends StatefulWidget {
  const DrawAppScreen({super.key});

  @override
  State<DrawAppScreen> createState() => _DrawAppScreenState();
}

class _DrawAppScreenState extends State<DrawAppScreen> {
  List<List<Offset?>> allPoints = [[]];
  List<Color> colors = [Colors.black];
  Color selectedColor = Colors.black;

  List<List<PointWithStroke>> allStokeWidths = [[]];
  double strokeWidth = 5.0; // Kích thước nét vẽ mặc định

  GlobalKey globalKey = GlobalKey();
  Offset? _stickerPosition;

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
                colors.add(selectedColor); // Thêm màu mực cho đường vẽ mới
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
              allPoints.add([]); // Thêm null để kết thúc một đường vẽ
              allStokeWidths.add([]);
              colors.add(selectedColor); // Thêm màu mực cho đường vẽ mới
            });
          },
          child: CustomPaint(
            painter: DrawPainter(allPoints: allPoints, colors: colors, allStokeWidths: allStokeWidths),
            size: Size.infinite,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            allPoints.clear(); // Xóa tất cả điểm để xóa bản vẽ
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
              items: <double>[1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0].map<DropdownMenuItem<double>>((double value) {
                return DropdownMenuItem<double>(
                  value: value,
                  child: Text('$value'),
                );
              }).toList(),
            ),
            // Thêm các nút màu khác tại đây
          ],
        ),
      ),
    );
  }

  // Hàm callback được gọi khi một màu được chọn
  void onSelectColor(Color color) {
    setState(() {
      selectedColor = color;
      colors[colors.length - 1] = selectedColor; // Cập nhật màu mực cho đường vẽ hiện tại
    });
  }

  Future<void> _saveImage() async {
    try {
      RenderRepaintBoundary? boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      ui.Image image = await boundary!.toImage(pixelRatio: 3.0); // Pixel ratio can be adjusted based on the need

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

// Widget để hiển thị nút chọn màu
class ColorButton extends StatelessWidget {
  final Color color;
  final Function(Color) onSelect;

  const ColorButton(this.color, this.onSelect, {super.key});

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

class DrawPainter extends CustomPainter {
  final List<List<Offset?>> allPoints;
  final List<Color> colors;
  final List<List<PointWithStroke>> allStokeWidths;

  DrawPainter({required this.allPoints, required this.colors, required this.allStokeWidths});

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ hình chữ nhật màu trắng với kích thước bằng CustomPaint
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (int i = 0; i < allPoints.length; i++) {
      if (i < colors.length && allPoints[i].isNotEmpty) {
        // Kiểm tra số lượng màu mực trước khi truy cập
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
