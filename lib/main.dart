import 'package:flutter/material.dart';
// import 'package:bloc/bloc.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/views/notes/clear_payment_view.dart';
// import 'package:my_app/services/auth/auth_service.dart';
// import 'package:my_app/views/login_view.dart';
import 'package:my_app/views/notes/create_update_note_view.dart';
import 'package:my_app/views/notes/notes_view.dart';
// import 'dart:developer' as devtools show log;

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
        createOrUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
        clearPaymentRoute: (context) => const ClearPaymentView(),
        notesRoute: (context) => const NotesView(),
      },
    ),
  );
}
