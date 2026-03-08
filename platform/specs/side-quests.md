# サイドクエスト

> [SPEC.md](../SPEC.md) > サイドクエスト

---

## サイドクエストのスコアリング（確定）

- サイドクエストは **アンロック（開始）してから全タスク完了までの経過時間** で順位がつく
- **1位ほど多くのポイント** を獲得できる（タイムアタック方式）
- つまりポイントは固定値ではなく、完了順位に基づく相対評価

<!-- TODO: 順位ごとのポイント配分（1位=何pt、2位=何pt...）の具体値は未確認。仮仕様で設計する -->

## Generative AI Insights

- **難易度**: 100レベル
- **想定時間**: 45分
- **ユースケース**: Generative AI
- **概要**: GenAIツールを活用してGameDayの戦略情報を強化する

**タスク一覧（順番に達成）:**

1. **MCPサーバーのツール一覧を発見する**
   - MCPサーバーURL: `https://tgoh1f9cb7.execute-api.us-east-1.amazonaws.com/prod/mcp`
   - MCPプロトコルに従ってツール一覧取得APIを呼び出す
   - 正解: 正しいMCPツールを特定（自動採点）

2. **チャットボットにMCPサーバーを接続する**
   - チャットボットURL: `http://gameday-chatbot-alb-796284871.us-east-1.elb.amazonaws.com`
   - ECSタスクの環境変数 `MCP_SERVER_URL` に `https://` 付きのMCPサーバーURLをセット

3. **Bedrock Knowledge Baseを作成してゲームルールを登録**
   - ゲームルールが書かれたファイルをKnowledge Baseにアップロード
   - 自動採点でKBの存在を確認（数分かかる）

4. **MCPサーバーのコードに `query_knowledgebase` ツールを追加**
   - MCPサーバーのコードを特定しTODOコメントを実装
   - Bedrock Knowledge Base IDを環境変数にセット

5. **チャットボットを実際に活用する（自動完了）**
   - チャットボットを戦略立案に活用する
   - コードの改善も可能（S3からDL → 編集 → アップロードで自動再デプロイ）

## AI-Powered Cloud Security with SentinelOne

- **難易度**: 100レベル
- **想定時間**: 60分
- **ユースケース**: Cybersecurity / Incident Response
- **使用サービス**: SentinelOne, Amazon EC2/S3/IAM, CloudTrail, Security Hub
- **概要**: SentinelOne Singularity Operations Centerを使ってAWSクラウドのセキュリティインシデントを調査・対応する

**タスク一覧（順番に達成）:**

1. **SentinelOneコンソールアクセス確認** — SSO経由でログイン、サイトIDを回答
2. **クラウドポスチャースキャン** — S3バケットの「Block Public Access not Enabled」誤設定を特定
3. **EKSクラスターの露出分析** — `purple-cluster` のExposure数を回答
4. **IAMロールの特定** — 高権限ノードロールARNを回答
5. **初期脆弱性の手動修正** — EKSロギング有効化、エンドポイントプライベート化、S3パブリックアクセスブロック、ポリシー最小権限化
6. **Hyperautomationで大規模ネットワーク修正** — `purple-sg*` セキュリティグループの一括修正
7. **Purple AI入門** — 最多イベントタイプを回答
8. **脅威検出** — `evil.sh` プロセスを特定
9. **脅威の緩和と解決** — Mitigate でプロセス隔離、アラート解決
10. **脅威の根絶** — S3から `evil.sh` 削除、`node_bootstrap.sh` 復元
11. **IMDSv2への移行** — ノードのIMDSをv2に変更
12. **攻撃タイムライン調査** — `HAXORSAURUS` ユーザーと `haxorsaurus_backdoor` Lambda関数を特定
13. **AI SIEM調査** — `HAXORSAURUS` のBedrock関連イベントを確認
14. **バックドアの削除** — IAMユーザーとLambda関数を削除
15. **AIインフラのアセスメントと修正** — `HaxorsaurusEgress` の露出確認、不正Bedrockエージェント削除

## Best Team Name（ツールクエスト）

- **難易度**: 100レベル
- **想定時間**: 5分
- **概要**: Scoreboardで全チームのチーム名を見て、お気に出りのチーム名に投票する
- 自チーム名には投票不可
- 最多得票チーム: **+10,000pt**
- 投票した全チーム: **+5,000pt**
