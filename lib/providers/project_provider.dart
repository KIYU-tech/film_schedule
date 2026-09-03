import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/project.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<CastMember> _cast = [];
  List<CrewMember> _crew = [];
  List<RundownItem> _rundown = [];
  List<SceneItem> _scenes = [];
  List<BroadcastSegment> _segments = [];
  Project? _currentProject;

  Project? get currentProject => _currentProject;
  List<Project> get projects =>
      [..._projects]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<CastMember> get castMembers => _cast
      .where((c) => c.projectId == _currentProject?.id)
      .toList();

  List<CrewMember> get crewMembers => _crew
      .where((c) => c.projectId == _currentProject?.id)
      .toList();

  List<RundownItem> get rundownItems => _rundown
      .where((r) => r.projectId == _currentProject?.id)
      .toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  List<SceneItem> get sceneItems => _scenes
      .where((s) => s.projectId == _currentProject?.id)
      .toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  List<BroadcastSegment> get segments => _segments
      .where((s) => s.projectId == _currentProject?.id)
      .toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  Future<void> init() async {
    await _load();
    if (_projects.isNotEmpty) {
      _currentProject = _projects.first;
    }
    notifyListeners();
  }

  // ===== 保存・読み込み =====
  Future<void> _save() async {
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
      'minutes': s.minutes, 'date': s.date,
      'memo': s.memo, 'sortKey': s.sortKey,
    }).toList()));
    prefs.setString('segments', jsonEncode(_segments.map((s) => {
      'id': s.id, 'projectId': s.projectId, 'kind': s.kind,
      'title': s.title, 'minutes': s.minutes,
      'gameTitle': s.gameTitle, 'players': s.players,
      'telop': s.telop, 'commentMemo': s.commentMemo,
      'obsMemo': s.obsMemo, 'memo': s.memo,
      'sortKey': s.sortKey,
    }).toList()));
  }

  Future<void> _load() async {
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
        props: e['props'], minutes: e['minutes'],
        date: e['date'], memo: e['memo'], sortKey: e['sortKey'],
      )).toList();
    }
    final sg = prefs.getString('segments');
    if (sg != null) {
      _segments = (jsonDecode(sg) as List).map((e) =>
        BroadcastSegment(
          id: e['id'], projectId: e['projectId'],
          kind: e['kind'] ?? 'メイン',
          title: e['title'] ?? '',
          minutes: e['minutes'] ?? 0,
          gameTitle: e['gameTitle'] ?? '',
          players: e['players'] ?? '',
          telop: e['telop'] ?? '',
          commentMemo: e['commentMemo'] ?? '',
          obsMemo: e['obsMemo'] ?? '',
          memo: e['memo'] ?? '',
          sortKey: e['sortKey'] ?? 0,
        )).toList();
    }
  }

  // ===== プロジェクト操作 =====
  Future<Project> createProject({
    required String title,
    required ProjectType type,
  }) async {
    final project = Project(title: title, typeKey: type.name);
    _projects.add(project);
    _currentProject = project;
    await _save();
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    _cast.removeWhere((c) => c.projectId == id);
    _crew.removeWhere((c) => c.projectId == id);
    _rundown.removeWhere((r) => r.projectId == id);
    _scenes.removeWhere((s) => s.projectId == id);
    _segments.removeWhere((s) => s.projectId == id);
    if (_currentProject?.id == id) {
      _currentProject = _projects.isNotEmpty ? _projects.first : null;
    }
    await _save();
    notifyListeners();
  }

  // ===== 演者操作 =====
  Future<void> addCastMember(CastMember m) async {
    _cast.add(m); await _save(); notifyListeners();
  }
  Future<void> updateCastMember(CastMember m) async {
    final i = _cast.indexWhere((c) => c.id == m.id);
    if (i >= 0) _cast[i] = m; await _save(); notifyListeners();
  }
  Future<void> deleteCastMember(String id) async {
    _cast.removeWhere((c) => c.id == id);
    await _save(); notifyListeners();
  }

  // ===== スタッフ操作 =====
  Future<void> addCrewMember(CrewMember m) async {
    _crew.add(m); await _save(); notifyListeners();
  }
  Future<void> updateCrewMember(CrewMember m) async {
    final i = _crew.indexWhere((c) => c.id == m.id);
    if (i >= 0) _crew[i] = m; await _save(); notifyListeners();
  }
  Future<void> deleteCrewMember(String id) async {
    _crew.removeWhere((c) => c.id == id);
    await _save(); notifyListeners();
  }

  // ===== 進行表操作 =====
  Future<void> addRundownItem(RundownItem r) async {
    r.sortKey = _rundown
        .where((x) => x.projectId == r.projectId).length;
    _rundown.add(r); await _save(); notifyListeners();
  }
  Future<void> updateRundownItem(RundownItem r) async {
    final i = _rundown.indexWhere((x) => x.id == r.id);
    if (i >= 0) _rundown[i] = r; await _save(); notifyListeners();
  }
  Future<void> deleteRundownItem(String id) async {
    _rundown.removeWhere((r) => r.id == id);
    await _save(); notifyListeners();
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
    await _save(); notifyListeners();
  }

  // ===== シーン操作 =====
  Future<void> addSceneItem(SceneItem s) async {
    s.sortKey = _scenes
        .where((x) => x.projectId == s.projectId).length;
    _scenes.add(s); await _save(); notifyListeners();
  }
  Future<void> updateSceneItem(SceneItem s) async {
    final i = _scenes.indexWhere((x) => x.id == s.id);
    if (i >= 0) _scenes[i] = s; await _save(); notifyListeners();
  }
  Future<void> deleteSceneItem(String id) async {
    _scenes.removeWhere((s) => s.id == id);
    await _save(); notifyListeners();
  }

  // ===== 配信コーナー操作 =====
  Future<void> addSegment(BroadcastSegment s) async {
    s.sortKey = _segments
        .where((x) => x.projectId == s.projectId).length;
    _segments.add(s); await _save(); notifyListeners();
  }
  Future<void> updateSegment(BroadcastSegment s) async {
    final i = _segments.indexWhere((x) => x.id == s.id);
    if (i >= 0) _segments[i] = s; await _save(); notifyListeners();
  }
  Future<void> deleteSegment(String id) async {
    _segments.removeWhere((s) => s.id == id);
    await _save(); notifyListeners();
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
    await _save(); notifyListeners();
  }

  // ===== 時刻計算 =====
  List<Map<String, dynamic>> calcRundownTimes(String startTime) {
    final parts = startTime.split(':');
    int total = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return rundownItems.map((r) {
      final start = total;
      total += r.minutes;
      return {
        'item': r,
        'startLabel': _toHM(start),
        'endLabel': _toHM(total),
      };
    }).toList();
  }

  List<Map<String, dynamic>> calcSegmentTimes(String startTime) {
    final parts = startTime.split(':');
    int total = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return segments.map((s) {
      final start = total;
      total += s.minutes;
      return {
        'segment': s,
        'startLabel': _toHM(start),
        'endLabel': _toHM(total),
      };
    }).toList();
  }

  String _toHM(int min) {
    final h = (min ~/ 60) % 24;
    final m = min % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}