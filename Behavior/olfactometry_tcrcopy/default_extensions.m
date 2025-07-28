function default_extensions(interface)

    interface.add(default_view(interface.getBlankInitializer()))

    %initializer for default_view
    function init = default_view(init)
        init.uid = 'default_view';
        init.name = 'Default';
        init.group = 'Views';
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onUncheck = @savePrefs;

        colorwheel = [1 0 0; 0 .7 0; 0 0 1; 1 .5 0; .5 1 0; .7 0 .7; 0 .5 .5];
        odor_presentation_patch_color = [0.7529 0.7529 0.7529];
        show_rois_name = false;
        overlay_traces = false;

        function drawView(drawaxes)
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            ri = interface.getCurrentRois();
            scale_factor = interface.getCurrentScaling(); %.01 to 1.0

            if isappdata(drawaxes,'PlotColorIndex')
                rmappdata(drawaxes,'PlotColorIndex')
            end

            if isfield(trial.other, 'elec_stim')
                tr = trial.other.elec_stim;
                txt = 'stim';
            elseif isfield(trial.other, 'sniff_pressure')
                tr = trial.other.sniff_pressure;
                if trial.other.samplingrate > 50
                    tr = lpf(denoise(tr),trial.other.samplingrate,2,25);
                end
                txt = 'sniff';

            elseif isfield(trial.other, 'sniff_thermo')
                tr = trial.other.sniff_thermo;
                if trial.other.samplingrate > 50
                    tr = lpf(denoise(tr),trial.other.samplingrate,2,12); %% default settings tr = lpf(denoise(tr),trial.other.samplingrate,2,25);
                   % tr = -tr; %inverted polarity!
                end
                txt = 'thermo';

            elseif isfield(trial.other, 'sniff_thermo')
                tr = trial.other.sniff_thermo;
                if trial.other.samplingrate > 50
                    tr = lpf(denoise(tr),trial.other.samplingrate,2,25);
                end
                txt = 'thermo';

            else
                tr = [];
            end
            if overlay_traces && ~isempty(ri)
                scale = 10*scale_factor*(2+~isempty(tr));
            else
%                 scale = 10*scale_factor*(length(ri)+1+~isempty(tr));
                scale = 0.5*scale_factor*(length(ri)+1+~isempty(tr));
            end
            interface.set('real_scale_factor',scale);

            if ~isempty(tr)
                if std(tr) == 0
                    plot((1:length(tr))./trial.other.samplingrate,0,'Color','black','Parent',drawaxes,'HitTest','off')
                else
%                     plot((1:length(tr))./trial.other.samplingrate,((tr - min(tr))./1.1./(max(tr)-min(tr))),'Color','black','Parent',drawaxes,'HitTest','off')
                    plot((1:length(tr))./trial.other.samplingrate,((tr - min(tr))./1.1./(max(tr)-min(tr))),'Color','black','Parent',drawaxes,'HitTest','off')
                end
                text(trial.trial_length*0.005,0.25,txt,'FontSize',8,'Parent',drawaxes)
            end

            time = (1:trial.rois.datasize(1))./trial.rois.samplingrate;
            tr_all = bsxfun(@ldivide,trial.rois.RLIs,trial.rois.traces);
            rois = o.rois(trial.rois.nums(ri));
            if show_rois_name
                roi_text = arrayfun(@(a) {[num2str(rois(a).index) ' - ' rois(a).name]}, 1:length(rois));
            else
                roi_text = arrayfun(@(a) {num2str(rois(a).index)}, 1:length(rois));
            end
            
            for rii = 1:length(ri)
                r = ri(rii);
                tr = tr_all(r,:);
                meantr = mean(tr);
                if overlay_traces
                    offset = -1;
                else
                    offset = -rii;
                end
                
                plot(time,((tr - meantr).*scale)+offset,'Parent',drawaxes,'Color',colorwheel(mod(r-1,length(colorwheel))+1,:),'HitTest','off')
                text(trial.trial_length*0.005,((tr(1) - meantr).*scale)+offset,roi_text(rii),'Interpreter','none','FontSize',8,'Parent',drawaxes)
            end

            if overlay_traces && ~isempty(ri)
                ylims = [-2 ~isempty(tr)+0.1];
            else
                ylims = [-length(ri)-1 ~isempty(tr)+0.1];
            end

            line([trial.trial_length*0.97 trial.trial_length*0.97],[ylims(1)+0.2 ylims(1)+0.2+scale*0.05],'Color','black','LineWidth',2,'HitTest','off','Parent',drawaxes,'Userdata',500)
            text(trial.trial_length*0.973, ylims(1)+0.2+scale*0.025,'5%','FontSize',6,'Parent',drawaxes,'Userdata',500)

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
            uimenu(menu, 'Label', 'Set odorant color', 'Callback', @show_options);
            if show_rois_name
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Show roi names', 'Checked', checked, 'Callback', @toggle_show_rois_name)
            if overlay_traces
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Overlay ROI traces', 'Checked', checked, 'Callback', @toggle_overlay_traces)
            
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')
            
            function show_about(varargin)
                msgbox({'This shows the default view, showing the sniff/stim trace, selected rois, and odorant presentation time.','','RMC','19 July 2007'}, 'Default view')
            end
            function show_options(varargin)
                odor_presentation_patch_color = uisetcolor(odor_presentation_patch_color,'Select color');
                interface.forceRedrawView()
            end
            function toggle_show_rois_name(varargin)
                show_rois_name = ~show_rois_name;
                interface.forceRedrawView()
            end
            function toggle_overlay_traces(varargin)
                overlay_traces = ~overlay_traces;
                interface.forceRedrawView()
            end
        end

        function savePrefs
            
        end
        
    end
end