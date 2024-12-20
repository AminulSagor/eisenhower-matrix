import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../advertisment/banner_ad.dart';
import '../../advertisment/interstitial_ad_helper.dart';
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
  final InterstitialAdHelper _interstitialAdHelper = InterstitialAdHelper();

  List<Note> notes = [];
  List<Note> filteredNotes = [];
  bool isLoading = true;
  String errorMessage = '';
  int filterSelectionCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotesFromBackend();
    _interstitialAdHelper.loadInterstitialAd();
  }

  Future<void> _fetchNotesFromBackend() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final fetchedNotes = await _noteService.fetchNotes();
      fetchedNotes.sort((a, b) => b.id.compareTo(a.id));
      setState(() {
        notes = fetchedNotes;
        filteredNotes = List.from(fetchedNotes);
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
      if (filter == 'All') {
        filteredNotes = List.from(notes);
      } else {
        filteredNotes = notes.where((note) => note.type == filter).toList();
      }

      filterSelectionCount++;

      // Show interstitial ad after every five selections
      if (filterSelectionCount % 5 == 0) {
        //_interstitialAdHelper.showInterstitialAd();
      }
    });
  }

  Future<void> _addNewNote() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNotePage()),
    ).then((_) {
      // Reload the notes after returning from the CreateNotePage
      _fetchNotesFromBackend();
    });
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
          content:
              Text('Are you sure you want to delete the note "${note.title}"?'),
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
          notes.removeWhere((note) => note.id == id);
          filteredNotes.removeWhere((note) => note.id == id);
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
    return Stack(children: [
      Scaffold(
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
          child: Column(
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
                child: isLoading
                    ? const SizedBox()
                    : filteredNotes.isEmpty
                        ? const Center(
                            child: Text(
                              'No notes available',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              // if ((index + 1) % 4 == 0 && index != 0) {
                              //   return const Column(
                              //     children: [
                              //       ListTile(
                              //         title: BannerAdWidget(),
                              //       ),
                              //       SizedBox(height: 10),
                              //     ],
                              //   );
                              // }
                              final note = filteredNotes[index];
                              return GestureDetector(
                                onLongPress: () =>
                                    _deleteNoteConfirmation(note),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreateNotePage(note: note),
                                    ),
                                  ).then((_) {
                                    _fetchNotesFromBackend();
                                  });
                                },
                                child: Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text(note.title),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note.content,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.black54),
                                        ),
                                        Text(
                                          note.type,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          note.createdAt,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
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
      ),
      if (isLoading)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5), // Background overlay
            child: Center(
              child: Lottie.asset(
                'assets/animations/loading_animation.json',
                width: 300,
                height: 300,
              ),
            ),
          ),
        ),
    ]);
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
                title: const Text('All'),
                onTap: () {
                  Navigator.of(context).pop();
                  _filterNotes('All');
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
}
