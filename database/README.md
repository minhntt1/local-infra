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