# セットアップガイド

MarumaCamをVRChatアバターへ導入する手順を説明します。

## 前提条件
- VRChat SDK - Avatars (3.0以上)
- [Modular Avatar](https://modular-avatar.nadena.dev/ja/) が導入されていること。

## 導入手順
1. **プロジェクトへのインポート**:
   - `Assets/Marumasa/MarumaCam` ディレクトリ一式をプロジェクトに配置してください。

2. **プレハブの配置**:
   - `Assets/Marumasa/MarumaCam/MarumaCam.prefab` を、アバターのルート（最上階層）にドラッグ＆ドロップしてください。
   - 位置や向きは必要に応じて微調整してください。

3. **Modular Avatarの同期**:
   - プレハブには必要な Modular Avatar コンポーネントが設定済みです。アップロード時に Animator Controller への自動統合が行われます。

4. **アバターのアップロード**:
   - 通常の手順でアバターを VRChat へアップロードしてください。

## トラブルシューティング
- **メニューが表示されない**: アバターの直下に正しく配置されているか、アバターの `VRC Avatar Descriptor` が正しく設定されているか確認してください。
- **映像が乱れる**: 依存する Render Texture や Shader が正しく参照されているか確認してください。
