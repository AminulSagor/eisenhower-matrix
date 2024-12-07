import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:eisenhower_matrix/service/token_service.dart';

import '../model/note_model.dart';

class NoteService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<bool> createNote({
    required String title,
    required String createdAt,
    required String type,
    required String content,
  }) async {
    // Get the stored token
    final token = await TokenService().getToken();
    print(token);

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/notes');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include the token for authentication
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'type' : type,
        'createdAt': createdAt,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to create note: ${response.body}');
    }
  }

  Future<List<Note>> fetchNotes() async {
    final token = await TokenService().getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/notes');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((noteData) => Note.fromJson(noteData)).toList();
    } else {
      throw Exception('Failed to fetch notes: ${response.body}');
    }
  }

  Future<bool> deleteNoteById(int id) async {
    final token = await TokenService().getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/notes/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true; // Note deleted successfully
    } else if (response.statusCode == 404) {
      throw Exception('Note not found: ${response.body}');
    } else {
      throw Exception('Failed to delete note: ${response.body}');
    }
  }

  Future<Note> updateNoteById({
    required int id,
    required String title,
    required String content,
    required String type,
    required String createdAt,
  }) async {
    // Get the stored token
    final token = await TokenService().getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/notes/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'type': type,
        'createdAt': createdAt,
      }),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Note not found: ${response.body}');
    } else {
      throw Exception('Failed to update note: ${response.body}');
    }
  }

  Future<Note> findNoteById(String id) async {
    // Get the stored token
    final token = await TokenService().getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/notes/$id'); // Adjust the endpoint
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token', // Include the token for authentication
      },
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body)); // Parse the response to Note object
    } else if (response.statusCode == 404) {
      throw Exception('Note with ID $id not found');
    } else {
      throw Exception('Failed to fetch note: ${response.body}');
    }
  }
}
