# Bank Customer Data Analysis Using SQL

## Overview

This project demonstrates the analysis of a banking database using SQL queries. The database consists of several tables containing information about bank customers, their accounts, and transactions. The goal of this analysis is to extract valuable insights about customer demographics, transaction patterns, and account details.

## Database Structure

The database contains the following key tables:

- **cliente**: Contains information about the customers such as ID, name, surname, and birthdate.
- **conto**: Contains details about the bank accounts held by customers, including account type.
- **transazioni**: Records all transactions, specifying the type (inflow or outflow) and amount.
- **tipo_transazione**: Specifies the nature of the transaction (inflow or outflow).
- **tipo_conto**: Describes the type of accounts.

## Analysis Queries

### 1. Calculating the Age of Customers
```sql
SELECT id_cliente, nome, cognome, data_nascita, CURDATE() AS oggi, 
       TIMESTAMPDIFF(YEAR, data_nascita, CURDATE()) AS eta 
FROM banca.cliente;
```

### 2. Number of Outgoing Transactions for All Accounts
```sql
SELECT a.id_cliente,
       COALESCE(SUM(num_trans_out), 0) AS num_trans_out
FROM
(
    SELECT a.id_cliente, nome, cognome, id_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, COUNT(*) AS num_trans_out
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '-')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente;
```

### 3. Number of Incoming Transactions for All Accounts
```sql
SELECT a.id_cliente,
       COALESCE(SUM(num_trans_in), 0) AS num_trans_in
FROM
(
    SELECT a.id_cliente, nome, cognome, id_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, COUNT(*) AS num_trans_in
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '+')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente;
```

### 4. Total Amount of Outgoing Transactions for All Accounts
```sql
SELECT a.id_cliente,
       COALESCE(SUM(importo_out), 0) AS importo_out
FROM
(
    SELECT a.id_cliente, nome, cognome, id_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, SUM(importo) AS importo_out
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '-')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente;
```

### 5. Total Amount of Incoming Transactions for All Accounts
```sql
SELECT a.id_cliente,
       COALESCE(SUM(importo_in), 0) AS importo_in
FROM
(
    SELECT a.id_cliente, nome, cognome, id_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, SUM(importo) AS importo_in
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '+')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente;
```

### 6. Total Number of Accounts Held
```sql
SELECT a.id_cliente, nome, cognome, COUNT(DISTINCT id_conto) AS num_conto
FROM banca.cliente a
LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
GROUP BY a.id_cliente;
```

### 7. Number of Accounts Held by Type
```sql
SELECT a.id_cliente, nome, cognome, c.desc_tipo_conto, COUNT(DISTINCT id_conto) AS num_conto
FROM banca.cliente a
LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
GROUP BY a.id_cliente, c.desc_tipo_conto;
```

### 8. Number of Outgoing Transactions for All Accounts by Type
```sql
SELECT a.id_cliente, a.desc_tipo_conto,
       COALESCE(SUM(b.num_trans_out), 0) AS num_trans_out
FROM
(
    SELECT a.id_cliente, nome, cognome, b.id_conto, c.desc_tipo_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
    INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, COUNT(*) AS num_trans_out
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '-')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente, a.desc_tipo_conto;
```

### 9. Number of Incoming Transactions for All Accounts by Type
```sql
SELECT a.id_cliente, a.desc_tipo_conto,
       COALESCE(SUM(b.num_trans_in), 0) AS num_trans_in
FROM
(
    SELECT a.id_cliente, nome, cognome, b.id_conto, c.desc_tipo_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
    INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, COUNT(*) AS num_trans_in
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '+')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente, a.desc_tipo_conto;
```

### 10. Total Outgoing Transaction Amount for All Accounts by Type
```sql
SELECT a.id_cliente, a.desc_tipo_conto,
       COALESCE(SUM(b.importo_out), 0) AS importo_out
FROM
(
    SELECT a.id_cliente, nome, cognome, b.id_conto, c.desc_tipo_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
    INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, SUM(importo) AS importo_out
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '-')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente, a.desc_tipo_conto;
```

### 11. Total Incoming Transaction Amount for All Accounts by Type
```sql
SELECT a.id_cliente, a.desc_tipo_conto,
       COALESCE(SUM(b.importo_in), 0) AS importo_in
FROM
(
    SELECT a.id_cliente, nome, cognome, b.id_conto, c.desc_tipo_conto
    FROM banca.cliente a
    LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
    INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
) AS a
LEFT OUTER JOIN
(
    SELECT id_conto, SUM(importo) AS importo_in
    FROM banca.transazioni 
    WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = '+')
    GROUP BY id_conto
) AS b ON a.id_conto = b.id_conto
GROUP BY a.id_cliente, a.desc_tipo_conto;
```

## How to Run the Queries

1. Ensure you have access to the SQL database.
2. Open your SQL client and connect to the `banca` database.
3. Copy and paste the desired query into the SQL client.
4. Execute the query to retrieve the results.

## Conclusion

This project provides a comprehensive analysis of a bank's customer data using SQL. The queries help in understanding customer demographics, transaction behaviors, and account details. This information can be valuable for making informed business decisions and improving customer service.
