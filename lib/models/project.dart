import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ProjectType {
  film,
  broadcast,
  live,
  event,
  conference,
  video,
}

extension ProjectTypeExt on ProjectType {
  String get label {
    switch (this) {
      case ProjectType.film:       return '映画・ドラマ';
      case ProjectType.broadcast:  return '配信番組';
      case ProjectType.live:       return '音楽ライブ';
      case ProjectType.event:      return 'イベント';
      case ProjectType.conference: return 'カンファレンス';
      case ProjectType.video:      return '映像制作';
    }
  }

  String get titleLabel {
    switch (this) {
      case ProjectType.film:       return '作品タイトル';
      case ProjectType.broadcast:  return '番組名';
      case ProjectType.live:       return 'ライブ名・公演名';
      case ProjectType.event:      return 'イベント名';
      case ProjectType.conference: return 'イベント名';
      case ProjectType.video:      return '案件名';
    }
  }

  String get directorLabel {
    switch (this) {
      case ProjectType.film:       return '監督';
      case ProjectType.broadcast:  return 'プロデューサー';
      case ProjectType.live:       return '制作ディレクター';
      case ProjectType.event:      return 'イベントディレクター';
      case ProjectType.conference: return '事務局長・責任者';
      case ProjectType.video:      return 'ディレクター';
    }
  }

  String get castWord {
    switch (this) {
      case ProjectType.film:       return '演者';
      case ProjectType.broadcast:  return '出演者';
      case ProjectType.live:       return 'アーティスト';
      case ProjectType.event:      return '登壇者';
      case ProjectType.conference: return 'スピーカー';
      case ProjectType.video:      return '出演者';
    }
  }

  List<String> get castRanks {
    switch (this) {
      case ProjectType.film:
        return ['主演','助演','脇役','端役','エキストラ','声の出演'];
      case ProjectType.broadcast:
        return ['メインMC','サブMC','ゲスト','コメンテーター','レポーター','ナレーター'];
      case ProjectType.live:
        return ['メインアーティスト','オープニングアクト','バンドメンバー','ダンサー','特別ゲスト','MC・司会'];
      case ProjectType.event:
        return ['主催者代表','来賓・VIP','登壇者','出演者','MC・司会','ゲスト'];
      case ProjectType.conference:
        return ['基調講演','パネリスト','モデレーター','一般講演者','スポンサー登壇','ファシリテーター'];
      case ProjectType.video:
        return ['メイン出演','サブ出演','モデル','ナレーター','エキストラ','声の出演'];
    }
  }

  bool get hasRundown =>
      this == ProjectType.broadcast ||
      this == ProjectType.live ||
      this == ProjectType.event ||
      this == ProjectType.conference;

  bool get hasScenes =>
      this == ProjectType.film ||
      this == ProjectType.video;

  String get description {
    switch (this) {
      case ProjectType.film:
        return '脚本からシーンを切り出し、香盤表・衣装・絵コンテまで作ります。';
      case ProjectType.broadcast:
        return '生放送・収録配信に対応。放送日・リハ日・進行表を管理します。';
      case ProjectType.live:
        return 'コンサート・ライブの進行表・機材・会場を管理します。';
      case ProjectType.event:
        return '式典・展示会・発表会の進行と運営を管理します。';
      case ProjectType.conference:
        return 'セッション・スピーカー・タイムテーブルを管理します。';
      case ProjectType.video:
        return 'PV・CM・企業VPの撮影スケジュール・ロケ地・納品を管理します。';
    }
  }
}

class Project {
  String id;
  String title;
  String director;
  String typeKey;
  DateTime? eventDate;
  DateTime? rehearsalDate;
  DateTime? loadinDate;
  String venue;
  String formatType;
  String memo;
  Map<String, String> extraInfo;
  DateTime createdAt;
  DateTime updatedAt;

