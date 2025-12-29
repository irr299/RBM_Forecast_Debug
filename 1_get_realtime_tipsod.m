%%
%
% Written by Ingo Michaelis, Jan 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, y, z]=get_realtime_tipsod(matlabd,sat,coords)
%     matlabd=linspace(datenum(2016,1,1,0,0,0),datenum(2017,1,1,0,0,0),8640);
%     matlabd=linspace(datenum(2018,1,24,0,0,0),datenum(2018,1,25,0,0,0),8640);
%     sat='rbspa';
    start_time=datestr(min(matlabd),'YYYY/mm/dd HH:MM:SS');
    stop_time=datestr(max(matlabd),'YYYY/mm/dd HH:MM:SS');
%     coords='GSM';
    
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
%     vars = [vars, 'OPT=','','&'];
%     vars = [vars, 'TRC_GEON=','','&'];
%     vars = [vars, 'TRC_GEOS=','','&'];
%     vars = [vars, 'TRC_GMN=','','&'];
%     vars = [vars, 'TRC_GMS=','','&'];
    vars = [vars, 'FILTER_DIST_UNITS=',num2str(1),'&'];
%     vars = [vars, 'TOD_APPLY_FILTER=','','&'];
%     vars = [vars, 'TODX_MNMX=','','&'];
%     vars = [vars, 'TOD_XGT=','','&'];
%     vars = [vars, 'TOD_XLT=','','&'];
%     vars = [vars, 'TODY_MNMX=','','&'];
%     vars = [vars, 'TOD_YGT=','','&'];
%     vars = [vars, 'TOD_YLT=','','&'];
%     vars = [vars, 'TODZ_MNMX=','','&'];
%     vars = [vars, 'TOD_ZGT=','','&'];
%     vars = [vars, 'TOD_ZLT=','','&'];
%     vars = [vars, 'TODLAT_MNMX=','','&'];
%     vars = [vars, 'TOD_LATGT=','','&'];
%     vars = [vars, 'TOD_LATLT=','','&'];
%     vars = [vars, 'TODLON_MNMX=','','&'];
%     vars = [vars, 'TOD_LONGT=','','&'];
%     vars = [vars, 'TOD_LONLT=','','&'];
%     vars = [vars, 'TODLT_MNMX=','','&'];
%     vars = [vars, 'TOD_LTGT=','','&'];
%     vars = [vars, 'TOD_LTLT=','','&'];
%     vars = [vars, 'J2000_APPLY_FILTER=','','&'];
%     vars = [vars, 'J2000X_MNMX=','','&'];
%     vars = [vars, 'J2000_XGT=','','&'];
%     vars = [vars, 'J2000_XLT=','','&'];
%     vars = [vars, 'J2000Y_MNMX=','','&'];
%     vars = [vars, 'J2000_YGT=','','&'];
%     vars = [vars, 'J2000_YLT=','','&'];
%     vars = [vars, 'J2000Z_MNMX=','','&'];
%     vars = [vars, 'J2000_ZGT=','','&'];
%     vars = [vars, 'J2000_ZLT=','','&'];
%     vars = [vars, 'J2000LAT_MNMX=','','&'];
%     vars = [vars, 'J2000_LATGT=','','&'];
%     vars = [vars, 'J2000_LATLT=','','&'];
%     vars = [vars, 'J2000LON_MNMX=','','&'];
%     vars = [vars, 'J2000_LONGT=','','&'];
%     vars = [vars, 'J2000_LONLT=','','&'];
%     vars = [vars, 'J2000LT_MNMX=','','&'];
%     vars = [vars, 'J2000_LTGT=','','&'];
%     vars = [vars, 'J2000_LTLT=','','&'];
%     vars = [vars, 'GEO_APPLY_FILTER=','','&'];
%     vars = [vars, 'GEOX_MNMX=','','&'];
%     vars = [vars, 'GEO_XGT=','','&'];
%     vars = [vars, 'GEO_XLT=','','&'];
%     vars = [vars, 'GEOY_MNMX=','','&'];
%     vars = [vars, 'GEO_YGT=','','&'];
%     vars = [vars, 'GEO_YLT=','','&'];
%     vars = [vars, 'GEOZ_MNMX=','','&'];
%     vars = [vars, 'GEO_ZGT=','','&'];
%     vars = [vars, 'GEO_ZLT=','','&'];
%     vars = [vars, 'GEOLAT_MNMX=','','&'];
%     vars = [vars, 'GEO_LATGT=','','&'];
%     vars = [vars, 'GEO_LATLT=','','&'];
%     vars = [vars, 'GEOLON_MNMX=','','&'];
%     vars = [vars, 'GEO_LONGT=','','&'];
%     vars = [vars, 'GEO_LONLT=','','&'];
%     vars = [vars, 'GEOLT_MNMX=','','&'];
%     vars = [vars, 'GEO_LTGT=','','&'];
%     vars = [vars, 'GEO_LTLT=','','&'];
%     vars = [vars, 'GM_APPLY_FILTER=','','&'];
%     vars = [vars, 'GMX_MNMX=','','&'];
%     vars = [vars, 'GM_XGT=','','&'];
%     vars = [vars, 'GM_XLT=','','&'];
%     vars = [vars, 'GMY_MNMX=','','&'];
%     vars = [vars, 'GM_YGT=','','&'];
%     vars = [vars, 'GM_YLT=','','&'];
%     vars = [vars, 'GMZ_MNMX=','','&'];
%     vars = [vars, 'GM_ZGT=','','&'];
%     vars = [vars, 'GM_ZLT=','','&'];
%     vars = [vars, 'GMLAT_MNMX=','','&'];
%     vars = [vars, 'GM_LATGT=','','&'];
%     vars = [vars, 'GM_LATLT=','','&'];
%     vars = [vars, 'GMLON_MNMX=','','&'];
%     vars = [vars, 'GM_LONGT=','','&'];
%     vars = [vars, 'GM_LONLT=','','&'];
%     vars = [vars, 'GMLT_MNMX=','','&'];
%     vars = [vars, 'GM_LTGT=','','&'];
%     vars = [vars, 'GM_LTLT=','','&'];
%     vars = [vars, 'GSE_APPLY_FILTER=','','&'];
%     vars = [vars, 'GSEX_MNMX=','','&'];
%     vars = [vars, 'GSE_XGT=','','&'];
%     vars = [vars, 'GSE_XLT=','','&'];
%     vars = [vars, 'GSEY_MNMX=','','&'];
%     vars = [vars, 'GSE_YGT=','','&'];
%     vars = [vars, 'GSE_YLT=','','&'];
%     vars = [vars, 'GSEZ_MNMX=','','&'];
%     vars = [vars, 'GSE_ZGT=','','&'];
%     vars = [vars, 'GSE_ZLT=','','&'];
%     vars = [vars, 'GSELAT_MNMX=','','&'];
%     vars = [vars, 'GSE_LATGT=','','&'];
%     vars = [vars, 'GSE_LATLT=','','&'];
%     vars = [vars, 'GSELON_MNMX=','','&'];
%     vars = [vars, 'GSE_LONGT=','','&'];
%     vars = [vars, 'GSE_LONLT=','','&'];
%     vars = [vars, 'GSELT_MNMX=','','&'];
%     vars = [vars, 'GSE_LTGT=','','&'];
%     vars = [vars, 'GSE_LTLT=','','&'];
%     vars = [vars, 'GSM_APPLY_FILTER=','','&'];
%     vars = [vars, 'GSMX_MNMX=','','&'];
%     vars = [vars, 'GSM_XGT=','','&'];
%     vars = [vars, 'GSM_XLT=','','&'];
%     vars = [vars, 'GSMY_MNMX=','','&'];
%     vars = [vars, 'GSM_YGT=','','&'];
%     vars = [vars, 'GSM_YLT=','','&'];
%     vars = [vars, 'GSMZ_MNMX=','','&'];
%     vars = [vars, 'GSM_ZGT=','','&'];
%     vars = [vars, 'GSM_ZLT=','','&'];
%     vars = [vars, 'GSMLAT_MNMX=','','&'];
%     vars = [vars, 'GSM_LATGT=','','&'];
%     vars = [vars, 'GSM_LATLT=','','&'];
%     vars = [vars, 'GSMLON_MNMX=','','&'];
%     vars = [vars, 'GSM_LONGT=','','&'];
%     vars = [vars, 'GSM_LONLT=','','&'];
%     vars = [vars, 'GSMLT_MNMX=','','&'];
%     vars = [vars, 'GSM_LTGT=','','&'];
%     vars = [vars, 'GSM_LTLT=','','&'];
%     vars = [vars, 'SM_APPLY_FILTER=','','&'];
%     vars = [vars, 'SMX_MNMX=','','&'];
%     vars = [vars, 'SM_XGT=','','&'];
%     vars = [vars, 'SM_XLT=','','&'];
%     vars = [vars, 'SMY_MNMX=','','&'];
%     vars = [vars, 'SM_YGT=','','&'];
%     vars = [vars, 'SM_YLT=','','&'];
%     vars = [vars, 'SMZ_MNMX=','','&'];
%     vars = [vars, 'SM_ZGT=','','&'];
%     vars = [vars, 'SM_ZLT=','','&'];
%     vars = [vars, 'SMLAT_MNMX=','','&'];
%     vars = [vars, 'SM_LATGT=','','&'];
%     vars = [vars, 'SM_LATLT=','','&'];
%     vars = [vars, 'SMLON_MNMX=','','&'];
%     vars = [vars, 'SM_LONGT=','','&'];
%     vars = [vars, 'SM_LONLT=','','&'];
%     vars = [vars, 'SMLT_MNMX=','','&'];
%     vars = [vars, 'SM_LTGT=','','&'];
%     vars = [vars, 'SM_LTLT=','','&'];
    vars = [vars, 'OTHER_FILTER_DIST_UNITS=',num2str(1),'&'];
