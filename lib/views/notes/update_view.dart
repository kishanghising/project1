import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/services/crud/notes_service.dart';
import 'package:my_app/utilities/generics/get_arguments.dart';

import '../../utilities/dialogs/delete_dialog.dart';

class UpdateView extends StatefulWidget {
  const UpdateView({super.key});

  @override
  State<UpdateView> createState() => _UpdateViewState();
}

class _UpdateViewState extends State<UpdateView> {
  DatabaseNote? _customer;
  late final NotesService _notesService;
  late final TextEditingController _customerController;
  late final TextEditingController _amountController;
  late final TextEditingController _addController;
  late final bool _fromAdd;

  @override
  void initState() {
    _notesService = NotesService();
    _customerController = TextEditingController();
    _amountController = TextEditingController(text: '0');
    _addController = TextEditingController();

    super.initState();
  }

  void _textControllerListener() async {
    final customer = _customer;
    if (customer == null) {
      return;
    }
    final customerName = _customerController.text;
    final amountText = _amountController.text;
    int amount = int.tryParse(amountText) ?? 0;
    await _notesService.updateCustomer(
        note: customer, customer: customerName, total: amount);
  }

  void _setupTextControllerListener() {
    _customerController.removeListener(_textControllerListener);
    _customerController.addListener(_textControllerListener);
    _amountController.removeListener(_textControllerListener);
    _amountController.addListener(_textControllerListener);
  }

  Future<DatabaseNote> getExistingCustomer(BuildContext context) async {
    final args = context.getArgument<Map<String, dynamic>>();
    final DatabaseNote widgetCustomer = args?['note'];
    _fromAdd = args?['Add'];

    _customer = widgetCustomer;
    _customerController.text = widgetCustomer.customer;
    _amountController.text = widgetCustomer.total.toString();
    return widgetCustomer;
  }

  void _deleteNoteIfTextIsEmpty() {
    final customer = _customer;
    if (_customerController.text.isEmpty && customer != null) {
      _notesService.deleteCustomer(id: customer.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final customer = _customer;
    final customerName = _customerController.text;
    final amountText = _amountController.text;
    int amount = int.tryParse(amountText) ?? 0;

    if (customerName.isNotEmpty && customer != null) {
      await _notesService.updateCustomer(
        note: customer,
        customer: customerName,
        total: amount,
      );
      if (amount != 0) {
        final purchase = amount - customer.total;
        if (purchase != 0) {
          await _notesService.createPurchase(
              amount: purchase, customerId: customer.id);
        }
      } else {
        await _notesService.deleteCustomer(id: customer.id);
      }
    }
  }

  void onDeleteNote() async {
    final note = _customer;
    if (note != null) {
      _notesService.deleteCustomer(id: note.id);
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
    return FutureBuilder(
      future: getExistingCustomer(context),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            _setupTextControllerListener();
            return Scaffold(
              appBar:
                  AppBar(title: Text(_fromAdd ? 'Add payment' : 'Clear payment')
                      // actions: [
                      //   IconButton(
                      //     onPressed: () async {},
                      //     icon: const Icon(Icons.share),
                      //   ),
                      // ],
                      ),
              body: Column(
                children: [
                  CustomerView(
                    customerController: _customerController,
                    amountController: _amountController,
                    addController: _addController,
                    fromAdd: _fromAdd,
                  ),
                  if (!_fromAdd)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final shouldDelete =
                                  await showDeleteDialog(context);
                              if (shouldDelete) {
                                onDeleteNote();
                                if (mounted) {
                                  Navigator.of(context)
                                      .pushReplacementNamed(notesRoute);
                                }
                              }
                            },
                            child: const Text('Clear All Payments'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

          default:
            return Scaffold(
              appBar: AppBar(
                title: Text(_fromAdd ? 'Add payment' : 'Clear payment'),
                // actions: [
                //   IconButton(
                //     onPressed: () async {},
                //     icon: const Icon(Icons.share),
                //   ),
                // ],
              ),
              body: const CircularProgressIndicator(),
            );
        }
      },
    );
  }
}

class CustomerView extends StatefulWidget {
  const CustomerView({
    super.key,
    required TextEditingController customerController,
    required TextEditingController amountController,
    required TextEditingController addController,
    required this.fromAdd,
  })  : _customerController = customerController,
        _amountController = amountController,
        _addController = addController;

  final TextEditingController _customerController;
  final TextEditingController _amountController;
  final TextEditingController _addController;
  final bool fromAdd;

  @override
  State<CustomerView> createState() => _CustomerViewState();
}

class _CustomerViewState extends State<CustomerView> {
  late FocusNode _firstTextFieldFocusNode;
  late FocusNode _secondTextFieldFocusNode;

  @override
  void initState() {
    _firstTextFieldFocusNode = FocusNode();
    _secondTextFieldFocusNode = FocusNode();

    super.initState();
  }

  void addToAmount() async {
    String text = widget._addController.text;
    final amountText = widget._amountController.text;
    int amount = int.tryParse(amountText) ?? 0;
    int number = int.tryParse(text) ?? 0;

    setState(() {
      if (widget.fromAdd) {
        amount += number;
      } else if (!widget.fromAdd) {
        amount -= number;
      }
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
          focusNode: _firstTextFieldFocusNode,
          onEditingComplete: () {
            _firstTextFieldFocusNode.unfocus();
            FocusScope.of(context).requestFocus(_secondTextFieldFocusNode);
          },
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
          focusNode: _secondTextFieldFocusNode,
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
