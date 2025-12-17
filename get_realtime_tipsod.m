%%
%
% Written by Ingo Michaelis, Jan 2018
% Modified by I. Johnson, Dec 2025
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
    vars = [vars, 'OTHER_FILTER_DIST_UNITS=',num2str(1),'&'];
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
    
    index_sat=0;
    i=1;
    while i<=size(lines,1)
        if strcmp(lines(i,1),sat)
            index_sat=i;
            i=i+1;
        elseif strcmp(lines(i,1),'</pre></pre>')
            index_end_data=i;
            i=i+1;
        else
            i=i+1;
        end
    end
    
    if index_sat>0
        data_header=lines(index_sat+2,1);
        data_header=data_header{1,1};
        data_header=strsplit(strtrim(data_header));
        raw_data=lines((index_sat+4):(index_end_data-1),1);

        data=zeros(size(raw_data,1),6);
        for i=1:size(raw_data,1)
            line=raw_data(i,1);
            line=line{1,1};
            line=strsplit(strtrim(line));
            data(i,1)=datenum(sprintf('%s %s',line{1,1},line{1,2}),'yy/mm/dd HH:MM:SS');
            data(i,2)=str2num(line{1,3});
            data(i,3)=str2num(line{1,4});
            data(i,4)=str2num(line{1,5});
        end

        x=interp1(data(:,1),data(:,2),matlabd,'spline');
        y=interp1(data(:,1),data(:,3),matlabd,'spline');
        z=interp1(data(:,1),data(:,4),matlabd,'spline');
    else
        x=[];
        y=[];
        z=[];
    end

end    
% stop_time=datetime(2018,1,24,23,59,59);
% coords='GSM';
% [x,y,z]=get_tipsod_realtime(matlabd,sat,coords);
