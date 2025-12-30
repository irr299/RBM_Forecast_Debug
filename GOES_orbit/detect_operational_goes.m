% Written by: I. Johnson, Dec 30, 2025
% Purpose: Detect the operational GOES satellites for the forecast system
% Input:
%   sat_position_dir: Path to the satellite position stream directory
%   utc_time: Current UTC time (datenum) to check for recent data
% Output:
%   primary_sat: Name of the primary GOES satellite
%   secondary_sat: Name of the secondary GOES satellite

function [primary_sat, secondary_sat] = detect_operational_goes(sat_position_dir, utc_time)
%DETECT_OPERATIONAL_GOES Automatically detect which GOES satellites have recent data
%
%   [primary_sat, secondary_sat] = detect_operational_goes(sat_position_dir, utc_time)
%
%   Checks all GOES satellite directories for recent position data and
%   returns the names of operational satellites.
%
%   INPUT:
%     sat_position_dir - Path to satellite position stream directory
%     utc_time         - Current UTC time (datenum) to check for recent data
%
%   OUTPUT:
%     primary_sat      - Name of primary GOES satellite (e.g., 'goes18')
%     secondary_sat    - Name of secondary GOES satellite (e.g., 'goes16')
%

    % Default values if nothing found
    primary_sat = '';
    secondary_sat = '';
    
    % Look for all GOES satellite directories
    goes_dirs = dir(fullfile(sat_position_dir, 'goes*'));
    goes_dirs = goes_dirs([goes_dirs.isdir]);
    
    % Remove . and .. entries
    goes_dirs = goes_dirs(~ismember({goes_dirs.name}, {'.', '..'}));
    
    if isempty(goes_dirs)
        warning('No GOES satellite directories found in %s', sat_position_dir);
        return;
    end
    
    fprintf('Checking GOES satellites for recent data...\n');
    
    % Structure to hold satellite info
    sat_info = struct('name', {}, 'last_date', {}, 'days_old', {});
    
    % Check each GOES satellite for most recent data
    for i = 1:length(goes_dirs)
        sat_name = goes_dirs(i).name;
        sat_path = fullfile(sat_position_dir, sat_name);
        
        % Find the most recent .mat file
        mat_files = dir(fullfile(sat_path, '**', [sat_name, '-position-*.mat']));
        
        if ~isempty(mat_files)
            % Get dates from filenames
            dates = [];
            for j = 1:length(mat_files)
                % Extract date from filename: goes16-position-20250630.mat
                fname = mat_files(j).name;
                date_str = regexp(fname, '\d{8}', 'match', 'once');
                if ~isempty(date_str)
                    year = str2double(date_str(1:4));
                    month = str2double(date_str(5:6));
                    day = str2double(date_str(7:8));
                    dates(end+1) = datenum(year, month, day);
                end
            end
            
            if ~isempty(dates)
                last_date = max(dates);
                days_old = utc_time - last_date;
                
                sat_info(end+1).name = sat_name;
                sat_info(end).last_date = last_date;
                sat_info(end).days_old = days_old;
                
                fprintf('  %s: Last data %s (%.1f days old)\n', ...
                    sat_name, datestr(last_date, 'yyyy-mm-dd'), days_old);
            end
        end
    end
    
    if isempty(sat_info)
        warning('No GOES satellites with position data found');
        return;
    end
    
    % Sort by most recent data (lowest days_old first)
    [~, sort_idx] = sort([sat_info.days_old]);
    sat_info = sat_info(sort_idx);
    
    % Consider a satellite operational if data is less than 7 days old
    operational_threshold = 7; % days
    operational_sats = sat_info([sat_info.days_old] < operational_threshold);
    
    if isempty(operational_sats)
        % No operational satellites, use most recent
        warning('No GOES satellites with recent data (<7 days). Using most recent.');
        primary_sat = sat_info(1).name;
        if length(sat_info) > 1
            secondary_sat = sat_info(2).name;
        end
    else
        % Use most recent as primary
        primary_sat = operational_sats(1).name;
        fprintf('Selected PRIMARY: %s\n', primary_sat);
        
        % Use second most recent as secondary (if exists)
        if length(operational_sats) > 1
            secondary_sat = operational_sats(2).name;
            fprintf('Selected SECONDARY: %s\n', secondary_sat);
        elseif length(sat_info) > 1
            % Use non-operational but most recent
            secondary_sat = sat_info(2).name;
            fprintf('Selected SECONDARY (non-operational): %s\n', secondary_sat);
        end
    end
    
end

