import 'package:flutter/material.dart';
import 'package:my_app/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Clear Payment',
    content: 'Are you sure you want to clear this account?',
    optionsBuilder: () => {
      'Cancel': false,
      'Yes': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
