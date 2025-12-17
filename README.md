# RBM_forecast_debug

The files are added here to track the changes made in the RBM_forecast code base.

## Files 
### 1. get_realtime_tipsod.m


### 2. ace_sw_mag_prop_simple.m
**Fixed array size incompatibility in `ace_sw_mag_prop_simple.m` (line 113)**: 
The function was using solar wind propagation time (`shifted_time_smooth`) directly with magnetic field data, 
causing a size mismatch when SW and MAG arrays had different lengths.
 The fix interpolates the propagation time from SW time coordinates 
 to MAG time coordinates before applying it, ensuring array sizes match.
