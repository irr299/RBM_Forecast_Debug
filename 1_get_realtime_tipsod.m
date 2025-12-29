%%
%
% Written by Ingo Michaelis, Jan 2018
% FIXED by Auto Dec 2025 - Updated for new SSCWeb HTML format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, y, z]=get_realtime_tipsod(matlabd,sat,coords)
    start_time=datestr(min(matlabd),'YYYY/mm/dd HH:MM:SS');
    stop_time=datestr(max(matlabd),'YYYY/mm/dd HH:MM:SS');
    
    url='https://sscweb.gsfc.nasa.gov/cgi-bin/Locator.cgi?';
    vars = '';

    vars = [vars, 'SPCR=',sat,'&'];
    vars = [vars, 'START_TIME=',start_time,'&'];
    vars = [vars, 'STOP_TIME=',stop_time,'&'];
    vars = [vars, 'RESOLUTION=',num2str(1),'&'];
    if strcmp(coords,'TOD')
        vars = [vars, 'TOD=',num2str(1),'&'];
        vars = [vars, 'TOD=',num2str(2),'&'];
        vars = [vars, 'TOD=',num2str(3),'&'];
    else
        vars = [vars, 'TOD=','','&'];
    end
    if strcmp(coords,'J2000')
        vars = [vars, 'J2000=',num2str(1),'&'];
        vars = [vars, 'J2000=',num2str(2),'&'];
        vars = [vars, 'J2000=',num2str(3),'&'];
    else
        vars = [vars, 'J2000=','','&'];
    end
    if strcmp(coords,'GEO')
        vars = [vars, 'GEO=',num2str(1),'&'];
        vars = [vars, 'GEO=',num2str(2),'&'];
        vars = [vars, 'GEO=',num2str(3),'&'];
    else
        vars = [vars, 'GEO=','','&'];
    end
    if strcmp(coords,'GM')
        vars = [vars, 'GM=',num2str(1),'&'];
        vars = [vars, 'GM=',num2str(2),'&'];
        vars = [vars, 'GM=',num2str(3),'&'];
    else
        vars = [vars, 'GM=','','&'];
    end
    if strcmp(coords,'GSE')
        vars = [vars, 'GSE=',num2str(1),'&'];
        vars = [vars, 'GSE=',num2str(2),'&'];
        vars = [vars, 'GSE=',num2str(3),'&'];
    else
        vars = [vars, 'GSE=','','&'];
    end
    if strcmp(coords,'GSM')
        vars = [vars, 'GSM=',num2str(1),'&'];
        vars = [vars, 'GSM=',num2str(2),'&'];
        vars = [vars, 'GSM=',num2str(3),'&'];
    else
        vars = [vars, 'GSM=','','&'];
    end
    if strcmp(coords,'SM')
        vars = [vars, 'SM=',num2str(1),'&'];
        vars = [vars, 'SM=',num2str(2),'&'];
        vars = [vars, 'SM=',num2str(3),'&'];
    else
        vars = [vars, 'SM=','','&'];
    end
    vars = [vars, 'REG_OPT=','','&'];
    vars = [vars, 'MNMX_FLTR_ACCURACY=',num2str(2),'&'];
    vars = [vars, 'FILTER_DIST_UNITS=',num2str(1),'&'];
    vars = [vars, 'EXTERNAL=',num2str(3),'&'];
    vars = [vars, 'EXT_T1989c=',num2str(1),'&'];
    vars = [vars, 'KP_LONG_89=',num2str(4),'&'];
    vars = [vars, 'INTERNAL=',num2str(1),'&'];
    vars = [vars, 'ALTITUDE=',num2str(100),'&'];
    vars = [vars, 'DAY=',num2str(2),'&'];
    vars = [vars, 'TIME=',num2str(2),'&'];
    vars = [vars, 'DISTANCE=',num2str(2),'&'];
    vars = [vars, 'DIST_DEC=',num2str(6),'&'];
    vars = [vars, 'DEG=',num2str(1),'&'];
    vars = [vars, 'DEG_DEC=',num2str(5),'&'];
    vars = [vars, 'DEG_DIR=',num2str(2),'&'];
    vars = [vars, 'OUTPUT_CDF=',num2str(1),'&'];
    vars = [vars, 'LINES_PAGE=',num2str(1),'&'];
    vars = [vars, 'PREV_SECTION=','SCS','&'];
    vars = [vars, 'SSC=','LOCATOR_GENERAL','&'];
    vars = [vars, 'SUBMIT=','Submit+query+and+wait+for+output','&'];
    vars = [vars, '.cgifields=','SPCR','&'];
 
    url_cgi=[url,vars];
    options = weboptions('Timeout',60);
    res=webread(url_cgi,options);
    lines=splitlines(res);
    
    % ============================================================
    % FIXED PARSING LOGIC - Works with new SSCWeb HTML format
    % ============================================================
    % Old code looked for satellite name as standalone line
    % New format has satellite name only in hidden input field
    % Solution: Find <pre> tag and extract all coordinate data
    
    index_pre_start = 0;
    index_end_data = 0;
    
    % Find <pre> tag that contains data (skip early ones in header)
    for i=100:size(lines,1)  % Start from line 100 to skip HTML header
        if contains(lines{i}, '<pre>') && ~contains(lines{i}, '</pre>')
            index_pre_start = i;
            break;
        end
    end
    
    % Find </pre></pre> tag (end of data section)
    for i=index_pre_start:size(lines,1)
        if strcmp(strtrim(lines{i}), '</pre></pre>')
            index_end_data = i;
            break;
        end
    end
    
    if index_pre_start > 0 && index_end_data > 0
        % Find first line with coordinate data (format: YYYY DDD HH:MM X Y Z)
        data_start = index_pre_start + 1;
        for i=data_start:index_end_data
            line_str = strtrim(lines{i});
            % Check if line matches coordinate pattern: starts with 4-digit year
            if length(line_str) > 10 && ~isempty(regexp(line_str, '^\d{4}\s+\d{1,3}\s+\d{2}:\d{2}', 'once'))
                data_start = i;
                break;
            end
        end
        
        % Extract raw data lines
        raw_data = lines(data_start:(index_end_data-1));
        
        % Parse coordinate data
        data = [];
        for i=1:length(raw_data)
            line_str = strtrim(raw_data{i});
            % Skip empty lines or HTML tags
            if isempty(line_str) || line_str(1) == '<'
                continue;
            end
            
            % Parse: YYYY DDD HH:MM X Y Z
            % Try to extract numbers
            tokens = sscanf(line_str, '%d %d %d:%d %f %f %f');
            if length(tokens) >= 7
                year = tokens(1);
                doy = tokens(2);  % Day of year
                hour = tokens(3);
                minute = tokens(4);
                x_coord = tokens(5);
                y_coord = tokens(6);
                z_coord = tokens(7);
                
                % Convert to MATLAB datenum
                matlab_time = datenum(year, 1, 1) + doy - 1 + hour/24 + minute/1440;
                
                % Store data
                data = [data; matlab_time, x_coord, y_coord, z_coord];
            end
        end
        
        % Interpolate to requested times
        if size(data,1) > 0
            x = interp1(data(:,1), data(:,2), matlabd, 'spline');
            y = interp1(data(:,1), data(:,3), matlabd, 'spline');
            z = interp1(data(:,1), data(:,4), matlabd, 'spline');
        else
            x = [];
            y = [];
            z = [];
        end
    else
        % Could not find data section
        x = [];
        y = [];
        z = [];
    end
end
