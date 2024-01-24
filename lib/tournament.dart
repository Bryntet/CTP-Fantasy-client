import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
            body: buildParticipantsFutureBuilder(tournament),
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
    return AlertDialog(
      title: const Text('Add Competition'),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          String errorMessage = '';
          return Column(
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
              TextFormField(
                controller: _addCompetitionController,
                decoration: const InputDecoration(labelText: 'Competition ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the competition ID';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
            ],
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Add'),
          onPressed: () {
            if (_addCompetitionController.text.isNotEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FutureBuilder<String?>(
                    future: ApiService().addCompetitionToFantasyTournament(
                        widget.id,
                        int.parse(_addCompetitionController.value.text)),
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
                        if (snapshot.error is DioException) {
                          var res = (snapshot.error as DioException)
                              .response
                              ?.statusMessage;
                          return AlertDialog(
                            title: Text(
                              'ERROR: ',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: res!.split('\n').length * 16.0),
                            ),
                            content: Text(
                              'Error: ${res ?? 'Unknown error'}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the inner dialog
                                },
                              ),
                            ],
                          );
                        } else {
                          return AlertDialog(
                            title: Text(
                              'ERROR: ',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      _errorMessage.split('\n').length * 16.0),
                            ),
                            content: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        }
                      } else if (snapshot.hasData) {
                        Navigator.of(context).pop();
                        return Container();
                      }
                      return Container();
                    },
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
}
