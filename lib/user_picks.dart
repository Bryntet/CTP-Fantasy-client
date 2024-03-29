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
  List<TextEditingController> controllers = []; // Add this line
  bool isOwner = false;
  late Future<int> maxPicks;
  late Future<List<Division>> divisions;
  Division selectedDivision = Division.MPO; // Add this line

  @override
  void initState() {
    super.initState();
    maxPicks = ApiService().maxPicks(widget.tournament.id);
    divisions =
        ApiService().getFantasyTournamentDivisions(widget.tournament.id);
    loadPicks(); // Call the new method here
  }

  void loadPicks() {
    ApiService()
        .getUserPicks(widget.tournament.id, widget.userId, selectedDivision)
        .then((fPicks) {
      setState(() {
        picks = fPicks.picks;
        picks.sort((a, b) => a.slot.compareTo(b.slot));
        isOwner = fPicks.owner;

        // Initialize the controllers
        controllers = List.generate(
            picks.length,
            (index) => TextEditingController(
                text: picks[index].pdgaNumber.toString()));
      });
    });
  }

  void parentSetState() {
    setState(() {});
  }

  Future<void> _addNewPick() async {
    String errorMessage = '';
    int newSlot = picks.length + 1;
    TextEditingController pdgaController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                      await ApiService().pickPlayer(widget.tournament.id,
                          newSlot, newPdgaNumber, selectedDivision);
                      Navigator.of(context).pop();
                      Pick newPick = await ApiService().getPick(
                          widget.tournament.id,
                          newSlot,
                          widget.userId,
                          selectedDivision);
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
          return const Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeCap: StrokeCap.round,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          int maxPicks = snapshot.data!;
          return FutureBuilder<List<Division>>(
              future: divisions,
              builder: (BuildContext context,
                  AsyncSnapshot<List<Division>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  List<Division> divisions = snapshot.data!;
                  double screenWidth = MediaQuery.of(context).size.width;
                  return Scaffold(
                    appBar: AppBar(
                      title: Text("Player picks by: \"${widget.username}\""),
                    ),
                    body: SizedBox(
                      width:
                          screenWidth > 1000 ? screenWidth * 0.15 : screenWidth,
                      child: isOwner
                          ? ReorderableListView.builder(
                              itemCount: picks.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  key: Key(picks[index].slot.toString() +
                                      selectedDivision.toString() +
                                      index.toString()),
                                  leading: buildPlayerImage(
                                      picks[index].pdgaNumber, index),
                                  title: Text(picks[index].name),
                                  subtitle: TextField(
                                    controller: controllers[index],
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        picks[index].pdgaNumber =
                                            int.parse(value);
                                      });
                                    },
                                  ),
                                  trailing: screenWidth > 600
                                      ? null
                                      : ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_handle),
                                        ),
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
                                return ListTile(
                                  key: Key(picks[index].slot.toString() +
                                      selectedDivision.toString() +
                                      index.toString()),
                                  leading: buildPlayerImage(
                                      picks[index].pdgaNumber, index),
                                  title: Text(picks[index].name),
                                  subtitle:
                                      Text(picks[index].pdgaNumber.toString()),
                                );
                              },
                            ),
                    ),
                    floatingActionButton: isOwner
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              IgnorePointer(
                                ignoring: picks.length >= maxPicks,
                                child: FloatingActionButton(
                                  heroTag: "addPickButton",
                                  onPressed: () async {
                                    await _addNewPick();
                                    setState(() {
                                      picks.sort(
                                          (a, b) => a.slot.compareTo(b.slot));
                                    });
                                  },
                                  backgroundColor: picks.length < maxPicks
                                      ? null
                                      : Colors.black12,
                                  tooltip: 'Add New Pick',
                                  child: const Icon(Icons.add),
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      10), // Add some spacing between the buttons
                              FloatingActionButton(
                                heroTag: "savePickButton",
                                onPressed: () async {
                                  try {
                                    await ApiService().addPicks(
                                        widget.tournament.id,
                                        picks,
                                        selectedDivision);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Picks saved successfully'),
                                        backgroundColor:
                                            Colors.greenAccent, // success color
                                      ),
                                    );
                                  } catch (e) {
                                    if (e is DioException) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e.response?.data),
                                          backgroundColor:
                                              Colors.red, // error color
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
                    bottomNavigationBar: divisions.length >= 2
                        ? BottomNavigationBar(
                            items: divisions
                                .map((division) => BottomNavigationBarItem(
                                      icon: const Icon(Icons.sports_esports),
                                      label:
                                          division.toString().split(".").last,
                                      //backgroundColor:
                                    ))
                                .toList(),
                            currentIndex: divisions.indexOf(selectedDivision),
                            onTap: (index) {
                              setState(() {
                                selectedDivision = divisions[index];
                                loadPicks();
                              });
                            },
                          )
                        : null,
                  );
                }
              });
        }
      },
    );
  }

  Widget buildPlayerImage(int pdgaNumber, int index) {
    return CircleAvatar(
        backgroundImage: Image.network(
      '${ApiService().url}/player/$pdgaNumber/image', // replace with your actual URL
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        // This is called when the image fails to load
        return Text("${index + 1}:", style: const TextStyle(fontSize: 24));
      },
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        return const Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeCap: StrokeCap.round,
            ),
          ),
        );
      },
    ).image);
  }
}
