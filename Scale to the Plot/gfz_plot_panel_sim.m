%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ax_sim]=gfz_plot_panel_sim(...
    nrow,ncol,cells, ...
    energy,pa, ...
    utc_use,times,L,flux, ...
    time_range, ...
    conf)

    ax_sim = subplot(nrow,ncol,cells);
    hold on
    ax_sim_plot=pcolor(ax_sim,times,L,log10(flux)');
    ylim(conf.range.L);
    ylabel('L*(T89)');
    yticks(conf.range.L_ticks)
    grid();
    if (utc_use>=min(times)) & (utc_use<=max(times))
        line(ax_sim,[utc_use utc_use],ylim,'Color',conf.color.act,'LineStyle',':','LineWidth',conf.scale.act_lwd);
    end
    hold off
    caxis(conf.range.flux);
    colormap(ax_sim,conf.color.cmap);
    %shading flat
    shading interp
    xlim(time_range);
    datetick('x','keepticks','keeplimits');
    label_pos_x=get(ax_sim,'xlim');label_pos_y=get(ax_sim,'ylim');
    ax_sim_title=title(ax_sim,'Reanalysis: VERB + real-time data');
    ax_sim_textul=text(ax_sim,.5*(label_pos_x(1)+label_pos_x(2)),label_pos_y(1),'PRELIMINARY. Not for publication','HorizontalAlignment','center','VerticalAlignment','Bottom');
    ax_sim_textbr=text(ax_sim,label_pos_x(2),label_pos_y(1),'VERB forecast','HorizontalAlignment','Right','VerticalAlignment','Bottom');
    ax_sim_textbl=text(ax_sim,label_pos_x(1),label_pos_y(1),strcat('Flux at E=',num2str(energy),' MeV, \alpha_{eq}=',num2str(pa),char(176)),'HorizontalAlignment','Left','VerticalAlignment','Bottom');
    set(ax_sim,'xticklabel',[]);
    set(ax_sim,'FontWeight','bold','linewidth',conf.scale.frame_width,'Color','black','layer','top');
    ax_sim.YLabel.Color=conf.color.axes;
    set(ax_sim, 'LooseInset', get(ax_sim,'TightInset'));
    ax_sim.Title.Color=conf.color.axes;
    ax_sim.XColor=conf.color.axes;
    ax_sim.YColor=conf.color.axes;
    ax_sim.Box='on';
    set(ax_sim_title,'Color',conf.color.axes,'FontWeight','bold','FontSize',conf.scale.flux_yaxis);
    set(ax_sim_textbr,'Color',conf.color.axes,'FontWeight','bold');
    set(ax_sim_textbl,'Color',conf.color.axes,'FontWeight','bold');
    set(ax_sim_textul,'Color',conf.color.axes,'FontWeight','bold');
