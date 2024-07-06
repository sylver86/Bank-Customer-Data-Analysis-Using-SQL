--- Analisi dei clienti di una Banca

--- 1. Calcolo dell'età

SELECT id_cliente, nome, cognome, data_nascita, CURDATE() AS oggi, 
       TIMESTAMPDIFF(YEAR, data_nascita, CURDATE()) AS eta 
FROM banca.cliente;

--- 2. Numero di transazioni in uscita su tutti i conti

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


--- 3. Numero di transazioni in entrata su tutti i conti

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


--- 4. Importo transato in uscita su tutti i conti

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


--- 5. Importo transato in entrata su tutti i conti

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


--- 6. Numero totale di conti posseduti

SELECT a.id_cliente, nome, cognome, COUNT(DISTINCT id_conto) AS num_conto
FROM banca.cliente a
LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
GROUP BY a.id_cliente;


--- 7. Numero di conti posseduti per tipologia

SELECT a.id_cliente, nome, cognome, c.desc_tipo_conto, COUNT(DISTINCT id_conto) AS num_conto
FROM banca.cliente a
LEFT OUTER JOIN banca.conto b ON a.id_cliente = b.id_cliente
INNER JOIN banca.tipo_conto c ON b.id_tipo_conto = c.id_tipo_conto 
GROUP BY a.id_cliente, c.desc_tipo_conto;


--- 8. Numero di transazioni in uscita su tutti i conti per tipologia

SELECT a.id_cliente,a.desc_tipo_conto,
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


--- 9. Numero di transazioni in entrata su tutti i conti per tipologia

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
 

--- 10. Importo transato in uscita su tutti i conti per tipologia
 
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
 

--- 11. Importo transato in entrata su tutti i conti per tipologia
 
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
