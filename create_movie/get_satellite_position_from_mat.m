%%
%
% Written by Ingo Michaelis, Jan 2020
% Modified by: I. Johnson, Dec 30, 2025 - Updating to handle the Satellite name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, y, z]=get_satellite_position_from_mat(matlabd,sat,coords,path)
%     matlabd=linspace(datenum(2020,1,21,0,0,0),datenum(2020,1,23,0,0,0),8640);
%     sat='arase';
%     coords='GSE';
%     path='/export/mag5/data/realtime-rbm-data/Realtime_Data/satellite_position_stream/';
    tmp=datevec(min(matlabd));start_datenum=datenum(tmp(1),tmp(2),tmp(3));
    tmp=datevec(max(matlabd)+1);stop_datenum=datenum(tmp(1),tmp(2),tmp(3));

    sel_files=[];
    sel_filedates=[];
    all_pos_data=[];
    
    % Map logical satellite names to actual satellite directory names
    % This handles the case where forecast code uses "goes_primary" but
    % position files are in "goes18" directory
    sat_map = struct('goes_primary', 'goes18', 'goes_secondary', 'goes16');
    if isfield(sat_map, sat)
        sat_dir = sat_map.(sat);
    else
        sat_dir = sat;
    end
    
    % Search for position files - try both the mapped name and original name
    posFiles=dir([path,sat_dir,'/*/*/',sat_dir,'*.mat']);
    if isempty(posFiles) && ~strcmp(sat_dir, sat)
        % Fallback: try with original satellite name
        posFiles=dir([path,sat,'/*/*/',sat,'*.mat']);
    end
    for i=1:length(posFiles)
        posFile=posFiles(i);
        dstr=strsplit(posFile.name,'-');
        dstr=dstr{1,3};
        dstr=strsplit(dstr,'.');
        dstr=dstr{1,1};
        
        year= str2double(dstr(1:4));
        month= str2double(dstr(5:6));
        day= str2double(dstr(7:8));
        utc=datenum(datetime(year,month,day));
        if (utc>=start_datenum) & (utc<=stop_datenum)
            sel_files=[sel_files i];
            sel_filedates=[sel_filedates utc];
            pos_file=strcat(posFile.folder,'/',posFile.name);
            tmp=load(pos_file);
            if isequal(coords,'GEO')
                all_pos_data=[all_pos_data [tmp.Datetime;tmp.GEO_x_RE;tmp.GEO_y_RE;tmp.GEO_z_RE]'];
            elseif isequal(coords,'GSE')
%                 all_pos_data=[all_pos_data [tmp.Datetime;tmp.GSE_x_RE;tmp.GSE_y_RE;tmp.GSE_z_RE]'];
                all_pos_data=cat(1,all_pos_data,[tmp.Datetime;tmp.GSE_x_RE;tmp.GSE_y_RE;tmp.GSE_z_RE]');
            elseif isequal(coords,'GSM')
                all_pos_data=[all_pos_data [tmp.Datetime;tmp.GSM_x_RE;tmp.GSM_y_RE;tmp.GSM_z_RE]'];
            end
        end
    end
    if size(all_pos_data,1)>1
        [~,sel]=unique(all_pos_data(:,1));
        all_pos_data=all_pos_data(sel,:);
    end
    if size(all_pos_data,1)>1
        x=interp1(all_pos_data(:,1),all_pos_data(:,2),matlabd,'linear');
        y=interp1(all_pos_data(:,1),all_pos_data(:,3),matlabd,'linear');
        z=interp1(all_pos_data(:,1),all_pos_data(:,4),matlabd,'linear');
        % fill missing data from TIPSOD website
        sel=isnan(x);
        if sum(sel)>0
            try
                [xi,yi,zi]=get_realtime_tipsod(matlabd(sel),sat,coords);
                x(sel)=xi./6371.2;
                y(sel)=yi./6371.2;
                z(sel)=zi./6371.2;
            catch
                fprintf('%s','no data loaded from TIPSOD to fill gaps')
            end
        end
    else
        x=[];
        y=[];
        z=[];
    end
end    

% matlabd=linspace(datenum(2020,1,21,0,0,0),datenum(2020,1,23,0,0,0),8640);
% sat='arase';
% start_datenum=min(matlabd);
% stop_datenum=max(matlabd);
% coords='GSE';
% path='/export/mag5/data/realtime-rbm-data/Realtime_Data/satellite_position_stream/';
% [x,y,z]=get_satellite_position_from_mat(matlabd,sat,coords,path);
