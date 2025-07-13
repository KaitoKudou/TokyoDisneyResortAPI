# TokyoDisneyResortAPI

💧 東京ディズニーリゾートのアトラクション、グリーティング、レストラン情報を提供するAPIサーバー、Vapor Webフレームワークとクリーンアーキテクチャで構築されています。

## 概要

このAPIは東京ディズニーランドと東京ディズニーシーの以下の情報をリアルタイムで提供します：

- アトラクション情報（待ち時間、運営状況、運営時間など）
- グリーティング情報（キャラクター、開催場所、待ち時間、開催時間など）
- レストラン情報（エリア、営業時間、予約URL、ポップコーンフレーバー、アイコンタグなど）

## 主なエンドポイント

- `GET /v1/{parkType}/attraction` - TDL/TDSのアトラクション情報を取得
- `GET /v1/{parkType}/greeting` - TDL/TDSのグリーティング情報を取得
- `GET /v1/{parkType}/restaurant` - TDL/TDSのレストラン情報を取得

`{parkType}`には`tdl`（東京ディズニーランド）または`tds`（東京ディズニーシー）を指定します。

各エンドポイントはOpenAPI仕様に準拠しており、`/Public/openapi.html`でインタラクティブなドキュメントが利用可能です。また、OpenAPIの詳細な仕様は`/Public/openapi.yaml`で確認できます。

## レスポンス例

### アトラクション情報

```json
[
    {
        "operatingHoursFrom": "9:00",
        "imageURL": "https://media1.tokyodisneyresort.jp/images/adventure/attraction/121_thum_name.jpg?mod=20240822144716",
        "facilityID": "227",
        "detailURL": "/tds/attraction/detail/227/",
        "iconTags": [
            "ライド/移動・周遊"
        ],
        "operatingStatus": "案内終了",
        "operatingHoursTo": "18:30",
        "updateTime": "18:23",
        "area": "メディテレーニアンハーバー",
        "name": "ディズニーシー・トランジットスチーマーライン"
    }
]
```

### グリーティング情報

```json
[
    {
        "character": "シェリーメイ",
        "area": "アメリカンウォーターフロント",
        "name": "ヴィレッジ・グリーティングプレイス",
        "facilityID": "905",
        "facilityName": "ヴィレッジ・グリーティングプレイス",
        "imageURL": "https://media1.tokyodisneyresort.jp/images/adventure/greeting/31_thum_name.jpg?mod=20231101102750",
        "useStandbyTimeStyle": false,
        "updateTime": "19:26",
        "operatinghours": [
            {
                "operatingHoursFrom": "9:30",
                "operatingHoursTo": "20:00",
                "operatingStatus": "案内終了"
            }
        ]
    }
]
```

### レストラン情報

```json
[
    {
        "area": "メディテレーニアンハーバー",
        "detailURL": "/tds/restaurant/detail/400/",
        "facilityID": "425",
        "operatingHours": [
            {
                "operatingHoursTo": "19:30",
                "operatingHoursFrom": "11:00",
                "operatingStatus": "案内終了"
            }
        ],
        "imageURL": "https://media1.tokyodisneyresort.jp/images/adventure/restaurant/522_thum_name.jpg?mod=20250218111452",
        "name": "カフェ・ポルトフィーノ",
        "iconTags": [],
        "useStandbyTimeStyle": false,
        "updateTime": "19:30"
    },
    {
        "area": "ワールドバザール",
        "name": "ポップコーンワゴン",
        "popCornFlavor": "キャラメル",
        "iconTags": [],
        "imageURL": "https://media1.tokyodisneyresort.jp/images/adventure/restaurant/101_thum_name.jpg?mod=20240101120000",
        "detailURL": "/tdl/restaurant/detail/101/",
        "facilityID": "101",
        "operatingHours": [
            {
                "operatingHoursFrom": "9:00",
                "operatingHoursTo": "22:00",
                "operatingStatus": "営業中"
            }
        ],
        "updateTime": "11:45"
    }
]
```

各エンドポイントは最新データを提供し、キャッシュメカニズムにより高速なレスポンスを実現しています。

## アーキテクチャ

このプロジェクトはクリーンアーキテクチャに基づいて設計され、関心事の分離とテスト容易性を重視しています。

### レポジトリ層

- `RepositoryProtocol` - すべてのリポジトリの基本インターフェース
- `CacheableEntity` - キャッシュ可能なエンティティを定義するプロトコル
- `AttractionRepository` - アトラクション情報の取得と管理を担当
- `GreetingRepository` - グリーティング情報の取得と管理を担当
- `RestaurantRepository` - レストラン情報の取得と管理を担当

### API層

API層は以下の主要コンポーネントで構成されています：

#### APIクライアント

- `TokyoDisneyResortClient` - ディズニーリゾートのWebサイト、APIからデータを取得
- `APIFetcher` - 汎用的なデータフェッチロジックを提供
- `TokyoDisneyResortRequest` - リクエストの構築と設定
- `TokyoDisneyResortRequestBuilder` - URLリクエストの構築

#### パーサー層

- `FacilityHTMLParser` - HTML解析の共通インターフェース
- `FacilityErrorResolvable` - 施設タイプに応じたエラー解決プロトコル
- 具体的な実装：
  - `AttractionHTMLParser` - アトラクション情報のHTML解析
  - `GreetingHTMLParser` - グリーティング情報のHTML解析
  - `RestaurantHTMLParser` - レストラン情報のHTML解析

#### データマッパー

- `AttractionDataMapper` - 取得データからアトラクションモデルへの変換
- `GreetingDataMapper` - 取得データからグリーティングモデルへの変換
- `RestaurantDataMapper` - 取得データからレストランモデルへの変換

### データモデル

- `Attraction` - アトラクション情報のデータモデル
- `Greeting` - グリーティング情報のデータモデル
- `Restaurant` - レストラン情報のデータモデル

### コントローラ層

- `OpenAPIController` - OpenAPI仕様に準拠したエンドポイント処理を担当

### データストア

- `CacheStoreProtocol` - キャッシュ操作のインターフェース
- `CacheStoreDependency` - キャッシュストアの依存関係を注入するためのプロトコル
- `VaporCacheStore` - Vaporのキャッシュシステムを利用した実装

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
