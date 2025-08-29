# NYC Taxi Ride Demand Forecasting and Revenue Analysis

**Author:** Arjun Loya  
**Course:** INFO6105 - Data Science Engineering Methods & Tools  
**Institution:** Northeastern University  
**Date:** March 2025

## Project Overview

This project analyzes NYC taxi trip data to forecast hourly ride demand and estimate revenue losses during periods of limited driver availability. Using time series analysis and business intelligence techniques, the project demonstrates how ride-sharing companies can optimize operations through data-driven insights.

## Research Questions

1. **Can we accurately forecast hourly ride demand using historical data?**
2. **How much revenue is potentially lost when insufficient drivers are available during certain hours?**

## Dataset

- **Source:** NYC Taxi and Limousine Commission (TLC) Trip Record Data
- **File:** `yellow_tripdata_2025-01.csv`
- **Records:** ~7 million taxi trips from January 2025
- **Key Variables:** pickup datetime, trip distance, fare amount, geographic data

## Technical Implementation

### Tools & Libraries
- **R Language** for statistical analysis and visualization
- **data.table** - Efficient data loading and manipulation
- **tidyverse** - Data wrangling and transformation
- **lubridate** - Date/time handling
- **forecast** - Time series modeling (ARIMA)
- **ggplot2** - Data visualization

### Methodology

1. **Data Preprocessing**
   - Load and clean 7M+ taxi trip records
   - Remove invalid entries (zero distance/fare)
   - Convert timestamps to hourly aggregations
   - Filter data quality issues

2. **Time Series Forecasting**
   - Aggregate rides by hour to create time series
   - Apply ARIMA modeling for demand prediction
   - Generate 24-hour ahead forecasts
   - Validate model performance

3. **Revenue Loss Simulation**
   - Model driver availability constraints (50 rides/hour cap during 12AM-6AM)
   - Calculate unmet demand during low-availability periods
   - Estimate financial impact ($10 average fare assumption)
   - Analyze patterns across days of the week

4. **Visualization & Analysis**
   - Time series forecast plots
   - Demand volatility boxplots by hour
   - Revenue loss bar charts
   - Demand intensity heatmaps

## Key Findings

### Forecasting Accuracy
- ARIMA model achieved reliable demand prediction
- Clear daily patterns with peaks during 4PM-8PM
- Model successfully captured recurring temporal trends
- 87% forecasting accuracy for operational planning

### Revenue Loss Analysis
- Significant revenue losses during 12AM-6AM period
- Estimated $300-$400 per hour in lost revenue during peak weekend nights
- Friday and Saturday late nights show highest unmet demand
- Driver shortage creates substantial opportunity costs

### Demand Patterns
- Consistent daily cycles with predictable peak hours
- Evening hours (6PM-8PM) show highest volatility
- Weekend nights extend peak demand later into evening
- Clear seasonality patterns across days of the week

## Project Files

```
nyc-taxi-demand-forecasting/
├── Final Project File.R          # Main analysis script
├── Data.csv                      # NYC taxi dataset (not included - download from TLC)
├── project_report.pdf            # Complete project report
├── README.md                     # This file
├── charts/                       # Generated visualizations
│   ├── chart_forecast.png        # ARIMA forecast plot
│   ├── chart_boxplot.png         # Hourly volatility analysis
│   ├── chart_lost_revenue.png    # Revenue loss simulation
│   └── chart_heatmap.png         # Demand heatmap
└── video_demo/
    └── demo_link.txt              # Link to project video demonstration
```

## Installation & Usage

### Prerequisites
- R (version 4.0+)
- Required R packages (automatically installed by script)

### Setup Instructions

1. **Clone or download project files**
2. **Download dataset:**
   - Visit [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
   - Download `yellow_tripdata_2025-01.csv`
   - Place in project directory as `Data.csv`

3. **Run analysis:**
   ```r
   # Open R/RStudio
   # Set working directory to project folder
   source("Final Project File.R")
   ```

### Script Execution
The main script will:
- Install required packages (first run only)
- Load and clean the dataset
- Generate all four key visualizations
- Save charts as PNG files
- Display results in R console

## Business Applications

### Operational Optimization
- **Driver Scheduling:** Use forecasts for proactive driver deployment
- **Resource Allocation:** Optimize fleet distribution based on predicted demand
- **Capacity Planning:** Anticipate peak periods for staffing decisions

### Revenue Optimization
- **Dynamic Pricing:** Implement surge pricing during high-demand periods
- **Incentive Programs:** Target driver bonuses for underserved time slots
- **Service Coverage:** Reduce revenue losses through strategic availability

### Strategic Planning
- **Market Analysis:** Understand temporal demand patterns
- **Competitive Advantage:** Data-driven operational decisions
- **Performance Metrics:** Quantify impact of operational changes

## Technical Challenges Addressed

1. **Large Dataset Processing:** Efficiently handled 7M+ records using data.table
2. **Time Series Complexity:** Proper ARIMA model selection and tuning
3. **Data Quality Issues:** Robust filtering for invalid/missing data
4. **Visualization Clarity:** Balanced detail with interpretability

## Results Summary

- **Forecasting Success:** Reliable 24-hour demand predictions
- **Business Impact:** Quantified revenue loss opportunities ($300-400/hour)
- **Operational Insights:** Clear patterns for resource optimization
- **Scalable Framework:** Methodology applicable to other cities/timeframes

## Future Enhancements

- **Weather Integration:** Incorporate weather data for improved accuracy
- **Geographic Segmentation:** Borough-level demand analysis
- **Real-time Implementation:** Live forecasting system
- **Machine Learning:** Compare ARIMA with neural network approaches

## Video Demonstration

Project walkthrough and technical demonstration available at:
[https://www.youtube.com/watch?v=4gnVIXm6WPQ](https://www.youtube.com/watch?v=4gnVIXm6WPQ)

## License

This project is created for academic purposes as part of coursework at Northeastern University.

## Contact

**Arjun Loya**  
MS Information Systems  
Northeastern University  
Email: loya.ar@northeastern.edu
