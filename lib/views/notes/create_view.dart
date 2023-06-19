import 'package:flutter/material.dart';
import 'package:my_app/services/crud/notes_service.dart';

class CreateView extends StatefulWidget {
  const CreateView({super.key});

  @override
  State<CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<CreateView> {
  DatabaseNote? _customer;
  late final NotesService _notesService;
  late final TextEditingController _customerController;
  late final TextEditingController _amountController;
  late final TextEditingController _addController;

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

  Future<DatabaseNote> createNewCustomer() async {
    final existingCustomer = _customer;
    if (existingCustomer != null) {
      return existingCustomer;
    }
    final newCustomer = await _notesService.createCustomer();
    _customer = newCustomer;
    return newCustomer;
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
        await _notesService.createPurchase(
            amount: amount, customerId: customer.id);
      } else {
        await _notesService.deleteCustomer(id: customer.id);
      }
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
        title: const Text('Create Customer'),
        // actions: [
        //   IconButton(
        //     onPressed: () async {},
        //     icon: const Icon(Icons.share),
        //   ),
        // ],
      ),
      body: FutureBuilder(
        future: createNewCustomer(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return CustomerView(
                  customerController: _customerController,
                  amountController: _amountController,
                  addController: _addController);

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
    required TextEditingController addController,
  })  : _customerController = customerController,
        _amountController = amountController,
        _addController = addController;

  final TextEditingController _customerController;
  final TextEditingController _amountController;
  final TextEditingController _addController;

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
    _firstTextFieldFocusNode.requestFocus();
    super.initState();
  }

  void addToAmount() async {
    String text = widget._addController.text;
    final amountText = widget._amountController.text;
    int amount = int.tryParse(amountText) ?? 0;
    int number = int.tryParse(text) ?? 0;

    setState(() {
      amount += number;
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
