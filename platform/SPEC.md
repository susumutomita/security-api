# AWS GameDay "Security Battle Royale" ゲーム仕様書

> このドキュメントはゲームプラットフォームの実装仕様の目次です。
> 各セクションの詳細は `specs/` 配下の個別ファイルを参照してください。

---

## 1. ゲーム概要

- **タイトル**: Security Battle Royale
- **難易度**: 400レベル
- **制限時間**: 240分（4時間）
- **参加者**: 複数チーム（各チームにAWSアカウント1つが割り当てられる）
- **世界観**: Unicorn.Rentals というレンタルサービス企業でセキュリティインシデントが発生。新入社員として採用されたチームがシミュレーション実験の中で自社インフラを守りながら他チームを攻撃し、最高スコアを目指す
- **ユースケース**: Security / Resilience / Well-Architected / Incident Response
- **使用AWSサービス**: Amazon EC2, Amazon RDS, Amazon S3, AWS IAM
- **AWSリージョン**: us-east-1

### 1.1 ゲーム構成

メインクエスト1本 + サイドクエスト2本 + ツールクエスト1本の計4クエストで構成される。

| クエスト | 種別 | 難易度 | 想定時間 |
|---------|------|--------|---------|
| Security Battle Royale | メインクエスト | 400 | 240分 |
| Generative AI Insights | サイドクエスト | 100 | 45分 |
| AI-Powered Cloud Security with SentinelOne | サイドクエスト | 100 | 60分 |
| Best Team Name | ツールクエスト | 100 | 5分 |

### 1.2 メインクエストのセクション構成

| セクション | 名称 | 概要 |
|-----------|------|------|
| 1 | Headquarters（司令部） | インフラの状態監視 |
| 2 | Defense Trench（防衛塹壕） | 受けている攻撃の監視・緩和 |
| 3 | Attack Station（攻撃ステーション） | 他チームへの攻撃 |
| 4 | Team Alliances（チーム同盟） | 同盟の締結・管理 |

---

## 詳細仕様

| セクション | ファイル | 概要 |
|-----------|---------|------|
| スコアリング | [specs/scoring.md](specs/scoring.md) | ヘルスチェック、攻撃ポイント、倹約ポイント、スコア重み |
| ゲーム進行 | [specs/game-flow.md](specs/game-flow.md) | 運営制御、ブラックアウト、進行タイムライン |
| 攻撃・防御 | [specs/attack-defense.md](specs/attack-defense.md) | 脆弱性一覧、攻撃カタログ、防御フロー |
| 同盟 | [specs/alliance.md](specs/alliance.md) | 同盟ルール、報酬分配 |
| サイドクエスト | [specs/side-quests.md](specs/side-quests.md) | GenAI Insights、SentinelOne、Best Team Name |
| 管理者機能 | [specs/admin.md](specs/admin.md) | ゲーム制御、チーム管理、妨害注入 |
| ダッシュボード | [specs/dashboards.md](specs/dashboards.md) | プレーヤー・管理者向けダッシュボード |
| 技術仕様 | [specs/technical.md](specs/technical.md) | インフラ構成、APIエンドポイント、デプロイ手順 |

---

## 未確認事項

| # | 項目 | 詳細 | 影響箇所 |
|---|------|------|---------|
| 10 | サイドクエスト順位ごとのポイント配分 | 1位=何pt、2位=何pt... の具体値は未確認 | スコアリングシステム |

---

## 変更履歴

- 2026-03-08: 初版作成（TODO多数 - ユーザーからの仕様確認待ち）
- 2026-03-08: 全面改訂 — PROMPT.md, AWS_GameDay文書, api.py, ユーザーヒアリング結果を反映
- 2026-03-08: スコアリング修正 — 「攻撃フェーズ」概念を廃止
- 2026-03-08: 仕様分割 — SPEC.md をポインタ化、詳細仕様を specs/ 配下に分割。TenkaCloud 統合に伴いプロトタイプコードを削除
