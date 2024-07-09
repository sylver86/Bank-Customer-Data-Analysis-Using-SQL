
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

## Stored Procedure for Analysis

### How to Create the Stored Procedure
You can create a stored procedure that incorporates all the analysis steps into temporary tables, and then compiles a final table with comprehensive customer data. Below is the SQL code to create this stored procedure:

```sql
-- 1. Calcolo dell'età
DROP TABLE IF EXISTS eta;
CREATE TEMPORARY TABLE eta AS
SELECT id_cliente, nome, cognome, data_nascita, CURDATE() AS oggi, 
       TIMESTAMPDIFF(YEAR, data_nascita, CURDATE()) AS eta 
FROM banca.cliente;

-- 2. Numero di transazioni in uscita su tutti i cont

i
DROP TABLE IF EXISTS num_trans_out;
CREATE TEMPORARY TABLE num_trans_out AS
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

-- 3. Numero di transazioni in entrata su tutti i conti
DROP TABLE IF EXISTS num_trans_in;
CREATE TEMPORARY TABLE num_trans_in AS
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

-- 4. Importo transato in uscita su tutti i conti
DROP TABLE IF EXISTS trans_out;
CREATE TEMPORARY TABLE trans_out AS 
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

-- 5. Importo transato in entrata su tutti i conti
DROP TABLE IF EXISTS trans_in;
CREATE TEMPORARY TABLE trans_in AS
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

-- 6. Numero totale di conti posseduti
DROP TABLE IF EXISTS num_conti;
CREATE TEMPORARY TABLE num_conti AS 
SELECT a.id_cliente, nome, cognome, COUNT(DISTINCT id_conto) AS num_conto
FROM banca.cliente a
LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
GROUP BY a.id_cliente;

-- 7. Numero di conti posseduti per tipologia
DROP TABLE IF EXISTS num_conti_per_tipo;
SET @sql = NULL;
SET @cols = NULL;
SELECT 
    GROUP_CONCAT(DISTINCT CONCAT(
        'COUNT(DISTINCT CASE WHEN c.desc_tipo_conto = ''',
        desc_tipo_conto,
        ''' THEN b.id_conto ELSE NULL END) AS `',
        desc_tipo_conto, '`'
    )) INTO @cols
