# 技術仕様

> [SPEC.md](../SPEC.md) > 技術仕様

---

## チーム側インフラ（各チームのAWSアカウント内）

```
┌──────────────────────┐     ┌──────────────────────────────┐
│  AUDITOR'S ACCOUNT   │     │       YOUR ACCOUNT           │
│  (アクセス不可)       │     │                              │
│                      │     │  ┌────────────┐              │
│                      │──→──│  │  Website   │              │
│                      │     │  │ (Amazon S3)│              │
│  ┌────────────────┐  │     │  └────────────┘              │
│  │ Auditing Tool  │──│──→──│  ┌──────────────┐  ┌──────┐  │
│  └────────────────┘  │     │  │API Flask App │→ │  DB  │  │
│                      │     │  │ (EC2)        │  │(RDS) │  │
└──────────────────────┘     │  └──────────────┘  └──────┘  │
                             └──────────────────────────────┘
```

| コンポーネント | サービス | 詳細 |
|--------------|---------|------|
| Website | Amazon S3 | 静的Webサイトホスティング |
| API Flask App | Amazon EC2 | Amazon Linux 2023 (x86), `API Flask App` という名前のインスタンス |
| Database | Amazon RDS | MySQL, データベース名 `cavsdb` |
| ソースコード保管 | Amazon S3 | `flask_api.zip` として保管 |
| ソースコード編集 | Cloud IDE | `/home/ubuntu/environment/GameDay/flask_api` 配下 |
| デプロイ | `package.sh` | S3バケットにpush |
| ログ | ファイル | `/api/output.log` |
| DBエンドポイント | SSM Parameter Store | パラメータ名 `CAVS_DB_ENDPOINT` |
| DBパスワード | Secrets Manager | シークレット名 `DatabasePasswordSecret` |
| IAMロール | IAM | インスタンスプロファイル `api-ec2-instance-profile` |

## チーム側APIエンドポイント一覧

| エンドポイント | メソッド | 説明 | 脆弱性 |
|--------------|---------|------|--------|
| `/` | GET | Hello World（トップページ） | なし |
| `/api/v1/apistatus` | GET | APIステータス確認（Auditor使用） | なし（変更禁止） |
| `/api/v1/dbstatus` | GET/POST | DBステータス確認 | なし |
| `/api/v1/setdbpwd` | POST | DBパスワード変更（Auditor使用） | 認証なし（変更禁止） |
| `/api/v1/unicorns` | GET | ユニコーン一覧取得 | SQLインジェクション |
| `/api/v1/unicorns/login` | GET | ログイン | SQLインジェクション + GET送信 |
| `/api/v1/unicorn` | POST | ユニコーン登録 | 推測容易なデフォルトパスワード |
| `/api/v1/unicorn` | PATCH | ユニコーン更新 | なし |
| `/api/v1/latest` | GET | 最新エントリ取得 | なし |
| `/api/v1/region` | GET | リージョン取得（Auditor使用） | なし（変更禁止） |
| `/api/v1/proxy` | GET | プロキシ（任意URLにリクエスト） | SSRF |
| `/backdoor` | GET | バックドア（任意コマンド実行） | RCE |

**注意**: `DO NOT CHANGE` / `DO NOT TOUCH` コメントのあるルートはAuditor Toolが使用するため、修正時は機能を維持する必要がある（ただし `/backdoor` は削除すべき）。

## アプリケーション再構築手順（ヒント1: 0pt）

```bash
#!/bin/bash -xe
dnf update -y
dnf install -y python3-pip
python3 -m pip install flask boto3 PyMySQL
dnf install mariadb105 -y
mkdir /api
cd /api
aws s3 cp s3://<APPLICATION_SOURCE_CODE_BUCKET>/flask_api.zip /api/flask_api.zip
unzip flask_api.zip
chmod +700 api.py
python3 api.py
```

- **AMI**: Amazon Linux 2023 (x86)
- **Security Group**: チーム固有
- **IAM Instance Profile**: `api-ec2-instance-profile`
- ヒント: EC2インスタンスからLaunch Templateを作成できる

## トラブルシューティング（ヒント2: -5,000pt）

1. API Flask Appインスタンスは動いているか？ → なければUser Dataを使って新規起動
2. エンドポイントをブラウザで開いて表示されるか？
3. アプリケーションは実行中か？ → `ps -ef | grep api`
4. ログにエラーはあるか？ → `view /api/output.log`
5. ログは流れているか？ → `tail -200f /api/output.log`
6. `ERROR Access denied for user 'admin'` → **Password Rotation攻撃**を受けた可能性。Secrets Manager の `DatabasePasswordSecret` からパスワードを取得
7. アプリケーション自体が存在するか？ → `ls -ltr /api`。なければ `/var/log/cloud-init-output.log` を確認
8. インスタンスが `PayToDecrypt` にリネームされている？ → **Leaked Credentials攻撃**を受けた。新しいインスタンスを起動するのが最も簡単

## プラットフォーム側（運営システム）

| コンポーネント | 技術 | 説明 |
|--------------|------|------|
| バックエンドAPI | TenkaCloud gameday-service (Hono) | ゲーム制御、スコア管理、攻撃処理 |
| フロントエンド | TenkaCloud application-plane (Next.js) | プレーヤーUI、管理者UI |
| リアルタイム通信 | WebSocket | スコア更新、攻撃通知等のリアルタイム配信 |
| 障害注入 | クロスアカウントAssumeRole | 各チームのAWSアカウントに対して障害注入を実行 |
| ヘルスチェック | 60秒間隔 | Website URL + API Flask App エンドポイントの死活監視 |

## GenAI チャットボット構成（サイドクエスト用）

| コンポーネント | サービス |
|--------------|---------|
| チャットボットコンテナ | Amazon ECS |
| ロードバランサー | ALB |
| MCPサーバー | API Gateway + Lambda |
| AI基盤 | Amazon Bedrock (Knowledge Base) |
| ソースコード | S3 |
| 自動ビルド | CodeBuild |
