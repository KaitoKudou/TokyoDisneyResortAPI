# TokyoDisneyResortAPI

💧 東京ディズニーリゾートのアトラクションとグリーティング情報を提供するAPIサーバー、Vapor Webフレームワークで構築されています。

## 概要

このAPIは東京ディズニーランドと東京ディズニーシーの以下の情報を提供します：

- アトラクション情報（待ち時間、運営状況など）
- グリーティング情報（キャラクター、開催時間など）

データはスクレイピングとTDRの公式JSONエンドポイントから取得され、キャッシュやエラーハンドリングを含む堅牢なアーキテクチャで提供されています。

## 主なエンドポイント

- `GET /tokyo_disney_resort/:parkType/attraction` - TDL/TDSのアトラクション情報を取得
- `GET /tokyo_disney_resort/:parkType/greeting` - TDL/TDSのグリーティング情報を取得

`:parkType`には`tdl`（東京ディズニーランド）または`tds`（東京ディズニーシー）を指定します。

## アーキテクチャ

このプロジェクトはクリーンアーキテクチャに基づいて設計され、関心事の分離とテスト容易性を重視しています。

### レポジトリ層

- `FacilityRepository` - アトラクションとグリーティングの共通リポジトリインターフェース
  - 共通のキャッシュロジックや施設タイプの抽象化を提供
- `AttractionRepository` - アトラクション情報の取得と管理を担当
- `GreetingRepository` - グリーティング情報の取得と管理を担当

### APIクライアント層

- `TokyoDisneyResortClient` - ディズニーリゾートのWebサイトからデータを取得
  - リトライロジックと強化されたエラーハンドリングを含む
- `APIFetcher` - 汎用的なデータフェッチロジックを提供
- `TokyoDisneyResortRequest` - リクエストの構築
- `FacilityHTMLParser` - HTML解析の共通インターフェース
  - `AttractionHTMLParser` - アトラクション情報のHTML解析
  - `GreetingHTMLParser` - グリーティング情報のHTML解析

### データモデル

- `Attraction` - アトラクション情報のデータモデル
- `Greeting` - グリーティング情報のデータモデル

### コントローラ層

- `TokyoDisneyResortController` - HTTPリクエストを処理し、リポジトリからのデータをJSONレスポンスに変換

### データストア

- `CacheStoreProtocol` - キャッシュのインターフェース
- `VaporCacheStore` - Vaporを利用したキャッシュ実装

## 始め方

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
