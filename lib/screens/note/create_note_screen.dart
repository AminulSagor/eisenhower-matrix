import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/note_model.dart';
import '../../service/note_service.dart';

class CreateNotePage extends StatefulWidget {
  final Note? note;

  const CreateNotePage({super.key, this.note});

  @override
  CreateNotePageState createState() => CreateNotePageState();
}

class CreateNotePageState extends State<CreateNotePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String? selectedNoteType;
  late String separator;
  bool isLoading = false;
  List<String> noteTypes = [
    'Important and urgent',
    'Important and not urgent',
    'Not important and urgent',
    'Not important and not urgent'
  ];

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      final note = widget.note!;
      titleController.text = note.title;
      contentController.text = note.content;
      selectedNoteType = note.type;
      separator = note.createdAt;
    } else {
      separator = DateFormat('EEEE, MMMM d, h:mm a').format(DateTime.now());
    }
  }

  Future<void> _saveOrUpdateNote() async {
    final title = titleController.text;
    final content = contentController.text;

    final currentContext = context;

    if (title.isNotEmpty && content.isNotEmpty && selectedNoteType != null) {
      setState(() {
        isLoading = true;
      });

      try {
        if (widget.note == null) {
          final success = await NoteService().createNote(
            title: title,
            content: content,
            createdAt: separator,
            type: selectedNoteType!,
          );

          if (success) {
            debugPrint('Note created: $title');
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(
                content: Text('Note created successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(currentContext);
          }
        } else {
          // Updating an existing note
          final updatedNote = await NoteService().updateNoteById(
            id: widget.note!.id,
            title: title,
            content: content,
            type: selectedNoteType!,
            createdAt: separator,
          );

          if (updatedNote != null) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(
                content: Text('Note updated successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(currentContext);
          } else {
            debugPrint('Failed to update note');
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(
                content: Text('Failed to update note!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to save/update note: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (title.isEmpty) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Title is required!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (content.isEmpty) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Note is required!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Category is required!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.note == null ? 'Create Note' : 'Update Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    separator,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.category),
                      onSelected: (value) {
                        setState(() {
                          selectedNoteType = value;
                          debugPrint('Selected note type: $selectedNoteType');
                        });
                      },
                      initialValue: selectedNoteType,
                      itemBuilder: (BuildContext context) {
                        return noteTypes.map((noteType) {
                          return PopupMenuItem<String>(
                            value: noteType,
                            child: Text(noteType),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: 'Write your note here',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isLoading ? null : _saveOrUpdateNote,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: isLoading
              ? const CircularProgressIndicator()
              : Text(widget.note == null ? 'Save Note' : 'Update Note'),
        ),
      ),
    );
  }
}
