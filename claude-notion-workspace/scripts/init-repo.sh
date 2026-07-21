#!/usr/bin/env bash
#
# init-repo.sh — このスキャフォールドを独立した GitHub リポジトリとして初期化する手順ガイド。
#
# 現在このフォルダ（claude-notion-workspace/）は親リポのサブフォルダとして存在する。
# 独立リポにするには、このフォルダを別の場所へコピーしてから以下を実行する。
# 破壊的操作は行わず、実行すべきコマンドを表示する（安全側）。
#
set -euo pipefail

REPO_NAME="${1:-claude-notion-workspace}"

cat <<EOF
========================================================================
 ${REPO_NAME} を独立 GitHub リポジトリとして初期化する手順
========================================================================

前提: このフォルダ（claude-notion-workspace/）を、親リポの外の空ディレクトリへコピー済みであること。
      例) cp -r claude-notion-workspace ~/work/${REPO_NAME} && cd ~/work/${REPO_NAME}

1) ローカル git を初期化してコミット:

     git init
     git add .
     git commit -m "chore: Claude Code x Notion 連携ワークスペース 初期化"

2) GitHub にリポジトリを作成して push（いずれか）:

   [A] gh CLI を使う場合:
     gh repo create ${REPO_NAME} --private --source=. --remote=origin --push

   [B] 手動で作る場合:
     # 1. https://github.com/new で空リポ ${REPO_NAME} を作成（README なし）
     # 2. 以下を実行
     git branch -M main
     git remote add origin git@github.com:<YOUR_ACCOUNT>/${REPO_NAME}.git
     git push -u origin main

3) Notion コネクタを接続:
     - Claude Code on the web: Settings → Connectors → Notion を接続・認可
     - CLI: リポ内で /mcp を実行し notion サーバを認可（.mcp.json は同梱済み）

4) 動作確認:
     - リポで Claude Code セッションを開始（CLAUDE.md が自動読込）
     - /session-startup を実行し、Notion から前回文脈が読めることを確認

========================================================================
 注意: セッションログ等 Notion への書き込みは権限プロンプト（承認）を経る設計です。
========================================================================
EOF
