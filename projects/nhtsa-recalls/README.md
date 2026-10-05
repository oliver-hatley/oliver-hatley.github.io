# Recall Severity by Manufacturer

Which vehicle makers have the most dangerous recalls, not just the most recalls? A severity score for every NHTSA vehicle recall (1966 to 2025), ranked by manufacturer.

Full write-up: https://oliver-hatley.github.io/projects/nhtsa-recalls/

## Tools

- PostgreSQL (Supabase) for cleaning, manufacturer name matching and severity scoring
- Power BI (Power Query, DAX) for the dashboard

## Files

```
nhtsa-recalls/
├── index.qmd                         # project page / write-up (rendered by Quarto)
├── README.md                         # this file
├── files/
│   ├── NHTSA_Recall_Severity.pbix    # Power BI report
│   └── nhtsa-recalls-dashboard.pdf   # PDF export of the dashboard
├── images/
│   ├── overview.png                  # page 1 of the PDF
│   └── ranking.png                   # page 2 of the PDF
└── sql/                              # coming soon: table setup, name cleanup, severity scoring
```

## Headline

Kia and Mazda have the most severe recall records among carmakers. Ford, GM and Chrysler issue the most recalls but none make the top 15.

## Data

NHTSA recalls flat file (public): https://www.nhtsa.gov/nhtsa-datasets-and-apis
