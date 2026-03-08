# 攻撃・防御メカニクス

> [SPEC.md](../SPEC.md) > 攻撃・防御

---

## 攻撃の種類

### 脆弱性悪用型攻撃（Exploiting system vulnerabilities）

- システムの脆弱性を突いて不正アクセス・業務妨害・情報窃取を行う
- **被攻撃側は脆弱性を修正（neutralize）することで攻撃を無効化できる**
- プレーヤーが攻撃ボタンを押すと実際にAWS操作が走る

### 可用性テスト型攻撃（Causing events）

- ハードウェア障害・データセンター障害・自然災害などのイベントをシミュレート
- **無効化はできないが、Well-Architectedなシステム設計で緩和可能**（例: Auto Scaling, Multi-AZ）

## 攻撃の購入・実行ルール

| ルール | 詳細 |
|--------|------|
| 購入コスト | 各攻撃は**一度きりの購入費用 3,000pt** が発生する（確定） |
| 再利用 | 購入後は**何度でも発動可能** |
| クールダウン | 発動後に **5分間のクールダウン** がある（再発動まで待つ必要がある）（確定） |
| ダメージ/報酬 | **全攻撃で共通**の値（確定）<!-- TODO: 具体的な数値は未確認 --> |
| 事前確認 | 購入前に「与えるダメージ」と「成功時の報酬ポイント」を確認できる |
| 自己攻撃 | 自分自身への攻撃はポイント変動なし（アプリ稼働への影響はあり得る） |
| 攻撃免疫 | 関連コンポーネントがダウン中の場合、その攻撃に対して免疫になる場合がある |

## 防御の流れ

1. **Defense Trench** で受けている攻撃の一覧を確認する
2. 各攻撃にはヒント（購入制）が付いており、緩和方法が分かる
3. ヒントコスト: 一部は **無料**、それ以外は **約3,000pt**（確定）
4. ヒントを開示する前にポイントコストを確認する
5. 実際にコード修正やAWSリソース変更を行って脆弱性を除去する
6. 脆弱性が修正されると、その攻撃は無効化（neutralize）される

### プレーヤーがアクセスできるもの（確定）

- **AWSコンソール**: チーム用AWSアカウントのフルアクセス（EC2, RDS, S3, IAM等）
- **APIのソースコード**: Cloud IDE上の `/home/ubuntu/environment/GameDay/flask_api` 配下のコードを直接編集可能
- **デプロイ**: `package.sh` でS3にpush → EC2がzip取得して展開
- **サイトの改ざん復旧**: S3ホスティングされたWebサイトが改ざんされた場合、復旧方法は明確でないがプレーヤーは復旧できていた（S3バケットの操作で元に戻す等）

## 脆弱性と攻撃の対応表

api.py に意図的に仕込まれた脆弱性と、対応する攻撃の対応関係：

| # | 脆弱性 | 箇所 | 推定攻撃名 | 修正方法 |
|---|--------|------|-----------|---------|
| 1 | バックドア（RCE） | `/backdoor` ルート | Remote Code Execution | ルート自体を完全に削除 |
| 2 | SQLインジェクション | `/api/v1/unicorns` の f-string SQL | SQL Injection | パラメータ化クエリ（`%s` プレースホルダ）を使用 |
| 3 | SQLインジェクション | `/api/v1/unicorns/login` の f-string SQL | SQL Injection | パラメータ化クエリを使用 |
| 4 | ハードコードDBパスワード | `get_db_connection()` 内 `dbpass = "adminadmin"` | Password Rotation | `get_secret('DatabasePasswordSecret')` を有効化 |
| 5 | SSRF | `/api/v1/proxy` で任意URLにリクエスト可能 | SSRF / Leaked Credentials | URLホワイトリスト検証、内部IPレンジのブロック |
| 6 | デバッグモード有効 | `app.config["DEBUG"] = True`, `debug=True` | 情報漏洩 | `debug=False` に変更 |
| 7 | パスワード平文保存・GET送信 | `password = f"{data['name']}@123"`, login が GET | 情報漏洩 | パスワードハッシュ化、POSTメソッド使用 |
| 8 | 認証・認可の欠如 | 全エンドポイントが認証なし。`/api/v1/setdbpwd` で DB パスワード変更可能 | 不正アクセス | 認証機構の追加 |

## 攻撃と防御の対応表（推定）

| 攻撃名 | 種別 | 対象脆弱性 | 防御方法 |
|--------|------|-----------|---------|
| Remote Code Execution | 脆弱性悪用 | `/backdoor` ルート | ルートを削除 |
| SQL Injection | 脆弱性悪用 | f-string SQL | パラメータ化クエリ |
| Password Rotation | 脆弱性悪用 | ハードコードパスワード | Secrets Manager 使用 |
| Leaked Credentials | 脆弱性悪用 | ハードコードパスワード / SSRF | パスワード除去 + SSRF修正 |
| SSRF Attack | 脆弱性悪用 | `/api/v1/proxy` | URL検証追加 |
| HA/Resilience攻撃 | 可用性テスト | 単一EC2構成 | Auto Scaling + Launch Template |

## 運営による妨害注入

- 運営は任意のタイミングで任意のチームに手動で妨害（攻撃）を注入できる
- プレーヤー間攻撃と同じメカニクスで動作する
