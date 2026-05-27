#!/bin/sh -e

# 事前にタグをフェッチ
git fetch --tags --force

repo="${GITHUB_REPOSITORY}"
current="$TAG"
prev="$(git tag --sort=version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | awk -v curr="$current" '{if ($0==curr) {print prev} prev=$0}')"

echo "Current tag: $current"
echo "Previous tag: ${prev:-none}"

desc="$(git tag -l --format='%(subject)' "$current")"
echo "Tag description: $desc"

range="${prev:+$prev..}$current"
pr_numbers=$(git log "$range" --pretty=format:'%s' \
  | sed -n 's/^Merge pull request #\([0-9]\+\).*/\1/p; s/.*(#\([0-9]\+\)).*/\1/p' \
  | sort -n | uniq)

{
  echo "$desc"
  echo
  echo '<details><summary>コミットログ（クリックで展開）</summary>'
  echo
  git log "$range" --pretty=tformat:'- %s (%h) by %an%w(0,2,2)%+b'
  echo
  echo '</details>'
  echo
  echo '<details><summary>取り込んだプルリクエスト一覧（クリックで展開）</summary>'
  echo
  if [ -n "$pr_numbers" ]; then
    for num in $pr_numbers; do
      if [ -z "$num" ]; then continue; fi

      pr_json=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" "${GITHUB_API_URL}/repos/${repo}/pulls/${num}")
      title=$(echo "$pr_json" | jq -r '.title // empty')
      user=$(echo "$pr_json" | jq -r '.user.login // empty')

      echo "- [#${num}](${GITHUB_SERVER_URL}/${repo}/pull/${num}) ${title:-（タイトル取得失敗）} by @${user:-unknown}"
    done
  else
    echo '- 該当するプルリクエストはありません'
  fi
  echo
  echo '</details>'
} > RELEASE_NOTES.md

echo
echo "Generated RELEASE_NOTES.md:"
cat RELEASE_NOTES.md

echo "notes-file=RELEASE_NOTES.md" >> "$GITHUB_OUTPUT"
