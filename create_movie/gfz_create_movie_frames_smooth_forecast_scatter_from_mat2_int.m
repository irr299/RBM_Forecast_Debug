%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), Jan, 2020
% Updated by ; I. Johnson, Jan, 2026
% Updated by ; I. Johnson, Feb, 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
addpath([getenv('FC_HOME'),'/Functions/'])
addpath([getenv('FC_HOME'),'/FunctionsPlot/'])
addpath(getenv('FC_IRBEM_HOME'))
onera_desp_lib_load(getenv('FC_IRBEM'))

% read configuration file for panels
conf_movie_frames_scatter
name_part='E_1_MeV_PA_50';
da_days=7;
fc_days=2;

simulationDir=[getenv('FC_MAT')];
sel_files=[];
sel_filedates=[];
all_forecast_data=struct([]);  % Initialize as empty struct array
simulationFiles=dir([simulationDir,'/*/','Forecast_',name_part,'_UTC_*.mat']);
for i=1:length(simulationFiles)
    simulationFile=simulationFiles(i);
    if ~strcmp(simulationFile.name,['Forecast_',name_part,'_UTC_latest.mat'])
        year= str2double(simulationFile.name(28:31));
        month= str2double(simulationFile.name(32:33));
        day= str2double(simulationFile.name(34:35));
        hour= str2double(simulationFile.name(37:38));
        minute= str2double(simulationFile.name(39:40));
        second= str2double(simulationFile.name(41:42));
        utc=datenum(datetime(year,month,day,hour,minute,second));
        if utc>=(now()-da_days)
            sel_files=[sel_files i];
            sel_filedates=[sel_filedates utc];
            forecast_file=strcat(simulationFile.folder,'/',simulationFile.name);
            tmp_forecast_data=load(forecast_file);
            if ~isfield(tmp_forecast_data,'rb_index')
                tmp_forecast_data.rb_index=[];
            end
            if ~isfield(tmp_forecast_data,'obs_flux')
                tmp_forecast_data.obs_flux=[];
            end
            if ~isfield(tmp_forecast_data,'sat_energies')
                tmp_forecast_data.sat_energies=[];
            end
            if ~isfield(tmp_forecast_data, 'Kp_source')
                tmp_forecast_data.Kp_source=[];
            else
                disp('No field Kp_source')
            end
            if ~isfield(tmp_forecast_data, 'mp_loc')
                tmp_forecast_data.mp_loc=[];
            else
                disp('No field mp_loc')
            end
            % Properly append to struct array
            if isempty(all_forecast_data)
                all_forecast_data = tmp_forecast_data;
            else
                all_forecast_data(end+1) = tmp_forecast_data;
            end
        end
    end
end
simulationFiles=simulationFiles(sel_files);

% create a plot every 5 minutes which is time resolution of TIPSOD
% act_time=datetime('now','timezone','utc');
act_time=clock;
act_time=datetime(act_time(1),act_time(2),act_time(3),act_time(4),0,0);
% start_date=datenum(act_time)-da_days;
start_date=datenum(act_time)-1; % changed to only 1 day for quicker plot production
end_date=datenum(act_time);
dt=5/86400*60;

time_vec = start_date:dt:end_date;
n_steps = numel(time_vec);

% disp("Number of time steps for video: ", n_steps)

parpool(24);

