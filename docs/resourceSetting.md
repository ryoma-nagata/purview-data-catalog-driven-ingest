# リソースの初期設定

## 1. DBアクセス

### 1-1. AdventureWorksLT データベースのアクセス設定

AdventureWorksLTリソースに移動し、クエリエディターをAD認証でログインします。

![ログイン画面](.image/2022-01-29-22-55-16.png)

以下のSQLを実行します。

```sql

CREATE USER [<Data Factory リソース名>] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_datareader] ADD MEMBER [<Data Factory リソース名>];

CREATE USER [<Purview リソース名>] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_datareader] ADD MEMBER [<Purview リソース名>];

```

### 1-2. pipeline_meta データベースのアクセス設定

pipeline_metaリソースに移動し、クエリエディターをAD認証でログインします。

![ログイン画面](.image/2022-01-29-22-48-41.png)

以下のSQLを実行します。

```sql

CREATE USER [<Data Factory リソース名>] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_owner] ADD MEMBER [<Data Factory リソース名>];


```

## 2. Purviewカタログ設定

https://web.purview.azure.com/ から、Purviewリソースを選択し、Purview Studioに移動します。

![](.image/2022-01-29-23-07-44.png)


### 2-1. Azure SQL ソース登録

1. 「Data Map」に移動し、「Register」を選択します。

![](.image/2022-01-29-23-15-33.png)

2. 「Azure SQL Database」を選択します。

![](.image/2022-01-29-23-16-56.png)

3. 作成したSQL Serverのリソースを選択し、「Register」をクリックします。

![](.image/2022-01-29-23-23-30.png)


### 2-2. AdventureWorksLTデータベースのスキャン実行

1. 「New Scan」をクリックします。

![](.image/2022-01-29-23-26-02.png)

2. 「AdventureWorksLT」を選択し、「Continue」をクリックします。

![](.image/2022-01-29-23-27-16.png)

3. 「Continue」をクリックします。

![](.image/2022-01-29-23-29-31.png)

4. 「Continue」をクリックします。

![](.image/2022-01-29-23-30-04.png)

5. 「Once」を選択し、「Continue」をクリックします。

![](.image/2022-01-29-23-30-41.png)

6. 「Save and run」をクリックします。

![](.image/2022-01-29-23-31-38.png)

### 2-3. 分類の作成

1. 「Data Map」に移動し、「Classifications」→「＋New」の順にクリックします。

![](.image/2022-01-29-23-36-13.png)

2. 「Name」に`MetadataDrivenCopyTask_0mc_TopLevel`を設定し、「OK」をクリックします。

![](.image/2022-01-29-23-38-42.png)

### 2-4. Data Factoryリソースへの権限割り当て

1. 「Data Map」に移動し、「Collections」→「Role assignments」→「Data Curator」にてData Factoryリソースを追加します。

![](.image/2022-01-30-00-13-04.png)

2. 「Data Reader」にてData Factoryリソースを追加します。

![](.image/2022-01-30-00-14-59.png)

## 次の手順

[メタデータの登録と取り込みパイプラインの実行](executePipeline.md)