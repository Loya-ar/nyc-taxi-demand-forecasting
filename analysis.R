# NYC Taxi Ride Demand Forecasting and Revenue Loss Analysis
# Author: Arjun Loya (INFO6105, Northeastern University)
#
# Forecasts hourly NYC yellow-taxi demand with ARIMA, measures forecast accuracy
# on a held-out week, and simulates revenue lost when overnight driver supply
# is capped.
#
# Usage (from the repository root):
#   Rscript analysis.R                         # reads data/yellow_tripdata_2025-01.parquet
#   Rscript analysis.R path/to/trips.csv       # or any TLC yellow-taxi file (.parquet or .csv)
#
# Charts and result tables are written to output/.

# ---------------------------------------------------------
# STEP 1: Load Required Libraries
# ---------------------------------------------------------
# Install any missing packages (first run only)
required <- c("tidyverse", "lubridate", "forecast", "data.table", "arrow")
missing <- setdiff(required, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing, repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(forecast)
  library(data.table)
})

# ---------------------------------------------------------
# SETTINGS
# ---------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
DATA_FILE    <- if (length(args) >= 1) args[1] else "data/yellow_tripdata_2025-01.parquet"
OUTPUT_DIR   <- "output"
PERIOD_START <- ymd_hms("2025-01-01 00:00:00")  # TLC files contain a few stray timestamps
PERIOD_END   <- ymd_hms("2025-02-01 00:00:00")  # from other months; keep January only
HOLDOUT_DAYS <- 7    # last week is held out to measure forecast accuracy
DRIVER_LIMIT <- 50   # simulated overnight capacity, rides per hour
AVG_FARE     <- 10   # assumed revenue per unserved ride, in dollars

dir.create(OUTPUT_DIR, showWarnings = FALSE)

# ---------------------------------------------------------
# FUNCTION: Load and Clean Data
# ---------------------------------------------------------
# This function reads the taxi trip dataset (.parquet or .csv),
# converts the pickup time to proper format,
# keeps only trips inside the study period,
# removes invalid rows (zero fare or distance),
# and returns a clean dataset
load_and_clean_data <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("Data file not found: ", file_path,
         "\nDownload yellow_tripdata_2025-01.parquet from ",
         "https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page into data/")
  }
  df <- if (grepl("\\.parquet$", file_path)) {
    as.data.table(arrow::read_parquet(file_path,
      col_select = c("tpep_pickup_datetime", "trip_distance", "fare_amount")))
  } else {
    fread(file_path, select = c("tpep_pickup_datetime", "trip_distance", "fare_amount"))
  }
  n_raw <- nrow(df)
  df <- df %>%
    mutate(pickup_datetime = as_datetime(tpep_pickup_datetime)) %>%
    filter(!is.na(pickup_datetime),
           pickup_datetime >= PERIOD_START, pickup_datetime < PERIOD_END) %>%
    filter(trip_distance > 0, fare_amount > 0)
  message(sprintf("Loaded %s trips, kept %s after cleaning (%.1f%%)",
                  format(n_raw, big.mark = ","), format(nrow(df), big.mark = ","),
                  100 * nrow(df) / n_raw))
  return(df)
}

# ---------------------------------------------------------
# FUNCTION: Aggregate Hourly Ride Demand
# ---------------------------------------------------------
# Groups the dataset by hour and counts total rides per hour.
# Hours with no rides are kept as zero so the series has no gaps,
# which the ARIMA model's 24-hour seasonality relies on.
aggregate_hourly_demand <- function(df) {
  all_hours <- tibble(hour = seq(PERIOD_START, PERIOD_END - hours(1), by = "hour"))
  df_hourly <- df %>%
    mutate(hour = floor_date(pickup_datetime, "hour")) %>%
    count(hour, name = "rides")
  df_hourly <- all_hours %>%
    left_join(df_hourly, by = "hour") %>%
    mutate(rides = replace_na(rides, 0L))
  return(df_hourly)
}

# ---------------------------------------------------------
# FUNCTION: Measure Forecast Accuracy on a Held-out Week
# ---------------------------------------------------------
# Fits ARIMA on everything except the last week, forecasts that week,
# and compares the error with a seasonal-naive baseline
# ("same hour yesterday"). Saves the metrics as a CSV.
evaluate_forecast <- function(df_hourly, holdout_days = HOLDOUT_DAYS) {
  h <- holdout_days * 24
  train <- head(df_hourly$rides, -h)
  test  <- tail(df_hourly$rides, h)

  arima_fc <- forecast(auto.arima(ts(train, frequency = 24)), h = h)
  naive_fc <- snaive(ts(train, frequency = 24), h = h)

  score <- function(fc, name) {
    err <- test - as.numeric(fc$mean)
    keep <- test > 0  # MAPE is undefined for zero-ride hours
    tibble(model = name,
           MAE  = mean(abs(err)),
           RMSE = sqrt(mean(err^2)),
           MAPE = mean(abs(err[keep]) / test[keep]) * 100)
  }
  metrics <- bind_rows(score(arima_fc, "ARIMA"), score(naive_fc, "Seasonal naive")) %>%
    mutate(across(c(MAE, RMSE, MAPE), ~ round(.x, 1)))

  print(metrics)
  write_csv(metrics, file.path(OUTPUT_DIR, "forecast_accuracy.csv"))
  invisible(metrics)
}

