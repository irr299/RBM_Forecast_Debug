%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ax_real,ax_real_color]=gfz_plot_panel_data(...
    nrow,ncol,cells, ...
    utc_use,times,L,flux, ...
    time_range, ...
    sat_names, ...
    conf)

    ax_real = subplot(nrow,ncol,cells);
    hold on
    ax_real_plot=scatter(ax_real,times,L,conf.scale.flux_rawdata,log10(flux)','filled');
    ylim(conf.range.L);
    ylabel('L*(T89)');
    yticks(conf.range.L_ticks);
    grid();
%     if (utc_use>=min(times)) & (utc_use<=max(times))
    line(ax_real,[utc_use utc_use],ylim,'Color',conf.color.act,'LineStyle',':','LineWidth',conf.scale.act_lwd);
%     end
    hold off
    caxis(conf.range.flux);
    shading flat
    %shading interp
    ax_real_color=colorbar(ax_real,'eastoutside','Color',conf.color.axes);
    ax_real_color.Label.String = {'Flux';'log_{10} J (#/cm^2.s.sr.keV)'};
    ax_real_color.FontSize=conf.scale.flux_colorbar;

    ax_real_color.Ticks = 0:1:4;                                   % integer steps only
    ax_real_color.Label.FontSize = conf.scale.flux_colorbar + 4;   % label larger than tick font

    colormap(ax_real,conf.color.cmap);
    xlim(time_range);
    datetick('x','keepticks','keeplimits');
    label_pos_x=get(ax_real,'xlim');label_pos_y=get(ax_real,'ylim');
    ax_real_title=title(ax_real,['Real-time data: ' sat_names]);
%     ax_real_textbl=text(ax_real,.5*(label_pos_x(1)+label_pos_x(2)),label_pos_y(1),'PRELIMINARY. Not for publication','HorizontalAlignment','center','VerticalAlignment','Bottom');
    set(ax_real,'xticklabel',[]);
    set(ax_real,'FontWeight','bold','linewidth',conf.scale.frame_width,'Color','black','layer','top');
    ax_real.YLabel.Color=conf.color.axes;
    set(ax_real, 'LooseInset', get(ax_real,'TightInset'));
    ax_real.XColor=conf.color.axes;
    ax_real.YColor=conf.color.axes;
    ax_real.Box='on';
    set(ax_real_title,'Color',conf.color.axes,'FontWeight','bold','FontSize',conf.scale.flux_yaxis);
%     set(ax_real_textbl,'Color','yellow','FontWeight','bold');
