# INFO6105 Final Project: Top 4 Charts with Instructions
# Author: [Your Name]

# ---------------------------------------------------------
# STEP 1: Load Required Libraries
# ---------------------------------------------------------
# Install required packages (run only once)
install.packages(c("tidyverse", "lubridate", "forecast", "data.table", "ggplot2"))

# Load packages (run every session)
library(tidyverse)
library(lubridate)
library(forecast)
library(data.table)
library(ggplot2)

# ---------------------------------------------------------
# FUNCTION: Load and Clean Data
# ---------------------------------------------------------
# This function reads the taxi trip dataset,
# converts the pickup time to proper format,
# removes invalid rows (zero fare or distance),
# and returns a clean dataset
load_and_clean_data <- function(file_path) {
  df <- fread(file_path)
  df <- df %>%
    mutate(pickup_datetime = ymd_hms(tpep_pickup_datetime)) %>%
    filter(!is.na(pickup_datetime)) %>%
    filter(trip_distance > 0, fare_amount > 0)
  return(df)
}

# ---------------------------------------------------------
# FUNCTION: Aggregate Hourly Ride Demand
# ---------------------------------------------------------
# Groups the dataset by hour and counts total rides per hour
aggregate_hourly_demand <- function(df) {
  df_hourly <- df %>%
    mutate(hour = floor_date(pickup_datetime, "hour")) %>%
    group_by(hour) %>%
    summarise(rides = n()) %>%
    ungroup()
  return(df_hourly)
}

# ---------------------------------------------------------
# FUNCTION: Forecast Next 24 Hours (ARIMA Model)
# ---------------------------------------------------------
# Uses time series forecasting to predict the next 24 hours of demand
# Saves the output as a line plot
plot_forecast <- function(df_hourly) {
  ts_data <- ts(df_hourly$rides, frequency = 24)
  model <- auto.arima(ts_data)
  forecast_result <- forecast(model, h = 24)
  p <- autoplot(forecast_result) +
    labs(title = "Forecast: Hourly Ride Demand (Next 24 Hours)",
         x = "Hour", y = "Predicted Rides") +
    theme_minimal()
  print(p)
  ggsave("chart_forecast.png", plot = p, width = 8, height = 5)
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
  ggsave("chart_boxplot.png", plot = p, width = 8, height = 5)
}

# ---------------------------------------------------------
# FUNCTION: Estimate Revenue Lost Overnight (12AM–6AM)
# ---------------------------------------------------------
# Simulates revenue loss assuming limited driver availability at night
plot_revenue_loss <- function(df_hourly, driver_limit = 50, avg_fare = 10) {
  df_hourly <- df_hourly %>%
    mutate(hour_of_day = hour(hour))
  low_hours <- df_hourly %>%
    filter(hour_of_day >= 0 & hour_of_day < 6) %>%
    mutate(unmet_demand = ifelse(rides > driver_limit, rides - driver_limit, 0),
           lost_revenue = unmet_demand * avg_fare)
  p <- ggplot(low_hours, aes(x = hour, y = lost_revenue)) +
    geom_col(fill = "tomato") +
    labs(title = "Estimated Revenue Loss (12AM–6AM)",
         x = "Hour", y = "Lost Revenue ($)") +
    theme_minimal()
  print(p)
  ggsave("chart_lost_revenue.png", plot = p, width = 8, height = 5)
}

# ---------------------------------------------------------
# FUNCTION: Heatmap - Ride Demand by Hour and Day
# ---------------------------------------------------------
# Visualizes how ride demand shifts throughout the week and day
plot_heatmap <- function(df) {
  df_heat <- df %>%
    mutate(day_of_week = wday(pickup_datetime),
           hour_of_day = hour(pickup_datetime)) %>%
    group_by(day_of_week, hour_of_day) %>%
    summarise(rides = n())
  df_heat$day_of_week <- factor(df_heat$day_of_week,
                                levels = 1:7,
                                labels = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"))
  p <- ggplot(df_heat, aes(x = hour_of_day, y = day_of_week, fill = rides)) +
    geom_tile(color = "white") +
    scale_fill_gradient(low = "lightyellow", high = "red") +
    labs(title = "Heatmap of Ride Demand by Hour and Day",
         x = "Hour of Day", y = "Day of Week", fill = "Rides") +
    theme_minimal()
  print(p)
  ggsave("chart_heatmap.png", plot = p, width = 8, height = 5)
}

# ---------------------------------------------------------
# FINAL EXECUTION: Run All Steps
# ---------------------------------------------------------
# 1. Load your cleaned data
df <- load_and_clean_data("Data.csv")  # Make sure this file is in your working directory

# 2. Aggregate ride counts by hour
df_hourly <- aggregate_hourly_demand(df)

# 3. Create forecast plot
plot_forecast(df_hourly)

# 4. Create boxplot for hourly demand variability
plot_boxplot_volatility(df_hourly)

# 5. Estimate lost revenue from low driver supply at night
plot_revenue_loss(df_hourly)

# 6. Generate heatmap of demand by hour/day
plot_heatmap(df)
