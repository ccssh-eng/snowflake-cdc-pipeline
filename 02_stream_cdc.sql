-- ============================================================
-- MODULE 07 - ÉTAPE 2 : STREAM CDC (Change Data Capture)
-- Projet : Pipeline CDC Snowflake - Cédric SH
-- ============================================================

-- 1. Création du Stream CDC sur la table RAW
--    APPEND_ONLY = FALSE : capture INSERT + UPDATE + DELETE

CREATE OR REPLACE STREAM FORMATION_DB.RAW.COMMANDES_STREAM
    ON TABLE FORMATION_DB.RAW.COMMANDES
    APPEND_ONLY = FALSE
    COMMENT = 'Stream CDC pour capturer toutes les modifications (INSERT/UPDATE/DELETE)';

-- 2. Création de la table STAGING (destination du pipeline)

CREATE OR REPLACE TABLE FORMATION_DB.STAGING.COMMANDES_STAGING (
    ID_COMMANDE   INT PRIMARY KEY,
    ID_CLIENT     INT,
    PRODUIT       VARCHAR(100),
    MONTANT       DECIMAL(10,2),
    DATE_COMMANDE DATE,
    STATUT        VARCHAR(50)
);

-- 3. Vérification du Stream (vide au départ = normal)

SELECT * FROM FORMATION_DB.RAW.COMMANDES_STREAM;

-- ============================================================
-- TESTS CDC - Exemples de modifications à tester
-- ============================================================

-- Test INSERT : nouvelles commandes

INSERT INTO FORMATION_DB.RAW.COMMANDES VALUES
    (9,  105, 'Laptop',    1200.00, '2024-03-01', 'EN_COURS'),
    (10, 106, 'Tablette',   450.00, '2024-03-02', 'EN_COURS'),
    (11, 107, 'Clavier',     89.99, '2024-03-03', 'EN_COURS');

-- Test UPDATE : modification d'un statut

UPDATE FORMATION_DB.RAW.COMMANDES
SET STATUT = 'LIVRE'
WHERE ID_COMMANDE = 9;

-- Test DELETE par condition métier (toutes les commandes annulées)
-- IMPORTANT : s'assurer que la Task est STARTED avant ce DELETE

DELETE FROM FORMATION_DB.RAW.COMMANDES
WHERE STATUT = 'ANNULE';

-- Vérification du Stream après modifications (contient les événements CDC)

SELECT
    ID_COMMANDE,
    STATUT,
    METADATA$ACTION,       -- 'INSERT' ou 'DELETE'
    METADATA$ISUPDATE,     -- TRUE si c'est un UPDATE (génère DELETE + INSERT)
    METADATA$ROW_ID
FROM FORMATION_DB.RAW.COMMANDES_STREAM
ORDER BY ID_COMMANDE;
