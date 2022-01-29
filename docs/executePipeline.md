# メタデータの登録と取り込みパイプラインの実行

## 1. 対象テーブルの設定

1. https://web.purview.azure.com/ から、Purviewリソースを選択し、Purview Studioに移動します。

![](.image/2022-01-29-23-07-44.png)

2. カタログ欄で`sql table`を入力して検索します。

![](.image/2022-01-29-23-48-38.png)

3. 任意のテーブルを選択して、「View Selected」をクリックします。
![](.image/2022-01-29-23-49-47.png)

4.「Bulk edit」をクリックします。

![](.image/2022-01-29-23-50-29.png)

5. 「Attribute」に`Classification`、「Operation」に`Add`、「New Value」に`MetadataDrivenCopyTask_0mc_TopLevel` を設定し、「Apply」をクリックします。

![](.image/2022-01-29-23-51-24.png)

## 2. パイプラインの実行



### 2-1. メタデータ登録パイプラインの実行
1. https://adf.azure.com/に移動して、Data Factoryリソースを選択し、Purview Studioに移動します。

![](.image/2022-01-29-23-54-17.png)

2. 「作成者」→パイプライン内の「InsertFromPurviewMetadataomc2」→「トリガーの追加」→「今すぐトリガー」の順にクリックします。

![パイプライン画面](.image/2022-01-29-23-56-26.png)

3. Purviewのリソース名をパラメータ「purviewName」に設定します。

![](.image/2022-01-29-23-58-35.png)

各パラメータの説明

| パラメータ                         | 説明                                                                                                  | 備考   |
|-------------------------------|-----------------------------------------------------------------------------------------------------|------|
| purviewName                   | 連携設定をしたPurviewリソース名                                                                                 |      |
| MetadataDrivenCopyTaskTopName | メタデータ駆動取り込みパイプラインの名称。取り込み対象テーブル情報を制御テーブルに挿入する際、この値が付与され、取り込みパイプラインは自身の名称で制御テーブルから取り込み対象テーブルを絞り込みます。 |      |
| MainControlTableName          | 制御テーブル名                                                                                             |      |
| rootFolderPath                | 取り込み先のルートフォルダ                                                                                       | 変更可能 |
| fileSystemName                | 取り込み先のストレージファイルシステム                                                                                 |


4. 実行完了後、制御テーブルに対象のテーブルの情報が登録されます。

![](.image/2022-01-30-00-17-02.png)

### 2-2. メタデータ駆動インジェストパイプラインの実行

1. 「MetadataDrivenCopyTask_0mc_`TopLevel`」→「トリガーの追加」→今すぐトリガーをクリックします。

![パイプライン画面](.image/2022-01-30-00-17-55.png)

2. このまま実行します;

![](.image/2022-01-30-00-20-25.png)

各パイプラインの詳細は[データのコピー ツール (プレビュー) でメタデータ駆動型の方法を使用して大規模なデータ コピー パイプラインを作成する](https://docs.microsoft.com/ja-jp/azure/data-factory/copy-data-tool-metadata-driven)を参照ください。

3. データレイクにデータが登録されたことを確認します。

![データレイク画面](.image/2022-01-30-00-34-02.png)