# Claude Code ⇄ Notion「AI外部脳」連携ワークスペース

Claude Code のセッションを、既存の Notion 知識体系（**FBSC ナレッジベース｜AI外部脳**）に接続し、
**コード作業を含む「仕事のことすべて」をセッションを跨いで記録・継承する**ためのリポジトリ。

チャット型 AI 用に設計された運用ルール（`00_AI運用ルール` / Personal preferences / Project Charter）を、
**Claude Code（CLI／Web クラウドセッション）も同じ規律で運用できるようにする**のが目的。

---

## 何が起きるか（ループの仕組み）

```
セッション開始 ── 起動時読込(7-14) ──▶ Notion から前回の文脈・既存知見を読む
     │                                  （セッションログ最新3件 / Mistakes / MASTER_KNOWLEDGE / 索引）
     ▼
   コード作業・調査・意思決定（Claude Code）
     │
     ▼
一段落 ── 記録(「整理して」) ──▶ セッションログ DB に1件追記（承認後）
                               決定→Decisions / 未解決→OPEN_ITEMS / 成果物→資料管理 を原子的に紐付け
                               プロジェクトの「現在地サマリー」を更新
```

**正本は Notion**。本リポの `CLAUDE.md` はその**コード側の入口（要約）**であり、矛盾時は Notion を優先する（二重正本を作らない）。

---

## 構成

```text
.
├── CLAUDE.md                 # 中核。起動時読込・記録・ルーティング規約（Claude Code が自動読込）
├── .mcp.json                 # Notion MCP サーバ（notion）のプロジェクト宣言
├── .claude/
│   ├── settings.json         # SessionStart フック＋権限（Notion 読取り=許可 / 書込=承認）
│   └── skills/
│       ├── session-startup/  # /session-startup … 起動時読込（読取りのみ）
│       ├── session-record/   # /session-record  … セッションログ記録（＝「整理して」／書込は承認後）
│       └── knowledge-search/ # /knowledge-search … 横断検索（7-1b）
├── docs/
│   └── CLAUDE_CODE_NOTION_INTEGRATION.md  # ベストプラクティス調査メモ
├── scripts/
│   └── init-repo.sh          # 独立 GitHub リポとして初期化する手順スクリプト
└── .gitignore
```

---

## 前提：Notion コネクタ

Claude Code から Notion を読み書きするには **Notion の MCP コネクタ**が必要。

- **Claude Code on the web / claude.ai**: コネクタ設定（Settings → Connectors）で **Notion** を接続・認可する（アカウント単位）。
- **Claude Code CLI**: `.mcp.json`（本リポ同梱）でプロジェクトに宣言済み。初回は OAuth 認可が必要（`/mcp` で状態確認）。

接続後、`00_AI運用ルール`・`セッションログ` などが読み書きできる。ツール名は環境により `mcp__notion__*` または `mcp__Notion__*`。

---

## 使い方

1. このリポで Claude Code セッションを開始する（`CLAUDE.md` が自動で読み込まれる）。
2. 冒頭で **`/session-startup`** を実行 → 前回の文脈・既存知見が要約される。
3. 通常どおりコード作業・相談を進める。新論点の前に **`/knowledge-search`** で既存知見を引く。
4. 一段落したら **`/session-record`**（または「整理して」）→ セッションログに記録（**書込はユーザー承認後**）。

> 安全設計：Notion への**読み込みは随時**、**書き込みは権限プロンプトで承認後**（`.claude/settings.json` の `ask`）。知識ベースを不用意に汚さない。

---

## 独立リポジトリ化

現在このスキャフォールドは親リポのサブフォルダとして生成されている。独立した GitHub リポにするには:

```bash
bash scripts/init-repo.sh    # 手順を表示（git init → commit → 新規リポ作成 → push）
```

詳細は [`scripts/init-repo.sh`](./scripts/init-repo.sh) を参照。

---

## 関連（Notion 側の正本）

- `00_AI運用ルール（このページを最初に読む）` — 運用規約の正本
- `Personal preferences保管ページ` — 個人の好み・番号ルール（7-x）
- `Project Governance／Project Charter v1.0` — ガバナンス
- `学び・ナレッジ所在マップ` — 知見の所在索引（横断参照の入口）

ID 一覧は [`CLAUDE.md` 第8節](./CLAUDE.md) を参照。
