%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by I. Michaelis (GFZ), 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ax_sw]=gfz_plot_panel_sw(...
    nrow,ncol,cells, ...
    utc_use,times, ...
    sw_n,sw_v, ...
    time_range, ...
    conf)

        ax_sw=subplot(nrow,ncol,cells);
        hold on
        yyaxis left
        ax_swv_line=scatter(ax_sw,times,sw_v,conf.scale.sw_sz,conf.color.swv,'filled');
        ax_swv_ylabel=ylabel('v_{sw}, km/s');
        xlim(time_range);
        ylim(conf.range.swv);
        yticks(conf.range.swv_ticks)
        set(ax_swv_ylabel,'Color',conf.color.swv)
        ax_sw.YColor=conf.color.swv;
        set(ax_swv_ylabel,'FontWeight','bold')
        set(ax_swv_ylabel,'FontSize',conf.scale.sw_yaxis)

        yyaxis right
        ax_swn_line=scatter(ax_sw,times,sw_n,conf.scale.sw_sz,conf.color.swn,'filled');
        ax_swn_ylabel=ylabel('n_{sw}, #/cm^3');
        xlim(time_range);
        ylim(conf.range.swn);
        yticks(conf.range.swn_ticks)
        datetick('x','mmm-dd','keepticks','keeplimits');
        if (utc_use>=min(times)) & (utc_use<=max(times))
            line(ax_sw,[utc_use utc_use],ylim,'Color',conf.color.act,'LineStyle',':','LineWidth',conf.scale.act_lwd);
        end
        ax_sw_title=title(ax_sw,'Propagated solar wind data');
        grid();
        set(ax_swn_ylabel,'Color',conf.color.swn)
        set(ax_swn_ylabel,'FontWeight','bold')
        set(ax_swn_ylabel,'FontSize',conf.scale.sw_yaxis)
        ax_sw.YColor=conf.color.swn;

        ax_sw.XColor=conf.color.axes;
        set(ax_sw,'xticklabel',[]);
        set(ax_sw,'FontWeight','bold','linewidth',conf.scale.frame_width,'Color','black','layer','top');
        
        % invisible colorbar keeps axis width aligned with flux panels that use 'eastoutside'
        cb_dummy = colorbar(ax_sw, 'eastoutside');
        cb_dummy.Visible = 'off';
        
        set(ax_sw, 'LooseInset', get(ax_sw,'TightInset'));
        ax_sw.Box='on';
        set(ax_sw_title,'Color',conf.color.axes,'FontWeight','bold','FontSize',conf.scale.sw_yaxis);
        hold off
