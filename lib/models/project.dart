import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ===== 制作の種類 =====
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

// ===== プロジェクト =====
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
      return ProjectType.values.firstWhere((e) => e.name == typeKey);
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

// ===== 演者 =====
class CastMember {
  String id;
  String projectId;
  String name;
  String role;
  String rank;
  String tel;
  String memo;
  Map<String, String> availability;
  // 写真はbase64文字列として保持する（軽量な写真のみ想定）
  String? photoBase64;

  CastMember({
    String? id,
    required this.projectId,
    this.name = '',
    this.role = '',
    this.rank = '',
    this.tel = '',
    this.memo = '',
    Map<String, String>? availability,
    this.photoBase64,
  })  : id = id ?? _uuid.v4(),
        availability = availability ?? {};
}

// ===== スタッフ =====
class CrewMember {
  String id;
  String projectId;
  String name;
  String company;
  String role;
  String tel;
  String ngDates;
  // 担当カテゴリ別の色（16進数カラーコード文字列で保持）
  String deptColor;
  // 担当カテゴリ
  String dept;

  CrewMember({
    String? id,
    required this.projectId,
    this.name = '',
    this.company = '',
    this.role = '',
    this.tel = '',
    this.ngDates = '',
    this.deptColor = '#6FBA2C',
    this.dept = '',
  }) : id = id ?? _uuid.v4();

  // よく使う担当カテゴリと色のマップ
  static const Map<String, String> deptColors = {
    '監督・演出':  '#E5484D',
    '制作':      '#6FBA2C',
    '撮影':      '#3B9EFF',
    '照明':      '#F5A623',
    '音声':      '#BF5AF2',
    '美術':      '#FF6B6B',
    '衣装':      '#FF9F0A',
    'メイク':    '#FF375F',
    '編集・VFX': '#32D74B',
    '音楽・MA':  '#64D2FF',
    'その他':    '#98989D',
  };
}

// ===== 進行表アイテム =====
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

// ===== 香盤表シーン =====
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

// ===== 配信番組種別 =====
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

// ===== 配信コーナー =====
class BroadcastSegment {
  String id;
  String projectId;
  String kind;
  String title;
  int minutes;
  String gameTitle;
  String players;
  String telop;
  String commentMemo;
  String obsMemo;
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
  }) : id = id ?? _uuid.v4();

  static const List<String> kinds = [
    'オープニング','メイン','コーナー','ゲーム','インタビュー',
    'トーク','エンディング','CM・休憩','その他',
  ];
}

// ===== ロケ地 =====
class LocationItem {
  String id;
  String projectId;
  String name;
  String address;
  String access;
  String hours;
  String contact;
  String memo;
  bool? indoor;
  bool permitRequired;
  bool hasParking;
  int sortKey;

  LocationItem({
    String? id,
    required this.projectId,
    this.name = '',
    this.address = '',
    this.access = '',
    this.hours = '',
    this.contact = '',
    this.memo = '',
    this.indoor,
    this.permitRequired = false,
    this.hasParking = false,
    this.sortKey = 0,
  }) : id = id ?? _uuid.v4();
}

// ===== 機材 =====
class EquipmentItem {
  String id;
  String projectId;
  String category;
  String name;
  int qty;
  String owner;
  String memo;
  bool isDone;
  // 貸出管理フィールド
  String loanFrom;    // 貸出元（会社・氏名）
  String loanDate;    // 貸出日
  String returnDate;  // 返却予定日
  bool isReturned;    // 返却済み

  EquipmentItem({
    String? id,
    required this.projectId,
    this.category = 'その他',
    this.name = '',
    this.qty = 1,
    this.owner = '',
    this.memo = '',
    this.isDone = false,
    this.loanFrom = '',
    this.loanDate = '',
    this.returnDate = '',
    this.isReturned = false,
  }) : id = id ?? _uuid.v4();
}

// ===== 予算 =====
class BudgetItem {
  String id;
  String projectId;
  String category;
  String name;
  int budget;
  int actual;
  String memo;

  BudgetItem({
    String? id,
    required this.projectId,
    this.category = 'その他',
    this.name = '',
    this.budget = 0,
    this.actual = 0,
    this.memo = '',
  }) : id = id ?? _uuid.v4();
}

// ===== ガントチャート =====
class GanttTask {
  String id;
  String projectId;
  String category;
  String name;
  DateTime startDate;
  DateTime endDate;
  String owner;
  int progress; // 0-100
  String memo;

  GanttTask({
    String? id,
    required this.projectId,
    this.category = '準備',
    this.name = '',
    required this.startDate,
    required this.endDate,
    this.owner = '',
    this.progress = 0,
    this.memo = '',
  }) : id = id ?? _uuid.v4();
}

// ===== 役の詳細（映画向け） =====
class CharacterDetail {
  String id;
  String projectId;
  String name;        // 役名
  String castId;      // 紐づく演者ID
  String age;         // 年齢設定
  String personality; // 性格・背景
  String costumeMemo; // 衣装メモ
  String makeup;      // メイクアップメモ
  String notes;       // 特記事項
  String sceneNos;    // 登場シーン番号（カンマ区切り）

  CharacterDetail({
    String? id,
    required this.projectId,
    this.name = '',
    this.castId = '',
    this.age = '',
    this.personality = '',
    this.costumeMemo = '',
    this.makeup = '',
    this.notes = '',
    this.sceneNos = '',
  }) : id = id ?? _uuid.v4();
}

