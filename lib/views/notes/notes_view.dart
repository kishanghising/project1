import 'package:flutter/material.dart';
import 'package:my_app/services/crud/notes_service.dart';
import 'package:my_app/views/notes/notes_list_view.dart';
import '../../constants/routes.dart';
// import '../../enums/menu_action.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final NotesService _notesService;

  @override
  void initState() {
    _notesService = NotesService();
    super.initState();
  }

  // @override
  // void dispose() {
  //   _notesService.close();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Customers'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createRoute);
            },
            icon: const Icon(Icons.add),
          ),
          // PopupMenuButton<MenuAction>(
          //   onSelected: (value) async {
          //     switch (value) {
          //       case MenuAction.logout:
          //         // final shouldLogout = await showLogOutDialog(context);
          //         // if (shouldLogout) {
          //         //   context.read<AuthBloc>().add(
          //         //         const AuthEventLogOut(),
          //         //       );
          //         // }
          //         break;
          //       default:
          //     }
          //   },
          //   itemBuilder: (context) {
          //     return const [
          //       PopupMenuItem<MenuAction>(
          //         value: MenuAction.logout,
          //         child: Text('Logout'),
          //       )
          //     ];
          //   },
          // )
        ],
      ),
      body: FutureBuilder(
          future: _notesService.open(),
          builder: (context, snapshot) {
            return StreamBuilder(
              stream: _notesService.allNotes,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                    if (snapshot.hasData) {
                      final allNotes = snapshot.data as Iterable<DatabaseNote>;
                      return NotesListView(
                        notes: allNotes,
                        // onDeleteNote: (note) async {
                        //   await _notesService.deleteNote(id: note.id);
                        // },
                        onTap: (note) {
                          Navigator.of(context).pushNamed(historyRoute,
                              arguments: {'note': note});
                        },
                        onAdd: (note) {
                          Navigator.of(context).pushNamed(updateRoute,
                              arguments: {'note': note, 'Add': true});
                        },
                        onClear: (note) {
                          Navigator.of(context).pushNamed(updateRoute,
                              arguments: {'note': note, 'Add': false});
                        },
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  default:
                    return const CircularProgressIndicator();
                }
              },
            );
          }),
    );
  }
}
