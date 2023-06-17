import 'package:flutter/material.dart';
// import 'package:my_app/constants/routes.dart';
import 'package:my_app/services/crud/notes_service.dart';
import 'package:my_app/utilities/dialogs/delete_dialog.dart';
// import 'package:my_app/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:my_app/utilities/generics/get_arguments.dart';
// import 'package:share_plus/share_plus.dart';

class ClearPaymentView extends StatefulWidget {
  const ClearPaymentView({super.key});

  @override
  State<ClearPaymentView> createState() => _ClearPaymentViewState();
}

class _ClearPaymentViewState extends State<ClearPaymentView> {
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

  void onDeleteNote() async {
    final note = _note;
    if (note != null) {
      _notesService.deleteNote(id: note.id);
    }
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
        title: const Text('Clear Payments'),
        // actions: [
        //   IconButton(
        //     onPressed: () async {},
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
                  CustomerDetail(
                      customerController: _customerController,
                      amountController: _amountController,
                      addController: _addController),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final currentContext = context;
                            final shouldDelete =
                                await showDeleteDialog(context);
                            if (shouldDelete) {
                              onDeleteNote();
                              if (mounted) {
                                Navigator.pop(currentContext);
                              }
                            }
                          },
                          child: const Text('Clear All Payments'),
                        ),
                      ],
                    ),
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

class CustomerDetail extends StatefulWidget {
  const CustomerDetail({
    super.key,
    required TextEditingController customerController,
    required TextEditingController amountController,
    required TextEditingController addController,
  })  : _customerController = customerController,
        _amountController = amountController,
        _addController = addController;

  final TextEditingController _customerController;
  final TextEditingController _amountController;
  final TextEditingController _addController;

  @override
  State<CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetail> {
  void addToAmount() async {
    String text = widget._addController.text;
    final amountText = widget._amountController.text;
    int amount = int.tryParse(amountText) ?? 0;
    int number = int.tryParse(text) ?? 0;

    setState(() {
      amount -= number;
      widget._amountController.text = amount.toString();
      widget._addController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget._customerController,
          keyboardType: TextInputType.text,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Customer',
          ),
        ),
        TextField(
          controller: widget._amountController,
          enabled: false,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Amount',
          ),
        ),
        TextField(
          autofocus: true,
          controller: widget._addController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter a number',
          ),
          onEditingComplete: () {
            addToAmount();
          },
        ),
      ],
    );
  }
}
