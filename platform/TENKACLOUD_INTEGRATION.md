# TenkaCloud 統合レポート — Security Battle Royale

> 作成日: 2026-03-08
> 対象: `/Users/susumu/TenkaCloud` (commit: latest on main)

---

## 1. TenkaCloud アーキテクチャ概要

### 1.1 プロジェクト概要

TenkaCloud は「クラウド天下一武道会」をコンセプトとした、OSS のマルチテナント競技プラットフォーム。AWS GameDay 文化をルーツに、マルチクラウド対応（AWS/GCP/Azure/LocalStack）で設計されている。

### 1.2 技術スタック

| レイヤー | 技術 |
|---------|------|
| フロントエンド | Next.js 16 (App Router), TypeScript, Tailwind CSS |
| バックエンド | Hono (軽量 Web FW), TypeScript, マイクロサービス |
| データベース | PostgreSQL (Prisma ORM) + DynamoDB (リポジトリ層) |
| 認証 | Auth0 (NextAuth 統合) |
| インフラ | AWS CDK (SBT), Docker, nginx, Terraform |
| パッケージ管理 | Bun (monorepo) |
| テスト | Vitest (99%+ カバレッジ必須) |

### 1.3 ディレクトリ構成

```
TenkaCloud/
├── apps/
│   ├── control-plane/        # 管理者 UI (Next.js 16)
│   └── application-plane/    # 競技者 UI (Next.js 16)
│
├── backend/services/
│   ├── control-plane/        # 共有プラットフォームサービス
│   │   ├── tenant-management/    # テナント CRUD (Hono + DynamoDB/Prisma)
│   │   ├── registration/         # テナント登録フロー
│   │   ├── user-management/      # ユーザー管理 (Auth0連携)
│   │   ├── deployment-management/ # デプロイメント管理
│   │   ├── system-management/    # システム管理
│   │   └── provisioning*/        # リソースプロビジョニング
│   │
│   ├── application-plane/    # テナント固有サービス
│   │   ├── problem-service/      # 問題管理・JAM互換・スコアリング (中核)
│   │   ├── battle-service/       # バトルセッション管理
│   │   ├── scoring-service/      # 採点 (S3/Terraform検証)
│   │   ├── leaderboard-service/  # リーダーボード
│   │   └── tenant-provisioner/   # テナント環境構築
│   │
│   └── shared/               # 共有ライブラリ
│       ├── dynamodb/             # DynamoDB リポジトリ層
│       ├── cloud-abstraction/    # マルチクラウド抽象化
│       ├── auth0/                # Auth0 認証アダプター
│       └── events/               # イベント共有
│
├── packages/                 # 共有 npm パッケージ
│   ├── core/                     # コアロジック (AWS SDK, スコアリング)
│   ├── shared/                   # 型定義・UIコンポーネント
│   └── design-system/            # UI コンポーネントライブラリ
│
└── infrastructure/
    ├── cdk/                      # AWS CDK (SBT統合)
    ├── nginx/                    # リバースプロキシ
    └── terraform/                # マルチクラウド IaC
```

### 1.4 マルチテナント設計

- **Control Plane / Application Plane** の2層分離
- Tenant ごとに `tenantId` でリソース分離
- `IsolationModel`: POOL（共有）/ SILO（専用）
- `TenantTier`: FREE / PRO / ENTERPRISE
- ユーザーロール: `TENANT_ADMIN` / `PARTICIPANT`

---

## 2. 既存機能マッピング

### 2.1 データモデル (Prisma Schema)

TenkaCloud は **8つの Prisma スキーマ**を持つ。GameDay 統合に特に関連するのは以下の3つ。

#### problem-service スキーマ（最重要、788行）

