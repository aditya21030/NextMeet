import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/glass_card.dart';

class SharedSketchpadScreen extends StatefulWidget {
  final String relId;
  const SharedSketchpadScreen({super.key, required this.relId});

  @override
  State<SharedSketchpadScreen> createState() => _SharedSketchpadScreenState();
}

class _SharedSketchpadScreenState extends State<SharedSketchpadScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  List<DrawingPoint?> _points = [];
  Color _selectedColor = AppColors.primary;
  double _strokeWidth = 3.0;
  String? _lastLoadedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        title: Column(
          children: [
            const Text('LOVE SKETCHPAD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: AppColors.textPrimary)),
            Text('Doodle together in real-time', style: AppTextStyles.bodyS.copyWith(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              VibrationService.error();
              setState(() => _points.clear());
              await _cloudService.clearSketchpadData(widget.relId);
            },
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
          ),
          IconButton(
            onPressed: () {
              VibrationService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sketch synced to the cloud! ✨')),
              );
            },
            icon: const Icon(Icons.check_rounded, color: AppColors.success),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('relationships').doc(widget.relId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final sketchData = data['sketchpadData'] as String?;
            final updatedBy = data['sketchpadUpdatedBy'] as String?;
            
            if (sketchData != _lastLoadedData && (updatedBy != _cloudService.currentUid || _lastLoadedData == null)) {
              _lastLoadedData = sketchData;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sketchData == null) {
                  setState(() => _points = []);
                } else {
                  _loadDrawing(sketchData);
                }
              });
            }
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          RenderBox renderBox = context.findRenderObject() as RenderBox;
                          _points.add(DrawingPoint(
                            offset: renderBox.globalToLocal(details.globalPosition),
                            paint: Paint()
                              ..color = _selectedColor
                              ..strokeCap = StrokeCap.round
                              ..strokeWidth = _strokeWidth,
                          ));
                        });
                      },
                      onPanStart: (details) {
                        setState(() {
                          RenderBox renderBox = context.findRenderObject() as RenderBox;
                          _points.add(DrawingPoint(
                            offset: renderBox.globalToLocal(details.globalPosition),
                            paint: Paint()
                              ..color = _selectedColor
                              ..strokeCap = StrokeCap.round
                              ..strokeWidth = _strokeWidth,
                          ));
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _points.add(null);
                        });
                        _saveDrawing(); // Sync after each stroke
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: DrawingPainter(pointsList: _points),
                      ),
                    ),
                  ),
                ),
              ),
              _buildToolbar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorCircle(AppColors.primary),
              _buildColorCircle(AppColors.accent),
              _buildColorCircle(Colors.amber),
              _buildColorCircle(Colors.lightBlue),
              _buildColorCircle(Colors.greenAccent),
              _buildColorCircle(Colors.black),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.line_weight_rounded, size: 20, color: AppColors.textSecondary),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0, max: 10.0,
                  activeColor: _selectedColor,
                  onChanged: (val) => setState(() => _strokeWidth = val),
                ),
              ),
              const Icon(Icons.brush_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        setState(() => _selectedColor = color);
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _selectedColor == color ? color : Colors.transparent, width: 2),
        ),
        child: CircleAvatar(radius: 14, backgroundColor: color),
      ),
    );
  }

  void _saveDrawing() async {
    final List<Map<String, dynamic>> pointsData = _points.map((p) {
      if (p == null) return {'isNull': true};
      return {
        'x': p.offset.dx,
        'y': p.offset.dy,
      // ignore: deprecated_member_use
        'color': p.paint.color.value,
        'width': p.paint.strokeWidth,
      };
    }).toList();
    
    final String jsonString = jsonEncode(pointsData);
    _lastLoadedData = jsonString; // Sync locally to prevent 'echo' reload
    try {
      await _cloudService.updateSketchpadData(widget.relId, jsonString);
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  void _loadDrawing(String sketchData) {
    try {
      final List<dynamic> decoded = jsonDecode(sketchData);
      setState(() {
        _points = decoded.map((p) {
          if (p['isNull'] == true) return null;
          return DrawingPoint(
            offset: Offset(p['x'], p['y']),
            paint: Paint()
              ..color = Color(p['color'])
              ..strokeCap = StrokeCap.round
              ..strokeWidth = p['width'],
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading sketch: $e');
    }
  }
}

class DrawingPoint {
  Offset offset;
  Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> pointsList;
  DrawingPainter({required this.pointsList});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i]!.offset, pointsList[i + 1]!.offset, pointsList[i]!.paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        canvas.drawPoints(PointMode.points, [pointsList[i]!.offset], pointsList[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
