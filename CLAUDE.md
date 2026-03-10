# GameDay Security Battle Royale

## リポジトリ構成

- このリポジトリ: プレーヤー向けコード + ゲーム仕様書
- 運営システム: https://github.com/susumutomita/TenkaCloud（gameday-service として統合）

## プレーヤー向けコード

- `api.py` — チーム側Flask API（脆弱性の参照元）
- `package.sh` — S3へのデプロイスクリプト

## 仕様書

- `platform/SPEC.md` — 仕様ポインタ（目次）
- `platform/specs/` — 詳細仕様
  - `scoring.md` — スコアリング
  - `game-flow.md` — ゲーム進行フロー
  - `attack-defense.md` — 攻撃・防御メカニクス
  - `alliance.md` — 同盟システム
  - `side-quests.md` — サイドクエスト
  - `admin.md` — 管理者機能
  - `dashboards.md` — ダッシュボード
  - `technical.md` — 技術仕様
- `platform/TENKACLOUD_INTEGRATION.md` — TenkaCloud 統合方針

## 参考資料

- `PROMPT.md` — ゲームルール/スコアリングの参考情報
- `AWS_GameDay_Security_Battle_Royale.md` — 実イベントの記録

## ルール

- 実装変更時は必ず `platform/SPEC.md` → `platform/specs/` の仕様に従うこと
- specs/ にない仕様は推測で実装せず、ユーザーに確認すること

# currentDate
Today's date is 2026-03-08.