| モデル | GameDay での対応 |
|-------|----------------|
| `Event` | GameDay セッション全体に対応。`type: GAMEDAY` で作成 |
| `EventStatus` enum | `DRAFT → SCHEDULED → ACTIVE → PAUSED → COMPLETED → CANCELLED` |
| `Problem` / `ProblemTemplate` | **脆弱性問題**の定義に利用可能 |
| `Challenge` | イベント内の個別問題インスタンス（JAM互換） |
| `Task` | チャレンジ内のステップ（タスク = 各脆弱性の修正ステップ） |
| `Clue` | ヒント（ペナルティ付き、購入制） |
| `Team` | チーム管理、`eventId` で紐付け |
| `TeamChallengeAnswer` | チームの回答状態・スコア・悲観的ロック |
| `TaskProgress` | タスクごとの進捗（ロック/アンロック/完了） |
| `TaskScoring` | タスク採点設定（ポイント + クルーペナルティ） |
| `ScoringResult` | 採点結果（基準別スコア） |
| `Leaderboard` / `LeaderboardEntry` | リーダーボード（フリーズ対応あり） |
| `TeamLeaderboardEntry` | チーム別スコア（`teamTotalEffectiveScore`） |
| `LeaderboardEntryHistory` | スコア推移履歴 |
| `EventLog` | イベントログ（タイプ付き、メタデータ対応） |
| `CompetitorAccount` | クラウドアカウント管理（`status: PENDING/READY/IN_USE`） |
| `DeploymentJob` | デプロイジョブ（リトライ付き） |
| `ScoringCriterion` | 採点基準（重み + 最大ポイント） |

#### battle-service スキーマ

| モデル | GameDay での対応 |
|-------|----------------|
| `Battle` | バトルセッション。`BattleStatus: WAITING → IN_PROGRESS → FINISHED` |
| `BattleParticipant` | 参加者（score, rank） |
| `Team` | チーム（Battle内） |
| `BattleHistory` | イベント履歴（リプレイ用） |

#### scoring-service スキーマ

| モデル | GameDay での対応 |
|-------|----------------|
| `EvaluationCriteria` | 評価基準（カテゴリ別: SECURITY等） |
| `CriteriaDetail` | 詳細ルール（`ruleKey: "s3_encryption"` 等） |
| `ScoringSession` | 採点セッション |
| `EvaluationItem` | 項目別結果 |
| `Feedback` | フィードバック（改善提案付き） |
| `TerraformSnapshot` | Terraform状態スナップショット |

### 2.2 スコアリングシステム

TenkaCloud には **3層のスコアリングエンジン**が存在する。

#### (A) ScoringEngine (`scoring/engine.ts`)
- ジョブキュー方式（`maxConcurrency: 5`, リトライ付き）
- `IScoringExecutor` インターフェースでプロバイダー抽象化
- 実装: `LambdaScoringFunction`, `ContainerScoringFunction`, `LocalScoringFunction`
- **Pub/Sub パターン**: `subscribe()` でスコア結果を購読可能

#### (B) RealtimeScoringEngine (`scoring/realtime-engine.ts`)
- ScoringEngine をラップしたリアルタイム層
- `startSession()` / `stopSession()` / `pauseSession()` / `resumeSession()`
- 定期的な採点ラウンド実行（`setInterval`）
- リーダーボードの自動更新 + フリーズ機能
- `onLeaderboardUpdate()` / `onScoreUpdate()` リスナー

#### (C) AWSGameDayScoringProvider (`scoring/providers/aws-gameday.ts`)
- EC2, S3, Lambda, CloudFormation, VPC, Security Group, IAM, CloudWatch, API Gateway の検証
- `ResourceValidator` パターンで拡張可能
- 基準名から自動で検証タイプを推測（`inferValidationType`）
- **現状はモック実装**（実際のAWS SDK呼び出しは TODO）

### 2.3 コンテスト管理 (`jam/contest.ts`)

