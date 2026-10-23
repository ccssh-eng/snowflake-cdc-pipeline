-- ============================================================
-- MODULE 07 - ÉTAPE 4 : VUE KPI PAR PRODUIT
-- Projet : Pipeline CDC Snowflake - Cédric SH
-- ============================================================

-- 1. Création de la vue KPI
--    Filtre uniquement les commandes LIVREES (logique métier)
--    Exclut : EN_COURS (pas encore finalisé) et ANNULE (pertes)
CREATE OR REPLACE VIEW FORMATION_DB.STAGING.KPI_PAR_PRODUIT AS
SELECT
    PRODUIT,
    COUNT(*)            AS nb_commandes,
    SUM(MONTANT)        AS chiffre_affaires,
    AVG(MONTANT)        AS panier_moyen,
    MAX(DATE_COMMANDE)  AS derniere_commande
FROM FORMATION_DB.STAGING.COMMANDES_STAGING
WHERE STATUT = 'LIVRE'
GROUP BY PRODUIT
ORDER BY chiffre_affaires DESC;

-- 2. Consultation de la vue KPI

SELECT * FROM FORMATION_DB.STAGING.KPI_PAR_PRODUIT;

-- ============================================================
-- ARCHITECTURE DU PIPELINE COMPLET
-- ============================================================
--
--  [CSV File]
--      │
--      V  
--  @COMMANDES_STAGE (Stage interne)
--      │  COPY INTO
--      V
--  RAW.COMMANDES (table source)
--      │
--      V
--  RAW.COMMANDES_STREAM (Stream CDC)
--      │  APPEND_ONLY=FALSE → capture INSERT / UPDATE / DELETE
--      V
--  SYNC_COMMANDES_TASK (Task automatisée, 1 min)
--      │  WHEN SYSTEM$STREAM_HAS_DATA(...)
--      │  MERGE INTO avec déduplication QUALIFY ROW_NUMBER()
--      V
--  STAGING.COMMANDES_STAGING (table cible)
--      │
--      V
--  STAGING.KPI_PAR_PRODUIT (vue agrégée)
--
-- Latence end-to-end : ~1 minute (fréquence de la Task)
-- ============================================================
