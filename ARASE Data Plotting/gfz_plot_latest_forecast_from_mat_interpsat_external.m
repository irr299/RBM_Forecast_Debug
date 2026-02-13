%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
addpath([getenv('FC_HOME'),'/Functions/'])
addpath([getenv('FC_HOME'),'/FunctionsPlot/'])
% addpath('../3DDA/')
addpath(getenv('FC_MATLAB_CDFPATCH'))

% read configuration file for panels
conf_plot_frame
name_part='E_1_MeV_PA_50';

latest_mat_file_info=dir([getenv('FC_LATEST') 'Forecast_' name_part '_UTC_latest.mat']);
% latest_mat_file_info=dir([getenv('FC_HOME') '/mat/Forecast_' name_part '_UTC_latest.mat']);
latest_mat_file=[latest_mat_file_info.folder,'/',latest_mat_file_info.name];
forecast_data=load(latest_mat_file);

forecast_data.timesd = forecast_data.timesd(1:4:end);
forecast_data.L_T89d = forecast_data.L_T89d(1:4:end);
forecast_data.fluxd = forecast_data.fluxd(1:4:end, :); 

time_range=[min(forecast_data.times),max(forecast_data.times)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nrow=8;
ncol=1;
[status, msg, msgID] = mkdir([getenv('FC_LATEST')]);
[status, msg, msgID] = mkdir([getenv('FC_PNG_FORECAST')]);
output_latest_file=[getenv('FC_LATEST') 'Forecast_' name_part '_UTC_latest_interpsat.png'];
output_date_file=[getenv('FC_PNG_FORECAST') sprintf('Forecast_%s_UTC_%s_interpsat.png',name_part,datestr(forecast_data.utc,'YYYYmmddTHHMMSS'))];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot figures for website latest figure
fig3=figure('visible', 'off');
% paper definition
fig3.PaperUnits = 'centimeters';
fig3.PaperPosition = [0 0 35 21];
fig3.PaperPositionMode = 'manual';
% set(fig3, 'visible', 'off')
set(fig3, 'visible', 'on')
% set current figure without putting it to foreground
set(groot, 'currentfigure', fig3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('plot data\n');
% plot real-time data
% sat_names='';
% forecast_data.sat_names=unique(forecast_data.sat_names);
% for i=1:size(forecast_data.sat_names,1)
%     if isfield(forecast_data,'sat_energies')
% %         sat_names=[sat_names sprintf('%s (%.2f MeV)',upper(forecast_data.sat_names{i,1}),forecast_data.sat_energies(i))];
%         sat_names=[sat_names sprintf('%s',upper(forecast_data.sat_names{i,1}))];
%     else
%         sat_names=[sat_names sprintf('%s',upper(forecast_data.sat_names{i,1}))];
%     end
%     if i<size(forecast_data.sat_names,1)
%         sat_names=[sat_names ', '];
%     end
% 
% end
% cells=[1,2];
% time_range=[min(forecast_data.times),max(forecast_data.times)];
% [ax_real,ax_real_color]=gfz_plot_panel_data(...
%     nrow,ncol,cells,...
%     forecast_data.utc,forecast_data.timesd,forecast_data.L_T89d,forecast_data.fluxd, ...
%     time_range, ...
%     sat_names, ...
%     conf_panel_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('select available satellites\n');
% plot real-time data
sat_names='';
for i=1:size(forecast_data.sat_names,1)
    if ~isempty(forecast_data.sat_energies)
%                     sat_names=[sat_names sprintf('%s (%.2f MeV)',upper(forecast_data.sat_names{i,1}),forecast_data.sat_energies(i))];
        sat_names=[sat_names sprintf('%s',upper(forecast_data.sat_names{i,1}))];
    else
        sat_names=[sat_names sprintf('%s',upper(forecast_data.sat_names{i,1}))];
    end
    if i<size(forecast_data.sat_names,1)
        sat_names=[sat_names ', '];
    end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('plot interpolated data\n');
cells=[1,3];
% plot simulated data
% PLOTTING, use pcolor as a default
[ax_data]=gfz_plot_panel_interpdata( ...
    nrow,ncol,cells, ...
    forecast_data.energy,forecast_data.pa, ...
    forecast_data.utc,forecast_data.times,forecast_data.L_T89,forecast_data.obs_flux, ...
    time_range, ...
    sat_names, ...
    conf_panel_sim);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('plot model\n');
cells=[4,6];
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
cells=7;
[ax_sw]=gfz_plot_panel_sw(...
    nrow,ncol,cells, ...
    forecast_data.utc,forecast_data.times, ...
    forecast_data.sw_n,forecast_data.sw_v, ...
    time_range, ...
    conf_panel_sw);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot Kp
cells=8;
[ax_kp]=gfz_plot_panel_kp(...
    nrow,ncol,cells, ...
    forecast_data.utc,forecast_data.times, ...
    forecast_data.Kp,forecast_data.Kp_source, ...
    time_range, ...
    conf_panel_kp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('plot title\n');
a = axes;
ax_title = title(strcat('Real-time Radiation Belt Forecast, ',datestr(forecast_data.utc,' HH:MM, mmm dd, yyyy'),' UTC'));
a.Visible = 'off'; % set(a,'Visible','off');
ax_title.Visible = 'on'; % set(t1,'Visible','on');
set(ax_title,'Color',conf_panel_title.color.title,'FontWeight','bold','FontSize',conf_panel_title.scale.title);
a.Position=conf_panel_title.pos.title;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('save plot\n');
set(fig3, 'visible', 'off')
fig3.Color='black';
fig3.InvertHardcopy = 'off';
saveas(fig3,output_latest_file);
saveas(fig3,output_date_file);

exit;