- `createContest()`: コンテスト作成（DRAFT状態）
- `startContest()`: 開始（ログ記録）
- `stopContest()`: 停止（ロック解除 + 最終リーダーボード生成）
- `pauseContest()` / `resumeContest()`: 一時停止/再開（TODO）
- `addChallengeToContest()`: 問題追加（Challenge + Task + Clue + Answer + TaskScoring をトランザクション作成）
- `registerTeamToContest()`: チーム登録（TaskProgress を自動初期化）
- `getContestTeams()`: 参加チーム一覧

### 2.4 JAM 互換機能 (`jam/`)

- **challenge.ts**: チャレンジ開始、一覧取得、詳細取得（タスク進捗含む）
- **scoring.ts**: クルー開放（ペナルティ計算）、回答検証（正解時のスコア更新 + リーダーボード更新 + 次タスクアンロック）
- **locking.ts**: 悲観的ロック（`SELECT FOR UPDATE` パターン、Serializable トランザクション）
- **dashboard.ts**: リーダーボード取得、チームダッシュボード、チャレンジ統計、スナップショット保存
- **eventlog.ts**: 構造化ログ（`EventLogType` enum: 12種類のログタイプ）

### 2.5 リーダーボード

#### problem-service 内 (`jam/dashboard.ts`)
- `getLeaderboard()`: TeamChallengeAnswer を集計してスコア降順ソート
- `getTeamDashboard()`: チーム視点のダッシュボード（ランク、チャレンジ進捗、最近のアクティビティ）
- `getEventDashboard()`: イベント全体ダッシュボード
- `saveLeaderboardSnapshot()`: 定期スナップショット + 履歴保存

#### leaderboard-service (`services/leaderboard.ts`)
- `isLeaderboardFrozen()`: バトル終了前のフリーズ判定（デフォルト10分前）
- `buildLeaderboard()`: 参加者スコアソート + ランク付け
- DynamoDB ベースのBattle リポジトリから読み取り

#### RealtimeScoringEngine 内
- インメモリリーダーボード管理
- フリーズ機能（`freezeBeforeEndMs`）
- トレンド計算（up/down/same）

### 2.6 イベントフェーズ制御

**EventStatus enum** (`problem-service/prisma/schema.prisma`):
```
DRAFT → SCHEDULED → ACTIVE → PAUSED → COMPLETED → CANCELLED
```

**BattleStatus** (`battle-service`):
```
DRAFT → OPEN → RUNNING → FINISHED → ARCHIVED
```

状態遷移は `transitionBattle()` で明示的に管理（`validTransitions` マップ）。OPEN→RUNNING 遷移時に参加者数チェックあり。

### 2.7 管理者 API (`routes/admin.ts`)

Hono ルーター。Zod バリデーション + Auth0 認証。主要エンドポイント:
- `POST /events`: イベント作成
- `PUT /events/:id/status`: ステータス変更
- `POST /events/:eventId/contest/start`: コンテスト開始
- `POST /events/:eventId/contest/stop`: コンテスト停止
- `POST /events/:eventId/challenges`: 問題追加
- `POST /events/:eventId/teams`: チーム登録
- `GET /events/:eventId/dashboard`: ダッシュボード
- `GET /events/:eventId/leaderboard`: リーダーボード
- `POST /events/:eventId/leaderboard/snapshot`: スナップショット保存

---

## 3. 追加が必要な機能一覧

TenkaCloud の既存機能と GameDay Security Battle Royale の要件を比較し、追加が必要な機能を特定する。

### 3.1 既存機能で直接利用可能

