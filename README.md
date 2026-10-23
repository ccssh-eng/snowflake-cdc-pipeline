# Pipeline CDC Snowflake — Stream, Task & MERGE INTO

Pipeline de données end-to-end construit sur Snowflake, implémentant le **Change Data Capture (CDC)** avec propagation automatique via Task et MERGE INTO.

## Architecture

```
[CSV File]
    │
    ▼
@COMMANDES_STAGE (Stage interne)
    │  COPY INTO
    ▼
RAW.COMMANDES (table source)
    │
    ▼
RAW.COMMANDES_STREAM (Stream CDC — APPEND_ONLY=FALSE)
    │  capture INSERT / UPDATE / DELETE
    ▼
SYNC_COMMANDES_TASK (Task automatisée — toutes les minutes)
    │  WHEN SYSTEM$STREAM_HAS_DATA(...)
    │  MERGE INTO avec déduplication QUALIFY ROW_NUMBER()
    ▼
STAGING.COMMANDES_STAGING (table cible)
    │
    ▼
STAGING.KPI_PAR_PRODUIT (vue KPI agrégée)
```

**Latence end-to-end : ~1 minute**

## Scripts SQL

| Fichier | Description |
|---|---|
| `01_stage_copy_into.sql` | Création du Stage interne, FILE FORMAT CSV, COPY INTO |
| `02_stream_cdc.sql` | Création du Stream CDC, tests INSERT/UPDATE/DELETE |
| `03_task_merge.sql` | Task automatisée avec MERGE INTO et déduplication |
| `04_kpi_view.sql` | Vue KPI par produit (chiffre d'affaires, panier moyen) |

## Concepts clés

### Stream CDC
- `APPEND_ONLY = FALSE` : capture les 3 types d'opérations (INSERT, UPDATE, DELETE)
- Un UPDATE génère 2 événements : `DELETE` (ancienne valeur) + `INSERT` (nouvelle valeur)
- Les métadonnées `METADATA$ACTION` et `METADATA$ISUPDATE` permettent de distinguer les opérations

### Task automatisée
- `SCHEDULE = '1 minute'` : polling toutes les minutes
- `WHEN SYSTEM$STREAM_HAS_DATA(...)` : la Task ne s'exécute que si le Stream contient des données (pas de consommation inutile du warehouse)
- La Task doit être **STARTED (RESUMED)** pour propager les changements

### MERGE INTO avec déduplication
```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ID_COMMANDE
    ORDER BY METADATA$ACTION DESC
) = 1
```
`DESC` sur `METADATA$ACTION` donne priorité à `'INSERT'` > `'DELETE'` alphabétiquement — à adapter selon le besoin métier.

### Vue KPI
- Filtre uniquement `STATUT = 'LIVRE'` : logique métier (commandes finalisées uniquement)
- Exclut `EN_COURS` et `ANNULE` du reporting

## Point d'attention CDC

> ⚠️e Stream capture les événements même quand la Task est **suspendue**.  
> Mais la propagation vers STAGING n'a lieu que quand la Task est **démarrée**.  
> En production : toujours `RESUME` la Task avant d'effectuer des modifications critiques.

## Technologies

- **Snowflake** — Cloud Data Warehouse
- **Snowflake Streams** — Change Data Capture natif
- **Snowflake Tasks** — Orchestration SQL automatisée
- **SQL** — MERGE INTO, QUALIFY, Window Functions

## Auteur

**Cédric SH** — Data Engineer  
Projet Snowflake — Module 07
