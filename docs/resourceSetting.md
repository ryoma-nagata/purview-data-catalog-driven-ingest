# リソースの初期設定

## 1. DBアクセス

### 1-1. AdventureWorksLT データベースのアクセス設定

AdventureWorksLTリソースに移動します。

![リソース概要]()

クエリエディターをAD認証でログインします。

![ログイン画面]]()

以下のSQLを実行します。

```sql

CREATE USER [<Data Factory リソース名>] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_datareader] ADD MEMBER [<Data Factory リソース名>];

CREATE USER [<Purview リソース名>] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_datareader] ADD MEMBER [<Purview リソース名>];

```

### 1-2. pipeline_meta データベースのアクセス設定

pipeline_metaリソースに移動します。

![リソース概要]()

クエリエディターをAD認証でログインします。

![ログイン画面]]()

以下のSQLを実行します。

```sql

CREATE USER [<Data Factory リソース名>] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_owner] ADD MEMBER [<Data Factory リソース名>];


```

## 2. Purviewカタログ設定

### 2-1. Azure SQL ソース登録

### 2-2. AdventureWorksLTデータベースのスキャン実行

### 2-3. 分類の作成


## 次の手順