| GameDay 機能 | TenkaCloud 対応 | 備考 |
|-------------|----------------|------|
| チーム管理 | `Team` モデル + `registerTeamToContest()` | そのまま使える |
| リーダーボード | `dashboard.ts` + `LeaderboardEntry` | フリーズ機能もあり |
| スコアリング基盤 | `ScoringEngine` + `RealtimeScoringEngine` | ジョブキュー + リアルタイム |
| イベント管理 | `Event` モデル + Admin API | CRUD + フェーズ制御 |
| ヒント購入 | `Clue` + `openClue()` | ペナルティ計算あり |
| イベントログ | `EventLog` + 12種のログタイプ | 構造化ログ |
| コンテスト開始/停止 | `startContest()` / `stopContest()` | ログ + ロック解除 |
| 悲観的ロック | `locking.ts` | PostgreSQL Serializable |
| AWS リソース検証 | `AWSGameDayScoringProvider` | 9種の検証タイプ |
| マルチテナント | Control Plane + tenant 管理 | テナント分離済み |

### 3.2 拡張が必要な機能

| GameDay 機能 | 既存の近い機能 | 必要な拡張 |
|-------------|--------------|-----------|
| アップタイムスコア（定期加算/減算） | `RealtimeScoringEngine` の定期採点 | **Auditor ポーリング結果に基づくスコア加減算ロジック**の追加 |
| 倹約ポイント | `ScoringCriterion` | EC2 インスタンス数チェック用の新しい `ScoringCriterion` |
| フェーズ制御（準備/攻撃/ブラックアウト） | `EventStatus` enum | **GameDay 固有のフェーズ enum** が必要（`PREPARATION`, `ATTACK`, `BLACKOUT`） |
| スコアボードブラックアウト | `isFrozen` フラグ | **ブラックアウトフェーズ**との連動。既存の `freezeLeaderboardMinutes` を活用可能 |
| 脆弱性管理 | `Problem` / `Challenge` | 脆弱性をモデル化するための**新しいスキーマ拡張**（`Vulnerability` テーブル） |

### 3.3 新規実装が必要な機能

| GameDay 機能 | 説明 | 優先度 |
|-------------|------|-------|
| **攻撃システム** | 攻撃購入、ターゲット選択、クールダウン、ダメージ/報酬計算 | P0 |
| **防御システム** | Defense Trench（受けている攻撃一覧）、脆弱性修正の自動検証 | P0 |
| **同盟システム** | 同盟の締結/破棄、報酬分配ロジック | P1 |
| **Auditor (ヘルスチェッカー)** | クロスアカウント AssumeRole でアプリ稼働状態を定期監視 | P0 |
| **障害注入エンジン** | 管理者による手動/自動の障害注入（AssumeRole 経由） | P1 |
| **攻撃実行エンジン** | 脆弱性悪用の実際の実行（バックドア RCE、SQLi 等のシミュレーション） | P0 |
| **WebSocket リアルタイム通信** | スコア更新、攻撃通知、リーダーボード更新のリアルタイム配信 | P1 |
| **投票システム** | ゲーム終了時のチーム投票（+5,000pt / 最多得票 +10,000pt） | P2 |
| **AWS アカウント管理** | チーム用 AWS アカウントのプロビジョニング + クレデンシャル配布 | P0 |

---

## 4. 統合アプローチの提案

### 4.1 推奨: ハイブリッドアプローチ（既存フレームワーク活用 + GameDay 専用サービス追加）

**理由**:
1. TenkaCloud は既にスコアリング、リーダーボード、イベント管理、チーム管理の基盤を持っている
2. しかし、攻撃/防御/同盟は TenkaCloud の設計思想（JAM 形式の問題解決型）とは根本的に異なるゲームメカニクスである
3. 完全に TenkaCloud に乗せると、TenkaCloud 側への大量の変更が必要になりメンテナンスコストが高い
4. 完全に独立構築すると、スコアリングやリーダーボードを再実装することになり非効率

### 4.2 統合レイヤーの設計

