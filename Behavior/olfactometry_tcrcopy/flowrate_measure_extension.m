%  This is to estimate the flowrate during sniffing, measured by
%  thermocouple through classic sniff canula.
%  It adds two new options in olfactometry upper_right menu to estimate and
%  edit the position of troughs and peaks during odor presentation (those
%  are the green plain and dotted lines, respectively). The flowrate will 
%  be represented by the magnitude of amplitude of the sniff, of value at 
%  peak minus value at trough.
%  It also computes the first derivative of the sniff trace, and returns
%  the value of its peaks, corresponding to highest rising slope of sniff
%  trace, another possible estimate of flowrate during inhalation.
%  Position of peak of derivative are represented by red dotted lines
%  ========================================================================
%  The data is stored in o.trials.measurement.flowrate, as a x-by-5 matrix
%  where x is the number of complete sniff cycles during odor presentation.
%  the five columns contain : 1) position of trough, 2) position of peak,
%  3) magnitude of sniff, 4) position of peak of derivative, 
%  5) value of peak of derivative.






function flowrate_measure_extension(interface)

        interface.add(flowrate_view(interface.getBlankInitializer()))    
        interface.add(flowrate_editor(interface.getBlankInitializer()))
    
        line_color=[[0.4 1 0];[1 0.4 0]];
        
    lines_p = [];
    lines_t = [];
    lines_d = [];
    
    
        function init = flowrate_view(init)
        init.uid = 'flowrate_view';
        init.name = 'Sniff lines flowrate';
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
                line_color = uisetcolor(line_color(1,:),'Select color');
                interface.forceRedrawView()
            end
        end

        function drawView(drawaxes)
%             odorant_onset_delay = 0.03; %30 ms

            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            lines_p = [];
            lines_t = [];
            lines_d = [];
%             if isfield(trial.measurement,'response_fits')
%                 pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,trial.rois.nums);
%                 % find first response after odorant onset:
%                 resps = trial.measurement.response_fits;
%                 resps = resps([resps.stimtime] > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh([resps.roi_num]));
%                 if isempty(resps)
%                     first_sniff_response = 0;
%                 else
%                     [c,respi] = min([resps.inflection]);
%                     first_sniff_response = resps(respi).stimtime; %get sniff associated with the response
%                 end
%             else
%                 first_sniff_response = 0;
%             end
            if isfield(trial.measurement,'flowrate')
                sniff_times = trial.measurement.flowrate;
                lines_t = sniff_times(:,1);
                lines_p = sniff_times(:,2);
                lines_d = sniff_times(:,4);
                for si = 1:length(sniff_times)
