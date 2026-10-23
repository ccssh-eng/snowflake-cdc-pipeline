-- ============================================================
-- MODULE 07 - ÉTAPE 3 : TASK AUTOMATISÉE & MERGE INTO
-- Projet : Pipeline CDC Snowflake - Cédric SH
-- ============================================================

-- 1. Création de la Task avec MERGE INTO
--    - SCHEDULE : toutes les minutes
--    - WHEN : s'exécute uniquement si le Stream contient des données
--    - QUALIFY ROW_NUMBER() : déduplique les événements CDC par ID_COMMANDE

CREATE OR REPLACE TASK FORMATION_DB.RAW.SYNC_COMMANDES_TASK
    WAREHOUSE = SNOWFLAKE_LEARNING_WH
    SCHEDULE  = '1 minute'
WHEN
    SYSTEM$STREAM_HAS_DATA('FORMATION_DB.RAW.COMMANDES_STREAM')
AS
    MERGE INTO FORMATION_DB.STAGING.COMMANDES_STAGING AS cible
    USING (
        -- Déduplication : on garde le dernier événement par commande
        -- DELETE a priorité sur INSERT (ORDER BY METADATA$ACTION DESC)
        SELECT
            ID_COMMANDE,
            ID_CLIENT,
            PRODUIT,
            MONTANT,
            DATE_COMMANDE,
            STATUT,
            METADATA$ACTION
        FROM FORMATION_DB.RAW.COMMANDES_STREAM
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY ID_COMMANDE
            ORDER BY METADATA$ACTION DESC
        ) = 1
    ) AS source
    ON cible.ID_COMMANDE = source.ID_COMMANDE

    -- Suppression physique si DELETE dans le Stream
    WHEN MATCHED AND source.METADATA$ACTION = 'DELETE' THEN
        DELETE

    -- Mise à jour si la commande existe déjà en STAGING
    WHEN MATCHED AND source.METADATA$ACTION = 'INSERT' THEN
        UPDATE SET
            cible.ID_CLIENT     = source.ID_CLIENT,
            cible.PRODUIT       = source.PRODUIT,
            cible.MONTANT       = source.MONTANT,
            cible.DATE_COMMANDE = source.DATE_COMMANDE,
            cible.STATUT        = source.STATUT

    -- Insertion si nouvelle commande
    WHEN NOT MATCHED AND source.METADATA$ACTION = 'INSERT' THEN
        INSERT (ID_COMMANDE, ID_CLIENT, PRODUIT, MONTANT, DATE_COMMANDE, STATUT)
        VALUES (source.ID_COMMANDE, source.ID_CLIENT, source.PRODUIT,
                source.MONTANT, source.DATE_COMMANDE, source.STATUT);

-- 2. Démarrage de la Task (obligatoire après création)
ALTER TASK FORMATION_DB.RAW.SYNC_COMMANDES_TASK RESUME;

-- 3. Vérification de l'état de la Task
SHOW TASKS IN SCHEMA FORMATION_DB.RAW;

-- 4. Historique d'exécution de la Task
SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    TASK_NAME => 'SYNC_COMMANDES_TASK'
))
ORDER BY SCHEDULED_TIME DESC;

-- 5. Suspension de la Task (fin de session / maintenance)
-- ALTER TASK FORMATION_DB.RAW.SYNC_COMMANDES_TASK SUSPEND;
