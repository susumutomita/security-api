# AWS GameDay "Security Battle Royale"

Security Battle Royale は、複数チームが自社AWSインフラを守りながら他チームの脆弱性を攻撃し、最高スコアを目指すセキュリティ競技イベント。

## リポジトリ構成

```
security-api/
├── api.py                  # チーム側 Flask API（意図的な脆弱性を含む）
├── package.sh              # S3へのデプロイスクリプト
├── cloudformation.yaml     # チーム用AWSリソーステンプレート
├── platform/
│   ├── SPEC.md             # ゲーム仕様（目次）
│   ├── TENKACLOUD_INTEGRATION.md  # TenkaCloud統合方針
│   └── specs/              # 詳細仕様
│       ├── scoring.md      # スコアリング
│       ├── game-flow.md    # ゲーム進行フロー
│       ├── attack-defense.md  # 攻撃・防御メカニクス
│       ├── alliance.md     # 同盟システム
│       ├── side-quests.md  # サイドクエスト
│       ├── admin.md        # 管理者機能
│       ├── dashboards.md   # ダッシュボード
│       └── technical.md    # 技術仕様
└── PROMPT.md               # ゲームルール参考情報
```

## チーム側インフラ

各チームに以下のAWSリソースが割り当てられる（`cloudformation.yaml` で定義）:

| コンポーネント | サービス | 説明 |
|--------------|---------|------|
| Website | Amazon S3 | 静的Webサイトホスティング |
| API Flask App | Amazon EC2 | Flask REST API（Amazon Linux 2023） |
| Database | Amazon RDS | MySQL（データベース名: `cavsdb`） |
| Source Code | Amazon S3 | `flask_api.zip` として保管 |

## API エンドポイント

| エンドポイント | メソッド | 説明 |
|--------------|---------|------|
| `/` | GET | トップページ |
| `/api/v1/apistatus` | GET | APIステータス（Auditor使用） |
| `/api/v1/dbstatus` | GET/POST | DBステータス確認 |
| `/api/v1/setdbpwd` | POST | DBパスワード変更（Auditor使用） |
| `/api/v1/unicorns` | GET | ユニコーン一覧 |
| `/api/v1/unicorns/login` | GET | ログイン |
| `/api/v1/unicorn` | POST/PATCH | ユニコーン登録・更新 |
| `/api/v1/latest` | GET | 最新エントリ |
| `/api/v1/region` | GET | リージョン取得（Auditor使用） |
| `/api/v1/proxy` | GET | プロキシ |
| `/backdoor` | GET | バックドア |

## デプロイ

```bash
chmod +x package.sh
./package.sh
```

## 運営システム

バックエンドは [TenkaCloud](https://github.com/susumutomita/TenkaCloud) の `gameday-service` として統合。詳細は `platform/TENKACLOUD_INTEGRATION.md` を参照。

## 依存関係

- Python 3, Flask, boto3, PyMySQL, requests