```
┌─────────────────────────────────────────────────────────┐
│                    security-api/platform                  │
│                                                          │
│  ┌──────────────────┐  ┌──────────────────────────────┐  │
│  │ GameDay Backend  │  │  Frontend (React/CloudScape) │  │
│  │ (FastAPI)        │  │                              │  │
│  │                  │  │  - Attack Station            │  │
│  │  - Attack Engine │  │  - Defense Trench            │  │
│  │  - Defense Mgr   │  │  - Headquarters              │  │
│  │  - Alliance Mgr  │  │  - Alliance Dashboard        │  │
│  │  - Auditor       │  │  - Scoreboard                │  │
│  │  - Fault Injector│  │                              │  │
│  └────────┬─────────┘  └──────────────────────────────┘  │
│           │                                              │
│           │ REST API / WebSocket                         │
│           ▼                                              │
│  ┌────────────────────────────────────────────────────┐  │
│  │         TenkaCloud Integration Layer               │  │
│  │                                                    │  │
│  │  Adapter Pattern で TenkaCloud API を呼び出し:     │  │
│  │  - Event 管理 → TenkaCloud Event API               │  │
│  │  - チーム管理 → TenkaCloud Team API                 │  │
│  │  - スコア記録 → TenkaCloud Scoring API              │  │
│  │  - リーダーボード → TenkaCloud Leaderboard API      │  │
│  │  - イベントログ → TenkaCloud EventLog API           │  │
│  └────────┬───────────────────────────────────────────┘  │
│           │                                              │
└───────────┼──────────────────────────────────────────────┘
            │ HTTP (internal)
            ▼
┌───────────────────────────────────────────────────────────┐
│                    TenkaCloud Backend                      │
│                                                           │
│  problem-service (Hono)                                   │
│  ├── Admin API: /events, /challenges, /teams              │
│  ├── Player API: /challenges, /clues, /validate           │
│  ├── Scoring Engine + Realtime Engine                     │
│  └── Dashboard + Leaderboard                              │
│                                                           │
│  battle-service (Hono)                                    │
│  ├── Battle CRUD + 状態遷移                                │
│  └── Participant 管理                                      │
│                                                           │
│  leaderboard-service (Hono)                               │
│  └── Leaderboard (DynamoDB)                               │
└───────────────────────────────────────────────────────────┘
```

### 4.3 何を TenkaCloud に委譲し、何を独自実装するか

#### TenkaCloud に委譲する機能

| 機能 | TenkaCloud API | 理由 |
|------|---------------|------|
| イベント作成・管理 | `POST /events`, `PUT /events/:id/status` | 既存の EventStatus 遷移で十分 |
| チーム登録・管理 | `POST /events/:eventId/teams` | TeamChallengeAnswer 自動初期化が便利 |
| スコア記録・集計 | `ScoringEngine.enqueue()` | ジョブキュー + リトライが堅牢 |
| リーダーボード | `getLeaderboard()`, `saveLeaderboardSnapshot()` | フリーズ機能含む |
| イベントログ | `addEventLog()` | 構造化ログ（12タイプ） |
| ヒント管理 | `openClue()` | ペナルティ計算ロジック済み |
| AWS リソース検証 | `AWSGameDayScoringProvider` | 拡張可能なバリデータパターン |

#### security-api で独自実装する機能

| 機能 | 理由 |
|------|------|
| 攻撃エンジン | TenkaCloud に「チーム間攻撃」の概念がない |
| 防御マネージャー | 脆弱性修正の自動検証は GameDay 固有 |
| 同盟システム | TenkaCloud に同盟の概念がない |
| Auditor (ヘルスチェッカー) | GameDay 固有のアップタイム監視 |
| 障害注入エンジン | 管理者による手動/自動障害注入 |
| フェーズ制御ロジック | GameDay 固有の準備/攻撃/ブラックアウトフェーズ |
| 投票システム | GameDay 固有 |
| WebSocket ハブ | リアルタイム通知（攻撃/防御/スコア） |

---

## 5. 具体的な実装計画

### Phase 1: 基盤統合（Week 1）

**目標**: TenkaCloud との接続を確立し、基本的なイベント/チーム管理を動作させる