  Project({
    String? id,
    this.title = '',
    this.director = '',
    this.typeKey = 'film',
    this.eventDate,
    this.rehearsalDate,
    this.loadinDate,
    this.venue = '',
    this.formatType = '',
    this.memo = '',
    Map<String, String>? extraInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        extraInfo = extraInfo ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ProjectType get type {
    try {
      return ProjectType.values
          .firstWhere((e) => e.name == typeKey);
    } catch (_) {
      return ProjectType.film;
    }
  }

  Project copyWith({
    String? title,
    String? director,
    String? typeKey,
    DateTime? eventDate,
    DateTime? rehearsalDate,
    DateTime? loadinDate,
    String? venue,
    String? formatType,
    String? memo,
    Map<String, String>? extraInfo,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      director: director ?? this.director,
      typeKey: typeKey ?? this.typeKey,
      eventDate: eventDate ?? this.eventDate,
      rehearsalDate: rehearsalDate ?? this.rehearsalDate,
      loadinDate: loadinDate ?? this.loadinDate,
      venue: venue ?? this.venue,
      formatType: formatType ?? this.formatType,
      memo: memo ?? this.memo,
      extraInfo: extraInfo ?? Map.from(this.extraInfo),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class CastMember {
  String id;
  String projectId;
  String name;
  String role;
  String rank;
  String tel;
  String memo;
  Map<String, String> availability;

  CastMember({
    String? id,
    required this.projectId,
    this.name = '',
    this.role = '',
    this.rank = '',
    this.tel = '',
    this.memo = '',
    Map<String, String>? availability,
  })  : id = id ?? _uuid.v4(),
        availability = availability ?? {};
}

class CrewMember {
  String id;
  String projectId;
  String name;
  String company;
  String role;
  String tel;
  String ngDates;

  CrewMember({
    String? id,
    required this.projectId,
    this.name = '',
    this.company = '',
    this.role = '',
    this.tel = '',
    this.ngDates = '',
  }) : id = id ?? _uuid.v4();
}

class RundownItem {
  String id;
  String projectId;
  String kind;
  String name;
  int minutes;
  String owner;
  String memo;
  int sortKey;

  RundownItem({
    String? id,
    required this.projectId,
    this.kind = '本番',
    this.name = '',
    this.minutes = 0,
    this.owner = '',
    this.memo = '',
    this.sortKey = 0,
  }) : id = id ?? _uuid.v4();

  static const List<String> kinds = [
    '準備','リハ','転換','本番','予備','撤収'
  ];
}

class SceneItem {
  String id;
  String projectId;
  String no;
  String location;
  String io;
  String timeOfDay;
  String description;
  List<String> castIds;
  String props;
  String costume;
  int minutes;
  String date;
  String memo;
  int sortKey;

  SceneItem({
    String? id,
    required this.projectId,
    this.no = '',
    this.location = '',
    this.io = '屋内',
    this.timeOfDay = '昼',
    this.description = '',
    List<String>? castIds,
    this.props = '',
    this.costume = '',
    this.minutes = 0,
    this.date = '',
    this.memo = '',
    this.sortKey = 0,
  })  : id = id ?? _uuid.v4(),
        castIds = castIds ?? [];
}
// 配信番組の種別
enum BroadcastGenre {
  vtuber,
  gameShow,
  esports,
  interview,
  talk,
  collab,
}

extension BroadcastGenreExt on BroadcastGenre {
  String get label {
    switch (this) {
      case BroadcastGenre.vtuber:    return 'Vtuber配信';
      case BroadcastGenre.gameShow:  return 'TVゲーム番組';
      case BroadcastGenre.esports:   return 'eスポーツ大会';
      case BroadcastGenre.interview: return 'インタビュー番組';
      case BroadcastGenre.talk:      return 'トーク番組';
      case BroadcastGenre.collab:    return 'コラボ配信';
    }
  }

  // 番組種別ごとの専用項目
  List<String> get customFields {
    switch (this) {
      case BroadcastGenre.vtuber:
        return ['配信タイトル','使用アバター','BGM','ハッシュタグ'];
      case BroadcastGenre.gameShow:
        return ['ゲームタイトル','機種・プラットフォーム','プレイヤー名','実績・クリア条件'];
      case BroadcastGenre.esports:
        return ['大会名','ゲームタイトル','出場チーム','ルール・フォーマット'];
      case BroadcastGenre.interview:
        return ['ゲスト名','テーマ','質問リスト','NGワード'];
      case BroadcastGenre.talk:
        return ['テーマ','トークテーマ一覧','ゲスト','備考'];
      case BroadcastGenre.collab:
        return ['コラボ相手','プラットフォーム','役割分担','告知URL'];
    }
  }
}

// 配信コーナー
class BroadcastSegment {
  String id;
  String projectId;
  String kind;        // オープニング/メイン/コーナー/エンディング/CM/休憩
  String title;       // コーナー名
  int minutes;        // 尺（分）
  String gameTitle;   // ゲームタイトル（ゲーム系）
  String players;     // プレイヤー・出演者
  String telop;       // テロップ内容
  String commentMemo; // コメント・配信橋メモ
  String obsMemo;     // OBSシーン切り替えメモ
  String memo;
  int sortKey;

  BroadcastSegment({
    String? id,
    required this.projectId,
    this.kind = 'メイン',
    this.title = '',
    this.minutes = 0,
    this.gameTitle = '',
    this.players = '',
    this.telop = '',
    this.commentMemo = '',
    this.obsMemo = '',
    this.memo = '',
    this.sortKey = 0,
  }) : id = id ?? const Uuid().v4();

  static const List<String> kinds = [
    'オープニング','メイン','コーナー','ゲーム','インタビュー',
    'トーク','エンディング','CM・休憩','その他',
  ];
}

// 映画シーン（既存のSceneItemと同じだが明示的に再定義）
// ※ SceneItemはproject.dartに既にあるのでそのまま使う