%                     if sniff_times(si) == first_sniff_response
%                         lines_p(si) = line([sniff_times(si,2) sniff_times(si,2)],get(drawaxes,'YLim'),'LineStyle','--','Color',line_color(1,:),'LineWidth',2,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
%                         lines_t(si) = line([sniff_times(si,1) sniff_times(si,1)],get(drawaxes,'YLim'),'Color',line_color(1,:),'LineWidth',2,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
%                         lines_d(si) = line([sniff_times(si,4) sniff_times(si,4)],get(drawaxes,'YLim'),'LineStyle','--','Color',line_color(2,:),'LineWidth',2,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
%                     else
                        lines_p(si) = line([sniff_times(si,2) sniff_times(si,2)],get(drawaxes,'YLim'),'LineStyle','--','Color',line_color(1,:),'LineWidth',1,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
                        lines_t(si) = line([sniff_times(si,1) sniff_times(si,1)],get(drawaxes,'YLim'),'Color',line_color(1,:),'LineWidth',1,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
                        lines_d(si) = line([sniff_times(si,4) sniff_times(si,4)],get(drawaxes,'YLim'),'LineStyle','--','Color',line_color(2,:),'LineWidth',1,'Parent',drawaxes,'Userdata',-500,'Tag','full_height');
%                     end
                end
            end
        end

        function savePrefs
            lines_p = [];
            lines_t = [];
            lines_d = [];
        end
    end
    
    
    
    
    
    
    
    
    
    
    function init =    flowrate_editor(init)


        init.uid = 'flowrate_editor';
        init.name = 'Edit flowrate estimate';
        init.group = 'Analysis editing tools';
        init.prerequisites = {'flowrate_view'};
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onCheck = @loadEditor;
        init.onUncheck = @unloadEditor;

        toolboxVisible = true;

        function drawView(drawaxes) %#ok<INUSD>
            set(lines_p, 'ButtonDownFcn', @fcn_click, 'LineWidth', 3);
            set(lines_t, 'ButtonDownFcn', @fcn_click, 'LineWidth', 3);
            set(lines_d, 'ButtonDownFcn', @fcn_click, 'LineWidth', 3);
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
                msgbox({'This allows estimation of flow rate during inhalation, with thermocouple.','','TC','10 December 2010'}, init.name)
            end
        end
        
         function fcn_plot_click
            switch get(interface.fig,'SelectionType')
%                 case 'normal' %add lines with left-click
%                     pt = get(interface.mainaxes, 'CurrentPoint');
%                     save_stim_times(pt(1)); %add new time and get redrawn
                case 'alt' %clear them all with a right-click
                    delete(lines_p);lines_p = [];
                    delete(lines_t);lines_t = [];
                    delete(lines_d);lines_d = [];
                     %we can clear these ourselves without redrawing
                    save_stim_times
            end
        end

        current_line_h = [];
        function fcn_click(varargin)
            switch get(interface.fig,'SelectionType')
                case 'normal'
                    current_line_h = gcbo;
                    if ~isempty(lines_d(ismember(lines_d,gcbo)))
                        set(interface.fig, 'WindowButtonMotionFcn', []);
                        set(interface.fig, 'WindowButtonUpFcn', []);
                    else
                        set(interface.fig, 'WindowButtonMotionFcn', @fcn_drag);
                        set(interface.fig, 'WindowButtonUpFcn', @fcn_drag_end);
                    end
                    
                case 'alt'
                    if ~isempty(lines_t(ismember(lines_t,gcbo)))
                        lines_t = setdiff(lines_t,gcbo);delete(gcbo);
                    elseif ~isempty(lines_p(ismember(lines_p,gcbo)))
                        lines_p = setdiff(lines_p,gcbo);delete(gcbo);
                    elseif ~isempty(lines_d(ismember(lines_d,gcbo)))
                        lines_d = setdiff(lines_d,gcbo);delete(gcbo);
                    end
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

        %function save_stim_times(addtime)
        function save_stim_times
%             if ~nargin
%                 addtime = [];
%             end
            p = get(lines_p,'XData');
            tr = get(lines_t,'XData');
%             d = get(lines_d,'XData');
            if iscell(p)
                p = cell2mat(p);
                p = p(:,1);
            end
            if iscell(tr)
                tr = cell2mat(tr);
                tr = tr(:,1);
            end
%             newvals_p = unique([p(:); addtime])';
%             newvals_t = unique([tr(:); addtime])';
%             newvals_d = unique([d(:); addtime])';
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            flows = o.trials(t).measurement.flowrate;
                      
            [new_tr, tr_ind] = setdiff(tr,flows(:,1));                            %getting new value for event, retrieving stored info and updating with new value
            [new_p, p_ind] = setdiff(p,flows(:,2));
            if ~isempty(tr_ind)
                flows(tr_ind,1) = new_tr;
                new_p = flows(tr_ind,2);
                new_mag = getNewMagnitude(new_p,new_tr);
                flows(tr_ind,3) = new_mag;
            end
            if ~isempty(p_ind)
                flows(p_ind,2) = new_p;
                new_tr = flows(p_ind,1);
                new_mag = getNewMagnitude(new_p,new_tr);
                flows(p_ind,3) = new_mag;
            end
            
            interface.updateOlfact(['trials(' num2str(t) ').measurement.flowrate'],...
                flows,...
                ['trials(' num2str(t) ').measurement_param.flowrate'],...
                struct('method', 'Manual', 'done', now));
            if nargin
                interface.forceRedrawView()
            end
            if toolboxVisible
                refresh_current_trial_details
            end
        end
        
        function mag = getNewMagnitude(peak,trough)                     % when a new peak/trough position is set by moving them on the display, this function will set the new peak/trough difference as magnitude for that sniff
            
           o = interface.getOlfact();
           t = interface.getCurrentTrial();
           samplingrate = o.trials(t).other.samplingrate;
           if isfield(o.trials(t).other,'sniff_thermo')
               snifftrace = o.trials(t).other.sniff_thermo;
           elseif isfield(o.trials(t).other,'sniff_pressure')
              snifftrace = o.trials(t).other.sniff_pressure;
           end
           snifftrace = snifftrace(2:end); snifftrace = (snifftrace-mean(snifftrace))./std(snifftrace);
%            snifftrace = lpf(snifftrace,samplingrate,2,10); snifftrace = hpf(snifftrace, samplingrate, 2,1);
           peak = round(peak.*samplingrate); trough = round(trough.*samplingrate);
           mag = snifftrace(peak) - snifftrace(trough);
            
        end
        
        
        h = [];
        current_trial_details = [];
        threshold = [];
        trial_selection = [];
        function showToolbox
            h.fig = figure('Name','Edit flowrate estimate','Units','pixels',...
                'Position',[400 400 440 80],...
                'MenuBar', 'none', 'DockControls', 'off', 'HandleVisibility','off','NumberTitle', 'off', ...
                'CloseRequestFcn',@hideToolbox,'Resize','off','Color', get(0,'DefaultUicontrolBackgroundColor'));
%             fig = figure('Name','Edit flowrate estimate','Units','pixels',...
%                 'Position',interface.getPrefposOrDefault('flowrate_editor',[400 400 440 80]),...
%                 'MenuBar', 'none', 'DockControls', 'off', 'HandleVisibility','off','NumberTitle', 'off', ...
%                 'CloseRequestFcn',@hideToolbox,'Resize','off','Color', get(0,'DefaultUicontrolBackgroundColor'));
             current_trial_details = uicontrol('Parent',h.fig,'style','text','String','','HorizontalAlignment','left',...
                 'Units','pixels','Position',[5 5 160 55]);
            uicontrol('Parent',h.fig,'style','text','String','Autodetect', 'Units','pixels','Position',[185 2 65 23]);
            trial_selection = uicontrol('Parent',h.fig,'style','popupmenu','String',{'this trial', 'all trials', 'selected trials'},...
                'Units','pixels','Position',[250 5 90 25],'BackgroundColor',[1 1 1]);
            uicontrol('Parent',h.fig,'style','pushbutton','String','Run','Units','pixels','Position',[349 7 45 25],...
                'Callback',@get_flowrates_Callback);
            uicontrol('Parent',h.fig,'style','pushbutton','String','Test','Units','pixels','Position',[364 35 30 25],...
                'Callback',@test_flowrates_Callback);
            uicontrol('Parent',h.fig,'style','text','String','Minimum amplitude between peak and through:',...              % set threshold for IE peak detection
                'Units','pixels','Position',[165 38 160 15]);
            threshold = uicontrol('Parent',h.fig,'style','edit','String','0.5','HorizontalAlignment','left',...
                'Units','pixels','Position',[330 38 30 20],'BackgroundColor',[1 1 1]);
            h.overwrite=uicontrol('Parent',h.fig,'Style','checkbox','Units','pixels','string','Overwrite ?',...
                'Value',0,'Position',[165 53 80 20]);
            
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
                    str{2} = 'Peak times identified:';
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
            interface.setPrefpos('flowrate_editor',get(h.fig,'Position'));
            delete(h.fig);
        end
        
        function get_flowrates_Callback(varargin)
            display('You hit Run !');
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

%             stims = cell(size(t));
            %changed = false(size(t));
            for ti = 1:length(t)
%                 if isfield(o.trials(t(ti)).other,'sniff_control')
%                     [stims{ti}, params] = detect_stims('sniff_pressure',-o.trials(t(ti)).other.sniff_control,o.trials(t(ti)).other.samplingrate,thresh);
                if isfield(o.trials(t(ti)).other,'sniff_pressure')
                    [flowr{ti}, params] = detect_peaks('sniff_pressure',o.trials(t(ti)).other.sniff_pressure,o.trials(t(ti)).other.samplingrate,thresh); %#ok<AGROW>
                elseif isfield(o.trials(t(ti)).other,'sniff_thermo')
                    [flowr{ti}, params] = detect_peaks('sniff_thermo',o.trials(t(ti)).other.sniff_thermo,o.trials(t(ti)).other.samplingrate,thresh); %#ok<AGROW>
%                 elseif isfield(o.trials(t(ti)).other,'elec_stim')
%                     [stims{ti}, params] = detect_stims('elec_stim',o.trials(t(ti)).other.elec_stim,o.trials(t(ti)).other.samplingrate,thresh);
                else
                    warning('detectStims:noStimTrace',['No stim/sniff trace in trial ' o.trials(t(ti)).name '. Skipping trial.'])
                    continue
                end
                
                if ~isfield(o.trials(t(ti)).measurement,'flowrate') | ...
                        numel(flowr{ti}) ~= numel(o.trials(t(ti)).measurement.flowrate) | ...
                        any(flowr{ti} ~= o.trials(t(ti)).measurement.flowrate) | ...
                        get(h.overwrite,'Value') %#ok<*OR2>
                    interface.updateOlfact(['trials(' num2str(t(ti)) ').measurement.flowrate'],...
                        flowr{ti},...
                        ['trials(' num2str(t(ti)) ').measurement_param.flowrate'],params);
                end
            end
            interface.forceRedrawView()
%             refresh_current_trial_details
        end
        
        function test_flowrates_Callback(varargin)
            display('You hit Test !');
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            
            thresh = str2double(get(threshold,'String'));
           if isempty(thresh) || isnan(thresh) 
                errordlg('Please provide a valid numeric threshold for sniff detection.','Bad Threshold')
                return
            end
            
%             if isfield(o.trials(t).other,'sniff_control')
%                 custom_detect_stims('sniff_pressure',-o.trials(t).other.sniff_control,o.trials(t).other.samplingrate,thresh);
%             elseif isfield(o.trials(t).other,'sniff_pressure')
%                 custom_detect_stims('sniff_pressure',o.trials(t).other.sniff_pressure,o.trials(t).other.samplingrate,thresh);
            if isfield(o.trials(t).other,'sniff_thermo')
                test_detect_sniffs('sniff_thermo',o.trials(t).other.sniff_thermo,o.trials(t).other.samplingrate,thresh,o.trials(t).measurement.odor_onoff);
%             elseif isfield(o.trials(t).other,'elec_stim')
%                 custom_detect_stims('elec_stim',o.trials(t).other.elec_stim,o.trials(t).other.samplingrate,thresh);
            else
                warning('detectStims:noStimTrace',['No stim/sniff trace in trial ' o.trials(t).name '. Skipping trial.'])
            end
            
        end
    end
end



function test_detect_sniffs(~, tr, samplingrate,thresh,odor_time)
    if which('test_flowrate')
        open('test_flowrate')
        
        
        [display_trace, display_deriv, horz_lines, flowrates] = test_flowrate(tr, samplingrate,thresh,odor_time);
        % flowrate: trough position, peak position, sniff amplitude, ...
        % deriv position at peak, deriv value at peak
        
        figure(3001);clf
        hold all
        plot((1:length(display_trace)) / samplingrate, display_trace)
        plot((1:length(display_deriv)) / samplingrate, display_deriv, 'Color',[1 0 0])
        xl = xlim; xlim(xl);
        for hi = 1:length(horz_lines)
            line(xl, [horz_lines(hi) horz_lines(hi)],'Color',[0 0 0],'LineStyle','--')
        end
        
        yl = ylim; ylim(yl);
        for si = 1:length(flowrates)    
            line([flowrates(si,2) flowrates(si,2)],yl,'Color',[.3 1 .5])  %plot full lines for peaks (IE transition)
            line([flowrates(si,1) flowrates(si,1)],yl,'Color',[.3 1 .5],'LineStyle','--')   %plot dashed lines for troughs
            line([flowrates(si,4) flowrates(si,4)],yl,'Color',[1 0 1],'LineStyle','--')
            text(flowrates(si,4),yl(2)-yl(2)./10,num2str(flowrates(si,5)),'Color',[1 0 0],'VerticalAlignment','top')      
            text(flowrates(si,1),yl(2),num2str(flowrates(si,3)),'VerticalAlignment','top')
        end
        return
    end

end

function [sniff_flowrate params] = detect_peaks(~, tr, samplingrate, thresh)
    
    params = struct('method','Auto. integ. sniff','thresh',thresh,'done',now);
            tr = tr(2:end);
            trz = (tr-mean(tr))./std(tr); %zscore
            trf=trz;
            
            %onset = odor_time.odor_onset;
            %offset = odor_time.odor_offset;
            %filtering (LPF smooths it; HPF removes any offset):
%             trf = lpf(trz,samplingrate,2,10);
%             trf = hpf(trf,samplingrate,2,1); %assume that transient effect of sniffing is over in < 1 s
            %trf = -trf; %inverted polarity! %% I don't want to inverse the
            %polarity (TC, 13/12/10)
            
            tr=tr-min(tr);
            trfd = diff(tr,1);     %First derivative of not z-scored signal
            

            [peaks,troughs] = peakdet(trf,thresh); %detecting peaks and troughs on sniff trace
            peaks_odor = [peaks(:,1)./samplingrate peaks(:,2)];
            troughs_odor = [troughs(:,1)./samplingrate troughs(:,2)];
            %[dpeaks,~] = peakdet(trfd,thresh./2); %detecting peaks only on derivative
           % dpeaks = [dpeaks(:,1)./samplingrate dpeaks(:,2)];

            
                         
            if peaks_odor(1,1)<troughs_odor(1,1)                                            %making sure we deal with entire cycles
                peaks_odor=peaks_odor(2:end,:);
                peaks=peaks(2:end,:);
            end
            if peaks_odor(end,1)<troughs_odor(end,1)                                        %making sure we deal with entire cycles
                troughs_odor=troughs_odor(1:end-1,:);
                troughs=troughs(1:end-1,:);
            end
            
            dflow=[];
            while length(find(dflow))/2 ~= size(peaks_odor,1) && thresh > 0
                [dpeaks,~] = peakdet(trfd,thresh); %detecting peaks only on derivative
                thresh = thresh - 0.05;
                if size(dpeaks,1) >= size(peaks_odor,1)
                    dpeaks = [dpeaks(:,1)./samplingrate dpeaks(:,2)];
                    dflow=zeros(size(peaks_odor,1),2);
                    for i=1:length(peaks_odor)
                        dflow_thiscycle = dpeaks(dpeaks(:,1) > troughs_odor(i,1) & dpeaks(:,1) < peaks_odor(i,1),:);
                        if ~isempty(dflow_thiscycle)
                            dflow(i,:)= dflow_thiscycle(find(min(dflow_thiscycle(:,1))),:);  %#ok<FNDSB> %for each trough and peak i get the value of the peak of the derivative (if several peaks, get the first one)
                        end
                    end
                end
            end

%             sniff_flowrate = [ troughs_odor(:,1) peaks_odor(:,1) peaks_odor(:,2)-troughs_odor(:,2) dflow(:,1) dflow(:,2)];   % put all this together : one row = one cycle, with trough position, peak position, amplitude of the sniff trace between trough and peak, position of peak derivative and peak of the derivative.
            sniff_flowrate = [ troughs_odor(:,1) peaks_odor(:,1) (tr(peaks(:,1))-tr(troughs(:,1)))' dflow(:,1) dflow(:,2)];   % put all this together : one row = one cycle, with trough position, peak position, amplitude of the sniff trace between trough and peak, position of peak derivative and peak of the derivative.


          
        
end
        
        
        

    
    