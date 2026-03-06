%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ax_kp]=gfz_plot_panel_kp(...
    nrow,ncol,cells, ...
    utc_use,times,Kp,Kp_source, ...
    time_range, ...
    conf)
        
    ax_kp = subplot(nrow,ncol,cells);
    hold on
    ax_kp_plot=bar(ax_kp,times,Kp,1.);
    xlim(time_range);
    datetick('x','mmm-dd','keepticks','keeplimits');
    ylim(conf.range.kp);
    ylabel('Kp','FontSize',conf.scale.kp_yaxis);
    yticks([0 3 6])
     if (utc_use>=min(times)) & (utc_use<=max(times))
        line(ax_kp,[utc_use utc_use],ylim,'Color',conf.color.act,'LineStyle',':','LineWidth',conf.scale.act_lwd);
    end
    xlabel('UTC');
    label_pos_x=get(ax_kp,'xlim');label_pos_y=get(ax_kp,'ylim');
    ax_kp_textl=text(ax_kp,label_pos_x(1),label_pos_y(2),'GFZ nowcast','HorizontalAlignment','Left','VerticalAlignment','Top');
    ax_kp_textr=text(ax_kp,label_pos_x(2),label_pos_y(2),strcat(Kp_source, ""),'HorizontalAlignment','Right','VerticalAlignment','Top');
    ax_kp_title=title(ax_kp,'Geomagnetic Kp Index');
    grid();

    set(ax_kp,'FontWeight','bold','linewidth',conf.scale.frame_width,'Color','black','layer','top');
   
    % invisible colorbar keeps axis width aligned with flux panels that use 'eastoutside'
    cb_dummy = colorbar(ax_kp, 'eastoutside');
    cb_dummy.Visible = 'off';

    set(ax_kp, 'LooseInset', get(ax_kp,'TightInset'));
    ax_kp.XLabel.Color=conf.color.axes;
    ax_kp.YLabel.Color=conf.color.axes;
    ax_kp.XColor=conf.color.axes;
    ax_kp.YColor=conf.color.axes;
    ax_kp.Box='on';
    set(ax_kp_plot,'FaceColor',conf.color.kp); 
    set(ax_kp_textl,'Color',conf.color.kp,'FontWeight','bold');
    set(ax_kp_textr,'Color',conf.color.kp,'FontWeight','bold');
    set(ax_kp_title,'Color',conf.color.axes,'FontWeight','bold','FontSize',conf.scale.kp_yaxis);
    hold off
