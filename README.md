# caremetrics-analytics

The analytics side of the CareMetrics analytics engineering portfolio project.
It turns the replicated operational data into tested, documented models with dbt, and will orchestrate the pipeline with Dagster.

```
operational Postgres  ->  Airbyte  ->  BigQuery (raw)  ->  dbt  ->  Looker Studio
 (caremetrics-source)                                    (this repo)
```

The source system, its synthetic data generator and the Airbyte ingestion setup live in [caremetrics-source](https://github.com/cernanb/caremetrics-source).
This repository starts where that one ends: the `caremetrics_raw` dataset in BigQuery is the contract between the two.

> **All data is synthetic.**
> It describes a fictional multi-clinic outpatient practice and contains no real PHI.

## Status

| Phase | Issue | State |
|---|---|---|
| dbt project, sources and staging models | [#1](https://github.com/cernanb/caremetrics-analytics/issues/1) | Done |
| Intermediate models and marts | [#2](https://github.com/cernanb/caremetrics-analytics/issues/2) | Planned |
| Snapshots for changing source records | [#3](https://github.com/cernanb/caremetrics-analytics/issues/3) | Done |
| Dagster orchestration | [#4](https://github.com/cernanb/caremetrics-analytics/issues/4) | Planned |
| Looker Studio dashboards | [#5](https://github.com/cernanb/caremetrics-analytics/issues/5) | Planned |

## Quick start

Requirements:

* Python 3.13 and [uv](https://docs.astral.sh/uv/) (used only to create the virtualenv).
  `dbt-bigquery` does not yet declare support for Python 3.14.
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`).
* A Google account with BigQuery access to the `care-metrics-510606` project: read on `caremetrics_raw`, and permission to create datasets and run jobs.

```bash
git clone https://github.com/cernanb/caremetrics-analytics.git
cd caremetrics-analytics

uv venv --seed .venv                 # Python 3.13, from .python-version
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt

gcloud auth application-default login
gcloud auth application-default set-quota-project care-metrics-510606

dbt debug                            # ends with "All checks passed!"
dbt build                            # builds every model and runs every test
```

`dbt build` should end with `ERROR=0`.

## Commands

All commands run from the repository root with the virtualenv active.

| Command | What it does |
|---|---|
| `dbt debug` | Check the profile and the BigQuery connection. |
| `dbt build` | Build all models and snapshots and run all tests, in dependency order. |
| `dbt build -s <model>` | Build one model and run every test that reads it. |
| `dbt test -s <test>` | Run one test without rebuilding anything. |
| `dbt snapshot` | Record new versions of changed records in the snapshot tables. |
| `dbt source freshness` | Check when Airbyte last synced each raw table. |
| `dbt show -s <model>` | Preview a model's rows. |
| `dbt show --inline "<sql>"` | Run ad-hoc SQL, with `ref()` and `source()` resolved. |
| `dbt docs generate && dbt docs serve` | Build and open the documentation site, including the lineage graph. |
| `sqlfluff lint` | Lint the SQL in `models/` and `tests/`. |
| `sqlfluff fix` | Fix what the linter can fix automatically. |

To debug a failing test, run its compiled SQL from `target/compiled/caremetrics/tests/<test>.sql` in the BigQuery console.
The rows it returns are the violations.

## Configuration

Connection settings are in `profiles.yml`, which is committed because it holds no secrets.
dbt authenticates with your Google application-default credentials (`method: oauth`), stored by `gcloud` outside the repository.

| Setting | Value |
|---|---|
| Project | `care-metrics-510606` |
| Location | `US`, the same as `caremetrics_raw` (BigQuery cannot join across locations) |
| Default target | `dev` |
| Query cost guard | `maximum_bytes_billed` of 1 GB per query |

Datasets follow dbt's default schema naming, the target's base dataset plus the layer:

| Dataset | Contents | Written by |
|---|---|---|
| `caremetrics_raw` | Raw tables replicated from the source database | Airbyte |
| `caremetrics_dev_staging` | Staging views, built locally | dbt, `dev` target |
| `caremetrics_dev_snapshots` | Snapshot history tables, recorded locally | dbt, `dev` target |

A `prod` target, writing to `caremetrics_staging`, `caremetrics_snapshots` and the later layers, will be added with Dagster (#4), together with a dedicated service account.
Development builds can never overwrite production tables.

## Project layout

```
.
├── models/
│   └── staging/
│       └── caremetrics/
│           ├── _caremetrics__sources.yml   # raw tables and freshness checks
│           ├── _caremetrics__models.yml    # column docs and generic tests
│           └── stg_caremetrics__*.sql      # one staging model per raw table
├── snapshots/                              # snapshot definitions, tests and docs: *_snapshot.yml
├── tests/                                  # singular tests: assert_*.sql
├── dbt_project.yml                         # project and layer configuration
├── profiles.yml                            # BigQuery connection (no secrets)
├── requirements.txt                        # dbt-core, dbt-bigquery
├── requirements-dev.txt                    # sqlfluff
├── .sqlfluff  .sqlfluffignore              # SQL lint and format rules
├── .editorconfig                           # whitespace and indentation
└── .python-version                         # 3.13
```

## Sources

The `caremetrics` source declares the seven raw tables in `caremetrics_raw`.

| Table | Airbyte sync mode |
|---|---|
| `locations`, `payers`, `providers` | Full refresh |
| `patients`, `appointments`, `encounters`, `claims` | Incremental, deduplicated on `id` by `updated_at` |

Freshness is measured on `_airbyte_extracted_at`, the time Airbyte last read each row, rather than on `updated_at`.
`updated_at` records when the clinic last changed a record, so reference tables that rarely change (payers were last edited in 2022) would always look stale even with a healthy sync.
Freshness warns after 1 day and errors after 7, because syncs are manual until Dagster schedules them.

## Staging models

One staging model per raw table, materialized as a view, and the only layer that reads raw data with `source()`.
Everything downstream reads staging with `ref()`.

Each model is a one-to-one cleanup of its raw table:

* Columns are listed explicitly and the four `_airbyte_*` metadata columns are dropped.
* Primary keys are renamed from `id` to `<entity>_id`, so a key has the same name in every table that uses it.
* Ambiguous names get the entity as a prefix (`location_name`, `payer_name`, `appointment_status`, `claim_status`) and booleans get `is_` (`is_active`).
* No casting is needed: Airbyte lands timestamps as UTC `TIMESTAMP`, `date_of_birth` as `DATE` and money as `NUMERIC`.
* Nothing derived and no business logic.
  For example, there is no age column: age depends on the date it is measured at, so it is computed per event downstream.

Models follow the dbt Labs layout: a `source` CTE, a `renamed` CTE, then `select * from renamed`.
Every model and column is documented in `_caremetrics__models.yml`.

## Snapshots

Snapshots record the history of records that change, one row per version, in the `snapshots` dataset (`caremetrics_dev_snapshots` locally).
Unlike models, they cannot be rebuilt: a version exists only because a snapshot run saw it.

| Snapshot | Records | Why its history matters |
|---|---|---|
| `patients_snapshot` | Patients | Demographic edits and corrections |
| `providers_snapshot` | Providers | Departures and clinic transfers |
| `appointments_snapshot` | Appointments | Status changes: scheduled to completed, cancelled or no-show |
| `claims_snapshot` | Claims | Status changes and payments |

`encounters` (chart amendments change no column that staging keeps), `locations` and `payers` (almost never change) are not snapshotted.

How they work:

* Each snapshot reads its staging model, so history uses the same clean column names as every other model.
* The timestamp strategy compares `updated_at`: a record whose `updated_at` moved gets a new version, and its previous version is closed.
* `dbt_valid_from` is the record's `updated_at`; `dbt_valid_to` is when the next version began, or null for the current version.
* The source never deletes rows, so deletes are ignored (`hard_deletes: ignore`).

Limits:

* **History starts at the first snapshot run.**
  Changes before then are not recorded anywhere.
* **A snapshot sees only what each sync delivered.**
  Airbyte keeps only the latest version of each row, so several changes to one record between two syncs appear as one version.
  The order that preserves the most history is: source changes, Airbyte sync, then `dbt snapshot`.
* **Version periods follow `updated_at`.**
  For changes made by the source simulator, `updated_at` is when the change was written, not the simulated event time, so version periods do not measure real durations such as payer turnaround.

## Tests

`dbt build` runs 117 tests.

**Generic tests on staging models (83)**, declared per column in `_caremetrics__models.yml`:

* `unique` and `not_null` on every primary key.
  On incremental streams, `unique` is what proves Airbyte's deduplication worked.
* `relationships` for every foreign key.
  BigQuery does not enforce foreign keys, and Airbyte syncs tables independently.
* `accepted_values` for status and type columns.
  These fail the build, because the source enforces the same lists, except `providers.specialty`, which only warns because the source does not constrain it.
* `not_null` on every column the source declares `not null`.

**Generic tests on snapshots (16)**, declared in each `snapshots/*_snapshot.yml`:

* `unique` and `not_null` on `dbt_scd_id`: no version was recorded twice.
* `not_null` on the record's key, and `unique` restricted to current versions (`where: dbt_valid_to is null`): at most one current version per record.

**Singular tests (18)** in `tests/`, each a query that returns the rows breaking one rule.
Most are ported from the source repository's `sql/verify_data.sql`:

| Area | Rules |
|---|---|
| Appointments | Booked before the scheduled time; booked after the patient registered and the provider was hired; not before the clinic went live; at the provider's clinic (warns). |
| Encounters | Exactly one per completed appointment; patient, provider and location match the appointment; starts within an hour of the scheduled time; completes before checkout. |
| Claims | Patient and provider match the encounter; created and submitted after the encounter completed; not before the payer was contracted; amounts and submission time agree with the status; paid share of billed between 20% and 90% (warns). |
| Clinical plausibility | Pediatrics sees only patients under 18 on the visit date (warns); OB/GYN sees only female patients (warns). |
| Completeness | Every staging model has as many rows as its raw table. |
| Snapshot history | Each record's versions are contiguous: every version has a positive period, ends exactly when the next begins, and only the newest is open. |

A test **warns** instead of failing when a violation could be valid data rather than a broken pipeline.
Each such test explains why in its header comment.

One rule from `verify_data.sql` is deliberately not ported: "no appointment scheduled after the provider left".
It relies on a departed provider's `updated_at` being their departure date, which holds for the current data but is not a source rule; snapshots (#3) are the right way to track departures.

## Known limitations

* **No claim payment or adjudication date.**
  The source records only a claim's latest status.
  `updated_at` is the payment date for seeded claims, but for claims changed by the source simulator it is the time the change was written, not the simulated event time.
  Days to payment therefore cannot be computed reliably yet; this needs a decision before the marts (#2).
* **No status history before the first snapshot.**
  Appointments and claims keep only their current status in the source.
  Snapshots record changes from their first run onward; earlier history cannot be recovered.
* **Providers store only their current clinic.**
  A transfer between clinics would rewrite history in staging, which is why the provider-clinic test only warns.
  `providers_snapshot` keeps the earlier clinic from the time of its first run.
* **Insurance is not stored on the patient.**
  A payer appears only on claims, and uninsured patients have none (see [caremetrics-source#9](https://github.com/cernanb/caremetrics-source/issues/9)).

## Development

* SQL is linted and formatted with [SQLFluff](https://docs.sqlfluff.com/) (BigQuery dialect, Jinja templater, so no BigQuery connection is needed).
  Run `sqlfluff lint` before committing.
* `.editorconfig` sets UTF-8, LF line endings, a final newline, no trailing whitespace, and 4-space indentation (2 for YAML).
* In VS Code, the EditorConfig and SQLFluff extensions apply both on save.
  Point the SQLFluff extension at `.venv/bin/sqlfluff` so it uses the pinned version.
