import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rusty_chains/user_picks.dart';

import 'api.dart';
import 'api_classes.dart';

class TournamentDetailsPage extends StatefulWidget {
  final int id;

  const TournamentDetailsPage({super.key, required this.id});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  late Future<FantasyTournament> tournament;
  late Future<List<Participant>> futureParticipants;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _addCompetitionController = TextEditingController(); // Add this line
  Future? addCompetitionFuture; // Add this line
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    tournament = ApiService().getFantasyTournament(widget.id);
    futureParticipants =
        ApiService().getFantasyTournamentParticipants(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return buildTournamentFutureBuilder();
  }

  FutureBuilder<FantasyTournament> buildTournamentFutureBuilder() {
    return FutureBuilder<FantasyTournament>(
      future: tournament,
      builder: (context, snapshot) {
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
          print(snapshot.error);
          return Text("${snapshot.error}");
        } else {
          FantasyTournament tournament = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text("Fantasy Tournament: \"${tournament.name}\""),
            ),
            body: buildTournamentDetailsGrid(tournament),
            floatingActionButton: buildOwnerActionButton(tournament),
          );
        }
      },
    );
  }

  FutureBuilder<List<Participant>> buildParticipantsFutureBuilder(
      FantasyTournament tournament) {
    return FutureBuilder<List<Participant>>(
      future: futureParticipants,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Participant> participants = snapshot.data!;
          participants.sort((a, b) => b.score.compareTo(a.score));
          return buildParticipantsListView(participants, tournament);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
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
    );
  }

  FutureBuilder<List<Competition>> buildCompetitionsFutureBuilder(
      FantasyTournament tournament) {
    return FutureBuilder<List<Competition>>(
      future: ApiService().getCompetitionsFromFantasyTournament(tournament.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Competition> competitions = snapshot.data!;
          return buildCompetitionsListView(competitions);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
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
    );
  }

  ListView buildParticipantsListView(
      List<Participant> participants, FantasyTournament tournament) {
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(participants[index].name),
            subtitle: Text('Score: ${participants[index].score}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPicksPage(
                    tournament: tournament,
                    userId: participants[index].id,
                    username: participants[index].name,
                  ),
                  settings: RouteSettings(
                    name:
                        '/tournament/${tournament.id}/user/${participants[index].id}/picks',
                  ),
                ),
              );
            });
      },
    );
  }

  ListView buildCompetitionsListView(List<Competition> competitions) {
    return ListView.builder(
      itemCount: competitions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(competitions[index].name),
          subtitle: Text('Level: ${competitions[index].level.name}'),
        );
      },
    );
  }

  Widget buildTournamentDetailsGrid(FantasyTournament tournament) {
    return Row(
      children: [
        Expanded(
          child: buildParticipantsFutureBuilder(tournament),
        ),
        Expanded(
          // Wrap the competition list for proper spacing
          child: buildCompetitionsFutureBuilder(tournament),
        ),
      ],
    );
  }

  Row buildOwnerActionButton(FantasyTournament tournament) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        FutureBuilder<int>(
            future: ApiService().getUserId(),
            builder: (context, snapshot) {
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
              }
              if (snapshot.hasError) {
                print(snapshot.error);
                return const Text('Error: :(');
              }
              if (snapshot.data == tournament.ownerUserId) {
                return FloatingActionButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return buildInviteUserDialog();
                      },
                    );
                  },
                  tooltip: 'Invite User',
                  child: const Icon(Icons.send),
                );
              }
              return Container();
            }),
        const SizedBox(width: 10), // Add space between the buttons
        FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return buildAddCompetitionDialog();
              },
            );
          },
          tooltip: 'Add Competition',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  AlertDialog buildInviteUserDialog() {
    return AlertDialog(
      title: const Text('Invite User'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _userIdController,
          decoration: const InputDecoration(labelText: 'Username'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the username';
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Invite'),
          onPressed: () async {
            if (_formKey.currentState?.validate() == true) {
              try {
                FantasyTournament tournamentData = await tournament;
                await ApiService()
                    .inviteUser(tournamentData.id, _userIdController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User invited successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context); // Close the dialog
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
            }
          },
        ),
      ],
    );
  }

  AlertDialog buildAddCompetitionDialog() {
    // Define a variable to hold the selected level
    CompetitionLevel? selectedLevel;

    return AlertDialog(
      title: const Text('Add Competition'),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _addCompetitionController,
                  decoration:
                      const InputDecoration(labelText: 'Competition ID'),
                  validator: (value) {
                    if (value == null) {
                      return 'Please enter the competition ID';
                    } else if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  name: 'Competition ID',
                ),
                FormBuilderDropdown<CompetitionLevel>(
                  name: 'level',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    hintText: 'Select Level',
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a level';
                    }
                    return null;
                  },
                  items: CompetitionLevel.values
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level.name),
                          ))
                      .toList(),
                  onChanged: (CompetitionLevel? newValue) {
                    setState(() {
                      selectedLevel = newValue;
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Add'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              int fantasyTournamentId = widget.id;
              int compId = int.parse(_addCompetitionController.text);
              CompetitionLevel level = selectedLevel!;

              // Create an instance of AddCompetition
              AddCompetition comp = AddCompetition(
                competitionId: compId,
                level: level,
              );
              try {
                // Assign the API call to the Future variable and await it
                setState(() {
                  addCompetitionFuture =
                      ApiService().addCompetitionToFantasyTournament(
                    fantasyTournamentId,
                    comp,
                  );
                });
                buildAddCompetitionFutureBuilder();

                // If the API call was successful, close the dialog
                Navigator.pop(context);
              } catch (e) {
                if (e is DioException) {
                  _errorMessage = e.response?.data;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.response?.data}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                // If an error occurred, show a SnackBar with the error message
              }
            }
          },
        ),
      ],
    );
  }

  FutureBuilder buildAddCompetitionFutureBuilder() {
    return FutureBuilder(
      future: addCompetitionFuture, // Use the Future variable here
      builder: (BuildContext context, AsyncSnapshot snapshot) {
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
          if (snapshot.error is DioException) {
            _errorMessage = (snapshot.error as DioException).response?.data;
          }
        } else if (snapshot.connectionState == ConnectionState.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Competition added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          return Text('Result: ${snapshot.data}');
        }
        // Return an empty Container when the Future is not yet called
        return Container();
      },
    );
  }
}
