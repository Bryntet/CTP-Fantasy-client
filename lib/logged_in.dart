import 'package:flutter/material.dart';
import 'package:rusty_chains/tournament.dart';
import 'api.dart';
import 'api-classes.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<FantasyTournament>>? _futureTournaments;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxPicksController = TextEditingController();
  bool _showDeclined = false;

  @override
  void initState() {
    super.initState();
    _futureTournaments = ApiService()
        .getFantasyTournaments(); // Use ApiService().getFantasyTournaments
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fantasy Tournaments'),
      ),
      body: Column(
        children: [
          CheckboxListTile(
            title: Text("Show Declined"),
            value: _showDeclined,
            onChanged: (bool? value) {
              setState(() {
                _showDeclined = value!;
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<FantasyTournament>>(
              future: _futureTournaments,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(child: Text('Error: :('));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var tournament = snapshot.data![index];
                      if (tournament.invitationStatus ==
                              InvitationStatus.Declined &&
                          !_showDeclined) {
                        return Container(); // Return an empty container for declined tournaments when _showDeclined is false
                      }
                      return ListTile(
                        tileColor: tournament.invitationStatus ==
                                InvitationStatus.Accepted
                            ? null
                            : tournament.invitationStatus ==
                                    InvitationStatus.Declined
                                ? Colors.red
                                : Colors.green,
                        title: Text(tournament.name),
                        trailing: tournament.userIsOwner
                            ? Icon(Icons.check_circle, color: Colors.yellow)
                            : null,
                        onTap: () {
                          if (tournament.invitationStatus !=
                              InvitationStatus.Declined) {
                            if (tournament.invitationStatus ==
                                InvitationStatus.Pending) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Invitation'),
                                    content: Text(
                                        'Do you want to accept the invitation?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Accept',
                                            style:
                                                TextStyle(color: Colors.green)),
                                        onPressed: () async {
                                          await ApiService().answerInvitation(
                                              tournament.id, true);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TournamentDetailsPage(
                                                      tournament: tournament),
                                            ),
                                          );
                                          setState(() {
                                            _futureTournaments = ApiService()
                                                .getFantasyTournaments();
                                          });
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Decline',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () async {
                                          await ApiService().answerInvitation(
                                              tournament.id, false);
                                          Navigator.pop(context);
                                          setState(() {
                                            _futureTournaments = ApiService()
                                                .getFantasyTournaments();
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TournamentDetailsPage(
                                      tournament: tournament),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Create Fantasy Tournament'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _maxPicksController,
                        decoration:
                            InputDecoration(labelText: 'Max Picks Per User'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Create'),
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true) {
                        var tournament = FantasyTournamentInput(
                          name: _nameController.text,
                          maxPicksPerUser:
                              int.tryParse(_maxPicksController.text),
                        );
                        ApiService().createFantasyTournament(
                            tournament); // Use ApiService().createFantasyTournament
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
