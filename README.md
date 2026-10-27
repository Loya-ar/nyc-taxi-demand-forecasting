# NYC Taxi Demand Forecasting

**Forecasting hourly NYC yellow-taxi demand and estimating revenue lost to overnight driver shortages**, using January 2025 TLC trip records and R.

The project answers two questions:

1. **Can hourly ride demand be forecast from historical data?** An ARIMA model with 24-hour seasonality is fitted on the hourly ride counts. Its accuracy is measured on a held-out final week and compared with a simple "same hour yesterday" baseline.
2. **How much revenue is lost when there aren't enough drivers?** A simulation caps overnight capacity (12 AM–6 AM) and values every unserved ride at an assumed fare.

## Contents

- [Quick start](#quick-start)
- [Method](#method)
- [Outputs](#outputs)
- [Findings](#findings)
- [Assumptions and limitations](#assumptions-and-limitations)
- [Project structure](#project-structure)
- [About](#about)

## Quick start

Requires **R 4.0+**. Missing packages (`tidyverse`, `lubridate`, `forecast`, `data.table`, `arrow`) are installed automatically on first run.

```bash
git clone https://github.com/Loya-ar/nyc-taxi-demand-forecasting.git
cd nyc-taxi-demand-forecasting

# Download the January 2025 yellow-taxi data (about 59 MB) into data/
curl -o data/yellow_tripdata_2025-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet

Rscript analysis.R
```

You can also run it from RStudio with `source("analysis.R")`, using the project folder as the working directory. To use a different TLC file, including a CSV export, pass its path: `Rscript analysis.R data/other_file.csv`. See [`data/README.md`](data/README.md).

## Method

| Step | What the script does |
|---|---|
| **Load** | Reads only the three columns it needs (pickup time, distance, fare) from Parquet or CSV |
| **Clean** | Keeps pickups inside January 2025 (TLC files include a few stray timestamps from other months and years) and drops trips with zero distance or fare |
| **Aggregate** | Counts rides per hour. Hours with no rides are kept as 0, so the series has exactly 744 hourly points with no gaps |
| **Validate** | Fits `auto.arima` on the first 24 days, forecasts the last 7, and reports MAE, RMSE and MAPE next to a seasonal-naive baseline |
| **Forecast** | Refits on the full month and forecasts the next 24 hours with 80% and 95% intervals |
| **Simulate** | For 12 AM–6 AM, `unmet = max(rides − 50, 0)` and `lost revenue = unmet × $10`, summarised per hour and per weekday |
| **Visualise** | Forecast, hourly volatility boxplot, overnight revenue loss, and a weekday × hour demand heatmap |

All settings (study period, hold-out length, driver cap, fare) are at the top of [`analysis.R`](analysis.R).

## Outputs

Everything is written to `output/` (git-ignored):

| File | Contents |
|---|---|
| `forecast_accuracy.csv` | MAE, RMSE and MAPE for ARIMA and the seasonal-naive baseline on the held-out week |
| `hourly_rides.csv` | The cleaned hourly series (744 rows) |
| `revenue_loss_by_weekday.csv` | Average and total simulated overnight loss for each weekday |
| `chart_forecast.png` | Last week of demand plus the 24-hour forecast |
| `chart_boxplot.png` | Spread of rides per hour across the month, by hour of day |
| `chart_lost_revenue.png` | Simulated lost revenue for each overnight hour |
| `chart_heatmap.png` | Average rides per hour by weekday and hour |

## Findings

From the original analysis, described in the [project report](docs/report.pdf):

- Demand follows a strong daily cycle and peaks between **4 PM and 8 PM**. Evening hours are also the most volatile.
- The ARIMA forecast tracked the recurring daily pattern closely.
- The overnight simulation estimated losses of **$300–$400 per hour**, highest on **Friday and Saturday nights**.

The script now also writes a measured accuracy table (`forecast_accuracy.csv`), which gives the forecasting claim an actual number and baseline. Rerun the analysis to reproduce it.

## Assumptions and limitations

- **The revenue-loss figures come from assumptions, not observed shortages.** The data records only completed trips, so real unmet demand isn't visible. The 50-rides-per-hour cap and the $10 fare are illustrative, and the result scales directly with both. Typical yellow-taxi fares are above $10; set `AVG_FARE` to `mean(df$fare_amount)` for a data-based value.
- **One month of data.** The model sees daily and weekly patterns but no seasonality across the year, holidays or weather.
- **City-wide totals.** Demand isn't broken down by borough or pickup zone.

## Project structure

```
nyc-taxi-demand-forecasting/
├── analysis.R          # Full pipeline: load, clean, validate, forecast, simulate, plot
├── data/
│   └── README.md       # Where to get the TLC trip file (data itself is git-ignored)
├── docs/
│   └── report.pdf      # Course report
└── output/             # Created by the script (git-ignored)
```

## About

Built by **Arjun Loya** for *INFO6105: Data Science Engineering Methods & Tools* at Northeastern University, March 2025. There's a video walkthrough on [YouTube](https://www.youtube.com/watch?v=4gnVIXm6WPQ).

Data: [NYC Taxi & Limousine Commission Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page).
