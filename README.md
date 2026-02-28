# MarumaCam

UnityおよびVRChat向けのVR180立体視映像表示システムです。

## 概要

独自の4分割アトラスマッピング技術を用いて、高解像度かつ低歪みなVR180映像を表示します。

## ディレクトリ構成

プロジェクトの主要ファイルは `Assets/Marumasa/MarumaVR180` 配下に格納されています。

- `Shaders/`: 映像投影・制御用シェーダー（`VR180-Camera.shader` 等）
- `RenderTextures/`: 映像ソース用RenderTexture
- `Prefabs/`: セットアップ済みプレハブ
- `Animation/`: 制御用アニメーションクリップ
