# Packed Value Table Download

## How it works

1. Our client app connects to our servers using _streaming_ http/2 and requests a table to download. In the request we have the tablename, the list of requested columns and the customer_id.

2. We select from the table, get the rows, then pack the values, then we respond to the client app with the encoded data.

3. The client received the data, decodes the packed values and copies that data straight into sqlite.

## What we need to do for this project

Using Postgrex, we get the get data from a table with the specific requested columns. We then encode each column and return that.

For the http server, we will be using Bandit.

### Making a request

The URL for getting a table is simple. The tablename is the last component of the URI address.

```
http://127.0.0.1:3000/table/customers
```

The columns is a comma separated list of column names joined by a comma (no spaces). For example: `_rowid,firstname,lastname`. This is in the _query item_ of name `columns` in the URI.

```
http://127.0.0.1:3000/table/customers?columns=_rowid...
```

## Sample data

You can use any table in a PG database.

Download various size CSV files here:
https://www.datablist.com/learn/csv/download-sample-csv-files

Note: Please make sure you test with a million row file.

How to copy CSV into PG:

```sql
COPY customers FROM '/Users/x/Downloads/customers.csv' HEADER CSV
```

## Tests

Select the data from the one table, encode it and save it to disk?

## Included Files

- encoded/datastore.py encapsulates PG (using asyncpg)
- encoded/download_table.py is the implementation of the "get table" API
- encoded/serialization.c is C code that serializes each column in a row (using packed values)
- encoded/apg_record.h is the asyncpg record representation in c
- decoder/PackedValue.swift decoded the file and inserts the database into sqlite
