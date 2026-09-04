// Supabaseの接続情報を一箇所にまとめるファイル
// 実際の値は自分のSupabaseプロジェクトのものを使う

class SupabaseConfig {
  // Project URL（SupabaseダッシュボードのSettings→APIから）
  static const String url = 'https://rbxrnoutdgfadmvzmeiw.supabase.co';

  // Publishable key（sb_publishable_...で始まるキー）
  // ※このキーはPublicに公開しても安全（RLSで保護されているため）
  static const String anonKey = 'sb_publishable_iTD_M5xzoxyXqlcpznYnmA_18wAhZ84';
}
