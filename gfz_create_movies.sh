#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Written by I. Michaelis (GFZ), 2020
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
UTCSTR=$(date -u +%Y%m%dT%H0000)
# create long movie 02:00 minutes
LD_PRELOAD=''
/usr/bin/mencoder mf://frames_movie/Forecast_E_1_MeV_PA_50*.png -mf w=1920:h=1080:fps=30:type=png -x264encopts bitrate=2000 -ovc x264 -oac copy -of lavf -o Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth.mp4
#source $FC_HOME/setup_forecast_output.sh

# create short movie 20 seconds
/usr/bin/ffmpeg -i Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth.mp4 -r 16 -filter:v "setpts=0.32*PTS"  Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth_short.mp4

# copy movies using timestamp
mkdir -p $FC_MP4
cp Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth.mp4 $FC_MP4/Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth_UTCSTR.mp4
cp Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth_short.mp4 $FC_MP4/Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth_short_UTCSTR.mp4

# move movies to latest directory
mv Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth.mp4 $FC_LATEST/Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth.mp4
mv Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth_short.mp4 $FC_LATEST/Forecast_UTC_E_1_MeV_PA_50_latest_scatter_smooth_short.mp4
source $FC_HOME/setup_forecast_output.sh

