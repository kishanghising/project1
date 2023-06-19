import 'package:flutter/material.dart';

import 'package:my_app/constants/routes.dart';

import 'package:my_app/views/notes/create_view.dart';
import 'package:my_app/views/notes/history_view.dart';
import 'package:my_app/views/notes/notes_view.dart';
import 'package:my_app/views/notes/update_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Payment app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotesView(),
      routes: {
        notesRoute: (context) => const NotesView(),
        createRoute: (context) => const CreateView(),
        updateRoute: (context) => const UpdateView(),
        historyRoute: (context) => const HistoryView(),
      },
    ),
  );
}
