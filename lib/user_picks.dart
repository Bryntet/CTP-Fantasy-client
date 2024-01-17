import 'package:flutter/material.dart';

import 'api-classes.dart';
import 'api.dart';

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

  void _addNewPick() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController pdgaController = TextEditingController();
        return AlertDialog(
          title: Text('Add New Pick'),
          content: TextField(
            controller: pdgaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter PDGA Number',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                setState(() {
                  int newSlot = picks.length + 1;
                  int newPdgaNumber = int.parse(pdgaController.text);
                  picks.add(
                      Pick(slot: newSlot, pdgaNumber: newPdgaNumber, name: ''));
                  picks.sort((a, b) => a.slot.compareTo(b.slot));
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
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

          return Scaffold(
            appBar: AppBar(
              title: Text("Player picks by: \"${widget.username}\""),
            ),
            body: isOwner
                ? ReorderableListView.builder(
                    itemCount: picks.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.1),
                            child: Text((index + 1).toString(),
                                style: TextStyle(fontSize: 24)),
                          ),
                          Expanded(
                            child: ListTile(
                              key: Key(picks[index].slot.toString()),
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
                            ),
                          ),
                        ],
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
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
                      return Row(
                        key: Key(picks[index].slot.toString()),
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.01),
                            child: Text(("${index + 1}:").toString(),
                                style: TextStyle(fontSize: 24)),
                          ),
                          Expanded(
                            child: ListTile(
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
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            floatingActionButton: isOwner
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FloatingActionButton.extended(
                        onPressed: () {
                          if (picks.length < snapshot.data!) {
                            setState(() {
                              _addNewPick();
                              picks.sort((a, b) => a.slot.compareTo(b.slot));
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                      SizedBox(
                          width: 10), // Add some spacing between the buttons
                      FloatingActionButton.extended(
                        onPressed: () {
                          ApiService().addPicks(widget.tournament.id, picks);
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
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
