%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), Jan, 2020
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

simulationDir=[getenv('FC_OUTPUT_ENSEMBLE_MAT')];
sel_files=[];
sel_filedates=[];
all_forecast_data=[]
simulationFiles=dir([simulationDir,'/*/','Forecast_mean_ensemble_',name_part,'_UTC_*.mat']);
for i=1:length(simulationFiles)
    simulationFile=simulationFiles(i);
    if ~strcmp(simulationFile.name,['Forecast_mean_ensemble_',name_part,'_UTC_latest.mat'])
        year= str2double(simulationFile.name(42:45));
        month= str2double(simulationFile.name(46:47));
        day= str2double(simulationFile.name(48:49));
        hour= str2double(simulationFile.name(51:52));
        minute= str2double(simulationFile.name(53:54));
        second= str2double(simulationFile.name(55:56));
        utc=datenum(datetime(year,month,day,hour,minute,second));
        if utc>=(now()-da_days)
            sel_files=[sel_files i];
            sel_filedates=[sel_filedates utc];
            forecast_file=strcat(simulationFile.folder,'/',simulationFile.name);
            tmp_forecast_data=load(forecast_file);
            if size(tmp_forecast_data.timesd, 1) ~= 1
                tmp_forecast_data.timesd = reshape(tmp_forecast_data.timesd, 1, []);
            end
            if ~isfield(tmp_forecast_data,'rb_index')
                tmp_forecast_data.rb_index=[];
            end
            if ~isfield(tmp_forecast_data,'obs_flux')
                tmp_forecast_data.obs_flux=[];
            end
            if ~isfield(tmp_forecast_data,'sat_energies')
                tmp_forecast_data.sat_energies=[];
            end
            all_forecast_data=[all_forecast_data tmp_forecast_data];
        end
    end
end
simulationFiles=simulationFiles(sel_files);
% keyboard;
% create a plot every 5 minutes which is time resolution of TIPSOD
act_time=clock;
act_time=datetime(act_time(1),act_time(2),act_time(3),act_time(4),0,0);
% start_date=datenum(act_time)-da_days;
start_date = datenum(act_time)-1;
end_date=datenum(act_time);
dt=5/86400*60;
time_vec = start_date:dt:end_date;
n_steps = numel(time_vec);
parpool(24);
% all_forecast_data_utc = all_forecast_data.utc;
parfor (step_idx = 1:n_steps, 24)
% for step_idx = 1:n_steps
    act_date = time_vec(step_idx);
    % get array index for forecast mat-file closest to plot date
    [M,all_index] = min(abs([all_forecast_data.utc]-act_date))
    % keyboard;
    forecast_data=all_forecast_data(all_index);
    % keyboard;
%     forecast_data.times=forecast_data.times-((forecast_data.times(2)-forecast_data.times(1))/2);
    % get array index for actual time
    t_index=find(abs(forecast_data.times-forecast_data.utc)<1e-9);
    fprintf('index: %s\n',datestr(act_date,'YYYY-mm-dd HH:MM:SS'));

    % keyboard;

    nrow=6;
    ncol=2;
    [status, msg, msgID] = mkdir('./frames_scatter_mean_ensemble');
    [status, msg, msgID] = mkdir(sprintf('./frames_scatter_mean_ensemble/%s',datestr(act_date,'YYYYmmdd')));
    output_anim_file=sprintf('./frames_scatter_mean_ensemble/%s/Forecast_%s_UTC_%s.png',datestr(act_date,'YYYYmmdd'),name_part,datestr(act_date,'YYYYmmddTHHMMSS'));
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
            fprintf('plot bfield and satellite orbits\n')
            % get list of involved satellites
            sats=forecast_data.sat_names;
%             kext=0;% for IGRF
            kext=4;% for T89
            cells=[1,3,5];
            axial_tilt = -23.44;
            [ax_bfield_sat]=gfz_plot_panel_bfield_sat( ...
                nrow,ncol,cells, ...
                act_date,sats,kext,maginput, ...
                conf_panel_bfield);
    %         set(ax_bfield_sat,'position',fc_pos.bfield_sat_pos,'units','normalized');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf('plot model donuts\n');
            cells=[7,9,11];
            sats=forecast_data.sat_names;
            [ax_donut,ax_donut_colbar]=gfz_plot_panel_donuts_scatter_3d(...
                nrow,ncol,cells, ...
                act_date,forecast_data.L_T89,forecast_data.flux(t_index,:), ...
                sats,kext,maginput, ...
                conf_panel_donut_scatter);

            set(ax_donut_colbar,'pos',conf_panel_donut_scatter.pos.flux_donut_colorbar);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf('plot data\n');
            % plot real-time data
            sat_names='';
            for i=1:size(forecast_data.sat_names,1)
                if ~isempty(forecast_data.sat_energies)
                    sat_names=[sat_names sprintf('%s (%.2f MeV)',upper(forecast_data.sat_names{i,1}),forecast_data.sat_energies(i))];
                else
                    sat_names=[sat_names sprintf('%s',upper(forecast_data.sat_names{i,1}))];
                end
                if i<size(forecast_data.sat_names,1)
                    sat_names=[sat_names ', '];
                end

            end
            cells=[2,4];
            time_range=[min(forecast_data.times),max(forecast_data.times)];
            [ax_real,ax_real_color]=gfz_plot_panel_data(...
                nrow,ncol,cells,...
                forecast_data.utc,forecast_data.timesd,forecast_data.L_T89d,forecast_data.fluxd, ...
                time_range, ...
                sat_names, ...
                conf_panel_data);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf('plot model\n');
            cells=[6,8];
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
            cells=10;
            [ax_sw]=gfz_plot_panel_sw(...
                nrow,ncol,cells, ...
                forecast_data.utc,forecast_data.times, ...
                forecast_data.sw_n,forecast_data.sw_v, ...
                time_range, ...
                conf_panel_sw);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % plot Kp
            cells=12;
            [ax_kp]=gfz_plot_panel_kp(...
                nrow,ncol,cells, ...
                forecast_data.utc,forecast_data.times, ...
                forecast_data.Kp,forecast_data.Kp_source, ...
                time_range, ...
                conf_panel_kp);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf('plot title\n');
            a = axes;
            ax_title = title(strcat('Real-time Radiation Belt Forecast v2, ',datestr(act_date,' HH:MM, mmm dd, yyyy'),' UTC'));
            a.Visible = 'off'; % set(a,'Visible','off');
            ax_title.Visible = 'on'; % set(t1,'Visible','on');
            set(ax_title,'Color',conf_panel_title.color.title,'FontWeight','bold','FontSize',conf_panel_title.scale.title);
            a.Position=conf_panel_title.pos.title;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            hold off
            fprintf('save plot\n');
            %set(fig1,'color',[0.3 0.3 0.3])
            set(fig1, 'visible', 'off')
            fig1.Color='black';
            fig1.InvertHardcopy = 'off';
            %saveas(fig1,output_anim_file);
%                 print(fig1,output_anim_file,'-dpng','-r120')
            %hgexport(fig1,output_anim_file);
            F = getframe(fig1); % get rendered grid from figure
            imwrite(F.cdata, output_anim_file)  % write rendered figure to png-file
%                 imwrite(F.cdata, 'test.png')
%             set(fig1, 'visible', 'on')
            clf(fig1);
            close(fig1);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        % clear maginput;clear sats;clear timerange;
    end
    % clear forecast_data
end
exit;


