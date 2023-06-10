import 'package:flutter/material.dart';
import 'package:my_app/services/crud/notes_service.dart';
// import 'package:my_app/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:my_app/utilities/generics/get_arguments.dart';
// import 'package:share_plus/share_plus.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _customerController;
  late final TextEditingController _amountController;
  late final TextEditingController _addController;

  @override
  void initState() {
    _notesService = NotesService();
    _customerController = TextEditingController();
    _amountController = TextEditingController();
    _addController = TextEditingController();

    super.initState();
  }

  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final customer = _customerController.text;
    final amountText = _amountController.text;
    int amount = int.tryParse(amountText) ?? 0;
    await _notesService.updateNote(
      note: note,
      customer: customer,
      amount: amount,
    );
  }

  void _setupTextControllerListener() {
    _customerController.removeListener(_textControllerListener);
    _customerController.addListener(_textControllerListener);
    _amountController.removeListener(_textControllerListener);
    _amountController.addListener(_textControllerListener);
    _addController.removeListener(_textControllerListener);
    _addController.addListener(_textControllerListener);
  }

  Future<DatabaseNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<DatabaseNote>();

    if (widgetNote != null) {
      _note = widgetNote;
      _customerController.text = widgetNote.customer;
      _amountController.text = widgetNote.amount.toString();
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final newNote = await _notesService.createNote();
    _note = newNote;
    return newNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_customerController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final customer = _customerController.text;
    final amountText = _amountController.text;
    int amount = int.tryParse(amountText) ?? 0;
    if (note != null && customer.isNotEmpty) {
      await _notesService.updateNote(
        note: note,
        customer: customer,
        amount: amount,
      );
    }
  }

  void _addToAmount() async {
    String text = _addController.text;
    final amountText = _amountController.text;
    final note = _note;
    final customer = _customerController.text;
    int amount = int.tryParse(amountText) ?? 0;
    int number = int.tryParse(text) ?? 0;
    setState(() async {
      amount += number;
      _amountController.text = amount.toString();
      if (note != null && customer.isNotEmpty) {
        await _notesService.updateNote(
          note: note,
          customer: customer,
          amount: amount,
        );
      }
      _addController.clear();
    });
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _customerController.dispose();
    _amountController.dispose();
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create or Update Customer'),
        // actions: [
        //   IconButton(
        //     onPressed: () async {
        //       final text = _customerController.text;
        //       if (_note == null || text.isEmpty) {
        //         await showCannotShareEmptyNoteDialog(context);
        //       } else {
        //         Share.share(text);
        //       }
        //     },
        //     icon: const Icon(Icons.share),
        //   ),
        // ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return Column(
                children: [
                  TextField(
                    controller: _customerController,
                    keyboardType: TextInputType.text,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                    ),
                  ),
                  TextField(
                    controller: _amountController,
                    enabled: false,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Amount',
                    ),
                  ),
                  TextField(
                    autofocus: true,
                    controller: _addController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter a number',
                    ),
                    onSubmitted: (_) {
                      _addToAmount();
                    },
                  ),
                ],
              );

            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