1. **TenkaCloud Adapter の実装**
   - `TenkaCloudClient` クラスを作成（HTTP クライアント）
   - イベント作成 / チーム登録 / スコア記録の Adapter メソッド
   - エラーハンドリング + リトライロジック

2. **データモデル拡張**
   - security-api 側に GameDay 固有のテーブルを追加:
     - `attacks`: 攻撃定義（名前、購入コスト、ダメージ、報酬、クールダウン、対応する脆弱性）
     - `team_attacks`: チームが購入した攻撃
     - `attack_history`: 攻撃実行履歴
     - `alliances`: 同盟関係
     - `vulnerabilities`: 脆弱性定義と修正状態
     - `uptime_checks`: アップタイムチェック結果
     - `game_phases`: フェーズ制御状態

3. **イベント作成フロー**
   - security-api 側で GameDay イベント作成
   - TenkaCloud 側に Event を同期作成（`type: GAMEDAY`）
   - チーム登録を両方に同期

### Phase 2: コア機能実装（Week 2-3）

**目標**: 攻撃/防御/Auditor の実装

4. **Auditor (ヘルスチェッカー) の実装**
   - 各チームの EC2/RDS/S3 の稼働状態を定期監視
   - クロスアカウント AssumeRole でアクセス
   - アップタイムスコアの加算/減算ロジック
   - 結果を TenkaCloud の `ScoringEngine` に送信

5. **攻撃エンジンの実装**
   - 攻撃購入 API
   - ターゲット選択 + 攻撃実行 API
   - クールダウン管理
   - ダメージ/報酬計算（同盟チームへの報酬分配含む）
   - 攻撃実行: AWS SDK 経由で対象アカウントにアクション実行

6. **防御マネージャーの実装**
   - Defense Trench: 受けている攻撃一覧 API
   - 脆弱性修正の自動検証
   - TenkaCloud の `AWSGameDayScoringProvider` を拡張して脆弱性チェックを追加

### Phase 3: ゲーム制御（Week 3-4）

7. **フェーズ制御の実装**
   - GameDay 固有のフェーズ: `PREPARATION → ATTACK → BLACKOUT → ENDED`
   - TenkaCloud の `EventStatus` と同期
   - ブラックアウト開始時に TenkaCloud のリーダーボードをフリーズ

8. **同盟システムの実装**
   - 同盟提案 / 受諾 / 破棄 API
   - 攻撃報酬の同盟チームへの分配ロジック

9. **障害注入エンジンの実装**
   - 管理者が任意のチームに障害を注入する API
   - スケジュール障害（自動）のサポート

### Phase 4: フロントエンド + 統合テスト（Week 4-5）

10. **フロントエンド実装**
    - Attack Station / Defense Trench / Headquarters / Alliance Dashboard
    - WebSocket によるリアルタイム更新
    - スコアボード（TenkaCloud リーダーボードを表示）

11. **投票システム**
    - ゲーム終了前の投票 API
    - 投票結果のスコア反映

12. **統合テスト**
    - E2E テスト（LocalStack 使用）
    - 負荷テスト（同時攻撃、大量スコア更新）

### 5.2 TenkaCloud スキーマ拡張案

TenkaCloud 側には**最小限の変更**で対応する。以下を `problem-service/prisma/schema.prisma` に追加する案:

```prisma
// GameDay フェーズ（Event に追加）
enum GameDayPhase {
  PREPARATION
  ATTACK
  BLACKOUT
  ENDED
}

// Event モデルにオプショナルフィールド追加
// gameDayPhase  GameDayPhase?
// gameDayConfig Json?  // { uptimeInterval, frugalityThreshold, etc. }
```

ただし、TenkaCloud 本体への変更は最小限に留め、GameDay 固有のデータは security-api 側で管理することを推奨する。

### 5.3 API 連携の具体例

