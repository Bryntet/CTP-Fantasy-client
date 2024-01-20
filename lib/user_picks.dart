import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'api_classes.dart';

class UserPicksPage extends StatefulWidget {
  final FantasyTournament tournament;
  final int userId;
  final String username;

  const UserPicksPage(
      {super.key,
      required this.tournament,
      required this.userId,
      required this.username});

  @override
  _UserPicksPageState createState() => _UserPicksPageState();
}

class _UserPicksPageState extends State<UserPicksPage> {
  List<Pick> picks = [];
  bool isOwner = false;
  late Future<int> maxPicks;

  @override
  void initState() {
    super.initState();
    maxPicks = ApiService().maxPicks(widget.tournament.id);
    ApiService()
        .getUserPicks(widget.tournament.id, widget.userId)
        .then((fPicks) {
      setState(() {
        picks = fPicks.picks;
        picks.sort((a, b) => a.slot.compareTo(b.slot));
        isOwner = fPicks.owner;
      });
    });
  }

  void parentSetState() {
    setState(() {});
  }

  Future<void> _addNewPick() async {
    String errorMessage = '';
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents the dialog from closing on outside touch
      builder: (BuildContext context) {
        TextEditingController pdgaController = TextEditingController();
        return StatefulBuilder(
          // Wrap AlertDialog with StatefulBuilder to update the state of the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Pick'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (errorMessage
                      .isNotEmpty) // Display error message if it's not empty
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'ERROR: ',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: errorMessage.split('\n').length * 16.0),
                        ),
                        Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  TextField(
                    controller: pdgaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter PDGA Number',
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    int newSlot = picks.length + 1;
                    int newPdgaNumber = int.parse(pdgaController.text);
                    try {
                      Navigator.of(context).pop();
                      await ApiService().pickPlayer(
                          widget.tournament.id, newSlot, newPdgaNumber);
                      Pick newPick = await ApiService().getPick(
                          widget.tournament.id, newSlot, widget.userId);
                      setState(() {
                        picks.add(newPick);
                        parentSetState();
                      });
                    } catch (e) {
                      if (e is DioException) {
                        setState(() {
                          errorMessage =
                              e.response?.data; // Update the error message
                        });
                      }
                    }
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Close the dialog when 'Cancel' is pressed
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: maxPicks,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          // Fill the picks list with empty picks until it's full

          double screenWidth = MediaQuery.of(context).size.width;
          return Scaffold(
            appBar: AppBar(
              title: Text("Player picks by: \"${widget.username}\""),
            ),
            body: SizedBox(
              width:
                  screenWidth > 1000 ? screenWidth * 0.15 : screenWidth * 0.8,
              child: isOwner
                  ? ReorderableListView.builder(
                      itemCount: picks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          key: Key(picks[index].slot.toString()),
                          leading: Text("${index + 1}:",
                              style: const TextStyle(fontSize: 24)),
                          title: Text(picks[index].name),
                          subtitle: TextField(
                            controller: TextEditingController(
                                text: picks[index].pdgaNumber.toString()),
                            keyboardType: TextInputType.number,
                            onSubmitted: (value) {
                              setState(() {
                                picks[index].pdgaNumber = int.parse(value);
                              });
                            },
                          ),
                          trailing: screenWidth > 600
                              ? null
                              : ReorderableDragStartListener(
                                  child: Icon(Icons.drag_handle),
                                  index: index,
                                ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        print("hello");
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final Pick item = picks.removeAt(oldIndex);
                          picks.insert(newIndex, item);

                          // Update the slot value of each Pick instance
                          for (int i = 0; i < picks.length; i++) {
                            picks[i].slot = i + 1;
                          }
                        });
                      },
                    )
                  : ListView.builder(
                      itemCount: picks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          key: Key(picks[index].slot.toString()),
                          leading: Text(("${index + 1}:").toString(),
                              style: const TextStyle(fontSize: 24)),
                          title: Text(picks[index].name),
                          subtitle: Text(picks[index].pdgaNumber.toString()),
                        );
                      },
                    ),
            ),
            floatingActionButton: isOwner
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      IgnorePointer(
                        ignoring: picks.length >= snapshot.data!,
                        child: FloatingActionButton(
                          heroTag: "addButton",
                          onPressed: () async {
                            await _addNewPick();
                            setState(() {
                              picks.sort((a, b) => a.slot.compareTo(b.slot));
                            });
                          },
                          backgroundColor: picks.length < snapshot.data!
                              ? null
                              : Colors.black12,
                          tooltip: 'Add New Pick',
                          child: const Icon(Icons.add),
                        ),
                      ),
                      const SizedBox(
                          width: 10), // Add some spacing between the buttons
                      FloatingActionButton(
                        heroTag: "saveButton",
                        onPressed: () async {
                          try {
                            await ApiService()
                                .addPicks(widget.tournament.id, picks);
                          } catch (e) {
                            if (e is DioException) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.response?.data),
                                  backgroundColor: Colors.red, // error color
                                ),
                              );
                            }
                          }
                        },
                        tooltip: 'Save Picks',
                        child: const Icon(Icons.save),
                      ),
                    ],
                  )
                : null,
          );
        }
      },
    );
  }
}
