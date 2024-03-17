class FantasyTournamentInput {
  String name;
  int? maxPicksPerUser;
  List<Division> divisions;

  FantasyTournamentInput(
      {required this.name, this.maxPicksPerUser, required this.divisions});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['divisions'] =
        divisions.map((e) => e.toString().split('.').last).toList();
    if (maxPicksPerUser != null) {
      data['max_picks_per_user'] = maxPicksPerUser;
    }
    return data;
  }
}

enum InvitationStatus { pending, accepted, declined }

class FantasyTournament {
  final int id;
  final String name;
  final int ownerUserId;
  final InvitationStatus invitationStatus;

  FantasyTournament(
      {required this.id,
      required this.name,
      required this.ownerUserId,
      required this.invitationStatus});

  factory FantasyTournament.fromJson(Map<String, dynamic> json) {
    return FantasyTournament(
      id: json['id'],
      name: json['name'],
      ownerUserId: json["owner_id"],
      invitationStatus: InvitationStatus.values.firstWhere(
          (e) =>
              e.toString() ==
              'InvitationStatus.${json['invitation_status'].toString().toLowerCase()}',
          orElse: () => throw Exception('Invalid invitation status')),
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['username'] as String,
    );
  }
}

class Player {
  final int pdgaNumber;
  final String name;

  Player({required this.pdgaNumber, required this.name});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      pdgaNumber: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PlayerScoreOnCompetition {
  final Player player;
  final int score;
  final int placement;

  PlayerScoreOnCompetition(
      {required this.player, required this.score, required this.placement});

  factory PlayerScoreOnCompetition.fromJson(Map<String, dynamic> json) {
    return PlayerScoreOnCompetition(
      player: Player.fromJson(json['player'] as Map<String, dynamic>),
      score: json['score'] as int,
      placement: json['placement'] as int,
    );
  }
}

class UserCompetitionScore {
  final User user;
  final int totalScore;
  final List<PlayerScoreOnCompetition> scores;

  UserCompetitionScore({
    required this.user,
    required this.totalScore,
    required this.scores,
  });

  factory UserCompetitionScore.fromJson(Map<String, dynamic> json) {
    return UserCompetitionScore(
      user: User.fromJson(json['user']),
      totalScore: json['total_score'] as int,
      scores: (json['competition_scores'] as List<dynamic>)
          .map((item) => PlayerScoreOnCompetition.fromJson(item))
          .toList(),
    );
  }
}

class UserWithScore {
  final User user;
  final int score;

  UserWithScore({required this.user, required this.score});

  factory UserWithScore.fromJson(Map<String, dynamic> json) {
    return UserWithScore(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      score: json['score'] as int,
    );
  }
}

class Pick {
  int slot;
  int pdgaNumber;
  String name;

  Pick({
    required this.slot,
    required this.pdgaNumber,
    required this.name,
  });

  factory Pick.fromJson(Map<String, dynamic> json) {
    return Pick(
        slot: json['slot'] as int,
        pdgaNumber: json['pdga_number'] as int,
        name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'pdga_number': pdgaNumber,
      'name': name,
      //'avatar': avatar
    };
  }

  static Pick empty(int slot) {
    return Pick(slot: slot, pdgaNumber: slot, name: ' ' * slot);
  }
}

class Picks {
  List<Pick> picks;
  final bool owner;
  final int fantasyTournamentId;

  Picks({
    required this.picks,
    required this.owner,
    required this.fantasyTournamentId,
  });

  factory Picks.fromJson(Map<String, dynamic> json) {
    return Picks(
      picks: (json['picks'] as List<dynamic>)
          .map((item) => Pick.fromJson(item as Map<String, dynamic>))
          .toList(),
      owner: json['owner'] as bool,
      fantasyTournamentId: json['fantasy_tournament_id'] as int,
    );
  }
}

enum Division { MPO, FPO }

extension DivisionExtension on Division {
  static Division fromJson(String key) {
    switch (key) {
      case 'MPO':
        return Division.MPO;
      case 'FPO':
        return Division.FPO;
      default:
        throw Exception('Unknown division');
    }
  }
}

enum CompetitionLevel { major, playOff, elitePlus, elite, silver }

extension CompetitionLevelExtension on CompetitionLevel {
  String get name {
    switch (this) {
      case CompetitionLevel.major:
        return 'Major';
      case CompetitionLevel.playOff:
        return 'Playoff';
      case CompetitionLevel.elitePlus:
        return 'ElitePlus';
      case CompetitionLevel.elite:
        return 'Elite';
      case CompetitionLevel.silver:
        return 'Silver';
      default:
        return 'unknown';
    }
  }
}

class AddCompetition {
  CompetitionLevel level;
  int competitionId;

  AddCompetition({required this.level, required this.competitionId});

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'competition_id': competitionId,
    };
  }
}

class Competition {
  CompetitionLevel level;
  int competitionId;
  String name;

  Competition(
      {required this.level, required this.competitionId, required this.name});
  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      level: CompetitionLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => throw Exception('Invalid competition level'),
      ),
      competitionId: json['competition_id'] as int,
      name: json['name'] as String,
    );
  }
}
