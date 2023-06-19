import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/utilities/generics/get_arguments.dart';

import '../../services/crud/notes_service.dart';
import '../../utilities/dialogs/delete_dialog.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  DatabaseNote? _customer;
  Iterable<DatabasePurchase>? _allPurchases;
  late final NotesService _notesService;
  late final TextEditingController _customerController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    _notesService = NotesService();
    _customerController = TextEditingController();
    _amountController = TextEditingController();

    super.initState();
  }

  void _textControllerListener() async {
    final customer = _customer;
    if (customer == null) {
      return;
    }
    final customerName = _customerController.text;

    await _notesService.updateCustomer(
        note: customer, customer: customerName, total: customer.total);
  }

  void _setupTextControllerListener() {
    _customerController.removeListener(_textControllerListener);
    _customerController.addListener(_textControllerListener);
  }

  Future<DatabaseNote> getExistingCustomer(BuildContext context) async {
    final args = context.getArgument<Map<String, dynamic>>();

    final DatabaseNote widgetCustomer = args?['note'];
    final allPurchases =
        await _notesService.getAllPurchases(customerId: widgetCustomer.id);
    _allPurchases = allPurchases;
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

  void onDeleteNote() async {
    final note = _customer;
    if (note != null) {
      _notesService.deleteCustomer(id: note.id);
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();

    _customerController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer History'),
        // actions: [
        //   IconButton(
        //     onPressed: () async {},
        //     icon: const Icon(Icons.share),
        //   ),
        // ],
      ),
      body: FutureBuilder(
        future: getExistingCustomer(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomerView(
                    customerController: _customerController,
                    amountController: _amountController,
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 335.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 95, 98, 100),
                        width: 2.0,
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: _allPurchases?.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = _allPurchases!.length - 1 - index;
                        final purchaseDate = _allPurchases
                            ?.elementAt(reversedIndex)
                            .purchaseDate;
                        final amount =
                            _allPurchases?.elementAt(reversedIndex).amount;

                        return ListTile(
                          title: Text(
                            purchaseDate!,
                            maxLines: 1,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            amount! < 0
                                ? 'Received: ${amount.abs()}'
                                : 'Added: $amount',
                            maxLines: 1,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).popAndPushNamed(updateRoute,
                              arguments: {'note': snapshot.data, 'Add': true});
                        },
                        child: const Text('Add'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).popAndPushNamed(updateRoute,
                              arguments: {'note': snapshot.data, 'Add': false});
                        },
                        child: const Text('Clear'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final shouldDelete = await showDeleteDialog(context);
                          if (shouldDelete) {
                            onDeleteNote();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('Clear All Payments'),
                      ),
                    ],
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

class CustomerView extends StatefulWidget {
  const CustomerView({
    super.key,
    required TextEditingController customerController,
    required TextEditingController amountController,
  })  : _customerController = customerController,
        _amountController = amountController;

  final TextEditingController _customerController;
  final TextEditingController _amountController;

  @override
  State<CustomerView> createState() => _CustomerViewState();
}

class _CustomerViewState extends State<CustomerView> {
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
            labelText: 'Total',
          ),
        ),

        // TextField(
        //   controller: widget._addController,
        //   focusNode: _secondTextFieldFocusNode,
        //   keyboardType: TextInputType.number,
        //   decoration: const InputDecoration(
        //     labelText: 'Enter a number',
        //   ),
        //   onEditingComplete: () {
        //     addToAmount();
        //   },
        // ),
      ],
    );
  }
}
