# Claude Code ⇄ Notion 連携ベストプラクティス（調査メモ）

本メモは「Claude Code セッションを Notion と連携させ、仕事を記録・継承する」ための設計判断と根拠をまとめる。
対象は Claude Code（CLI／Web クラウドセッション）。正本の運用規約は Notion（`00_AI運用ルール` 他）にあり、本リポはそのコード側の実装。

---

## 1. 連携の土台：Notion MCP コネクタ

Claude Code は **MCP（Model Context Protocol）サーバ**経由で外部サービスを読み書きする。Notion は公式のリモート MCP サーバ（`https://mcp.notion.com/mcp`）を提供しており、これを接続すると `notion-search` / `notion-fetch` / `notion-create-pages` / `notion-update-page` 等のツールが使える。

- **Web / claude.ai**: コネクタはアカウント設定（Settings → Connectors）で接続・OAuth 認可する。
- **CLI**: プロジェクトの `.mcp.json` にサーバを宣言し、初回に OAuth 認可する（`/mcp` で状態確認）。本リポは `.mcp.json` を同梱。

参考: Claude Code 公式ドキュメント（MCP）: https://code.claude.com/docs/en/mcp

### 判断
- リポに **`.mcp.json` を置く**ことで「このリポは Notion に依存する」ことを明示し、CLI セッションで自動的にサーバ候補になる。Web ではコネクタがアカウント側だが、依存の文書化として有用。
- ツール名は環境で `mcp__notion__*` / `mcp__Notion__*` と揺れるため、権限設定・スキルは両方を許容する。

---

## 2. プロトコルは「フック」でなく「CLAUDE.md＋スキル」で表現する

Claude Code の **hooks（`SessionStart` 等）はシェルコマンドを実行する仕組み**であり、MCP ツール（Notion 読み書き）を直接呼べない。したがって「起動時に Notion から文脈を読む」ような **MCP を伴う手順は、シェルフックではなく CLAUDE.md の指示＋スキルで表現する**のが正しい。

- **`CLAUDE.md`**: セッション開始時に自動で読み込まれるメモリファイル。ここに「起動時読込」「記録」「ルーティング」の規約を書くと、Claude Code が毎セッション従う。README の代わりではなく、**エージェントへの運用指示書**として簡潔に書く。
- **Skills（`.claude/skills/<name>/SKILL.md`）**: 手順を再利用可能な単位に切り出す。`/session-startup` 等でユーザーが明示起動でき、description に基づく自動発動もされる。SKILL.md は YAML frontmatter（`name` / `description`）＋本文（progressive disclosure）。
- **`SessionStart` フックの役割**: 環境準備（依存インストール等）と、**「起動時読込スキルを実行せよ」というリマインダ出力**に限定する。Notion 読込そのものはフックの外。

参考: Hooks: https://code.claude.com/docs/en/hooks ／ Skills（Agent Skills）: https://code.claude.com/docs/en/skills ／ Memory（CLAUDE.md）: https://code.claude.com/docs/en/memory

### 判断
- 起動時 Notion 読込 = `CLAUDE.md 第1節` ＋ `/session-startup` スキル。
- `SessionStart` フックは echo によるリマインダのみ（MCP を呼ばない）。

---

## 3. 書き込みは「承認ゲート」で保護する

Notion の知識ベースは正本であり、誤った自動書込は害が大きい。Claude Code の **permissions**（`.claude/settings.json`）で、
**読取り系ツールは `allow`（プロンプトなし）、書込系は `ask`（都度承認）** に分ける。

```jsonc
{
  "permissions": {
    "allow": ["mcp__notion__notion-search", "mcp__notion__notion-fetch", ...],
    "ask":   ["mcp__notion__notion-create-pages", "mcp__notion__notion-update-page", ...]
  }
}
```

参考: Settings / Permissions: https://code.claude.com/docs/en/settings ／ https://code.claude.com/docs/en/iam

### 判断
- 起動時読込・横断検索は摩擦なく走る。セッションログ記録など書込は必ずユーザー承認を経る。
- Notion 側規約 `00_AI運用ルール 第6節（透明性）`「サイレントで読み書きしない」とも整合する。

---

## 4. 記録の粒度：既存スキーマに合わせる

ユーザーは成熟した Notion スキーマ（`セッションログ` DB 他）を持つ。**新スキーマを作らず既存に合わせる**のが最重要。
`セッションログ` の必須フィールド（`タイトル`=日付＋主題 / `検討経緯` / `結論` / `次アクション` / `ステータス` / `前回との関係` / `日付`）と、
`関連Decisions`・`関連OPEN_ITEMS`・`関連資料`・`プロジェクト` リレーションを埋める。決定・未解決・資料は各 DB に**原子的**に登録して紐付ける。

### 判断
- スキルは既存フィールド名・ID をハードコードして参照ズレを防ぐ。ID は改称で変わり得るため、参照失敗時は `notion-search` で引き直す運用を明記。
- 「作成前重複チェック」（同日・同主題の既存レコード確認）を記録スキルに組み込む（Mistakes DB の教訓 SL-76 に対応）。

---

## 5. コスト効率化

Notion MCP のレスポンスは大きくなりがち。`00_AI運用ルール` の「コスト効率化A」に従い、
**`max_highlight_length=0`・`page_size≤5` を既定**にし、起動時の全文読込は「現在地サマリー」に限定する。

### 判断
- スキルと CLAUDE.md に既定値を明記。クラウドセッションのコンテキスト消費を抑える。

---

## 6. コードと知識のトレーサビリティ

本リポはコード作業の場でもある。**コミット/PR・生成物をセッションログの `関連資料` や `資料管理` DB に紐付ける**ことで、
「どのコード変更が、どの検討・決定に基づくか」を Notion 側から辿れるようにする。二重正本禁止（D-007）に従い、生記録は台帳・確定ルールのみ規約へ。

---

## 7. まとめ（このリポの設計）

| レイヤ | 手段 | 中身 |
|---|---|---|
| 依存宣言 | `.mcp.json` | Notion MCP サーバ |
| 運用指示書 | `CLAUDE.md` | 起動時読込・記録・ルーティング・透明性 |
| 手順の再利用 | `.claude/skills/` | session-startup / session-record / knowledge-search |
| 環境・摩擦制御 | `.claude/settings.json` | SessionStart リマインダ＋読取り許可/書込承認 |
| 調査 | 本メモ | 上記判断の根拠 |

**正本は Notion**。本リポは Claude Code をその運用規律に接続する薄い実装であり、規約が更新されたら Notion を追随して本リポを直す。

---

### 参照ドキュメント（Claude Code 公式）
- MCP: https://code.claude.com/docs/en/mcp
- Memory / CLAUDE.md: https://code.claude.com/docs/en/memory
- Skills: https://code.claude.com/docs/en/skills
- Hooks: https://code.claude.com/docs/en/hooks
- Settings: https://code.claude.com/docs/en/settings
- Claude Code on the web: https://code.claude.com/docs/en/claude-code-on-the-web
