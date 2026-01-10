%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), 2019
% Updated by ; I. Johnson, Jan, 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  [sw,mag] = get_realtime_ace_sw_mag_from_mat(path_ace,matlabd,prop,time_start,time_end)
    sw.matlabd=[];sw.jd=[];sw.stat=[];sw.swn=[];sw.swv=[];sw.swT=[];
    mag.matlabd=[];mag.jd=[];mag.stat=[];mag.bx=[];mag.by=[];mag.bz=[];mag.bt=[];mag.lat=[];mag.lon=[];
    in_sw.matlabd=[];in_sw.jd=[];in_sw.stat=[];in_sw.swn=[];in_sw.swv=[];in_sw.swT=[];
    in_mag.matlabd=[];in_mag.jd=[];in_mag.stat=[];in_mag.bx=[];in_mag.by=[];in_mag.bz=[];in_mag.bt=[];in_mag.lat=[];in_mag.lon=[];
    if ~isempty(matlabd)
        time_start=floor(min(matlabd));
        time_end=ceil(max(matlabd));
    else
        matlabd=time_start:time_end;
    end
    for day=time_start:time_end
        in_sw_file=strcat(path_ace,"swepam_1m/",datestr(datenum(day),'YYYYmm'),"/","ace_swepam_1m_",datestr(datenum(day),'YYYYmmdd'),".mat");
        fprintf('%s\n',in_sw_file);
        if exist(in_sw_file, 'file')
            % Check if file is not empty (0 bytes)
            file_info = dir(in_sw_file);
            if file_info.bytes > 0
                try
                    data=load(in_sw_file);
                    % Check if data structure is valid
                    if isfield(data, 'data') && isfield(data.data, 'matlabd') && ~isempty(data.data.matlabd)
                        in_sw.matlabd=cat(1,in_sw.matlabd,data.data.matlabd);
                        in_sw.jd=cat(1,in_sw.jd,data.data.jd);
                        in_sw.stat=cat(1,in_sw.stat,data.data.status);
                        in_sw.swn=cat(1,in_sw.swn,data.data.swn);
                        in_sw.swv=cat(1,in_sw.swv,data.data.swv);
                        in_sw.swT=cat(1,in_sw.swT,data.data.swT);
                    else
                        fprintf('Warning: File %s exists but has invalid structure, skipping.\n', in_sw_file);
                    end
                catch ME
                    fprintf('Warning: Error loading file %s: %s\n', in_sw_file, ME.message);
                end
            else
                fprintf('Warning: File %s is empty (0 bytes), skipping.\n', in_sw_file);
            end
        else
            fprintf('Warning: File %s does not exist, skipping.\n', in_sw_file);
        end

        in_mag_file=strcat(path_ace,"/mag_1m/",datestr(datenum(day),'YYYYmm'),"/","ace_mag_1m_",datestr(datenum(day),'YYYYmmdd'),".mat");
        fprintf('%s\n',in_mag_file);
        if exist(in_mag_file, 'file')
            % Check if file is not empty (0 bytes)
            file_info = dir(in_mag_file);
            if file_info.bytes > 0
                try
                    data=load(in_mag_file);
                    % Check if data structure is valid
                    if isfield(data, 'data') && isfield(data.data, 'matlabd') && ~isempty(data.data.matlabd)
                        in_mag.matlabd=cat(1,in_mag.matlabd,data.data.matlabd);
                        in_mag.jd=cat(1,in_mag.jd,data.data.jd);
                        in_mag.stat=cat(1,in_mag.stat,data.data.status);
                        in_mag.bx=cat(1,in_mag.bx,data.data.bx);
                        in_mag.by=cat(1,in_mag.by,data.data.by);
                        in_mag.bz=cat(1,in_mag.bz,data.data.bz);
                        in_mag.bt=cat(1,in_mag.bt,data.data.bt);
                        in_mag.lat=cat(1,in_mag.lat,data.data.lat);
                        in_mag.lon=cat(1,in_mag.lon,data.data.lon);
                    else
                        fprintf('Warning: File %s exists but has invalid structure, skipping.\n', in_mag_file);
                    end
                catch ME
                    fprintf('Warning: Error loading file %s: %s\n', in_mag_file, ME.message);
                end
            else
                fprintf('Warning: File %s is empty (0 bytes), skipping.\n', in_mag_file);
            end
        else
            fprintf('Warning: File %s does not exist, skipping.\n', in_mag_file);
        end
    end
    
    if prop
        % Check if we have any data before processing
        if isempty(in_sw.matlabd) && isempty(in_mag.matlabd)
            fprintf('Warning: No ACE data loaded for time range %s to %s\n', datestr(time_start), datestr(time_end));
            % Return empty arrays with NaN values
            sw.matlabd=matlabd;
            sw.jd=nan(size(matlabd));
            sw.stat=nan(size(matlabd));
            sw.swn=nan(size(matlabd));
            sw.swv=nan(size(matlabd));
            sw.swT=nan(size(matlabd));
            
            mag.matlabd=matlabd;
            mag.jd=nan(size(matlabd));
            mag.stat=nan(size(matlabd));
            mag.bx=nan(size(matlabd));
            mag.by=nan(size(matlabd));
            mag.bz=nan(size(matlabd));
            mag.bt=nan(size(matlabd));
            mag.lat=nan(size(matlabd));
            mag.lon=nan(size(matlabd));
        else
            [sw_prop,mag_prop] = ace_sw_mag_prop_simple( ...
                                cat(2,in_sw.matlabd,in_sw.jd,in_sw.stat,in_sw.swn,in_sw.swv,in_sw.swT), ...
                                cat(2,in_mag.matlabd,in_mag.jd,in_mag.stat,in_mag.bx,in_mag.by,in_mag.bz,in_mag.bt,in_mag.lat,in_mag.lon) ...
                                );
            sw.matlabd=matlabd;
            % Check if propagation produced valid data
            if ~isempty(sw_prop) && size(sw_prop,1) > 0 && ~isempty(sw_prop(:,1))
                % Use 'extrap' to handle gaps in data (will extrapolate or use NaN for out-of-range)
                sw.jd=interp1(sw_prop(:,1),sw_prop(:,2),sw.matlabd,'linear','extrap');
                sw.stat=interp1(sw_prop(:,1),sw_prop(:,3),sw.matlabd,'nearest','extrap');
                sw.swn=interp1(sw_prop(:,1),sw_prop(:,4),sw.matlabd,'linear','extrap');
                sw.swv=interp1(sw_prop(:,1),sw_prop(:,5),sw.matlabd,'linear','extrap');
                sw.swT=interp1(sw_prop(:,1),sw_prop(:,6),sw.matlabd,'linear','extrap');
            else
                fprintf('Warning: No valid solar wind data after propagation, using NaN values.\n');
                sw.jd=nan(size(matlabd));
                sw.stat=nan(size(matlabd));
                sw.swn=nan(size(matlabd));
                sw.swv=nan(size(matlabd));
                sw.swT=nan(size(matlabd));
            end

            mag.matlabd=matlabd;
            if ~isempty(mag_prop) && size(mag_prop,1) > 0 && ~isempty(mag_prop(:,1))
                mag.jd=interp1(mag_prop(:,1),mag_prop(:,2),mag.matlabd,'linear','extrap');
                mag.stat=interp1(mag_prop(:,1),mag_prop(:,3),mag.matlabd,'nearest','extrap');
                mag.bx=interp1(mag_prop(:,1),mag_prop(:,4),mag.matlabd,'linear','extrap');
                mag.by=interp1(mag_prop(:,1),mag_prop(:,5),mag.matlabd,'linear','extrap');
                mag.bz=interp1(mag_prop(:,1),mag_prop(:,6),mag.matlabd,'linear','extrap');
                mag.bt=interp1(mag_prop(:,1),mag_prop(:,7),mag.matlabd,'linear','extrap');
                mag.lat=interp1(mag_prop(:,1),mag_prop(:,8),mag.matlabd,'linear','extrap');
                mag.lon=interp1(mag_prop(:,1),mag_prop(:,9),mag.matlabd,'linear','extrap');
            else
                fprintf('Warning: No valid magnetic field data after propagation, using NaN values.\n');
                mag.jd=nan(size(matlabd));
                mag.stat=nan(size(matlabd));
                mag.bx=nan(size(matlabd));
                mag.by=nan(size(matlabd));
                mag.bz=nan(size(matlabd));
                mag.bt=nan(size(matlabd));
                mag.lat=nan(size(matlabd));
                mag.lon=nan(size(matlabd));
            end
        end
        
    else
        sw.matlabd=matlabd;
        sw.jd=interp1(in.matlabd,in_sw.jd,matlabd,'linear');
        sw.stat=interp1(in.matlabd,in_sw.stat,matlabd,'nearest');
        sw.swn=interp1(in.matlabd,in_sw.swn,matlabd,'linear');
        sw.swv=interp1(in.matlabd,in_sw.swv,matlabd,'linear');
        sw.swT=interp1(in.matlabd,in_sw.swT,matlabd,'linear');

        mag.matlabd=matlabd;
        mag.jd=interp1(in_mag.matlabd,in_mag.jd,matlabd,'linear');
        mag.stat=interp1(in_mag.matlabd,in_mag.stat,matlabd,'nearest');
        mag.bx=interp1(in_mag.matlabd,in_mag.bx,matlabd,'linear');
        mag.by=interp1(in_mag.matlabd,in_mag.by,matlabd,'linear');
        mag.bz=interp1(in_mag.matlabd,in_mag.bz,matlabd,'linear');
        mag.bt=interp1(in_mag.matlabd,in_mag.bt,matlabd,'linear');
        mag.lat=interp1(in_mag.matlabd,in_mag.lat,matlabd,'linear');
        mag.lon=interp1(in_mag.matlabd,in_mag.lon,matlabd,'linear');
    end
return;

% path_ace=getenv("FC_ACE_REALTIME_PROCESSED_DATA_DIR");
% time_start=datenum(2019,8,15);
% time_end=datenum(2019,8,22);
% matlabd=time_start:.5:time_end;
% prop=0;
% sw=get_realtime_ace_sw_from_mat(path_ace,matlabd,prop)
% 

