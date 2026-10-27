# Data

Put the NYC TLC yellow-taxi trip file for January 2025 here:

```
data/yellow_tripdata_2025-01.parquet
```

Download it from the [TLC Trip Record Data page](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
(Yellow Taxi Trip Records → 2025 → January, about 59 MB), or directly:

```bash
curl -o data/yellow_tripdata_2025-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet
```

A CSV export with the same columns also works: `Rscript analysis.R data/your_file.csv`.
The script only reads `tpep_pickup_datetime`, `trip_distance` and `fare_amount`.

Data files in this folder are git-ignored.
