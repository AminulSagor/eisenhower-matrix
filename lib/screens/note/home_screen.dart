import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/note_model.dart';
import '../../service/auth_service.dart';
import '../../service/note_service.dart';
import '../authentication/login_screen.dart';
import 'create_note_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final NoteService _noteService = NoteService();

  List<Note> notes = [];
  List<Note> filteredNotes = [];
  String selectedFilter = 'New to Old';
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNotesFromBackend();
  }

  Future<void> _fetchNotesFromBackend() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final fetchedNotes = await _noteService.fetchNotes();
      setState(() {
        notes = fetchedNotes;
        filteredNotes = List.from(fetchedNotes); // Initialize filtered notes
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch notes. Please try again. $e';
        isLoading = false;
      });
    }
  }

  void _filterNotes(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'New to Old') {
        filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else if (filter == 'Old to New') {
        filteredNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        filteredNotes = notes.where((note) => note.type == filter).toList();
      }
    });
  }

  Future<void> _addNewNote() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNotePage()),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _deleteNoteConfirmation(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: Text('Are you sure you want to delete the note "${note.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteNoteById(note.id);
    }
  }

  Future<void> _deleteNoteById(int id) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
      final success = await _noteService.deleteNoteById(id);
      if (success) {
        setState(() {
          notes.removeWhere((note) => note.id == id );
          filteredNotes.removeWhere((note) => note.id == id );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully.')),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to delete note. Please try again. $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eisenhower Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : Column(
          children: [
            // Search Container
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Notes',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filteredNotes = notes
                            .where((note) => note.title
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of Notes
            Expanded(
              child: ListView.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  return GestureDetector(
                    onLongPress: () => _deleteNoteConfirmation(note),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateNotePage(note: note), // Pass the note object
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(note.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            Text(
                              note.type,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatDate(note.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 50),
        child: FloatingActionButton(
          onPressed: _addNewNote,
          tooltip: 'Add Note',
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('New to Old'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('New to Old');
                },
              ),
              ListTile(
                title: const Text('Old to New'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('Old to New');
                },
              ),
              ListTile(
                title: const Text('Important and urgent'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('Important and urgent');
                },
              ),
              ListTile(
                title: const Text('Important and not urgent'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('Important and not urgent');
                },
              ),
              ListTile(
                title: const Text('Not important and urgent'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('Not important and urgent');
                },
              ),
              ListTile(
                title: const Text('Not important and not urgent'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('Not important and not urgent');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      return DateFormat('MMMM dd').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }
}
