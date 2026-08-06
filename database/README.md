# Database Schema Backups

## Structure

```
database/
├── prod/
│   └── mysql/
│       ├── network_statistics/
│       │   ├── sql/
│       │   └── changelog/
│       └── quartz/
│           ├── sql/
│           └── changelog/
└── dev/
    └── mysql/
        ├── network_statistics/
        │   ├── sql/
        │   └── changelog/
        └── quartz/
            ├── sql/
            └── changelog/
```

## Directories

- **sql/** - Baseline schema dumps (`v00000__baseline.sql`) and future migration scripts
- **changelog/** - Liquibase changelog XML files referencing SQL scripts for automated deployment

> Note: the directory listing above is abbreviated; dev also contains a `testdb/` database alongside
> `network_statistics/` and `quartz/`.

## Automated Deployment (Liquibase)

Changelogs under this tree are applied automatically to the live MySQL databases by the
`k8s-gh-runner` ARC-based GitHub Actions runner (see `.github/workflows/README.md` for the runner setup):

- **Preview** (`liquibase-preview.yml`): on PRs that touch `database/**`, records the existing
  baselines via `changelogSync` (non-destructive) then runs `liquibase status --verbose` and
  `liquibase updateSQL`, posting the pending changesets and DDL as a PR comment for review.
- **Apply** (`liquibase-sync.yml`): on merge to `main` that touches `database/**`, runs
  `changelogSync` then `liquibase update` against the affected dev/prod databases.
- Only the databases whose changelog directory changed are synced (via
  `dorny/paths-filter@v3`), so a change to, e.g., `dev/mysql/testdb` does not touch prod or
  other schemas.

> **Why `changelogSync` is run before `update`:** the baseline `v00000__baseline.sql` files are
> full `mysqldump` exports (`DROP TABLE IF EXISTS ... CREATE TABLE ...`). Running `update`
> against an already-populated database would replay that dump and **drop/recreate every table**.
> `changelogSync` records the `init-baseline` changeset in `DATABASECHANGELOG` *without*
> executing the SQL, so the subsequent `update` is a no-op (the DB is reported "up to date").
> This protects existing data while still letting future migration scripts apply incrementally.

Database/MySQL access uses the `root` user; credentials are sealed into SealedSecrets in the
`github-runners` namespace and mounted into the ephemeral runner pod as
`DEV_JDBC_PASSWORD` / `PROD_JDBC_PASSWORD`.

Liquibase Community 4.32.0 does **not** bundle the MySQL JDBC driver, so both workflows download
`mysql-connector-j` into `/tmp/liquibase-lib` and pass it via `--classpath`.

## Changelog conventions

Every `changelog/changelog1.xml` must:

- Declare the Liquibase 4.x namespace + XSD on the root element:

  ```xml
  <databaseChangeLog
      xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
          http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">
  ```

- Give each `changeSet` **both** an `id` and an `author` (required by the XSD), and put its
  description in the child `<comment>` element — **not** in a `comment`/`comments` attribute
  (that fails XSD validation):

  ```xml
  <changeSet id="init-baseline" author="liquibase">
      <comment>init baseline</comment>
      <sqlFile path="database/dev/mysql/network_statistics/sql/v00000__baseline.sql" />
  </changeSet>
  ```

- Reference SQL files with a **repo-root-relative** path (e.g.
  `database/dev/mysql/network_statistics/sql/v00000__baseline.sql`), not a path relative to the
  changelog file. Liquibase resolves `sqlFile`/`include` paths against its search path (the
  repo root, which is the workflow's working directory), so `../sql/...` is **not** found.

The `quartz` databases use an `<include file=".../sql/v00000__baseline.sql"/>` form with the same
repo-root-relative path rule.