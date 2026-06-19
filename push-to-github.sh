#!/bin/bash
# MorningInsight — Auto push + Thai TTS podcast generator
# Runs on Mac: generates podcast.mp3 via edge-tts then pushes everything to GitHub

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Token is read from environment variable GITHUB_TOKEN (never hardcode here)
# Set it in your shell before running: export GITHUB_TOKEN="ghp_..."
# Or store it in ~/.morninginsight_token (gitignored) and it will be loaded below.
if [ -z "$GITHUB_TOKEN" ]; then
  # 1. Try Mac home folder token file
  if [ -f "$HOME/.morninginsight_token" ]; then
    GITHUB_TOKEN="$(cat "$HOME/.morninginsight_token")"
  # 2. Try token file next to this script (works from Cowork sandbox)
  elif [ -f "$REPO_DIR/.morninginsight_token" ]; then
    GITHUB_TOKEN="$(cat "$REPO_DIR/.morninginsight_token")"
  # 3. Try parsing github-config.txt in the same folder
  elif [ -f "$REPO_DIR/github-config.txt" ]; then
    GITHUB_TOKEN="$(grep -E '^GITHUB_TOKEN=' "$REPO_DIR/github-config.txt" | cut -d= -f2 | tr -d '[:space:]')"
    if [ "$GITHUB_TOKEN" = "YOUR_TOKEN_HERE" ] || [ -z "$GITHUB_TOKEN" ]; then
      GITHUB_TOKEN=""
    fi
  fi
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ GITHUB_TOKEN is not set. Try one of:"
  echo "   a) Save token to: ~/.morninginsight_token"
  echo "   b) Save token to: $REPO_DIR/.morninginsight_token"
  echo "   c) Edit github-config.txt and set GITHUB_TOKEN=ghp_yourtoken"
  exit 1
fi
TOKEN="$GITHUB_TOKEN"
REPO="picnicwi/mymorning"
BRANCH="main"
USER_NAME="picnicwi"
USER_EMAIL="bizzpicnic@gmail.com"
VOICE="th-TH-NiwatNeural"   # Natural Thai male voice

cd "$REPO_DIR" || exit 1
echo "📁 Working in: $REPO_DIR"

# ── Step 1: Generate podcast.mp3 from podcast-script.txt ──────────────────
if [ -f "podcast-script.txt" ]; then
  echo ""
  echo "🎙️  Generating Thai podcast audio (NiwatNeural male voice)..."

  # Install edge-tts if not present
  if ! command -v edge-tts &>/dev/null; then
    echo "  📦 Installing edge-tts..."
    pip3 install edge-tts -q && echo "  ✓ edge-tts installed" || {
      echo "  ❌ Failed to install edge-tts. Run: pip3 install edge-tts"
      echo "  ⚠️  Skipping audio generation — pushing other files only"
    }
  fi

  # Generate MP3
  if command -v edge-tts &>/dev/null; then
    edge-tts \
      --voice "$VOICE" \
      --file "podcast-script.txt" \
      --write-media "podcast.mp3" \
      --write-subtitles "podcast.vtt" 2>/dev/null

    if [ -f "podcast.mp3" ]; then
      SIZE=$(du -sh podcast.mp3 | cut -f1)
      echo "  ✅ podcast.mp3 generated ($SIZE)"
    else
      echo "  ❌ edge-tts ran but podcast.mp3 not found — check network connection"
    fi
  fi
else
  echo "  ⚠️  podcast-script.txt not found — skipping audio generation"
fi

# ── Step 2: Git push ───────────────────────────────────────────────────────
echo ""
echo "🔧 Configuring git..."
git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"
git remote set-url origin "https://${TOKEN}@github.com/${REPO}.git"

# Clear ALL stale lock files
rm -f .git/index.lock .git/HEAD.lock .git/MERGE_HEAD .git/COMMIT_EDITMSG.lock 2>/dev/null || true

# Fetch latest
git fetch origin $BRANCH 2>/dev/null || true

# Stage all deliverables
echo "📄 Staging files..."
for file in index.html podcast.html podcast.mp3 podcast-script.txt; do
  if [ -f "$file" ]; then
    git add "$file"
    echo "  ✓ $file"
  fi
done

git status --short

# Commit
DATE=$(date '+%Y-%m-%d')
if git diff --cached --quiet; then
  echo "ℹ️  Nothing new to commit"
else
  git commit -m "chore: daily AI news update $DATE"
  echo "✅ Committed"
fi

# Push
echo ""
echo "🚀 Pushing to GitHub..."
git push origin $BRANCH \
  && echo "✅ Pushed successfully → https://picnicwi.github.io/mymorning/" \
  || echo "❌ Push failed — check token or network"