# ---------------------------------------------------------
# FUNCTION: Forecast Next 24 Hours (ARIMA Model)
# ---------------------------------------------------------
# Uses time series forecasting to predict the next 24 hours of demand
# Saves the output as a line plot of the last week plus the forecast
plot_forecast <- function(df_hourly) {
  ts_data <- ts(df_hourly$rides, frequency = 24)
  model <- auto.arima(ts_data)
  message("Fitted model: ", paste(capture.output(print(model))[2], collapse = ""))
  forecast_result <- forecast(model, h = 24)
  p <- autoplot(forecast_result, include = 7 * 24) +
    labs(title = "Forecast: Hourly Ride Demand (Next 24 Hours)",
         subtitle = "Last 7 days of January 2025 shown, with 80% and 95% intervals",
         x = "Day of series", y = "Rides per Hour") +
    theme_minimal()
  print(p)
  ggsave(file.path(OUTPUT_DIR, "chart_forecast.png"), plot = p, width = 8, height = 5, bg = "white")
}

# ---------------------------------------------------------
# FUNCTION: Boxplot - Demand Volatility by Hour
# ---------------------------------------------------------
# Shows how consistent or variable demand is across different hours
# Helpful for identifying unpredictable peak times
plot_boxplot_volatility <- function(df_hourly) {
  df_hourly <- df_hourly %>%
    mutate(hour_of_day = hour(hour))
  p <- ggplot(df_hourly, aes(x = factor(hour_of_day), y = rides)) +
    geom_boxplot(fill = "lightgreen") +
    labs(title = "Ride Demand Volatility by Hour",
         x = "Hour of Day", y = "Rides per Hour") +
    theme_minimal()
  print(p)
  ggsave(file.path(OUTPUT_DIR, "chart_boxplot.png"), plot = p, width = 8, height = 5, bg = "white")
}

# ---------------------------------------------------------
# FUNCTION: Estimate Revenue Lost Overnight (12AM–6AM)
# ---------------------------------------------------------
# Simulates revenue loss assuming limited driver availability at night:
# every ride above the hourly driver limit is counted as unserved.
# Saves a per-hour chart and a per-weekday summary table.
plot_revenue_loss <- function(df_hourly, driver_limit = DRIVER_LIMIT, avg_fare = AVG_FARE) {
  low_hours <- df_hourly %>%
    mutate(hour_of_day = hour(hour)) %>%
    filter(hour_of_day >= 0 & hour_of_day < 6) %>%
    mutate(unmet_demand = pmax(rides - driver_limit, 0),
           lost_revenue = unmet_demand * avg_fare)

  by_weekday <- low_hours %>%
    mutate(day_of_week = lubridate::wday(hour, label = TRUE, week_start = 1)) %>%
    group_by(day_of_week) %>%
    summarise(nights = n_distinct(as_date(hour)),
              avg_lost_per_hour = round(mean(lost_revenue)),
              total_lost = sum(lost_revenue), .groups = "drop")
  print(by_weekday)
  write_csv(by_weekday, file.path(OUTPUT_DIR, "revenue_loss_by_weekday.csv"))
  message(sprintf("Average overnight loss: $%s per hour ($%s for the month)",
                  format(round(mean(low_hours$lost_revenue)), big.mark = ","),
                  format(sum(low_hours$lost_revenue), big.mark = ",")))

  p <- ggplot(low_hours, aes(x = hour, y = lost_revenue)) +
    geom_col(fill = "tomato") +
    scale_y_continuous(labels = scales::dollar) +
    labs(title = "Estimated Revenue Loss (12AM–6AM)",
         subtitle = sprintf("Assumes %d rides/hour driver capacity and $%d per unserved ride",
                            driver_limit, avg_fare),
         x = "Hour", y = "Lost Revenue") +
    theme_minimal()
  print(p)
  ggsave(file.path(OUTPUT_DIR, "chart_lost_revenue.png"), plot = p, width = 8, height = 5, bg = "white")
}

# ---------------------------------------------------------
# FUNCTION: Heatmap - Ride Demand by Hour and Day
# ---------------------------------------------------------
# Visualizes how ride demand shifts throughout the week and day
# (average rides per hour, so weekdays that occur 4 vs 5 times compare fairly)
plot_heatmap <- function(df_hourly) {
  df_heat <- df_hourly %>%
    mutate(day_of_week = lubridate::wday(hour, label = TRUE, week_start = 1),
           hour_of_day = hour(hour)) %>%
    group_by(day_of_week, hour_of_day) %>%
    summarise(rides = mean(rides), .groups = "drop")
  p <- ggplot(df_heat, aes(x = hour_of_day, y = fct_rev(day_of_week), fill = rides)) +
    geom_tile(color = "white") +
    scale_fill_gradient(low = "lightyellow", high = "red") +
    labs(title = "Heatmap of Ride Demand by Hour and Day",
         x = "Hour of Day", y = "Day of Week", fill = "Avg rides\nper hour") +
    theme_minimal()
  print(p)
  ggsave(file.path(OUTPUT_DIR, "chart_heatmap.png"), plot = p, width = 8, height = 5, bg = "white")
}

# ---------------------------------------------------------
# FINAL EXECUTION: Run All Steps
# ---------------------------------------------------------
# 1. Load and clean the trip data
df <- load_and_clean_data(DATA_FILE)

# 2. Aggregate ride counts by hour
df_hourly <- aggregate_hourly_demand(df)
write_csv(df_hourly, file.path(OUTPUT_DIR, "hourly_rides.csv"))

# 3. Measure forecast accuracy on the held-out final week
evaluate_forecast(df_hourly)

# 4. Create forecast plot
plot_forecast(df_hourly)

# 5. Create boxplot for hourly demand variability
plot_boxplot_volatility(df_hourly)

# 6. Estimate lost revenue from low driver supply at night
plot_revenue_loss(df_hourly)

# 7. Generate heatmap of demand by hour/day
plot_heatmap(df_hourly)

message("Done. Charts and tables saved to ", OUTPUT_DIR, "/")