// ===== 交通費 =====
class TransportCost {
  String id;
  String projectId;
  String personName;   // 対象者（演者・スタッフ名）
  String personType;   // 'cast' or 'crew'
  String date;         // 日付
  String from;         // 出発地
  String to;           // 目的地
  String method;       // 交通手段
  int amount;          // 金額
  bool isPaid;         // 精算済み
  String memo;

  TransportCost({
    String? id,
    required this.projectId,
    this.personName = '',
    this.personType = 'cast',
    this.date = '',
    this.from = '',
    this.to = '',
    this.method = '',
    this.amount = 0,
    this.isPaid = false,
    this.memo = '',
  }) : id = id ?? _uuid.v4();
}

// ===== 制作物リスト =====
enum ProductionStatus { notStarted, inProgress, review, done }

extension ProductionStatusExt on ProductionStatus {
  String get label {
    switch (this) {
      case ProductionStatus.notStarted: return '未着手';
      case ProductionStatus.inProgress: return '進行中';
      case ProductionStatus.review:     return '確認待ち';
      case ProductionStatus.done:       return '完了';
    }
  }
  // 色はindex番号で管理（Colorはモデル層に入れない）
  int get colorIndex {
    switch (this) {
      case ProductionStatus.notStarted: return 0; // grey
      case ProductionStatus.inProgress: return 1; // blue
      case ProductionStatus.review:     return 2; // orange
      case ProductionStatus.done:       return 3; // green
    }
  }
}

class ProductionItem {
  String id;
  String projectId;
  String category;    // 映像/音声/グラフィック/書類/その他
  String name;        // 制作物名
  String owner;       // 担当
  String deadline;    // 期日
  String status;      // ProductionStatus.name
  String memo;
  int sortKey;

  ProductionItem({
    String? id,
    required this.projectId,
    this.category = 'その他',
    this.name = '',
    this.owner = '',
    this.deadline = '',
    this.status = 'notStarted',
    this.memo = '',
    this.sortKey = 0,
  }) : id = id ?? _uuid.v4();

  ProductionStatus get statusEnum {
    try {
      return ProductionStatus.values.firstWhere((e) => e.name == status);
    } catch (_) {
      return ProductionStatus.notStarted;
    }
  }

  static const List<String> categories = [
    '映像', '音声', 'グラフィック', '書類', '衣装・小道具', 'その他'
  ];
}

// ===== ライブ・コンサート 出番表 =====
class LiveAct {
  String id;
  String projectId;
  String actNo;       // 出番番号
  String artist;      // アーティスト名
  String actType;     // 本番/転換/リハ/開演前/終演後
  int minutes;        // 尺（分）
  int changeMinutes;  // 転換時間（分）
  String setlist;     // セットリスト（改行区切り）
  String paMemo;      // PA要望
  String lightMemo;   // 照明要望
  String memo;        // 備考
  int sortKey;

  LiveAct({
    String? id,
    required this.projectId,
    this.actNo = '',
    this.artist = '',
    this.actType = '本番',
    this.minutes = 0,
    this.changeMinutes = 0,
    this.setlist = '',
    this.paMemo = '',
    this.lightMemo = '',
    this.memo = '',
    this.sortKey = 0,
  }) : id = id ?? _uuid.v4();

  static const List<String> actTypes = ['本番','転換','リハ','開演前/SE','終演後'];
}

// ===== イベント・式典 コーナー表 =====
class EventCorner {
  String id;
  String projectId;
  String time;        // 開始時刻
  int minutes;        // 尺（分）
  String name;        // コーナー名
  String presenter;   // 登壇者・司会
  String cue;         // きっかけ（照明・音響）
  String owner;       // 担当
  String memo;        // 備考
  int sortKey;

  EventCorner({
    String? id,
    required this.projectId,
    this.time = '',
    this.minutes = 0,
    this.name = '',
    this.presenter = '',
    this.cue = '',
    this.owner = '',
    this.memo = '',
    this.sortKey = 0,
  }) : id = id ?? _uuid.v4();
}

// ===== カンファレンス セッション表 =====
class ConferenceSession {
  String id;
  String projectId;
  String time;        // 開始時刻
  int minutes;        // 尺（分）
  String sessionName; // セッション名
  String speakers;    // 登壇者（改行区切り）
  String hall;        // 会場・ホール名
  String format;      // 形式（講演/パネル/ワークショップ）
  bool hasInterpreter; // 通訳あり
  bool hasMaterial;   // 資料あり
  String memo;
  int sortKey;

  ConferenceSession({
    String? id,
    required this.projectId,
    this.time = '',
    this.minutes = 0,
    this.sessionName = '',
    this.speakers = '',
    this.hall = '',
    this.format = '講演',
    this.hasInterpreter = false,
    this.hasMaterial = false,
    this.memo = '',
    this.sortKey = 0,
  }) : id = id ?? _uuid.v4();

  static const List<String> formats = ['講演','パネルディスカッション','ワークショップ','展示・デモ','懇親会'];
}

// ===== 脚本・台本ファイル =====
class ScriptFile {
  String id;
  String projectId;
  String title;       // タイトル・バージョン名
  String fileType;    // 'text' or 'pdf'
  String content;     // テキストの場合の本文、PDFの場合はbase64
  String memo;
  DateTime updatedAt;

  ScriptFile({
    String? id,
    required this.projectId,
    this.title = '',
    this.fileType = 'text',
    this.content = '',
    this.memo = '',
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       updatedAt = updatedAt ?? DateTime.now();
}
