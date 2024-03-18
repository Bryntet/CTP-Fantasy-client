import 'dart:async'; // Import Timer

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:rustling_chains/user_picks.dart';

import 'api.dart';
import 'api_classes.dart';
import 'competition_scores.dart';

class TournamentDetailsPage extends StatefulWidget {
  final int id;

  const TournamentDetailsPage({super.key, required this.id});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  late Future<FantasyTournament> tournament;
  late Future<List<UserWithScore>> futureParticipants;
  late Future<ExchangeWindowInformation> myExchangeWindowInfo;
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
    myExchangeWindowInfo = ApiService().getUserId().then((userId) {
      return ApiService().getExchangeWindowStatus(widget.id, 1);
    });
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

  FutureBuilder<List<UserWithScore>> buildParticipantsFutureBuilder(
      FantasyTournament tournament) {
    return FutureBuilder<List<UserWithScore>>(
      future: futureParticipants,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<UserWithScore> participants = snapshot.data!;
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

  FutureBuilder<ExchangeWindowInformation>
      exchangeWindowInformationFutureBuilder() {
    return FutureBuilder<ExchangeWindowInformation>(
      future: myExchangeWindowInfo,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CountdownBanner(exchangeWindowInformation: snapshot.data!);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
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
          return Text("${snapshot.error}");
        }
        return const SizedBox.shrink(); // Or some placeholder if necessary
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
      List<UserWithScore> participants, FantasyTournament tournament) {
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(participants[index].user.name),
            subtitle: Text('Score: ${participants[index].score}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPicksPage(
                    tournament: tournament,
                    userId: participants[index].user.id,
                    username: participants[index].user.name,
                  ),
                  settings: RouteSettings(
                    name:
                        '/tournament/${tournament.id}/user/${participants[index].user.id}/picks',
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
          title: Text(
              "${competitions[index].name} - ${DateFormat('yyyy-MM-dd').format(competitions[index].startDate)}"),
          subtitle: Text('Level: ${competitions[index].level.name}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompetitionScoresPage(
                  fantasyTournamentId: widget.id,
                  competitionId: competitions[index].competitionId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildTournamentDetailsGrid(FantasyTournament tournament) {
    return Column(
      children: [
        // First, add the countdown banner if applicable

        Row(children: [
          Expanded(child: exchangeWindowInformationFutureBuilder())
        ]),

        // Then the rest of your tournament details grid
        Expanded(
          // Wrap the Row with Expanded
          child: Row(
            children: [
              Expanded(
                child: buildParticipantsFutureBuilder(tournament),
              ),
              Expanded(
                child: buildCompetitionsFutureBuilder(tournament),
              ),
            ],
          ),
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

class CountdownBanner extends StatefulWidget {
  final ExchangeWindowInformation exchangeWindowInformation;

  const CountdownBanner({Key? key, required this.exchangeWindowInformation})
      : super(key: key);

  @override
  _CountdownBannerState createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<CountdownBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (Timer t) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exchangeWindowInformation.status ==
        ExchangeWindowStatus.AllowedToExchange) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.green,
        child: const Text(
          'Your trading window is open',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (widget.exchangeWindowInformation.status ==
        ExchangeWindowStatus.AllowedToReorder) {
      final Duration remainingTime = widget
          .exchangeWindowInformation.windowOpensAt!
          .difference(DateTime.now());
      if (remainingTime.isNegative) {
        widget.exchangeWindowInformation.status =
            ExchangeWindowStatus.AllowedToExchange;
        return build(context); // Return an empty widget if the time has passed
      }
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.blue,
        child: Text(
          'Trading window opens in: ${formatDuration(remainingTime)}',
          style: const TextStyle(color: Colors.white),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red,
        child: const Text(
          'Ongoing competition, so all trades are closed',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String formatDuration(Duration duration) {
    // Helper function to format Duration to a readable string
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