%     vars = [vars, 'RD_APPLY=','','&'];
%     vars = [vars, 'FS_APPLY=','','&'];
%     vars = [vars, 'NS_APPLY=','','&'];
%     vars = [vars, 'BS_APPLY=','','&'];
%     vars = [vars, 'MG_APPLY=','','&'];
%     vars = [vars, 'LV_APPLY=','','&'];
%     vars = [vars, 'IL_APPLY=','','&'];
%     vars = [vars, 'REG_FLTR_SWITCH=','','&'];
%     vars = [vars, 'SCR_APPLY=','','&'];
%     vars = [vars, 'SCR=','','&'];
%     vars = [vars, 'RTR_APPLY=','','&'];
%     vars = [vars, 'RTR=','','&'];
%     vars = [vars, 'BTR_APPLY=','','&'];
%     vars = [vars, 'NBTR=','','&'];
%     vars = [vars, 'SBTR=','','&'];
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
%     vars = [vars, 'RNG_FLTR_METHOD=','','&'];
    vars = [vars, 'PREV_SECTION=','SCS','&'];
    vars = [vars, 'SSC=','LOCATOR_GENERAL','&'];
    vars = [vars, 'SUBMIT=','Submit+query+and+wait+for+output','&'];
    vars = [vars, '.cgifields=','SPCR','&'];
 
    url_cgi=[url,vars];
%     options = weboptions;
%     options.Timeout=60;
    options = weboptions('Timeout',60);
    res=webread(url_cgi,options);
%     res=webread(url_cgi);
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

%     hold on
%     plot(matlabd,x,'r-');
%     plot(data(:,1),data(:,2),'r.');
%     hold off
%     hold on
%     plot(matlabd,y,'g-');
%     plot(data(:,1),data(:,3),'g.');
%     hold off
%     hold on
%     plot(matlabd,z,'b-');
%     plot(data(:,1),data(:,4),'b.');
%     hold off
end    

% matlabd=linspace(datenum(2018,1,24,0,0,0),datenum(2018,1,25,0,0,0),8640);
% sat='rbspa';
% start_time=datetime(2018,1,24);
% stop_time=datetime(2018,1,24,23,59,59);
% coords='GSM';
% [x,y,z]=get_tipsod_realtime(matlabd,sat,coords);