```python
# security-api 側 (FastAPI)

class TenkaCloudAdapter:
    """TenkaCloud problem-service との連携アダプター"""

    def __init__(self, base_url: str, auth_token: str):
        self.base_url = base_url
        self.auth_token = auth_token

    async def create_event(self, name: str, teams: int, duration_min: int) -> str:
        """TenkaCloud にイベントを作成"""
        response = await self._post("/admin/events", {
            "name": name,
            "type": "GAMEDAY",
            "tenantId": self.tenant_id,
            "startTime": datetime.now().isoformat(),
            "endTime": (datetime.now() + timedelta(minutes=duration_min)).isoformat(),
            "participantType": "TEAM",
            "maxParticipants": teams,
            "cloudProvider": "AWS",
            "regions": ["us-east-1"],
            "scoringType": "REALTIME",
            "scoringIntervalMinutes": 1,
            "leaderboardVisible": True,
            "freezeLeaderboardMinutes": 15,
        })
        return response["id"]

    async def register_team(self, event_id: str, team_name: str) -> str:
        """TenkaCloud にチームを登録"""
        response = await self._post(
            f"/admin/events/{event_id}/teams",
            {"teamName": team_name}
        )
        return response["teamId"]

    async def update_score(self, event_id: str, team_id: str, delta: int, reason: str):
        """TenkaCloud のリーダーボードスコアを更新"""
        await self._post(f"/admin/events/{event_id}/scores", {
            "teamId": team_id,
            "delta": delta,
            "reason": reason,
        })

    async def freeze_leaderboard(self, event_id: str):
        """リーダーボードをフリーズ（ブラックアウト）"""
        await self._post(f"/admin/events/{event_id}/leaderboard/freeze")

    async def add_event_log(self, event_id: str, team_name: str,
                            message: str, log_type: str):
        """イベントログを追加"""
        await self._post(f"/admin/events/{event_id}/logs", {
            "teamName": team_name,
            "message": message,
            "logType": log_type,
        })
```

### 5.4 TenkaCloud 側に必要な最小変更

1. **スコア増減 API の追加** (`admin.ts`):
   - `POST /events/:eventId/scores` — `teamTotalEffectiveScore` の直接増減（攻撃/防御/アップタイム用）
   - 現状の TenkaCloud は「回答正解時」にのみスコアが変動するが、GameDay では「定期チェック」や「攻撃」でもスコアが変動する

2. **リーダーボードフリーズ API**:
   - `POST /events/:eventId/leaderboard/freeze` — 既存の `isFrozen` フラグを制御
   - 現状はコードで条件判定するのみだが、管理者が明示的にフリーズできる API が必要

3. **EventLog タイプの拡張**:
   - `EventLogType` に GameDay 固有のタイプを追加: `ATTACK_SENT`, `ATTACK_RECEIVED`, `ALLIANCE_FORMED`, `ALLIANCE_BROKEN`, `UPTIME_CHECK`, `FAULT_INJECTED`

---

## 付録: 用語対応表

| GameDay 用語 | TenkaCloud 用語 | 備考 |
|-------------|----------------|------|
| Game Session | Event | `type: GAMEDAY` |
| Team | Team | 同一概念 |
| Scoreboard | Leaderboard | フリーズ機能あり |
| Phase | EventStatus / GameDayPhase | 拡張が必要 |
| Attack | (新規) | security-api で管理 |
| Defense | (新規) | security-api で管理 |
| Alliance | (新規) | security-api で管理 |
| Vulnerability | Problem/Challenge | 脆弱性を Problem として定義可能 |
| Hint | Clue | ペナルティ付きヒント |
| Auditor | ScoringEngine | ヘルスチェック用のカスタム Executor |
| Fault Injection | (新規) | security-api で管理 |
| Blackout | Leaderboard.isFrozen | 既存機能を活用 |
| Frugality Points | ScoringCriterion | EC2 数チェック用の基準 |
| Uptime Score | (新規) | 定期加算/減算ロジック |
