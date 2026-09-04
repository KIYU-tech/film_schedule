import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/project.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<CastMember> _cast = [];
  List<CrewMember> _crew = [];
  List<RundownItem> _rundown = [];
  List<SceneItem> _scenes = [];
  List<BroadcastSegment> _segments = [];
  List<LocationItem> _locations = [];
  List<EquipmentItem> _equipment = [];
  List<BudgetItem> _budget = [];
  List<GanttTask> _gantt = [];
  Project? _currentProject;

  // Supabaseクライアントのショートカット
  // get → 読み取り専用のプロパティ（変数のように使えるメソッド）
  SupabaseClient get _sb => Supabase.instance.client;
  String? get _userId => _sb.auth.currentUser?.id;
  bool get isLoggedIn => _userId != null;

  Project? get currentProject => _currentProject;
  List<Project> get projects =>
      [..._projects]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<CastMember> get castMembers => _cast
      .where((c) => c.projectId == _currentProject?.id).toList();
  List<CrewMember> get crewMembers => _crew
      .where((c) => c.projectId == _currentProject?.id).toList();
  List<RundownItem> get rundownItems => _rundown
      .where((r) => r.projectId == _currentProject?.id).toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  List<SceneItem> get sceneItems => _scenes
      .where((s) => s.projectId == _currentProject?.id).toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  List<BroadcastSegment> get segments => _segments
      .where((s) => s.projectId == _currentProject?.id).toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  List<LocationItem> get locations => _locations
      .where((l) => l.projectId == _currentProject?.id).toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  List<EquipmentItem> get equipmentItems => _equipment
      .where((e) => e.projectId == _currentProject?.id).toList();
  List<BudgetItem> get budgetItems => _budget
      .where((b) => b.projectId == _currentProject?.id).toList();
  List<GanttTask> get ganttTasks => _gantt
      .where((g) => g.projectId == _currentProject?.id).toList();

  Future<void> init() async {
    await _loadLocal();
    if (isLoggedIn) {
      // ログイン済みならSupabaseから読み込む
      await syncFromSupabase();
    }
    if (_projects.isNotEmpty) _currentProject = _projects.first;
    notifyListeners();
  }

  // ===== Supabaseとの同期 =====

  // Supabaseから全データを読み込む
  Future<void> syncFromSupabase() async {
    if (!isLoggedIn) return;
    try {
      // Supabaseのテーブルからデータを取得
      // .select() → SELECT * に相当
      final pj = await _sb.from('projects')
          .select().eq('user_id', _userId!);
      _projects = (pj as List).map((e) => Project(
        id: e['id'], title: e['title'] ?? '',
        director: e['director'] ?? '',
        typeKey: e['type_key'] ?? 'film',
        venue: e['venue'] ?? '',
        formatType: e['format_type'] ?? '',
        memo: e['memo'] ?? '',
        extraInfo: Map<String, String>.from(
          (e['extra_info'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), v.toString()))),
        createdAt: DateTime.parse(e['created_at']),
        updatedAt: DateTime.parse(e['updated_at']),
      )).toList();

      final ca = await _sb.from('cast_members').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _cast = (ca as List).map((e) => CastMember(
        id: e['id'], projectId: e['project_id'],
        name: e['name'] ?? '', role: e['role'] ?? '',
        rank: e['rank'] ?? '', tel: e['tel'] ?? '',
        memo: e['memo'] ?? '',
        availability: Map<String, String>.from(
          (e['availability'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), v.toString()))),
      )).toList();

      final cr = await _sb.from('crew_members').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _crew = (cr as List).map((e) => CrewMember(
        id: e['id'], projectId: e['project_id'],
        name: e['name'] ?? '', company: e['company'] ?? '',
        role: e['role'] ?? '', tel: e['tel'] ?? '',
        ngDates: e['ng_dates'] ?? '',
      )).toList();

      final rd = await _sb.from('rundown_items').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _rundown = (rd as List).map((e) => RundownItem(
        id: e['id'], projectId: e['project_id'],
        kind: e['kind'] ?? '本番', name: e['name'] ?? '',
        minutes: e['minutes'] ?? 0, owner: e['owner'] ?? '',
        memo: e['memo'] ?? '', sortKey: e['sort_key'] ?? 0,
      )).toList();

      final sc = await _sb.from('scene_items').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _scenes = (sc as List).map((e) => SceneItem(
        id: e['id'], projectId: e['project_id'],
        no: e['no'] ?? '', location: e['location'] ?? '',
        io: e['io'] ?? '屋内', timeOfDay: e['time_of_day'] ?? '昼',
        description: e['description'] ?? '',
        castIds: List<String>.from(e['cast_ids'] ?? []),
        props: e['props'] ?? '', costume: e['costume'] ?? '',
        minutes: e['minutes'] ?? 0, date: e['date'] ?? '',
        memo: e['memo'] ?? '', sortKey: e['sort_key'] ?? 0,
      )).toList();

      final sg = await _sb.from('broadcast_segments').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _segments = (sg as List).map((e) => BroadcastSegment(
        id: e['id'], projectId: e['project_id'],
        kind: e['kind'] ?? 'メイン', title: e['title'] ?? '',
        minutes: e['minutes'] ?? 0,
        gameTitle: e['game_title'] ?? '',
        players: e['players'] ?? '', telop: e['telop'] ?? '',
        commentMemo: e['comment_memo'] ?? '',
        obsMemo: e['obs_memo'] ?? '',
        memo: e['memo'] ?? '', sortKey: e['sort_key'] ?? 0,
      )).toList();

      final lo = await _sb.from('location_items').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _locations = (lo as List).map((e) => LocationItem(
        id: e['id'], projectId: e['project_id'],
        name: e['name'] ?? '', address: e['address'] ?? '',
        access: e['access'] ?? '', hours: e['hours'] ?? '',
        contact: e['contact'] ?? '', memo: e['memo'] ?? '',
        indoor: e['indoor'],
        permitRequired: e['permit_required'] ?? false,
        hasParking: e['has_parking'] ?? false,
        sortKey: e['sort_key'] ?? 0,
      )).toList();

      final eq = await _sb.from('equipment_items').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _equipment = (eq as List).map((e) => EquipmentItem(
        id: e['id'], projectId: e['project_id'],
        category: e['category'] ?? 'その他',
        name: e['name'] ?? '', qty: e['qty'] ?? 1,
        owner: e['owner'] ?? '', memo: e['memo'] ?? '',
        isDone: e['is_done'] ?? false,
      )).toList();

      final bu = await _sb.from('budget_items').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _budget = (bu as List).map((e) => BudgetItem(
        id: e['id'], projectId: e['project_id'],
        category: e['category'] ?? 'その他',
        name: e['name'] ?? '', budget: e['budget'] ?? 0,
        actual: e['actual'] ?? 0, memo: e['memo'] ?? '',
      )).toList();

      final ga = await _sb.from('gantt_tasks').select()
          .inFilter('project_id', _projects.map((p) => p.id).toList());
      _gantt = (ga as List).map((e) => GanttTask(
        id: e['id'], projectId: e['project_id'],
        category: e['category'] ?? '準備',
        name: e['name'] ?? '',
        startDate: DateTime.parse(e['start_date']),
        endDate: DateTime.parse(e['end_date']),
        owner: e['owner'] ?? '',
        progress: e['progress'] ?? 0,
        memo: e['memo'] ?? '',
      )).toList();

      // ローカルにも保存しておく（オフライン対応）
      await _saveLocal();
      notifyListeners();
    } catch (e) {
      // Supabase取得に失敗してもローカルデータで続行
      debugPrint('Supabase sync error: $e');
    }
  }

  // ===== ローカル保存（SharedPreferences）=====
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('projects', jsonEncode(_projects.map((p) => {
      'id': p.id, 'title': p.title, 'director': p.director,
      'typeKey': p.typeKey, 'venue': p.venue,
      'formatType': p.formatType, 'memo': p.memo,
      'extraInfo': p.extraInfo,
      'createdAt': p.createdAt.toIso8601String(),
      'updatedAt': p.updatedAt.toIso8601String(),
    }).toList()));
    prefs.setString('cast', jsonEncode(_cast.map((c) => {
      'id': c.id, 'projectId': c.projectId, 'name': c.name,
      'role': c.role, 'rank': c.rank, 'tel': c.tel,
      'memo': c.memo, 'availability': c.availability,
    }).toList()));
    prefs.setString('crew', jsonEncode(_crew.map((c) => {
      'id': c.id, 'projectId': c.projectId, 'name': c.name,
      'company': c.company, 'role': c.role, 'tel': c.tel,
      'ngDates': c.ngDates,
    }).toList()));
    prefs.setString('rundown', jsonEncode(_rundown.map((r) => {
      'id': r.id, 'projectId': r.projectId, 'kind': r.kind,
      'name': r.name, 'minutes': r.minutes, 'owner': r.owner,
      'memo': r.memo, 'sortKey': r.sortKey,
    }).toList()));
    prefs.setString('scenes', jsonEncode(_scenes.map((s) => {
      'id': s.id, 'projectId': s.projectId, 'no': s.no,
      'location': s.location, 'io': s.io,
      'timeOfDay': s.timeOfDay, 'description': s.description,
      'castIds': s.castIds, 'props': s.props,
      'costume': s.costume, 'minutes': s.minutes,
      'date': s.date, 'memo': s.memo, 'sortKey': s.sortKey,
    }).toList()));
    prefs.setString('segments', jsonEncode(_segments.map((s) => {
      'id': s.id, 'projectId': s.projectId, 'kind': s.kind,
      'title': s.title, 'minutes': s.minutes,
      'gameTitle': s.gameTitle, 'players': s.players,
      'telop': s.telop, 'commentMemo': s.commentMemo,
      'obsMemo': s.obsMemo, 'memo': s.memo, 'sortKey': s.sortKey,
    }).toList()));
    prefs.setString('locations', jsonEncode(_locations.map((l) => {
      'id': l.id, 'projectId': l.projectId, 'name': l.name,
      'address': l.address, 'access': l.access,
      'hours': l.hours, 'contact': l.contact, 'memo': l.memo,
      'indoor': l.indoor, 'permitRequired': l.permitRequired,
      'hasParking': l.hasParking, 'sortKey': l.sortKey,
    }).toList()));
    prefs.setString('equipment', jsonEncode(_equipment.map((e) => {
      'id': e.id, 'projectId': e.projectId,
      'category': e.category, 'name': e.name,
      'qty': e.qty, 'owner': e.owner,
      'memo': e.memo, 'isDone': e.isDone,
    }).toList()));
    prefs.setString('budget', jsonEncode(_budget.map((b) => {
      'id': b.id, 'projectId': b.projectId,
      'category': b.category, 'name': b.name,
      'budget': b.budget, 'actual': b.actual, 'memo': b.memo,
    }).toList()));
    prefs.setString('gantt', jsonEncode(_gantt.map((g) => {
      'id': g.id, 'projectId': g.projectId,
      'category': g.category, 'name': g.name,
      'startDate': g.startDate.toIso8601String(),
      'endDate': g.endDate.toIso8601String(),
      'owner': g.owner, 'progress': g.progress, 'memo': g.memo,
    }).toList()));
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final pj = prefs.getString('projects');
    if (pj != null) {
      _projects = (jsonDecode(pj) as List).map((e) => Project(
        id: e['id'], title: e['title'], director: e['director'],
        typeKey: e['typeKey'], venue: e['venue'] ?? '',
        formatType: e['formatType'] ?? '', memo: e['memo'] ?? '',
        extraInfo: Map<String, String>.from(e['extraInfo'] ?? {}),
        createdAt: DateTime.parse(e['createdAt']),
        updatedAt: DateTime.parse(e['updatedAt']),
      )).toList();
    }
    final ca = prefs.getString('cast');
    if (ca != null) {
      _cast = (jsonDecode(ca) as List).map((e) => CastMember(
        id: e['id'], projectId: e['projectId'], name: e['name'],
        role: e['role'], rank: e['rank'], tel: e['tel'],
        memo: e['memo'],
        availability: Map<String, String>.from(e['availability'] ?? {}),
      )).toList();
    }
    final cr = prefs.getString('crew');
    if (cr != null) {
      _crew = (jsonDecode(cr) as List).map((e) => CrewMember(
        id: e['id'], projectId: e['projectId'], name: e['name'],
        company: e['company'], role: e['role'], tel: e['tel'],
        ngDates: e['ngDates'] ?? '',
      )).toList();
    }
    final rd = prefs.getString('rundown');
    if (rd != null) {
      _rundown = (jsonDecode(rd) as List).map((e) => RundownItem(
        id: e['id'], projectId: e['projectId'], kind: e['kind'],
        name: e['name'], minutes: e['minutes'], owner: e['owner'],
        memo: e['memo'], sortKey: e['sortKey'],
      )).toList();
    }
    final sc = prefs.getString('scenes');
    if (sc != null) {
      _scenes = (jsonDecode(sc) as List).map((e) => SceneItem(
        id: e['id'], projectId: e['projectId'], no: e['no'],
        location: e['location'], io: e['io'],
        timeOfDay: e['timeOfDay'], description: e['description'],
        castIds: List<String>.from(e['castIds'] ?? []),
        props: e['props'], costume: e['costume'] ?? '',
        minutes: e['minutes'], date: e['date'],
        memo: e['memo'], sortKey: e['sortKey'],
      )).toList();
    }
    final sg = prefs.getString('segments');
    if (sg != null) {
      _segments = (jsonDecode(sg) as List).map((e) => BroadcastSegment(
        id: e['id'], projectId: e['projectId'],
        kind: e['kind'] ?? 'メイン', title: e['title'] ?? '',
        minutes: e['minutes'] ?? 0, gameTitle: e['gameTitle'] ?? '',
        players: e['players'] ?? '', telop: e['telop'] ?? '',
        commentMemo: e['commentMemo'] ?? '',
        obsMemo: e['obsMemo'] ?? '', memo: e['memo'] ?? '',
        sortKey: e['sortKey'] ?? 0,
      )).toList();
    }
    final lo = prefs.getString('locations');
    if (lo != null) {
      _locations = (jsonDecode(lo) as List).map((e) => LocationItem(
        id: e['id'], projectId: e['projectId'],
        name: e['name'] ?? '', address: e['address'] ?? '',
        access: e['access'] ?? '', hours: e['hours'] ?? '',
        contact: e['contact'] ?? '', memo: e['memo'] ?? '',
        indoor: e['indoor'],
        permitRequired: e['permitRequired'] ?? false,
        hasParking: e['hasParking'] ?? false,
        sortKey: e['sortKey'] ?? 0,
      )).toList();
    }
    final eq = prefs.getString('equipment');
    if (eq != null) {
      _equipment = (jsonDecode(eq) as List).map((e) => EquipmentItem(
        id: e['id'], projectId: e['projectId'],
        category: e['category'] ?? 'その他',
        name: e['name'] ?? '', qty: e['qty'] ?? 1,
        owner: e['owner'] ?? '', memo: e['memo'] ?? '',
        isDone: e['isDone'] ?? false,
      )).toList();
    }
    final bu = prefs.getString('budget');
    if (bu != null) {
      _budget = (jsonDecode(bu) as List).map((e) => BudgetItem(
        id: e['id'], projectId: e['projectId'],
        category: e['category'] ?? 'その他',
        name: e['name'] ?? '', budget: e['budget'] ?? 0,
        actual: e['actual'] ?? 0, memo: e['memo'] ?? '',
      )).toList();
    }
    final ga = prefs.getString('gantt');
    if (ga != null) {
      _gantt = (jsonDecode(ga) as List).map((e) => GanttTask(
        id: e['id'], projectId: e['projectId'],
        category: e['category'] ?? '準備',
        name: e['name'] ?? '',
        startDate: DateTime.parse(e['startDate']),
        endDate: DateTime.parse(e['endDate']),
        owner: e['owner'] ?? '',
        progress: e['progress'] ?? 0,
        memo: e['memo'] ?? '',
      )).toList();
    }
  }

  // ===== ローカル＋Supabase両方に保存するヘルパー =====
  // upsert → INSERT or UPDATE（あれば更新、なければ追加）
  Future<void> _save() async {
    await _saveLocal();
    notifyListeners();
  }

  Future<void> _upsertToSb(String table, Map<String, dynamic> data) async {
    if (!isLoggedIn) return;
    try {
      await _sb.from(table).upsert(data);
    } catch (e) {
      debugPrint('Supabase upsert error ($table): $e');
    }
  }

  Future<void> _deleteFromSb(String table, String id) async {
    if (!isLoggedIn) return;
    try {
      await _sb.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase delete error ($table): $e');
    }
  }

  // ===== プロジェクト操作 =====
  Future<Project> createProject({
    required String title, required ProjectType type,
  }) async {
    final project = Project(title: title, typeKey: type.name);
    _projects.add(project);
    _currentProject = project;
    await _save();
    await _upsertToSb('projects', {
      'id': project.id, 'user_id': _userId,
      'title': project.title, 'director': project.director,
      'type_key': project.typeKey, 'venue': project.venue,
      'format_type': project.formatType, 'memo': project.memo,
      'extra_info': project.extraInfo,
      'created_at': project.createdAt.toIso8601String(),
      'updated_at': project.updatedAt.toIso8601String(),
    });
    return project;
  }

  Future<void> openProject(String id) async {
    _currentProject = _projects.firstWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    project.updatedAt = DateTime.now();
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i >= 0) _projects[i] = project;
    if (_currentProject?.id == project.id) _currentProject = project;
    await _save();
    await _upsertToSb('projects', {
      'id': project.id, 'user_id': _userId,
      'title': project.title, 'director': project.director,
      'type_key': project.typeKey, 'venue': project.venue,
      'format_type': project.formatType, 'memo': project.memo,
      'extra_info': project.extraInfo,
      'updated_at': project.updatedAt.toIso8601String(),
    });
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    _cast.removeWhere((c) => c.projectId == id);
    _crew.removeWhere((c) => c.projectId == id);
    _rundown.removeWhere((r) => r.projectId == id);
    _scenes.removeWhere((s) => s.projectId == id);
    _segments.removeWhere((s) => s.projectId == id);
    _locations.removeWhere((l) => l.projectId == id);
    _equipment.removeWhere((e) => e.projectId == id);
    _budget.removeWhere((b) => b.projectId == id);
    _gantt.removeWhere((g) => g.projectId == id);
    if (_currentProject?.id == id) {
      _currentProject = _projects.isNotEmpty ? _projects.first : null;
    }
    await _save();
    await _deleteFromSb('projects', id);
  }

  // ===== 演者操作 =====
  Future<void> addCastMember(CastMember m) async {
    _cast.add(m); await _save();
    await _upsertToSb('cast_members', {
      'id': m.id, 'project_id': m.projectId, 'name': m.name,
      'role': m.role, 'rank': m.rank, 'tel': m.tel,
      'memo': m.memo, 'availability': m.availability,
    });
  }
  Future<void> updateCastMember(CastMember m) async {
    final i = _cast.indexWhere((c) => c.id == m.id);
    if (i >= 0) _cast[i] = m; await _save();
    await _upsertToSb('cast_members', {
      'id': m.id, 'project_id': m.projectId, 'name': m.name,
      'role': m.role, 'rank': m.rank, 'tel': m.tel,
      'memo': m.memo, 'availability': m.availability,
    });
  }
  Future<void> deleteCastMember(String id) async {
    _cast.removeWhere((c) => c.id == id);
    await _save(); await _deleteFromSb('cast_members', id);
  }
  Future<void> updateAvailability(
      String castId, String date, String value) async {
    final i = _cast.indexWhere((c) => c.id == castId);
    if (i < 0) return;
    _cast[i].availability[date] = value;
    await _save();
    await _upsertToSb('cast_members', {
      'id': _cast[i].id, 'project_id': _cast[i].projectId,
      'name': _cast[i].name, 'role': _cast[i].role,
      'rank': _cast[i].rank, 'tel': _cast[i].tel,
      'memo': _cast[i].memo, 'availability': _cast[i].availability,
    });
  }

  // ===== スタッフ操作 =====
  Future<void> addCrewMember(CrewMember m) async {
    _crew.add(m); await _save();
    await _upsertToSb('crew_members', {
      'id': m.id, 'project_id': m.projectId, 'name': m.name,
      'company': m.company, 'role': m.role, 'tel': m.tel,
      'ng_dates': m.ngDates,
    });
  }
  Future<void> updateCrewMember(CrewMember m) async {
    final i = _crew.indexWhere((c) => c.id == m.id);
    if (i >= 0) _crew[i] = m; await _save();
    await _upsertToSb('crew_members', {
      'id': m.id, 'project_id': m.projectId, 'name': m.name,
      'company': m.company, 'role': m.role, 'tel': m.tel,
      'ng_dates': m.ngDates,
    });
  }
  Future<void> deleteCrewMember(String id) async {
    _crew.removeWhere((c) => c.id == id);
    await _save(); await _deleteFromSb('crew_members', id);
  }

  // ===== 進行表操作 =====
  Future<void> addRundownItem(RundownItem r) async {
    r.sortKey = _rundown.where((x) => x.projectId == r.projectId).length;
    _rundown.add(r); await _save();
    await _upsertToSb('rundown_items', {
      'id': r.id, 'project_id': r.projectId, 'kind': r.kind,
      'name': r.name, 'minutes': r.minutes, 'owner': r.owner,
      'memo': r.memo, 'sort_key': r.sortKey,
    });
  }
  Future<void> updateRundownItem(RundownItem r) async {
    final i = _rundown.indexWhere((x) => x.id == r.id);
    if (i >= 0) _rundown[i] = r; await _save();
    await _upsertToSb('rundown_items', {
      'id': r.id, 'project_id': r.projectId, 'kind': r.kind,
      'name': r.name, 'minutes': r.minutes, 'owner': r.owner,
      'memo': r.memo, 'sort_key': r.sortKey,
    });
  }
  Future<void> deleteRundownItem(String id) async {
    _rundown.removeWhere((r) => r.id == id);
    await _save(); await _deleteFromSb('rundown_items', id);
  }
  Future<void> reorderRundown(int oldIndex, int newIndex) async {
    final items = rundownItems;
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    for (var i = 0; i < items.length; i++) {
      final idx = _rundown.indexWhere((r) => r.id == items[i].id);
      if (idx >= 0) _rundown[idx].sortKey = i;
    }
    await _save();
    for (final r in rundownItems) {
      await _upsertToSb('rundown_items', {
        'id': r.id, 'project_id': r.projectId, 'kind': r.kind,
        'name': r.name, 'minutes': r.minutes, 'owner': r.owner,
        'memo': r.memo, 'sort_key': r.sortKey,
      });
    }
  }

  // ===== シーン操作 =====
  Future<void> addSceneItem(SceneItem s) async {
    s.sortKey = _scenes.where((x) => x.projectId == s.projectId).length;
    _scenes.add(s); await _save();
    await _upsertToSb('scene_items', {
      'id': s.id, 'project_id': s.projectId, 'no': s.no,
      'location': s.location, 'io': s.io,
      'time_of_day': s.timeOfDay, 'description': s.description,
      'cast_ids': s.castIds, 'props': s.props, 'costume': s.costume,
      'minutes': s.minutes, 'date': s.date,
      'memo': s.memo, 'sort_key': s.sortKey,
    });
  }
  Future<void> updateSceneItem(SceneItem s) async {
    final i = _scenes.indexWhere((x) => x.id == s.id);
    if (i >= 0) _scenes[i] = s; await _save();
    await _upsertToSb('scene_items', {
      'id': s.id, 'project_id': s.projectId, 'no': s.no,
      'location': s.location, 'io': s.io,
      'time_of_day': s.timeOfDay, 'description': s.description,
      'cast_ids': s.castIds, 'props': s.props, 'costume': s.costume,
      'minutes': s.minutes, 'date': s.date,
      'memo': s.memo, 'sort_key': s.sortKey,
    });
  }
  Future<void> deleteSceneItem(String id) async {
    _scenes.removeWhere((s) => s.id == id);
    await _save(); await _deleteFromSb('scene_items', id);
  }

  // ===== 配信コーナー操作 =====
  Future<void> addSegment(BroadcastSegment s) async {
    s.sortKey = _segments.where((x) => x.projectId == s.projectId).length;
    _segments.add(s); await _save();
    await _upsertToSb('broadcast_segments', {
      'id': s.id, 'project_id': s.projectId, 'kind': s.kind,
      'title': s.title, 'minutes': s.minutes,
      'game_title': s.gameTitle, 'players': s.players,
      'telop': s.telop, 'comment_memo': s.commentMemo,
      'obs_memo': s.obsMemo, 'memo': s.memo, 'sort_key': s.sortKey,
    });
  }
  Future<void> updateSegment(BroadcastSegment s) async {
    final i = _segments.indexWhere((x) => x.id == s.id);
    if (i >= 0) _segments[i] = s; await _save();
    await _upsertToSb('broadcast_segments', {
      'id': s.id, 'project_id': s.projectId, 'kind': s.kind,
      'title': s.title, 'minutes': s.minutes,
      'game_title': s.gameTitle, 'players': s.players,
      'telop': s.telop, 'comment_memo': s.commentMemo,
      'obs_memo': s.obsMemo, 'memo': s.memo, 'sort_key': s.sortKey,
    });
  }
  Future<void> deleteSegment(String id) async {
    _segments.removeWhere((s) => s.id == id);
    await _save(); await _deleteFromSb('broadcast_segments', id);
  }
  Future<void> reorderSegments(int oldIndex, int newIndex) async {
    final items = segments;
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    for (var i = 0; i < items.length; i++) {
      final idx = _segments.indexWhere((s) => s.id == items[i].id);
      if (idx >= 0) _segments[idx].sortKey = i;
    }
    await _save();
  }

  // ===== ロケ地操作 =====
  Future<void> addLocation(LocationItem l) async {
    l.sortKey = _locations.where((x) => x.projectId == l.projectId).length;
    _locations.add(l); await _save();
    await _upsertToSb('location_items', {
      'id': l.id, 'project_id': l.projectId, 'name': l.name,
      'address': l.address, 'access': l.access,
      'hours': l.hours, 'contact': l.contact, 'memo': l.memo,
      'indoor': l.indoor, 'permit_required': l.permitRequired,
      'has_parking': l.hasParking, 'sort_key': l.sortKey,
    });
  }
  Future<void> updateLocation(LocationItem l) async {
    final i = _locations.indexWhere((x) => x.id == l.id);
    if (i >= 0) _locations[i] = l; await _save();
    await _upsertToSb('location_items', {
      'id': l.id, 'project_id': l.projectId, 'name': l.name,
      'address': l.address, 'access': l.access,
      'hours': l.hours, 'contact': l.contact, 'memo': l.memo,
      'indoor': l.indoor, 'permit_required': l.permitRequired,
      'has_parking': l.hasParking, 'sort_key': l.sortKey,
    });
  }
  Future<void> deleteLocation(String id) async {
    _locations.removeWhere((l) => l.id == id);
    await _save(); await _deleteFromSb('location_items', id);
  }

  // ===== 機材操作 =====
  Future<void> addEquipment(EquipmentItem e) async {
    _equipment.add(e); await _save();
    await _upsertToSb('equipment_items', {
      'id': e.id, 'project_id': e.projectId,
      'category': e.category, 'name': e.name,
      'qty': e.qty, 'owner': e.owner,
      'memo': e.memo, 'is_done': e.isDone,
    });
  }
  Future<void> updateEquipment(EquipmentItem e) async {
    final i = _equipment.indexWhere((x) => x.id == e.id);
    if (i >= 0) _equipment[i] = e; await _save();
    await _upsertToSb('equipment_items', {
      'id': e.id, 'project_id': e.projectId,
      'category': e.category, 'name': e.name,
      'qty': e.qty, 'owner': e.owner,
      'memo': e.memo, 'is_done': e.isDone,
    });
  }
  Future<void> deleteEquipment(String id) async {
    _equipment.removeWhere((e) => e.id == id);
    await _save(); await _deleteFromSb('equipment_items', id);
  }

  // ===== 予算操作 =====
  Future<void> addBudgetItem(BudgetItem b) async {
    _budget.add(b); await _save();
    await _upsertToSb('budget_items', {
      'id': b.id, 'project_id': b.projectId,
      'category': b.category, 'name': b.name,
      'budget': b.budget, 'actual': b.actual, 'memo': b.memo,
    });
  }
  Future<void> updateBudgetItem(BudgetItem b) async {
    final i = _budget.indexWhere((x) => x.id == b.id);
    if (i >= 0) _budget[i] = b; await _save();
    await _upsertToSb('budget_items', {
      'id': b.id, 'project_id': b.projectId,
      'category': b.category, 'name': b.name,
      'budget': b.budget, 'actual': b.actual, 'memo': b.memo,
    });
  }
  Future<void> deleteBudgetItem(String id) async {
    _budget.removeWhere((b) => b.id == id);
    await _save(); await _deleteFromSb('budget_items', id);
  }

  // ===== ガント操作 =====
  Future<void> addGanttTask(GanttTask g) async {
    _gantt.add(g); await _save();
    await _upsertToSb('gantt_tasks', {
      'id': g.id, 'project_id': g.projectId,
      'category': g.category, 'name': g.name,
      'start_date': g.startDate.toIso8601String().substring(0, 10),
      'end_date': g.endDate.toIso8601String().substring(0, 10),
      'owner': g.owner, 'progress': g.progress, 'memo': g.memo,
    });
  }
  Future<void> updateGanttTask(GanttTask g) async {
    final i = _gantt.indexWhere((x) => x.id == g.id);
    if (i >= 0) _gantt[i] = g; await _save();
    await _upsertToSb('gantt_tasks', {
      'id': g.id, 'project_id': g.projectId,
      'category': g.category, 'name': g.name,
      'start_date': g.startDate.toIso8601String().substring(0, 10),
      'end_date': g.endDate.toIso8601String().substring(0, 10),
      'owner': g.owner, 'progress': g.progress, 'memo': g.memo,
    });
  }
  Future<void> deleteGanttTask(String id) async {
    _gantt.removeWhere((g) => g.id == id);
    await _save(); await _deleteFromSb('gantt_tasks', id);
  }

  // ===== 時刻計算 =====
  List<Map<String, dynamic>> calcRundownTimes(String startTime) {
    final parts = startTime.split(':');
    int total = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return rundownItems.map((r) {
      final start = total; total += r.minutes;
      return {'item': r, 'startLabel': _toHM(start), 'endLabel': _toHM(total)};
    }).toList();
  }
  List<Map<String, dynamic>> calcSegmentTimes(String startTime) {
    final parts = startTime.split(':');
    int total = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return segments.map((s) {
      final start = total; total += s.minutes;
      return {'segment': s, 'startLabel': _toHM(start), 'endLabel': _toHM(total)};
    }).toList();
  }
  String _toHM(int min) {
    final h = (min ~/ 60) % 24;
    final m = min % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
