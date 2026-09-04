// ログイン・サインアップ画面
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;   // true=ログイン, false=新規登録
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Supabase.instance.client → Supabaseクライアントのシングルトン
  // シングルトン = アプリ全体で1つだけ存在するオブジェクト
  final _supabase = Supabase.instance.client;

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = ''; });

    try {
      if (_isLogin) {
        // ログイン
        await _supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        // 新規登録
        await _supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        // 確認メールが送られる
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('確認メールを送信しました。メールを確認してください。')));
        }
      }
    } on AuthException catch (e) {
      // AuthException → Supabaseの認証エラー
      setState(() => _error = _translateError(e.message));
    } catch (e) {
      setState(() => _error = 'エラーが発生しました: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 英語のエラーメッセージを日本語に変換
  String _translateError(String msg) {
    if (msg.contains('Invalid login')) return 'メールアドレスまたはパスワードが間違っています';
    if (msg.contains('Email not confirmed')) return 'メールアドレスが確認されていません';
    if (msg.contains('already registered')) return 'このメールアドレスはすでに登録済みです';
    if (msg.contains('Password should be')) return 'パスワードは6文字以上にしてください';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glightロゴ
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: glightGreen,
                  borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text('G',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 36))),
              ),
              const SizedBox(height: 16),
              const Text('制作スケジュール帳',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'ログイン' : '新規アカウント作成',
                style: TextStyle(
                  fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 32),

              // メールアドレス
              TextField(
                controller: _emailCtrl,
                // keyboardType → キーボードの種類を指定
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 14),

              // パスワード
              TextField(
                controller: _passCtrl,
                obscureText: true, // パスワードを隠す
                decoration: const InputDecoration(
                  labelText: 'パスワード（6文字以上）',
                  prefixIcon: Icon(Icons.lock_outlined)),
              ),
              const SizedBox(height: 24),

              // エラーメッセージ
              if (_error.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3))),
                  child: Text(_error,
                    style: const TextStyle(
                      color: Colors.red, fontSize: 13))),
                const SizedBox(height: 16),
              ],

              // ログイン/登録ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                      : Text(_isLogin ? 'ログイン' : 'アカウントを作成'),
                ),
              ),
              const SizedBox(height: 16),

              // 切り替えボタン
              TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = '';
                }),
                child: Text(
                  _isLogin
                      ? 'アカウントをお持ちでない方はこちら'
                      : 'すでにアカウントをお持ちの方はこちら',
                  style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