FROM banca.tipo_conto;
SET @sql = CONCAT(
    'CREATE TEMPORARY TABLE num_conti_per_tipo AS 
     SELECT a.id_cliente, a.nome, a.cognome, ', @cols, ' 
     FROM banca.cliente a 
     LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente 
     INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
     GROUP BY a.id_cliente, a.nome, a.cognome'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 8. Numero di transazioni in uscita su tutti i conti per tipologia
DROP TABLE IF EXISTS num_trans_out_tipo;
SELECT 
GROUP_CONCAT(DISTINCT CONCAT(
        'SUM(CASE WHEN a.desc_tipo_conto = ''',
        desc_tipo_conto,
        ''' THEN b.num_trans_out ELSE 0 END) AS `',
        desc_tipo_conto, '`'
    )) INTO @cols
FROM banca.tipo_conto;
SET @sql = CONCAT(
    'CREATE TEMPORARY TABLE num_trans_out_tipo AS
     SELECT a.id_cliente, ', @cols, ' 
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
         WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = ''-'')
         GROUP BY id_conto
     ) AS b ON a.id_conto = b.id_conto
     GROUP BY a.id_cliente'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 9. Numero di transazioni in entrata su tutti i conti per tipologia
DROP TABLE IF EXISTS num_trans_in_tipo;
SELECT 
GROUP_CONCAT(DISTINCT CONCAT(
        'SUM(CASE WHEN a.desc_tipo_conto = ''',
        desc_tipo_conto,
        ''' THEN b.num_trans_in ELSE 0 END) AS `',
        desc_tipo_conto, '`'
    )) INTO @cols
FROM banca.tipo_conto;
SET @sql = CONCAT(
    'CREATE TEMPORARY TABLE num_trans_in_tipo AS
     SELECT a.id_cliente, ', @cols, ' 
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
         WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = ''+'')
         GROUP BY id_conto
     ) AS b ON a.id_conto = b.id_conto
     GROUP BY a.id_cliente'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 10. Importo transato in uscita su tutti i conti per tipologia
DROP TABLE IF EXISTS trans_out_tipo;
SELECT 
GROUP_CONCAT(DISTINCT CONCAT(
    'SUM(CASE WHEN a.desc_tipo_conto = ''',
    desc_tipo_conto,
    ''' THEN b.importo_out ELSE 0 END) AS `',
    desc_tipo_conto, '`'
    )) INTO @cols
FROM banca.tipo_conto;
SET @sql = CONCAT(
    'CREATE TEMPORARY TABLE trans_out_tipo AS
     SELECT a.id_cliente, ', @cols, ' 
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
         WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = ''-'')
         GROUP BY id_conto
     ) AS b ON a.id_conto = b.id_conto
     GROUP BY a.id_cliente'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 11. Importo transato in entrata su tutti i conti per tipologia
DROP TABLE IF EXISTS trans_in_tipo;		
SELECT 
GROUP_CONCAT(DISTINCT CONCAT(
    'SUM(CASE WHEN a.desc_tipo_conto = ''',
    desc_tipo_conto,
    ''' THEN b.importo_in ELSE 0 END) AS `',
    desc_tipo_conto, '`'
    )) INTO @cols
FROM banca.tipo_conto;
SET @sql = CONCAT(
    'CREATE TEMPORARY TABLE trans_in_tipo AS
     SELECT a.id_cliente, ', @cols,

 ' 
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
         WHERE id_tipo_trans IN (SELECT id_tipo_transazione FROM banca.tipo_transazione WHERE segno = ''+'')
         GROUP BY id_conto
     ) AS b ON a.id_conto = b.id_conto
     GROUP BY a.id_cliente'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Creazione della tabella finale unendo tutte le tabelle temporanee
DROP TABLE IF EXISTS analisi_clienti;

CREATE TEMPORARY TABLE analisi_clienti AS
SELECT e.*, -- Seleziona tutte le colonne dalla tabella eta
       -- Seleziona solo le colonne specifiche dalle altre tabelle, evitando id_cliente e le colonne già presenti in eta
       nc.num_conto AS `Tot N° Conti`,
       nct.`Conto Base` AS `di cui N° Conto Base`, 
       nct.`Conto Business` AS `di cui N° Conto Business`, 
       nct.`Conto Famiglie` AS `di cui N° Conto Famiglie`, 
       nct.`Conto Privati` AS `di cui N° Conto Privati`,
       
       nto.num_trans_out AS `N° Transazioni Out`, 
       nto_tipo.`Conto Base` AS `di cui N°trans Out Conto Base`, 
       nto_tipo.`Conto Business` AS `di cui N°trans Out Conto Business`, 
       nto_tipo.`Conto Famiglie` AS `di cui N°trans Out Conto Famiglie`,
       nto_tipo.`Conto Privati` AS `di cui N°trans Out Conto Privati`,
       
       nti.num_trans_in AS `N° Transazioni In`,
       nti_tipo.`Conto Base` AS `di cui N°trans In Conto Base`, 
       nti_tipo.`Conto Business` AS `di cui N°trans In Conto Business`, 
       nti_tipo.`Conto Famiglie` AS `di cui N°trans In Conto Famiglie`,
       nti_tipo.`Conto Privati` AS `di cui N°trans In Conto Privati`,
     
       tto.importo_out AS `Tot Transato Out`,
       tto_tipo.`Conto Base` AS `di cui Imp Trans Out Conto Base`, 
       tto_tipo.`Conto Business` AS `di cui Imp Trans Out Conto Business`, 
       tto_tipo.`Conto Famiglie` AS `di cui Imp Trans Out Conto Famiglie`,
       tto_tipo.`Conto Privati` AS `di cui Imp Trans Out Conto Privati`,
       
       tti.importo_in AS `Tot Transato In`,
       tti_tipo.`Conto Base` AS `di cui Imp Trans In Conto Base`, 
       tti_tipo.`Conto Business` AS `di cui Imp Trans In Conto Business`, 
       tti_tipo.`Conto Famiglie` AS `di cui Imp Trans In Conto Famiglie`,
       tti_tipo.`Conto Privati` AS `di cui Imp Trans In Conto Privati`
      
FROM eta e
LEFT JOIN num_trans_out nto ON e.id_cliente = nto.id_cliente
LEFT JOIN num_trans_in nti ON e.id_cliente = nti.id_cliente
LEFT JOIN trans_out tto ON e.id_cliente = tto.id_cliente
LEFT JOIN trans_in tti ON e.id_cliente = tti.id_cliente
LEFT JOIN num_conti nc ON e.id_cliente = nc.id_cliente
LEFT JOIN num_conti_per_tipo nct ON e.id_cliente = nct.id_cliente
LEFT JOIN num_trans_out_tipo nto_tipo ON e.id_cliente = nto_tipo.id_cliente
LEFT JOIN num_trans_in_tipo nti_tipo ON e.id_cliente = nti_tipo.id_cliente
LEFT JOIN trans_out_tipo tto_tipo ON e.id_cliente = tto_tipo.id_cliente
LEFT JOIN trans_in_tipo tti_tipo ON e.id_cliente = tti_tipo.id_cliente;

SELECT * FROM analisi_clienti;
```

## How to Run the Queries

1. Ensure you have access to the SQL database.
2. Open your SQL client and connect to the `banca` database.
3. Copy and paste the desired query or the stored procedure into the SQL client.
4. Execute the query or procedure to retrieve the results.

## Conclusion

This project provides a comprehensive analysis of a bank's customer data using SQL. The queries and stored procedure help in understanding customer demographics, transaction behaviors, and account details. This information can be valuable for making informed business decisions and improving customer service.

---

Questo README ora include la procedura memorizzata per eseguire l'analisi, facilitando l'automazione e l'integrazione delle varie query.
