# Generate Release Notes

Git タグ間のコミット・PR 一覧からリリースノートを生成する GitHub Action です。

## 生成されるリリースノートの構成

```
<タグの説明文>

<details><summary>コミットログ（クリックで展開）</summary>

- <コミットメッセージ> (<ハッシュ>) by <作者>
...

</details>

<details><summary>取り込んだプルリクエスト一覧（クリックで展開）</summary>

- [#123](https://github.com/org/repo/pull/123) PR タイトル by @user
...

</details>
```

## Inputs

| Name | Required | Description |
|------|----------|-------------|
| `tag` | Yes | リリースノートを生成するタグ名 (例: `v1.2.3`) |
| `token` | Yes | GitHub トークン (PR 情報取得に使用) |

## Outputs

| Name | Description |
|------|-------------|
| `notes-file` | 生成されたリリースノートのファイルパス (常に `RELEASE_NOTES.md`) |

## 使用例

### タグプッシュ時に GitHub Release を作成する

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v6

      - uses: u0reo/generate-release-notes@v1
        id: notes
        with:
          tag: ${{ github.ref_name }}
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: softprops/action-gh-release@v2
        with:
          body_path: ${{ steps.notes.outputs.notes-file }}
```

### update-version と組み合わせる

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: リリースバージョン (x.y.z)
        required: true
        type: string
      description:
        description: タグ/コミットメッセージに使用する説明文
        required: true
        type: string

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v6

      - uses: u0reo/update-version@v1
        id: ver
        with:
          version: ${{ github.event.inputs.version }}
          description: ${{ github.event.inputs.description }}

      - uses: u0reo/generate-release-notes@v1
        id: notes
        with:
          tag: ${{ steps.ver.outputs.tag }}
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ steps.ver.outputs.tag }}
          body_path: ${{ steps.notes.outputs.notes-file }}
```

## 必要な権限

- `contents: write` — GitHub Release の作成に必要

## 前提条件

- `jq` がインストールされていること
- `curl` が利用可能であること
