import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

class _DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;

  _DrawnLine({required this.path, required this.color, required this.width});

  Map<String, dynamic> toMap() {
    return {
      'points': path.map((p) => [p.dx, p.dy]).toList(),
      'color': color.toARGB32(),
      'width': width,
    };
  }

  static _DrawnLine fromMap(Map<String, dynamic> map) {
    final pointsList = (map['points'] as List<dynamic>?) ?? [];
    final offsets = pointsList.map((pt) {
      final list = pt as List<dynamic>;
      return Offset((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }).toList();

    return _DrawnLine(
      path: offsets,
      color: Color((map['color'] as num?)?.toInt() ?? 0xFFFF4D8D),
      width: (map['width'] as num?)?.toDouble() ?? 4.0,
    );
  }
}

/// NextMeet Shared Real-Time Drawing Game
/// Strictly following NextMeet Redesign.pdf (Page 51)
class DrawTogetherScreen extends StatefulWidget {
  final String? relId;
  const DrawTogetherScreen({super.key, this.relId});

  @override
  State<DrawTogetherScreen> createState() => _DrawTogetherScreenState();
}

class _DrawTogetherScreenState extends State<DrawTogetherScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  final List<_DrawnLine> _lines = [];
  Color _selectedColor = AppColors.primary;
  final double _strokeWidth = 4.0;
  bool _isEraser = false;

  final List<Color> _palette = [
    AppColors.primary,
    AppColors.partner,
    AppColors.mintText,
    AppColors.butterText,
    AppColors.ink,
  ];

  bool _isPanActive = false;
  int _lastCloudUpdate = 0;

  void _clearCanvas() {
    VibrationService.light();
    setState(() => _lines.clear());
    if (widget.relId != null) {
      _gameService.clearDrawing(widget.relId!);
    }
  }

  void _saveDrawing() {
    VibrationService.success();
    if (widget.relId != null) {
      _cloudService.addCoupleXp(widget.relId!, 80);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved drawing to Memories! +80 XP 🎨')),
    );
  }

  void _syncLinesToCloud() {
    if (widget.relId == null) return;
    final serialized = _lines.map((l) => l.toMap()).toList();
    _gameService.updateDrawing(widget.relId!, serialized);
  }

  @override
  Widget build(BuildContext context) {
    final relId = widget.relId;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: relId != null ? _gameService.streamDrawing(relId) : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.data() != null && !_isPanActive) {
          final data = snapshot.data!.data()!;
          final cloudLines = (data['lines'] as List<dynamic>?) ?? [];
          final ts = (data['updatedAt'] as dynamic)?.hashCode ?? cloudLines.length;
          if (ts != _lastCloudUpdate) {
            _lastCloudUpdate = ts;
            _lines.clear();
            for (final item in cloudLines) {
              if (item is Map) {
                _lines.add(_DrawnLine.fromMap(Map<String, dynamic>.from(item)));
              }
            }
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Draw Together',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _clearCanvas,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.ink),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _saveDrawing,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text('Save', style: AppTextStyles.button.copyWith(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Canvas Area (Page 51)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GestureDetector(
                      onPanStart: (details) {
                        _isPanActive = true;
                        setState(() {
                          _lines.add(
                            _DrawnLine(
                              path: [details.localPosition],
                              color: _isEraser ? Colors.white : _selectedColor,
                              width: _isEraser ? 20.0 : _strokeWidth,
                            ),
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        if (_lines.isNotEmpty) {
                          setState(() {
                            _lines.last.path.add(details.localPosition);
                          });
                        }
                      },
                      onPanEnd: (_) {
                        _isPanActive = false;
                        _syncLinesToCloud();
                      },
                      child: CustomPaint(
                        painter: _DrawingPainter(lines: _lines),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Floating Drawing Toolbar (Colors + Eraser)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Palette
                      Row(
                        children: _palette.map((color) {
                          final isSelected = !_isEraser && _selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() {
                                _selectedColor = color;
                                _isEraser = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Eraser Toggle
                      GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          setState(() => _isEraser = !_isEraser);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isEraser ? AppColors.partnerSoft : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_fix_normal_outlined,
                                size: 18,
                                color: _isEraser ? AppColors.partner : AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Eraser',
                                style: AppTextStyles.caption.copyWith(
                                  color: _isEraser ? AppColors.partnerText : AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawnLine> lines;
  _DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.path.isEmpty) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      if (line.path.length == 1) {
        canvas.drawCircle(line.path.first, line.width / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path();
        path.moveTo(line.path.first.dx, line.path.first.dy);
        for (int i = 1; i < line.path.length; i++) {
          path.lineTo(line.path[i].dx, line.path[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
