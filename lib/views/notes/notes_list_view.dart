import 'package:flutter/material.dart';
import 'package:my_app/services/crud/notes_service.dart';
// import 'package:my_app/utilities/dialogs/delete_dialog.dart';

typedef NoteCallback = void Function(DatabaseNote note);

class NotesListView extends StatelessWidget {
  final Iterable<DatabaseNote> notes;
  final NoteCallback onTap;
  final NoteCallback onAdd;
  final NoteCallback onClear;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onTap,
    required this.onAdd,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final reversedIndex = notes.length - 1 - index;
        final note = notes.elementAt(reversedIndex);
        return ListTile(
          onTap: () {
            onTap(note);
          },
          title: Row(
            children: [
              Text(
                note.customer,
                maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 16),
              Text(
                "${note.total}",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  // final shouldDelete = await showDeleteDialog(context);
                  // if (shouldDelete) {
                  //   onDeleteNote(note);
                  // }
                  onClear(note);
                },
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  onAdd(note);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
}
