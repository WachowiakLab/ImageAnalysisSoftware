function artificial_sniff_extensions(interface)

    interface.add(artificial_sniff_view(interface.getBlankInitializer()))

    %initializer for default_view
    function init = artificial_sniff_view(init)
        init.uid = 'artificial_sniff_view';
        init.name = 'Artificial Sniff';
        init.group = 'Views';
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onUncheck = @savePrefs;

        show_text_labels = false;
        odor_presentation_patch_color = [.5 .5 .5]; %tcr added this
        
        function drawView(drawaxes)
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            scale_factor = interface.getCurrentScaling();

            if isappdata(drawaxes,'PlotColorIndex')
                rmappdata(drawaxes,'PlotColorIndex')
            end

            scale = scale_factor*(5);
            interface.set('real_scale_factor',scale);

            if isfield(trial.other, 'sniff_control')
                tr = trial.other.sniff_control;
                plot((1:length(tr))./trial.other.samplingrate,((tr - min(tr))./1.1./(max(tr)-min(tr))),'Color','black','Parent',drawaxes)
                if show_text_labels
                    text(trial.trial_length*0.005,0.25,'sniff_control','Interpreter','none','FontSize',8,'Parent',drawaxes)
                end
            end
            
%             others = {'sniff_pressure','sniff_thermocouple','sniff_syringe_pressure'};
            others = {'sniff_pressure','sniff_thermo','sniff_syringe_pressure'};
            colors = {'red',[.2 .6 .2],'blue'};
            scaling = [1, 8, .2];
            
            for ji = 1:length(others)
                if isfield(trial.other, others{ji})
                    tr = trial.other.(others{ji});
                    meantr = mean(tr);
                    plot((1:length(tr))./trial.other.samplingrate,((denoise(tr) - meantr).*scale.*scaling(ji))-ji,'Color',colors{ji},'Parent',drawaxes)
                    if show_text_labels
                        text(trial.trial_length*0.005,((tr(1) - meantr).*scale.*scaling(ji))-ji,others{ji},'Interpreter','none','FontSize',8,'Parent',drawaxes)
                    end
                end
            end
            
            ylims = [-5 1.1];
            set(drawaxes,'YLim',ylims,'XLim',[0 trial.trial_length])
            xlabel(drawaxes,'time (s)')

            if isfield(trial.measurement,'odor_onoff') && ~isempty(trial.measurement.odor_onoff.odor_onset)
                patch([trial.measurement.odor_onoff.odor_onset,...
                       trial.measurement.odor_onoff.odor_onset,...
                       trial.measurement.odor_onoff.odor_offset,...
                       trial.measurement.odor_onoff.odor_offset], ...
                    [ylims fliplr(ylims)]-[0 0 0 0],odor_presentation_patch_color,'EdgeColor','none','Tag','full_height','HitTest','off','Parent',drawaxes,'Userdata',-1000);
            end
        end

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            if show_text_labels
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Show text labels', 'Checked', checked, 'Callback', @toggle_show_text_labels)
            set(menu,'Visible','on')
            
            function show_about(varargin)
                msgbox({'This view shows several traces related to developing artificial sniffing.','','RMC','10 October 2007'}, 'Artificial sniff view')
            end
            function toggle_show_text_labels(varargin)
                show_text_labels = ~show_text_labels;
                interface.forceRedrawView()
            end

        end

        function savePrefs
            
        end
        
    end
end