### 1. Operational Runner Scripts

These are the primary entry points for different forecast operations:

#### **run_forecast_cleaned.m** ⭐ [Operational]
- **Purpose**: Main operational forecast script (simplified version)
- **What it does**:
  - Loads settings from `settings_cleaned.m`
  - Runs a single forecast cycle from current UTC time
  - Calls `fc_loaddxx_DA3D_Neumann_cleaned.m` to perform computation
  - Saves output to Archive directory
- **Key Variables**:
  - `specified_utc`: Time to run forecast from
  - `fcopt.da_time`: Data assimilation window (e.g., 7 days)
  - `fcopt.forecast_duration`: 2.1 days
- **Output**: `PSD_fastforecast_YYYYMMDD_HHMMSS.mat`

#### **run_forecast.m**
- **Purpose**: Full-featured forecast runner with multiple run modes
- **Run Modes**:
  - `run_mode = 0`: Standard forecast mode (periodic forecasts)
  - `run_mode = 1`: Single date/period mode
  - `run_mode = 2`: Monthly data assimilation mode
  - `run_mode = 3`: Diurnal (daily) data assimilation mode
- **Key Function Calls**:
  - `Ini_dirs` - Initialize directory paths
  - `settings1` - Load configuration
  - `make_vars(fcopt)` - Create directory structure based on settings
  - `fc_loaddxx_DA3D_Neumann` - Main computation engine

#### **run_forecast_ensemble.m**
- **Purpose**: Generate ensemble forecasts using Kp ensemble predictions
- **What it does**:
  - Loads latest reanalysis result
  - Loads Kp ensemble predictions (multiple scenarios)
  - Runs forecast for each ensemble member (typically 99 members)
  - Useful for uncertainty quantification
- **Key Function Calls**:
  - `get_forecast_only(reanalysis)` - Extract forecast-only portion
  - `fc_loaddxx_DA3D_Neumann_ensemble` - Compute each ensemble member
- **Output**: `PSD_fastforecast_ensemble_XX_latest.mat` (XX = 01 to 99)

#### **run_specific_date_forecast.m**
- **Purpose**: Run forecast for specific historical dates (verification)
- **Use Case**: Model validation, reanalysis of past events
- **Calls**: `fc_loaddxx_DA3D_Neumann_specific_date`

#### **run_forecast_ensemble_verification.m**
- **Purpose**: Run ensemble forecasts for historical periods
- **Dates**: Pre-configured for April 2017 and September 2017 storms
- **Calls**: `fc_loaddxx_DA3D_Neumann_ensemble_verification`