function  [sw_prop,mag_prop] = ace_sw_mag_prop_simple(sw,mag)
%this function makes a simple propagation on ACE data, 
%corrects for non-monotonic propgation
% adapted from sw_prop_simple.m by A. Kellerman Jan, 2014
% ACE data read from real-time streams
% I. Michaelis Jan, 2018
% Modified by I. Johnson Dec,19 2025

fprintf('propagation of sw\n');

if ~isempty(sw)
    matlabd_sw = sw(:,1);
    stdate_sw=min(matlabd_sw);
    endate_sw=max(matlabd_sw);

    matlabd_mag = mag(:,1);
    stdate_mag=min(matlabd_mag);
    endate_mag=max(matlabd_mag);

    sw_qual = sw(:,3);
    bad_sw = find(sw_qual > 1); % 0 eliminates too much data
    sw(bad_sw,:) = NaN;
    sw(sw < -999) = NaN;
    
    mag_qual = mag(:,3);
    bad_mag = find(mag_qual > 1); % 0 eliminates too much data
    mag(bad_mag,:) = NaN;
    mag(mag < -999) = NaN;

    vel = sw(:,5);

    %Assume distance is 1.5 million km and make a simple propagation

    distance = 1.5e6;
    shifted_time = distance ./ vel; %seconds
    shifted_time_smooth = smoothn(shifted_time,3); %robust spline smoothing
    
    % Save original shifted_time_smooth and timestamps for mag data processing later
    shifted_time_smooth_orig = shifted_time_smooth;
    matlabd_sw_orig = matlabd_sw;

    newtime_smooth = matlabd_sw + shifted_time_smooth ./ 86400 ; 
    okinx = find(newtime_smooth >= stdate_sw & newtime_smooth < endate_sw);
    if ~isempty(okinx)
        newtime_smooth = newtime_smooth(okinx);
        sw = sw(okinx,:);

        den = sw(:,4);
        vel = sw(:,5);
        temp = sw(:,6);

        den(den <= 0) = NaN;
        vel(vel <= 0) = NaN;
        temp(temp <= 0) = NaN;

        bad2=find(isnan(den) | isnan(vel) | isnan(temp) | isnan(newtime_smooth));

        newtime_smooth(bad2) = NaN;
        nvals = find(~isnan(newtime_smooth));
        if ~isempty(nvals)
            sw = sw(nvals,:);
            newtime_smooth = newtime_smooth(nvals);
            cnt=1
        else
            cnt=0
        end

        %now remove any 'reverse' time points (trust the last point first as this is more likely the truth, and remove any originally earlier time points that are now later.

        newtime_smooth = floor(newtime_smooth .* 1440); %round to minutes
        dt = newtime_smooth(2:end) - newtime_smooth(1:end-1);
        badt = find(dt<=0);
        blen = num2str(length(badt));
        while ~isempty(badt)
            cnt = cnt+1;
            %remove the point before time went negative, as the higher wind will push this forward before it reaches the Earth
            %dt is one element less which makes it useful for removing the point we want
            newtime_smooth(badt(1)) = NaN;
            nvals = find(~isnan(newtime_smooth));
            if mod(cnt,100) == 0
                system('tput cuu 1');
                fprintf('Removed %s/~%s non-monotonic time points, %s remain\n',...
                    num2str(cnt),blen,num2str(length(newtime_smooth)));
            end
            if ~isempty(nvals)
                sw = sw(nvals,:);
                newtime_smooth = newtime_smooth(nvals);
            end
            dt = newtime_smooth(2:end) - newtime_smooth(1:end-1);
            badt = find(dt<=0);
        end
        system('tput cuu 1');
        fprintf('Removed %s non-monotonic time points\n',num2str(cnt));
        newtime_smooth = newtime_smooth ./1440; %back to days
        %with nans removed
        den = sw(:,4);
        vel = sw(:,5);
        temp = sw(:,6);

        fprintf('%s\n','time points are now monotonically increasing');

        %[yr,mo,dy,hr,mi,sc]=datevec(newtime_smooth);
        sw_prop = sw;
        sw_prop(:,1) = newtime_smooth;
        sw_prop(:,4:6) = cat(2,den,vel,temp);

        %shifted_sw_data = shifted_sw_data(:,1:9);

        zz = find(~isnan(sw_prop(:,1)));
        if ~isempty(zz)
            sw_prop = sw_prop(zz,:);
            fprintf('\n');
            fprintf('Done\n');
            fprintf('New size is %s.\n',num2str(length(sw_prop(:,1))));
        end
    end

    % Interpolate shifted_time_smooth to mag timestamps
    % Use the original shifted_time_smooth (before sw filtering) for mag data
    % Filter out NaN and Inf values for robust interpolation
    valid_idx = ~isnan(shifted_time_smooth_orig) & ~isinf(shifted_time_smooth_orig) & ~isnan(matlabd_sw_orig);
    
    if sum(valid_idx) >= 3  % Need at least 3 points for interpolation
        % Pre-compute median for efficient extrapolation
        median_shift = median(shifted_time_smooth_orig(valid_idx), 'omitnan');
        if isnan(median_shift)
            median_shift = 3600; % fallback to typical value
        end
        
        % Get valid sw timestamps and values for interpolation
        sw_times_valid = matlabd_sw_orig(valid_idx);
        sw_shift_valid = shifted_time_smooth_orig(valid_idx);
        
        % Find mag timestamps within valid range for interpolation
        sw_time_min = min(sw_times_valid);
        sw_time_max = max(sw_times_valid);
        in_range = matlabd_mag >= sw_time_min & matlabd_mag <= sw_time_max;
        
        % Initialize output array with median value (for extrapolation)
        shifted_time_smooth_mag = median_shift * ones(size(matlabd_mag));
        
        % Only interpolate for mag timestamps within valid range (much faster)
        if any(in_range)
            shifted_time_smooth_mag(in_range) = interp1(sw_times_valid, ...
                sw_shift_valid, matlabd_mag(in_range), 'linear');
        end
        
        % For points outside range, use nearest boundary value instead of linear extrapolation
        % This is much faster and more stable than linear extrapolation
        below_range = matlabd_mag < sw_time_min;
        above_range = matlabd_mag > sw_time_max;
        if any(below_range)
            shifted_time_smooth_mag(below_range) = sw_shift_valid(1);
        end
        if any(above_range)
            shifted_time_smooth_mag(above_range) = sw_shift_valid(end);
        end
    else
        % Fallback: use median propagation time if insufficient valid data
        median_shift = median(shifted_time_smooth_orig(valid_idx), 'omitnan');
        if isnan(median_shift)
            % If no valid data at all, use typical propagation time (~3600 sec for 400 km/s)
            median_shift = 3600;
            fprintf('Warning: No valid SW propagation data, using typical value (3600 sec)\n');
        end
        shifted_time_smooth_mag = median_shift * ones(size(matlabd_mag));
    end
    
    newtime_smooth = matlabd_mag + shifted_time_smooth_mag ./ 86400 ; 
    okinx = find(newtime_smooth >= stdate_mag & newtime_smooth < endate_mag);
    if ~isempty(okinx)
        newtime_smooth = newtime_smooth(okinx);
        mag =mag(okinx,:);

        bx = mag(:,4);
        by = mag(:,5);
        bz = mag(:,6);
        bt = mag(:,7);
        lat = mag(:,8);
        lon = mag(:,9);

        bad2=find(isnan(bx) | isnan(by) | isnan(bz) | isnan(bt) | isnan(lat) | isnan(lon) | isnan(newtime_smooth));

        newtime_smooth(bad2) = NaN;
        nvals = find(~isnan(newtime_smooth));
        if ~isempty(nvals)
            mag = mag(nvals,:);
            newtime_smooth = newtime_smooth(nvals);
            cnt=1
        else
            cnt=0
        end

        %now remove any 'reverse' time points (trust the last point first as this is more likely the truth, and remove any originally earlier time points that are now later.

        newtime_smooth = floor(newtime_smooth .* 1440); %round to minutes
        dt = newtime_smooth(2:end) - newtime_smooth(1:end-1);
        badt = find(dt<=0);
        blen = num2str(length(badt));
        while ~isempty(badt)
            cnt = cnt+1;
            %remove the point before time went negative, as the higher wind will push this forward before it reaches the Earth
            %dt is one element less which makes it useful for removing the point we want
            newtime_smooth(badt(1)) = NaN;
            nvals = find(~isnan(newtime_smooth));
            if mod(cnt,100) == 0
                system('tput cuu 1');
                fprintf('Removed %s/~%s non-monotonic time points, %s remain\n',...
                    num2str(cnt),blen,num2str(length(newtime_smooth)));
            end
            if ~isempty(nvals)
                mag = mag(nvals,:);
                newtime_smooth = newtime_smooth(nvals);
            end
            dt = newtime_smooth(2:end) - newtime_smooth(1:end-1);
            badt = find(dt<=0);
        end
        system('tput cuu 1');
        fprintf('Removed %s non-monotonic time points\n',num2str(cnt));
        newtime_smooth = newtime_smooth ./1440; %back to days
        %with nans removed
        bx = mag(:,4);
        by = mag(:,5);
        bz = mag(:,6);
        bt = mag(:,7);
        lat = mag(:,8);
        lon = mag(:,9);

        fprintf('%s\n','time points are now monotonically increasing');

        %[yr,mo,dy,hr,mi,sc]=datevec(newtime_smooth);
        mag_prop = mag;
        mag_prop(:,1) = newtime_smooth;
        mag_prop(:,4:9) = cat(2,bx,by,bz,bt,lat,lon);

        %shifted_sw_data = shifted_sw_data(:,1:9);

        zz = find(~isnan(mag_prop(:,1)));
        if ~isempty(zz)
            mag_prop = mag_prop(zz,:);
            fprintf('\n');
            fprintf('Done\n');
            fprintf('New size is %s.\n',num2str(length(mag_prop(:,1))));
        end
    end
end