% for act_date=start_date:dt:end_date
% for act_date=start_date:dt:end_date
parfor (step_idx = 1:n_steps, 24)
    % CRITICAL: Load IRBEM library and set paths in each parallel worker
    % The library must be loaded in each worker session for field line tracing to work
    addpath([getenv('FC_HOME'),'/Functions/'])
    addpath([getenv('FC_HOME'),'/FunctionsPlot/'])
    addpath(getenv('FC_IRBEM_HOME'))
    onera_desp_lib_load(getenv('FC_IRBEM'))
    
    % CRITICAL: Ensure FC_SAT_POSITION_DIR is set in each worker
    % This is needed for satellite position retrieval in gfz_plot_object_sat
    if isempty(getenv('FC_SAT_POSITION_DIR'))
        setenv('FC_SAT_POSITION_DIR', '/PAGER/WP6/data/outputs/RBM_Forecast/realtime_stream/satellite_position_stream/');
    end
    
    tic
    act_date = time_vec(step_idx);
    % get array index for forecast mat-file closest to plot date
    if ~isempty(all_forecast_data)
        [M,all_index] = min(abs([all_forecast_data.utc]-act_date));
        forecast_data=all_forecast_data(all_index);
    else
        fprintf('Warning: No forecast data available, skipping step %d\n', step_idx);
        continue;
    end
%     forecast_data.times=forecast_data.times-((forecast_data.times(2)-forecast_data.times(1))/2);
    % get array index for actual time
    t_index=find(abs(forecast_data.times-forecast_data.utc)<1e-9);
    fprintf('index: %s\n',datestr(act_date,'YYYY-mm-dd HH:MM:SS'));

    nrow=8;
    ncol=2;
    [status, msg, msgID] = mkdir('./frames_scatter_smooth');
    [status, msg, msgID] = mkdir(sprintf('./frames_scatter_smooth/%s',datestr(act_date,'YYYYmmdd')));
    output_anim_file=sprintf('./frames_scatter_smooth/%s/Forecast_%s_UTC_%s.png',datestr(act_date,'YYYYmmdd'),name_part,datestr(act_date,'YYYYmmddTHHMMSS'));
    output_test_anim_file=sprintf('./Forecast_%s_UTC_%s.png',datestr(act_date,'YYYYmmdd'),name_part,datestr(act_date,'YYYYmmddTHHMMSS'));
    fprintf('Processing file %s\n',output_anim_file);

    if exist(output_anim_file, "file")==0
        if isempty(dir(output_anim_file))
            fprintf('Create file %s\n',output_anim_file);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % plot figures for website animation
%             fig1=figure('visible', 'off');
            fig1=figure('visible', 'on');
            % paper definition
            fig1.Position = [0 0 1920 1080];
            fig1.PaperUnits = 'inches';
            fig1.PaperPosition = [0 0 16 9];
            fig1.PaperPositionMode = 'manual';
            %fig1.Units = 'pixels';
            %fig1.Position = out_resolution;
            %fig1.Resize='off';
            %fig1.InnerPosition = out_resolution;
            %fig1.OuterPosition = out_resolution;
            %set(fig1, 'visible', 'off')
%             set(gcf,'Resize','off')
            % set current figure without putting it to foreground
            set(groot, 'currentfigure', fig1);
%             kext=0;% for IGRF
%             kext=4;% for T89
            maginput=zeros(25,1);maginput(1)=forecast_data.Kp(t_index);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('plot bfield and satellite orbits\n')
            % get list of involved satellites
            sats=forecast_data.sat_names;
