#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Written by I. Michaelis (GFZ), 2023
# Updated by I. Johnson, 24 Dec, 2025
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
UTCSTR=$(date -u +%Y%m%dT%H0000)
# create long movie 02:00 minutes
# Using ffmpeg instead of mencoder to avoid B-frame corruption issues
LD_PRELOAD=''
# Create sorted file list, only including files that actually exist
FRAME_LIST_FILE=/tmp/frame_list_$$.txt
rm -f "$FRAME_LIST_FILE"
for f in $(find frames_movie_mean_ensemble -name "Forecast_E_1_MeV_PA_50*.png" -type f | sort -V); do
    if [ -f "$f" ]; then
        echo "file '$(pwd)/$f'" >> "$FRAME_LIST_FILE"
        echo "duration 0.033333" >> "$FRAME_LIST_FILE"
    fi
done
# Use concat demuxer with explicit duration per frame (1/30 second = 0.033333)
/usr/bin/ffmpeg -y -f concat -safe 0 -i "$FRAME_LIST_FILE" -vf "scale=1920:1080:flags=lanczos" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -r 30 -movflags +faststart -bf 0 Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble.mp4
rm -f "$FRAME_LIST_FILE"
#source $FC_HOME/setup_forecast_output.sh

# create short movie 20 seconds
/usr/bin/ffmpeg -y -i Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble.mp4 -r 16 -filter:v "setpts=0.32*PTS"  Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble_short.mp4
# copy movies using timestamp
mkdir -p $FC_MP4
cp Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble.mp4 $FC_MP4/Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble_UTCSTR.mp4
cp Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble_short.mp4 $FC_MP4/Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble_short_UTCSTR.mp4

# move movies to latest directory
mv Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble.mp4 $FC_LATEST/Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble.mp4
mv Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble_short.mp4 $FC_LATEST/Forecast_UTC_E_1_MeV_PA_50_latest_mean_ensemble_short.mp4
source $FC_HOME/setup_forecast_output.sh

