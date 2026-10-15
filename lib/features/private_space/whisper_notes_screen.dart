import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';

class WhisperNotesScreen extends StatefulWidget {
  final String relId;
  const WhisperNotesScreen({super.key, required this.relId});

  @override
  State<WhisperNotesScreen> createState() => _WhisperNotesScreenState();
}

class _WhisperNotesScreenState extends State<WhisperNotesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  void _addNote() {
    final controller = TextEditingController();
    String selectedHex = '0xFFFFF9C4'; // Default yellow Post-it
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Whisper Note ✍️', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Leave a sweet note...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.grey.shade50,
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: ['0xFFFFF9C4', '0xFFFFCCBC', '0xFFC8E6C9', '0xFFBBDEFB', '0xFFF8BBD0'].map((hex) => GestureDetector(
                  onTap: () => setDialogState(() => selectedHex = hex),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(hex)),
                      shape: BoxShape.circle,
                      border: Border.all(color: selectedHex == hex ? Colors.black : Colors.transparent, width: 2),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _cloudService.addWhisperNote(widget.relId, controller.text, selectedHex);
      // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('STICK IT', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF1), // Light pink parchment
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
        ),
        title: const Text('WHISPER NOTES', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2, fontSize: 14)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.note_alt_rounded, color: Colors.white),
        label: const Text('POST NOTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cloudService.streamWhisperNotes(widget.relId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.push_pin_rounded, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text('No notes pinned yet...', style: AppTextStyles.bodyM.copyWith(color: Colors.grey)),
                  Text('Leave a surprise for your love!', style: AppTextStyles.bodyS.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: docs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final node = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final color = Color(int.parse(node['color']));
                  
                  // Handle missing coordinates (legacy or new notes)
                  double px = (node['posX'] ?? 0.5).toDouble();
                  double py = (node['posY'] ?? 0.5).toDouble();

                  // Convert relative to absolute (capping to stay within bounds)
                  double left = (px * (constraints.maxWidth - 160)).clamp(0.0, constraints.maxWidth - 160);
                  double top = (py * (constraints.maxHeight - 160)).clamp(0.0, constraints.maxHeight - 160);

                  return Positioned(
                    left: left,
                    top: top,
                    child: ZoomIn(
                      delay: Duration(milliseconds: index * 50),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                           // Update locally for smooth dragging
                           double newX = (left + details.delta.dx) / (constraints.maxWidth - 160);
                           double newY = (top + details.delta.dy) / (constraints.maxHeight - 160);
                           _cloudService.updateWhisperNotePosition(widget.relId, id, newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0));
                        },
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: _buildNoteCard(id, node, color),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(String id, Map<String, dynamic> data, Color color) {
    final isMe = data['authorUid'] == _cloudService.currentUid;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(4, 4))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data['content'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.4, color: Colors.black87),
                  ),
                ),
                Text(
                  isMe ? 'By Me' : 'By Partner',
                  style: TextStyle(color: Colors.black38, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.black26),
              onPressed: () => _cloudService.deleteWhisperNote(widget.relId, id),
            ),
          ),
          // Pin visual
          const Positioned(
            top: 8, left: 0, right: 0,
            child: Center(
              child: Icon(Icons.push_pin_rounded, color: Colors.redAccent, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
