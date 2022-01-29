## Azure SQL

### DBアクセス
```sql

CREATE USER [rypv-syn-001] FROM EXTERNAL PROVIDER
ALTER ROLE [db_datareader] ADD MEMBER [rypv-syn-001] 

```

## Purview

### ソース

### スキャン

### 分類

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fryoma-nagata%2Fpurview-data-catalog-driven-ingest%2Fmaster%2Finfra%2Fmain.json)