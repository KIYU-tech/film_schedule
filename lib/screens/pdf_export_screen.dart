// pdf と printing パッケージを使う
// pdf → PDFファイルを作るパッケージ
// printing → 作ったPDFを印刷・プレビュー・保存するパッケージ
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';           // PdfColor など色の定義
import 'package:pdf/widgets.dart' as pw; // PDF用ウィジェット（pw.Text など）
import 'package:printing/printing.dart'; // 印刷・プレビュー機能
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

// PDF書き出し画面
// StatelessWidget → 状態を持たないシンプルな画面
class PdfExportScreen extends StatelessWidget {
  const PdfExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch → ProjectProviderの変更を監視して自動更新
    final provider = context.watch<ProjectProvider>();
    final project = provider.currentProject;
    if (project == null) return const SizedBox.shrink();

    // 書き出せるドキュメントの一覧
    // (タイトル, 説明, アイコン, 書き出し関数) のタプル
    final exports = _buildExportList(project.type);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ヘッダーカード
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                      color: glightGreen, size: 24),
                    const SizedBox(width: 10),
                    const Text('PDF書き出し',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '書き出したいドキュメントを選んでください。\nブラウザのPDF印刷ダイアログが開きます。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.6)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 書き出しボタン一覧
        // ...exports.map → exports リストを各ウィジェットに変換
        ...exports.map((e) => _ExportCard(
          title: e.$1,
          description: e.$2,
          icon: e.$3,
          onExport: () => _export(context, provider, e.$4),
        )),
      ],
    );
  }

  // プロジェクト種別に応じて書き出し可能なドキュメントを返す
  List<(String, String, IconData, String)> _buildExportList(
      ProjectType type) {
    // 全種別共通
    final common = [
      ('スタッフ・キャスト連絡先', '全員の連絡先一覧',
        Icons.people_outline, 'contact'),
      ('予算表', '予算・実績一覧',
        Icons.account_balance_wallet_outlined, 'budget'),
    ];

    // 種別ごとの固有ドキュメント
    switch (type) {
      case ProjectType.film:
      case ProjectType.video:
        return [
          ('香盤表', 'シーン・出演者・ロケ地一覧',
            Icons.grid_view_outlined, 'scenes'),
          ('ロケ地表', 'ロケ地の詳細一覧',
            Icons.location_on_outlined, 'locations'),
          ...common,
        ];
      default:
        return [
          ('進行表', 'タイムテーブル・進行一覧',
            Icons.list_alt_outlined, 'rundown'),
          ('機材リスト', '機材・技術構成一覧',
            Icons.videocam_outlined, 'equipment'),
          ...common,
        ];
    }
  }

  // PDF生成→プレビュー表示
  Future<void> _export(BuildContext context,
      ProjectProvider provider, String type) async {
    // PDF ドキュメントを作成
    // pw.Document() → PDFファイルの入れ物を作る
    final pdf = pw.Document();

    final project = provider.currentProject!;

    // type によって内容を切り替える
    switch (type) {
      case 'scenes':
        _addScenesPage(pdf, project, provider.sceneItems,
          provider.castMembers);
        break;
      case 'rundown':
        _addRundownPage(pdf, project,
          provider.calcRundownTimes('09:00'));
        break;
      case 'contact':
        _addContactPage(pdf, project,
          provider.castMembers, provider.crewMembers);
        break;
      case 'budget':
        _addBudgetPage(pdf, project, provider.budgetItems);
        break;
      case 'equipment':
        _addEquipmentPage(pdf, project, provider.equipmentItems);
        break;
      case 'locations':
        _addLocationsPage(pdf, project, provider.locations);
        break;
    }

    // Printing.layoutPdf → PDFプレビュー画面を開く
    // onLayout → PDFのバイト列を返す関数
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // ===== 各PDF生成関数 =====

  // 共通ヘッダーを作る関数
  // pw.Column → PDFの縦並びレイアウト
  pw.Widget _header(Project project, String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(project.title.isEmpty ? '（タイトル未設定）' : project.title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('6FBA2C'))), // Glightグリーン
            pw.Text(title,
              style: pw.TextStyle(fontSize: 12,
                color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColor.fromHex('6FBA2C'), thickness: 1.5),
        pw.SizedBox(height: 12),
      ],
    );
  }

  // 香盤表PDF
  void _addScenesPage(pw.Document pdf, Project project,
      List<SceneItem> scenes, List<CastMember> cast) {
    // pdf.addPage → PDFにページを追加
    pdf.addPage(pw.MultiPage( // MultiPage → 内容が多い時に自動改ページ
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(project, '香盤表'),
        // pw.Table → PDFの表
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),  // No.
            1: const pw.FixedColumnWidth(80),  // 場所
            2: const pw.FixedColumnWidth(30),  // 内外
            3: const pw.FixedColumnWidth(30),  // 時間帯
            4: const pw.FlexColumnWidth(),      // 内容
            5: const pw.FlexColumnWidth(),      // 出演者
          },
          children: [
            // ヘッダー行
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: ['No.','場所','内/外','時間帯','内容','出演者']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10))))
                .toList(),
            ),
            // データ行
            ...scenes.map((s) {
              final castNames = cast
                .where((c) => s.castIds.contains(c.id))
                .map((c) => c.name).join('・');
              return pw.TableRow(children: [
                s.no, s.location, s.io, s.timeOfDay,
                s.description, castNames,
              ].map((v) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))))
              .toList());
            }),
          ],
        ),
      ],
    ));
  }

  // 進行表PDF
  void _addRundownPage(pw.Document pdf, Project project,
      List<Map<String, dynamic>> timed) {
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(project, '進行表'),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(50),
            1: const pw.FixedColumnWidth(50),
            2: const pw.FixedColumnWidth(40),
            3: const pw.FixedColumnWidth(40),
            4: const pw.FlexColumnWidth(),
            5: const pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: ['開始','終了','区分','尺(分)','内容','備考']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))))
                .toList(),
            ),
            ...timed.map((t) {
              final item = t['item'] as RundownItem;
              return pw.TableRow(children: [
                t['startLabel'] as String,
                t['endLabel'] as String,
                item.kind,
                '${item.minutes}',
                item.name,
                item.memo,
              ].map((v) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))))
              .toList());
            }),
          ],
        ),
      ],
    ));
  }

  // 連絡先PDF
  void _addContactPage(pw.Document pdf, Project project,
      List<CastMember> cast, List<CrewMember> crew) {
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(project, '連絡先一覧'),
        pw.Text('■ 出演者',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: ['氏名','役名','区分','連絡先']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))))
                .toList(),
            ),
            ...cast.map((c) => pw.TableRow(children: [
              c.name, c.role, c.rank, c.tel,
            ].map((v) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))))
            .toList())),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('■ スタッフ',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: ['氏名','担当','会社','連絡先']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))))
                .toList(),
            ),
            ...crew.map((c) => pw.TableRow(children: [
              c.name, c.role, c.company, c.tel,
            ].map((v) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))))
            .toList())),
          ],
        ),
      ],
    ));
  }

  // 予算PDF
  void _addBudgetPage(pw.Document pdf, Project project,
      List<BudgetItem> items) {
    final totalBudget = items.fold(0, (a, b) => a + b.budget);
    final totalActual = items.fold(0, (a, b) => a + b.actual);

    String fmt(int v) {
      if (v == 0) return '—';
      final s = v.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return '¥$buf';
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(project, '予算表'),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(70),
            3: const pw.FixedColumnWidth(70),
            4: const pw.FixedColumnWidth(70),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: ['カテゴリ','項目','予算','実績','差額']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))))
                .toList(),
            ),
            ...items.map((b) {
              final diff = b.budget - b.actual;
              return pw.TableRow(children: [
                b.category, b.name,
                fmt(b.budget), fmt(b.actual), fmt(diff),
              ].map((v) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))))
              .toList());
            }),
            // 合計行
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: [
                '合計', '',
                fmt(totalBudget), fmt(totalActual),
                fmt(totalBudget - totalActual),
              ].map((v) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(v,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10))))
              .toList(),
            ),
          ],
        ),
      ],
    ));
  }

  // 機材リストPDF
  void _addEquipmentPage(pw.Document pdf, Project project,
      List<EquipmentItem> items) {
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(project, '機材リスト'),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(30),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(30),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F5D5')),
              children: ['区分','機材名','数','担当','確認']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))))
                .toList(),
            ),
            ...items.map((e) => pw.TableRow(children: [
              e.category, e.name,
              '${e.qty}', e.owner,
              e.isDone ? '✓' : '□',
            ].map((v) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))))
            .toList())),
          ],
        ),
      ],
    ));
  }

  // ロケ地表PDF
  void _addLocationsPage(pw.Document pdf, Project project,
      List<LocationItem> locations) {
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(project, 'ロケ地表'),
        ...locations.map((l) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey300, width: 0.5),
            borderRadius: const pw.BorderRadius.all(
              pw.Radius.circular(4))),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(l.name,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 12,
                  color: PdfColor.fromHex('6FBA2C'))),
              pw.SizedBox(height: 4),
              if (l.address.isNotEmpty)
                pw.Text('住所: ${l.address}',
                  style: const pw.TextStyle(fontSize: 10)),
              if (l.access.isNotEmpty)
                pw.Text('アクセス: ${l.access}',
                  style: const pw.TextStyle(fontSize: 10)),
              if (l.hours.isNotEmpty)
                pw.Text('使用時間: ${l.hours}',
                  style: const pw.TextStyle(fontSize: 10)),
              if (l.contact.isNotEmpty)
                pw.Text('連絡先: ${l.contact}',
                  style: const pw.TextStyle(fontSize: 10)),
              if (l.memo.isNotEmpty)
                pw.Text('備考: ${l.memo}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        )),
      ],
    ));
  }
}

// 書き出しカードウィジェット
class _ExportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onExport; // VoidCallback → 引数なし・戻り値なしの関数型

  const _ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: glightGreenLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: glightGreenDark, size: 22),
        ),
        title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.5))),
        trailing: ElevatedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('書き出す'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