%             kext=0;% for IGRF
            kext=4;% for T89
            cells=[1,3,5,7];
            axial_tilt = -23.44;
            [ax_bfield_sat]=gfz_plot_panel_bfield_sat( ...
                nrow,ncol,cells, ...
                act_date,sats,kext,maginput, ...
                conf_panel_bfield);
    %         set(ax_bfield_sat,'position',fc_pos.bfield_sat_pos,'units','normalized');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('plot model donuts\n');
            cells=[9,11,13,15];
            sats=forecast_data.sat_names;
            [ax_donut,ax_donut_colbar]=gfz_plot_panel_donuts_scatter_3d(...
                nrow,ncol,cells, ...
                act_date,forecast_data.L_T89,forecast_data.flux(t_index,:), ...
                sats,kext,maginput, ...
                conf_panel_donut_scatter);

            set(ax_donut_colbar,'pos',conf_panel_donut_scatter.pos.flux_donut_colorbar);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('select available satellites\n');
            % plot real-time data
            sat_names='';
            for i=1:size(forecast_data.sat_names,1)
                sat_names=[sat_names sprintf('%s',upper(forecast_data.sat_names{i,1}))];
                if i<size(forecast_data.sat_names,1)
                    sat_names=[sat_names ', '];
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('plot data\n');
            % plot real-time data
            cells=[2,4];
            % Rolling window: scroll x-axis with act_date so right panels animate
            time_range=[act_date - da_days, act_date + fc_days];
            forecast_data.timesd = forecast_data.timesd(1:4:end);
            forecast_data.L_T89d = forecast_data.L_T89d(1:4:end);
            forecast_data.fluxd = forecast_data.fluxd(1:4:end, :); 
            [ax_real,ax_real_color]=gfz_plot_panel_data(...
                nrow,ncol,cells,...
                forecast_data.utc,forecast_data.timesd,forecast_data.L_T89d,forecast_data.fluxd, ...
                time_range, ...
                sat_names, ...
                conf_panel_data);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('plot interpolated data\n');
            cells=[6,8];
            % plot simulated data
            % PLOTTING, use pcolor as a default
            [ax_sim]=gfz_plot_panel_interpdata( ...
                nrow,ncol,cells, ...
                forecast_data.energy,forecast_data.pa, ...
                forecast_data.utc,forecast_data.times,forecast_data.L_T89,forecast_data.obs_flux, ...
                time_range, ...
                sat_names, ...
                conf_panel_sim);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('plot model\n');
            cells=[10,12];
            % plot simulated data
            % PLOTTING, use pcolor as a default
            [ax_sim]=gfz_plot_panel_sim( ...
                nrow,ncol,cells, ...
                forecast_data.energy,forecast_data.pa, ...
                forecast_data.utc,forecast_data.times,forecast_data.L_T89,forecast_data.flux, ...
                time_range, ...
                conf_panel_sim);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % plot solar wind data
            cells=14;
            [ax_sw]=gfz_plot_panel_sw(...
                nrow,ncol,cells, ...
                forecast_data.utc,forecast_data.times, ...
                forecast_data.sw_n,forecast_data.sw_v, ...
                time_range, ...
                conf_panel_sw);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % plot Kp
            cells=16;
            [ax_kp]=gfz_plot_panel_kp(...
                nrow,ncol,cells, ...
                forecast_data.utc,forecast_data.times, ...
                forecast_data.Kp,forecast_data.Kp_source, ...
                time_range, ...
                conf_panel_kp);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fprintf('plot title\n');
            a = axes;
            ax_title = title(strcat('Real-time Radiation Belt Forecast v2, ',datestr(act_date,' HH:MM, mmm dd, yyyy'),' UTC'));
            a.Visible = 'off'; % set(a,'Visible','off');
            ax_title.Visible = 'on'; % set(t1,'Visible','on');
            set(ax_title,'Color',conf_panel_title.color.title,'FontWeight','bold','FontSize',conf_panel_title.scale.title);
            a.Position=conf_panel_title.pos.title;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            hold off
            % fprintf('save plot\n');
            %set(fig1,'color',[0.3 0.3 0.3])
            set(fig1, 'visible', 'off')
            fig1.Color='black';
            fig1.InvertHardcopy = 'off';
            %saveas(fig1,output_anim_file);
%                 print(fig1,output_anim_file,'-dpng','-r120')
            %hgexport(fig1,output_anim_file);
            F = getframe(fig1); % get rendered grid from figure
            imwrite(F.cdata, output_anim_file)  % write rendered figure to png-file
            %exportgraphics(fig1,output_test_anim_file,'BackgroundColor','black','ContentType','image','Resolution',300);
%                 imwrite(F.cdata, 'test.png')
%             set(fig1, 'visible', 'on')
            clf(fig1);
            close(fig1);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        % clear maginput;clear sats;clear timerange;
    end
    toc
    % clear forecast_data
end
exit;


