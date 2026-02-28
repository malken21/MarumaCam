# 技術仕様詳細

MarumaCamの映像生成プロセスの技術的な背景を説明します。

## 1. 4分割アトラスマッピング
通常の正距円筒図法（Equirectangular）を、独自の 4分割方式（Atlas Mapping）でRender Texture に書き込みます。
- **メリット**: テクスチャ領域を無駄なく利用し、低歪みで効率的なデータ保存が可能です。
- **実装**: `VR180-Format.shader` がこの変換プロセスを担当しています。

## 2. 解像度設定
デフォルトでは、高精細な撮影を目的とした Render Texture 解像度設定を行っています。
- **設定値**: 各分割領域 1440 x 1440 px
- **注意点**: 必要に応じてプロジェクトの負荷状況に合わせた解像度調整を行ってください。

## 3. シェーダー仕様
VR180 フォーマットに最適化されたシェーダー群を使用しています。
- `VR180-Format.shader`: 入力カメラ（左右）の映像をアトラス化。
- `VR180-Preview.shader`: アトラス化された映像を、プレビュー用に適した形式でデコードして表示。
- `BodySurface.shader`: カメラに描画されないように設定されたシェーダー。

## 4. プロジェクト構造
- 制御: Animator Controller (`MarumaCam.controller`)
- 同期: Modular Avatar (Parameters / Menu)
- 出力: Render Texture (Rethink resolution if performance is an issue)
