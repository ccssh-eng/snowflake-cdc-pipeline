-- ============================================================
-- MODULE 07 - ÉTAPE 1 : STAGE INTERNE & COPY INTO
-- Projet : Pipeline CDC Snowflake - Cédric SH
-- ============================================================

-- 1. Création du FILE FORMAT CSV
CREATE OR REPLACE FILE FORMAT FORMATION_DB.RAW.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE;

-- 2. Création du Stage interne
CREATE OR REPLACE STAGE FORMATION_DB.RAW.COMMANDES_STAGE
    FILE_FORMAT = FORMATION_DB.RAW.CSV_FORMAT
    COMMENT = 'Stage interne pour chargement des commandes CSV';

-- 3. Upload du fichier via SnowSQL (depuis terminal local)
-- PUT file:///chemin/local/commandes.csv @FORMATION_DB.RAW.COMMANDES_STAGE;

-- 4. Vérification du fichier uploadé
LIST @FORMATION_DB.RAW.COMMANDES_STAGE;

-- 5. Création de la table RAW
CREATE OR REPLACE TABLE FORMATION_DB.RAW.COMMANDES (
    ID_COMMANDE   INT,
    ID_CLIENT     INT,
    PRODUIT       VARCHAR(100),
    MONTANT       DECIMAL(10,2),
    DATE_COMMANDE DATE,
    STATUT        VARCHAR(50)
);

-- 6. Chargement des données via COPY INTO
COPY INTO FORMATION_DB.RAW.COMMANDES
FROM @FORMATION_DB.RAW.COMMANDES_STAGE/commandes.csv
FILE_FORMAT = (FORMAT_NAME = 'FORMATION_DB.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 7. Vérification du chargement
SELECT * FROM FORMATION_DB.RAW.COMMANDES ORDER BY ID_COMMANDE;
