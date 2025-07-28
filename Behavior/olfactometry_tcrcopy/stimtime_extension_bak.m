function stimtime_extension(interface)

    interface.add(stimtime_view(interface.getBlankInitializer()))
    interface.add(stimtime_editor(interface.getBlankInitializer()))

    line_color = [.5 0 .5];
    lines_h = [];

    function init = stimtime_view(init)
        init.uid = 'stimtime_view';
        init.name = 'Sniff/stim lines';
        init.group = 'Views';
%        init.prerequisites = {'default_view'};
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onUncheck = @savePrefs;

        function rightClick(menu)
            uimenu(menu, 'Label', 'Set line color', 'Callback', @show_options);
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function show_about(varargin)
                msgbox({'This shows the automatically-detected or manually set stim times.','','RMC','19 July 2007'}, init.name)
            end
            function show_options(varargin)
                line_color = uisetcolor(line_color,'Select color');
                interface.forceRedrawView()
            end
        end

        function drawView(drawaxes)
            odorant_onset_delay = 0.03; %30 ms

            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            lines_h = [];
            if isfield(trial.measurement,'response_fits')
                pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,trial.rois.nums);
                % find first response after odorant onset:
                resps = trial.measurement.response_fits;
                resps = resps([resps.stimtime] > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh([resps.roi_num]));
                if isempty(resps)
                    first_sniff_response = 0;
                else
                    [c,respi] = min([resps.inflection]);
                    first_sniff_response = resps(respi).stimtime; %get sniff associated with the response
                end
            else
                first_sniff_response = 0;
            end
            if isfield(trial.measurement,'stim_times')
                stim_times = trial.measurement.stim_times;
                lines_h = stim_times;
                for si = 1:length(stim_times)
                    if stim_times(si) == first_sniff_response
                        lines_h(si) = line([stim_times(si) stim_times(si)],get(drawaxes,'YLim'),'Color',line_color,'LineWidth',3,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
                    else
                        lines_h(si) = line([stim_times(si) stim_times(si)],get(drawaxes,'YLim'),'Color',line_color,'LineWidth',2,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
                    end
                end
            end
        end

        function savePrefs
            lines_h = [];
        end
    end

    function init = stimtime_editor(init)
        init.uid = 'stimtime_editor';
        init.name = 'Edit sniff/stim times';
        init.group = 'Analysis editing tools';
        init.prerequisites = {'stimtime_view'};
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onCheck = @loadEditor;
        init.onUncheck = @unloadEditor;

        toolboxVisible = true;

        function drawView(drawaxes) %#ok<INUSD>
            set(lines_h, 'ButtonDownFcn', @fcn_click, 'LineWidth', 3);
        end

        function loadEditor
            toolboxVisible = true;
            showToolbox
            interface.register_event_listener('mainaxes_click', @fcn_plot_click);
        end
        function unloadEditor
            if toolboxVisible
                hideToolbox
            end
            interface.unregister_event_listener('mainaxes_click', @fcn_plot_click);
        end

        function rightClick(menu)
            set(menu,'Visible','on')
            if toolboxVisible
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Show toolbox', 'Checked', checked, 'Callback', @toggle_toolbox_visible)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function toggle_toolbox_visible(varargin)
                toolboxVisible = ~toolboxVisible;
                if toolboxVisible
                    showToolbox
                else
                    hideToolbox
                end
            end

            function show_about(varargin)
                msgbox({'This allows manual editing or automatic detection of sniff/stim times.','','RMC','19 July 2007'}, init.name)
            end
        end

        function fcn_plot_click
            switch get(interface.fig,'SelectionType')
                case 'normal' %add lines with left-click
                    pt = get(interface.mainaxes, 'CurrentPoint');
                    save_stim_times(pt(1)); %add new time and get redrawn
                case 'alt' %clear them all with a right-click
                    delete(lines_h)
                    lines_h = []; %we can clear these ourselves without redrawing
                    save_stim_times
            end
        end

        current_line_h = [];
        function fcn_click(varargin)
            switch get(interface.fig,'SelectionType')
                case 'normal'
                    current_line_h = gcbo;
                    set(interface.fig, 'WindowButtonMotionFcn', @fcn_drag);
                    set(interface.fig, 'WindowButtonUpFcn', @fcn_drag_end);
                case 'alt'
                    lines_h = setdiff(lines_h,gcbo);
                    delete(gcbo);
                    save_stim_times
            end
        end
        function fcn_drag(varargin)
            pt = get(interface.mainaxes, 'CurrentPoint');
            set(current_line_h, 'XData', repmat(pt(1),size(get(current_line_h, 'YData'))));
        end
        function fcn_drag_end(varargin)
            set(interface.fig, 'WindowButtonMotionFcn', []);
            set(interface.fig, 'WindowButtonUpFcn', []);
            save_stim_times
        end

        function save_stim_times(addtime)
            if ~nargin
                addtime = [];
            end
            l = get(lines_h,'XData');
            if iscell(l)
                l = cell2mat(l);
            end
            newvals = unique([l(:); addtime])';

            t = interface.getCurrentTrial();
            interface.updateOlfact(['trials(' num2str(t) ').measurement.stim_times'],...
                newvals,...
                ['trials(' num2str(t) ').measurement_param.stim_times'],...
                struct('method', 'Manual', 'done', now));
            if nargin
                interface.forceRedrawView()
            end
            if toolboxVisible
                refresh_current_trial_details
            end
        end

        fig = [];
        current_trial_details = [];
        threshold = [];
        trial_selection = [];
        function showToolbox
%             fig = figure('Name','Edit sniff/stim times','Units','pixels',...
%                 'Position',interface.getPrefposOrDefault('stimtime_editor',[400 400 400 65]),...
%                 'MenuBar', 'none', 'DockControls', 'off', 'HandleVisibility','off','NumberTitle', 'off', ...
%                 'CloseRequestFcn',@hideToolbox,'Resize','off','Color', get(0,'DefaultUicontrolBackgroundColor'));
            fig = figure('Name','Edit sniff/stim times','Units','pixels',...
                'Position',[400 400 400 65],...
                'MenuBar', 'none', 'DockControls', 'off', 'HandleVisibility','off','NumberTitle', 'off', ...
                'CloseRequestFcn',@hideToolbox,'Resize','off','Color', get(0,'DefaultUicontrolBackgroundColor'));
            current_trial_details = uicontrol('Parent',fig,'style','text','String','','HorizontalAlignment','left',...
                'Units','pixels','Position',[5 5 160 55]);
            uicontrol('Parent',fig,'style','text','String','Autodetect', 'Units','pixels','Position',[185 2 65 23]);
            trial_selection = uicontrol('Parent',fig,'style','popupmenu','String',{'this trial', 'all trials', 'selected trials'},...
                'Units','pixels','Position',[250 5 90 25],'BackgroundColor',[1 1 1]);
            uicontrol('Parent',fig,'style','pushbutton','String','Run','Units','pixels','Position',[345 7 45 25],...
                'Callback',@auto_detect_stim_times_Callback);
            uicontrol('Parent',fig,'style','pushbutton','String','Test','Units','pixels','Position',[364 35 30 25],...
                'Callback',@test_stim_times_Callback);
            uicontrol('Parent',fig,'style','text','String','Threshold for sniff detection:',...
                'Units','pixels','Position',[185 38 140 15]);
            threshold = uicontrol('Parent',fig,'style','edit','String','0.2','HorizontalAlignment','left',...
                'Units','pixels','Position',[330 38 30 20],'BackgroundColor',[1 1 1]);
            interface.register_event_listener('before_unload_trial',@clear_current_trial_details)
            interface.register_event_listener('after_load_trial',@refresh_current_trial_details)
            refresh_current_trial_details
        end

        function clear_current_trial_details
            set(current_trial_details,'String','')
        end
        function refresh_current_trial_details
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            if t > 0
                trial = o.trials(t);
                str = {'','','',''};
                if isfield(trial.other,'sniff_pressure')
                    str{1} = 'Pressure sniff waveform';
                elseif isfield(trial.other,'sniff_thermo')
                    str{1} = 'Thermocouple sniff waveform';
                elseif isfield(trial.other,'elec_stim')
                    str{1} = 'Electrical stimulation waveform';
                else
                    str{1} = 'No stimulation waveform available';
                end
                if isfield(trial.measurement,'stim_times')
                    str{2} = 'Stimulation times identified:';
                    str{3} = trial.measurement_param.stim_times.method;
                    if isfield(trial.measurement_param.stim_times,'thresh')
                        str{3} = [str{3} ' (thresh: ' num2str(trial.measurement_param.stim_times.thresh) ')'];
                    end
                    str{4} = datestr(trial.measurement_param.stim_times.done);
                else
                    str{2} = 'Stimulation times not yet identified.';
                end
                set(current_trial_details,'String',str)
            end
        end
        
        function hideToolbox(varargin)
            interface.unregister_event_listener('before_unload_trial',@clear_current_trial_details)
            interface.unregister_event_listener('after_load_trial',@refresh_current_trial_details)
            toolboxVisible = false;
            interface.setPrefpos('stimtime_editor',get(fig,'Position'));
            delete(fig);
        end

        function auto_detect_stim_times_Callback(varargin)
            o = interface.getOlfact();
            switch get(trial_selection,'Value')
                case 1
                    t = interface.getCurrentTrial();
                    if t == 0
                        t = [];
                    end
                case 2
                    t = 1:length(o.trials);
                case 3
                    t = interface.getSelectedItems();
            end
            
            thresh = str2double(get(threshold,'String'));
            if isempty(thresh) || isnan(thresh)
                errordlg('Please provide a valid numeric threshold for sniff detection.','Bad Threshold')
                return
            end

            stims = cell(size(t));
            %changed = false(size(t));
            for ti = 1:length(t)
                if isfield(o.trials(t(ti)).other,'sniff_control')
                    [stims{ti}, params] = detect_stims('sniff_pressure',-o.trials(t(ti)).other.sniff_control,o.trials(t(ti)).other.samplingrate,thresh);
                elseif isfield(o.trials(t(ti)).other,'sniff_pressure')
                    [stims{ti}, params] = detect_stims('sniff_pressure',o.trials(t(ti)).other.sniff_pressure,o.trials(t(ti)).other.samplingrate,thresh);
                elseif isfield(o.trials(t(ti)).other,'sniff_thermo')
                    [stims{ti}, params] = custom_autodetect_stims('sniff_thermo',o.trials(t(ti)).other.sniff_thermo,o.trials(t(ti)).other.samplingrate,thresh);
                elseif isfield(o.trials(t(ti)).other,'elec_stim')
                    [stims{ti}, params] = detect_stims('elec_stim',o.trials(t(ti)).other.elec_stim,o.trials(t(ti)).other.samplingrate,thresh);
                else
                    warning('detectStims:noStimTrace',['No stim/sniff trace in trial ' o.trials(t(ti)).name '. Skipping trial.'])
                    continue
                end
                if ~isfield(o.trials(t(ti)).measurement,'stim_times') || ...
                        numel(stims{ti}) ~= numel(o.trials(t(ti)).measurement.stim_times) || ...
                        any(stims{ti} ~= o.trials(t(ti)).measurement.stim_times)
                    interface.updateOlfact(['trials(' num2str(t(ti)) ').measurement.stim_times'],...
                        stims{ti},...
                        ['trials(' num2str(t(ti)) ').measurement_param.stim_times'],params);
                end
            end
            interface.forceRedrawView()
            refresh_current_trial_details
        end
        
        function test_stim_times_Callback(varargin)
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            
            thresh = str2double(get(threshold,'String'));
            if isempty(thresh) || isnan(thresh)
                errordlg('Please provide a valid numeric threshold for sniff detection.','Bad Threshold')
                return
            end
            
            if isfield(o.trials(t).other,'sniff_control')
                custom_detect_stims('sniff_pressure',-o.trials(t).other.sniff_control,o.trials(t).other.samplingrate,thresh);
            elseif isfield(o.trials(t).other,'sniff_pressure')
                custom_detect_stims('sniff_pressure',o.trials(t).other.sniff_pressure,o.trials(t).other.samplingrate,thresh);
            elseif isfield(o.trials(t).other,'sniff_thermo')
                custom_detect_stims('sniff_thermo',o.trials(t).other.sniff_thermo,o.trials(t).other.samplingrate,thresh);
            elseif isfield(o.trials(t).other,'elec_stim')
                custom_detect_stims('elec_stim',o.trials(t).other.elec_stim,o.trials(t).other.samplingrate,thresh);
            else
                warning('detectStims:noStimTrace',['No stim/sniff trace in trial ' o.trials(t).name '. Skipping trial.'])
            end
            
        end
    end
end

%        if ~ispref('Olfactometry','previous_sniff_detect_thresh')
%            setpref('Olfactometry','previous_sniff_detect_thresh',0.5)
%        end
%        setpref('Olfactometry','previous_sniff_detect_thresh',thresh)

function [stimtimes params] = custom_autodetect_stims(type, tr, samplingrate, thresh)
    fcn = str2func(['stimtime_' type]);
    [~, ~, stimtimes] = fcn(tr, samplingrate, thresh);
    params = struct('method','custom','thresh',thresh,'done',now);
end

function custom_detect_stims(type, tr, samplingrate, thresh)
    if which(['stimtime_' type])
        open(['stimtime_' type])

        fcn = str2func(['stimtime_' type]);
        [display_trace, horz_lines, stimtimes] = fcn(tr, samplingrate, thresh);
        figure(3001);clf
        hold all
        plot((1:length(display_trace)) / samplingrate, display_trace)
        xl = xlim; xlim(xl);
        for hi = 1:length(horz_lines)
            line(xl, [horz_lines(hi) horz_lines(hi)],'Color',[0 0 0],'LineStyle','--')
        end
        
        yl = ylim; ylim(yl);
        for si = 1:length(stimtimes)
            line([stimtimes(si) stimtimes(si)],yl,'Color',[0 0 0])
        end
        
        return
    end

end

function [stimtimes params] = detect_stims(type, tr, samplingrate, thresh)

    switch type
        case 'sniff_pressure'
            params = struct('method','Auto. integ. sniff','thresh',thresh,'done',now);
            trz = (tr-mean(tr))./std(tr); %zscore
            lookahead = samplingrate/50;
            %filtering (LPF smooths it; HPF removes any offset):
            trf = lpf(trz,samplingrate,2,25);
            trf = hpf(trf,samplingrate,2,1); %assume that transient effect of sniffing is over in < 1 s
            stimtimes = find(trf(1:end-1-lookahead) < 0 & trf(2:end-lookahead) >= 0 & trf(2+lookahead:end) > thresh) ./ samplingrate;
        case 'sniff_thermo'
            params = struct('method','Auto. integ. sniff','thresh',thresh,'done',now);
            trz = (tr-mean(tr))./std(tr); %zscore
            lookahead = samplingrate/50;
            %filtering (LPF smooths it; HPF removes any offset):
            trf = lpf(trz,samplingrate,2,2);
            trf = hpf(trf,samplingrate,2,1); %assume that transient effect of sniffing is over in < 1 s
            trf = -trf; %inverted polarity!
            stimtimes = find(trf(1:end-1-lookahead) < 0 & trf(2:end-lookahead) >= 0 & trf(2+lookahead:end) > thresh) ./ samplingrate;
        case 'elec_stim'
            params = struct('method','Auto. stim detect','done',now);
            stimtimes = find(tr > mean(tr(200:500))+500) ./ samplingrate; %threshold at 500 + avg of first 100 points; gives all shocks
            % define the TIME of a stimulation as the first stimulation in a train
            % (with more than 20 ms before it).
            stimtimes = stimtimes(diff([0 stimtimes]) > 0.02);
    end
end
