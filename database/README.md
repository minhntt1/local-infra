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

- **Preview** (`liquibase-preview.yml`): on PRs that touch `database/**`, runs
  `liquibase status --verbose` and `liquibase updateSQL` and posts the pending changesets and
  DDL as a PR comment for review.
- **Apply** (`liquibase-sync.yml`): on merge to `main` that touches `database/**`, runs
  `liquibase update` against the affected dev/prod databases.
- Only the databases whose changelog directory changed are synced (via
  `dorny/paths-filter@v3`), so a change to, e.g., `dev/mysql/testdb` does not touch prod or
  other schemas.

Database/MySQL access uses the `root` user; credentials are sealed into SealedSecrets in the
`github-runners` namespace and mounted into the ephemeral runner pod as
`DEV_JDBC_PASSWORD` / `PROD_JDBC_PASSWORD`.