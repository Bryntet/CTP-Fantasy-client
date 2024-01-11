import 'package:flutter/material.dart';
import 'api-classes.dart';
import 'api.dart';

class UserPicksPage extends StatefulWidget {
  final FantasyTournament tournament;
  final int userId;
  final String username;

  const UserPicksPage(
      {super.key, required this.tournament, required this.userId, required this.username});

  @override
  _UserPicksPageState createState() => _UserPicksPageState();
}

class _UserPicksPageState extends State<UserPicksPage> {
  late Future<SimpleFantasyPicks> futurePicks;

  @override
  void initState() {
    super.initState();
    futurePicks =
        ApiService().getUserPicks(widget.tournament.id, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Player picks by: \"${widget.username}\""),
      ),
      body: FutureBuilder<SimpleFantasyPicks>(
        future: futurePicks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            SimpleFantasyPicks picks = snapshot.data!;
            picks.picks.sort((a, b) => a.slot.compareTo(b.slot));
            return ListView.builder(
              itemCount: picks.picks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(picks.picks[index].name),
                  subtitle: Text('Slot: ${picks.picks[index].slot}'),
                  onTap: picks.owner
                      ? () {
                          // Navigate to a new page where the user can change the pick
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePickPage(pick: picks.picks[index])));
                        }
                      : null,
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
