function response_fitting_extension(interface)

    interface.add(response_fitting(interface.getBlankInitializer()))
    interface.add(extract(interface.getBlankInitializer()))

    line_color = [.9 .9 .9];
    lines_h = [];
    lines_num = [];
	opt = optimset('Display','off');

    
    function init = response_fitting(init)
        init.uid = 'response_fitting';
        init.name = 'Fit responses';
        init.group = 'Analysis editing tools';
        init.prerequisites = {'default_view'};
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onCheck = @loadEditor;
        init.onUncheck = @unloadEditor;

        toolboxVisible = true;


        function drawView(drawaxes)
            check_noise = true;
            rendering_samplingrate = 100; %Hz
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            ri = interface.getCurrentRois();
            pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,trial.rois.nums(ri));

            scale = interface.get('real_scale_factor');
            tr_all = bsxfun(@ldivide,trial.rois.RLIs(ri),trial.rois.traces(ri,:));
            meantr_all = mean(tr_all,2);
            
            if isfield(trial.measurement,'response_fits')
                lines_num = 1:length(trial.measurement.response_fits);
                lines_h = zeros(size(lines_num));
                for n = 1:length(trial.measurement.response_fits)
                    [tf, rii] = ismember(trial.measurement.response_fits(n).roi_num,ri);
                    if tf
                        time = trial.measurement.response_fits(n).start:(1/rendering_samplingrate):trial.measurement.response_fits(n).end;
                        if trial.measurement.response_fits(n).rise_amplitude > pre_odor_noise_thresh(rii) || ~check_noise
                            plot(trial.measurement.response_fits(n).inflection,(trial.measurement.response_fits(n).y_offset-meantr_all(rii))*scale-rii,'ok','MarkerSize',3,'Parent',drawaxes);
                            if ~isempty(trial.measurement.response_fits(n).t_10)
                                plot(trial.measurement.response_fits(n).start + trial.measurement.response_fits(n).t_10 + trial.measurement.response_fits(n).rise_time,(trial.measurement.response_fits(n).y_offset + trial.measurement.response_fits(n).rise_amplitude - meantr_all(rii))*scale-rii,'*k','MarkerSize',3,'Parent',drawaxes);
                            end
                            lines_h(n) = plot(time,(dbl_sigmoid(trial.measurement.response_fits(n),time-time(1))-meantr_all(rii)).*scale-rii,'LineStyle','-','Color','black','LineWidth',1,'Parent',drawaxes,'ButtonDownFcn', @fcn_click);
                        else
                            lines_h(n) = plot(time,(dbl_sigmoid(trial.measurement.response_fits(n),time-time(1))-meantr_all(rii)).*scale-rii,'LineStyle',':','Color','black','LineWidth',1,'Parent',drawaxes,'ButtonDownFcn', @fcn_click);
                        end
                    end
                end
                lines_num = lines_num(lines_h > 0);
                lines_h = lines_h(lines_h > 0);
            end
        end

        function loadEditor
            showToolbox
        end
        function unloadEditor
            if toolboxVisible
                hideToolbox
            end
        end

        function rightClick(menu)
            set(menu,'Visible','on')
            if toolboxVisible
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Show toolbox', 'Checked', checked, 'Callback', @toggle_toolbox_visible)
            uimenu(menu, 'Label', 'Set line color', 'Callback', @show_options);

            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function show_options(varargin)
                line_color = uisetcolor(line_color,'Select color');
                interface.forceRedrawView()
            end

            function toggle_toolbox_visible(varargin)
                if toolboxVisible
                    hideToolbox
                else
                    showToolbox
                end
            end

            function show_about(varargin)
                msgbox({'This fits curves to calcium responses.','','RMC','28 July 2007'}, init.name)
            end
        end

        function fcn_click(varargin)
            switch get(interface.fig,'SelectionType')
                case 'normal' %display info about the fit
                    [tf, loc] = ismember(gcbo,lines_h);
                    if tf
                        o = interface.getOlfact();
                        t = interface.getCurrentTrial();
                        disp(o.trials(t).measurement.response_fits(lines_num(loc)));
                    end
                case 'alt' %remove the fit
                    [tf, loc] = ismember(gcbo,lines_h);
                    if tf
                        o = interface.getOlfact();
                        t = interface.getCurrentTrial();
                        f = lines_num(loc);
                        newfits = o.trials(t).measurement.response_fits([1:f-1 f+1:end]);
                        paramsfits = o.trials(t).measurement_param.response_fits;
                        paramsfits.method = 'pseudoinflection+edit';
                        paramsfits.done = now;

                        interface.updateOlfact(...
                            ['trials(' num2str(t) ').measurement.response_fits'], newfits,...
                            ['trials(' num2str(t) ').measurement_param.response_fits'], paramsfits);
                        interface.forceRedrawView()
                    end
            end
        end

        fig = [];
        current_trial_details = [];
        threshold = [];
        only_one_response = []; only_one_response_t1 = []; only_one_response_t2 = [];
        only_displayed_rois = [];
        trial_selection = [];
        function showToolbox
            fig = figure('Name','Fit responses','Units','pixels',...
                'Position',interface.getPrefposOrDefault('response_fitting_editor_v2',[400 300 400 95]),...
                'MenuBar', 'none', 'DockControls', 'off', 'HandleVisibility','off','NumberTitle', 'off', ...
                'CloseRequestFcn',@hideToolbox,'Resize','off','Color', get(0,'DefaultUicontrolBackgroundColor'));
            current_trial_details = uicontrol('Parent',fig,'style','text','String','','HorizontalAlignment','left',...
                'Units','pixels','Position',[5 35 175 55]);

            uicontrol('Parent',fig,'style','text','String','Response start concav. thresh:',...
                'Units','pixels','Position',[185 72 160 15]);
            threshold = uicontrol('Parent',fig,'style','edit','String','1e-008','HorizontalAlignment','left',...
                'Units','pixels','Position',[345 73 50 20],'BackgroundColor',[1 1 1]);
            
            only_one_response = uicontrol('Parent',fig,'style','checkbox','String','Detect 1 response starting',...
                'Units','pixels','Position',[185 48 155 23]);
            uicontrol('Parent',fig,'style','text','String','-         s',...
                'Units','pixels','Position',[359 46 38 20]);
            only_one_response_t1 = uicontrol('Parent',fig,'style','edit','String','2','HorizontalAlignment','right',...
                'Units','pixels','Position',[335 50 25 20],'BackgroundColor',[1 1 1]);
            only_one_response_t2 = uicontrol('Parent',fig,'style','edit','String','3','HorizontalAlignment','right',...
                'Units','pixels','Position',[365 50 25 20],'BackgroundColor',[1 1 1]);

            only_displayed_rois = uicontrol('Parent',fig,'style','checkbox','String','Only use displayed rois',...
                'Units','pixels','Position',[185 28 140 23]);

            uicontrol('Parent',fig,'style','text','String','Autodetect', 'Units','pixels','Position',[185 2 65 23]);
            trial_selection = uicontrol('Parent',fig,'style','popupmenu','String',{'this trial', 'all trials', 'selected trials'},...
                'Units','pixels','Position',[250 5 90 25],'BackgroundColor',[1 1 1]);
            uicontrol('Parent',fig,'style','pushbutton','String','Run','Units','pixels','Position',[345 7 45 25],...
                'Callback',@fit_responses_Callback);

            interface.register_event_listener('before_unload_trial',@clear_current_trial_details)
            interface.register_event_listener('after_load_trial',@refresh_current_trial_details)
            toolboxVisible = true;
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
                if isfield(trial.measurement,'response_fits')
                    str{1} = 'Responses fitted:';
                    str{2} = trial.measurement_param.response_fits.method;
                    if isfield(trial.measurement_param.response_fits,'thresh')
                        str{2} = [str{2} ' (thresh: ' num2str(trial.measurement_param.response_fits.thresh) ')'];
                    end
                    str{4} = datestr(trial.measurement_param.response_fits.done);
                else
                    str{1} = 'Responses fitting not yet done.';
                end
                set(current_trial_details,'String',str)
            end
        end

        function hideToolbox(varargin)
            interface.unregister_event_listener('before_unload_trial',@clear_current_trial_details)
            interface.unregister_event_listener('after_load_trial',@refresh_current_trial_details)
            toolboxVisible = false;
            interface.setPrefpos('response_fitting_editor_v2',get(fig,'Position'));
            delete(fig);
        end

        function fit_responses_Callback(varargin)
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
                errordlg('Please provide a valid numeric threshold for response concavity.','Bad Threshold')
                return
            end

            if get(only_one_response,'Value')
                one_resp_start = str2double(get(only_one_response_t1,'String'));
                if isempty(one_resp_start) || isnan(one_resp_start)
                    errordlg('Please provide a valid numeric time.','Bad number')
                    return
                end
                one_resp_end = str2double(get(only_one_response_t2,'String'));
                if isempty(one_resp_end) || isnan(one_resp_end)
                    errordlg('Please provide a valid numeric time.','Bad number')
                    return
                end
                find_only_one_response = [one_resp_start, one_resp_end];
            else
                find_only_one_response = [];
            end
            
            opt = optimset('Display','off','MaxIter',1);
            warning_backup = warning('query','all');
            warning('off','optim:lsqncommon:SwitchToLineSearch')
            
            use_only_displayed_rois = get(only_displayed_rois,'Value');
            if use_only_displayed_rois
                use_ris = interface.getCurrentRois();
            end
            for ti = 1:length(t)
                fits = cell(1,length(o.trials(t(ti)).rois.nums));
                noise = cell(1,length(o.trials(t(ti)).rois.nums));
                for ri = 1:length(o.trials(t(ti)).rois.nums)
                    if (~use_only_displayed_rois || ismember(ri,use_ris))
                        [fits{ri}, noise{ri}] = fit_responses(o.trials(t(ti)), ri, thresh, find_only_one_response);
                        if ~isempty(fits{ri})
                            [fits{ri}.roi_num] = deal(ri);
                        end
                        if ~isempty(noise{ri})
                            [noise{ri}.roi_num] = deal(ri);
                        end
%                    if length(t) < 5
%                        interface.update_status_waitbar((ti-1+ri/length(o.trials(t(ti)).rois.nums))/length(t))
%                    end
                    end
                end
                interface.update_status_waitbar(ti/length(t))
                paramsfits = struct('method','pseudoinflection','thresh',thresh,'done',now);
                paramsnoise = struct('method','max/min','done',now);
                
                interface.updateOlfact(...
                    ['trials(' num2str(t(ti)) ').measurement.response_fits'], [fits{:}],...
                    ['trials(' num2str(t(ti)) ').measurement.roi_stim_noise'], [noise{:}],...
                    ['trials(' num2str(t(ti)) ').measurement_param.response_fits'], paramsfits,...
                    ['trials(' num2str(t(ti)) ').measurement_param.roi_stim_noise'], paramsnoise);
            end
            warning(warning_backup)
            interface.clear_status_waitbar()
            interface.forceRedrawView()
            refresh_current_trial_details
            assignin('base','fit_responses',fits);
        end
    end

    function [fits, noise] = fit_responses(trial, ri, thresh, find_only_one_response)
        tr = trial.rois.traces(ri,:) ./ trial.rois.RLIs(ri);

        ftr = denoise(hpf(lpf(tr,trial.rois.samplingrate,2,4),trial.rois.samplingrate,2,0.4));

        dtr = [0 diff(ftr)]; %first derivative - slope
        lmins = find(dtr(1:end-1) < 0 & dtr(2:end) >= 0);
        tdtr = dtr .* (dtr > 0); %thresholded version
        ddtr = [0 diff(dtr)]; %second derivative - concavity
        tddtr = ddtr .* (ddtr > 0); %thresholded version 
        comb = tdtr .* tddtr; %slope*concavity
        comb = comb .* (comb > thresh); %THRESHOLD it
        dcomb = [0 diff(comb)];
        pcomb = find(dcomb(1:end-1) > 0 & dcomb(2:end) <= 0); %find times of all local max(slope*concavity) (above a threshold)
        if ~isempty(pcomb)
            vcomb = find(dcomb(1:end-1) <= 0 & dcomb(2:end) > 0, length(pcomb)); %find times of all local min...
            inflections = pcomb(comb(vcomb) == 0);
        else
            inflections = [];
        end
        starts = inflections;

        if ~isempty(find_only_one_response)
            find_only_one_response = find_only_one_response .* trial.rois.samplingrate;
            inwindow = find(find_only_one_response(1) <= starts & starts < find_only_one_response(2));
            if length(inwindow) > 1
                [m l] = max(comb(starts(inwindow))); %find the maximum slope*concavity in the window
                inwindow = inwindow(l);
            end
            starts = starts(inwindow);
            if isfield(trial.measurement,'flowrate') && ~isempty(trial.measurement.flowrate)
                fits = struct('stimtime',num2cell(starts ./ trial.rois.samplingrate),'start',num2cell(starts ./ trial.rois.samplingrate),'inflection',num2cell(inflections(inwindow) ./ trial.rois.samplingrate),'rise_amplitude',[],'onset_time',[],'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],'t_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[],'flowrate_mag',[],'flowrate_diff',[]);
                noise = struct('stimtime',{},'min',{},'max',{},'roi_num',{});
            else
                fits = struct('stimtime',num2cell(starts ./ trial.rois.samplingrate),'start',num2cell(starts ./ trial.rois.samplingrate),'inflection',num2cell(inflections(inwindow) ./ trial.rois.samplingrate),'rise_amplitude',[],'onset_time',[],'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],'t_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[]);
                noise = struct('stimtime',{},'min',{},'max',{},'roi_num',{});
            end
        elseif isfield(trial.measurement,'stim_times') && ~isempty(trial.measurement.stim_times)
            stims_samp = [floor(trial.measurement.stim_times .* trial.rois.samplingrate) trial.rois.datasize(1)]; %resample to rois
            stimtime_samp = zeros(size(starts));
            stimtime = zeros(size(starts));
            noise_mins = zeros(1,length(trial.measurement.stim_times));
            noise_maxs = noise_mins;
            
            for s = 1:length(stims_samp)-1 %assign stimtimes, make sure there's at most one response in between each stimulus
                inwindow = find(stims_samp(s) <= starts & starts < stims_samp(s+1) & starts-stims_samp(s) < (trial.rois.samplingrate*0.500));
                if length(inwindow) > 1
                    [m l] = max(comb(starts(inwindow))); %find the maximum slope*concavity in the window
                    inwindow = inwindow(l);
                end
                stimtime(inwindow) = trial.measurement.stim_times(s);
                stimtime_samp(inwindow) = stims_samp(s);
                
                %do noise calculation (max/min within first 500 ms after sniff):
                subtr_end = min(stims_samp(s+1),stims_samp(s)+floor(0.5 * trial.rois.samplingrate));
                noise_mins(s) = min(tr(stims_samp(s):subtr_end));
                noise_maxs(s) = max(tr(stims_samp(s):subtr_end));
            end
            %keep elements with assigned stimtime (max in a stim window):
            starts = starts(stimtime > 0);
            inflections = inflections(stimtime > 0);
            stimtime_samp = stimtime_samp(stimtime > 0);
            stimtime = stimtime(stimtime > 0);
            for n = 1:length(starts)
                l = find(lmins <= starts(n),1,'last');
                if ~isempty(l) && lmins(l) > stimtime_samp(n)
                    starts(n) = lmins(l);  %should move start back to either local min before it
                else
                    starts(n) = stimtime_samp(n)+1; % or to stimulus (whichever is later)
                end
            end
            if isfield(trial.measurement,'flowrate') && ~isempty(trial.measurement.flowrate) 
                fits = struct('stimtime',num2cell(stimtime),'start',num2cell(starts ./ trial.rois.samplingrate),'inflection',num2cell(inflections ./ trial.rois.samplingrate),'rise_amplitude',[],'onset_time',[],'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],'t_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[],'flowrate_mag',[],'flowrate_diff',[]);
                noise = struct('stimtime',num2cell(trial.measurement.stim_times),'min',num2cell(noise_mins),'max',num2cell(noise_maxs),'roi_num',[]);
            else
                fits = struct('stimtime',num2cell(stimtime),'start',num2cell(starts ./ trial.rois.samplingrate),'inflection',num2cell(inflections ./ trial.rois.samplingrate),'rise_amplitude',[],'onset_time',[],'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],'t_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[]);
                noise = struct('stimtime',num2cell(trial.measurement.stim_times),'min',num2cell(noise_mins),'max',num2cell(noise_maxs),'roi_num',[]);
            end
        else
            if isfield(trial.measurement,'flowrate') && ~isempty(trial.measurement.flowrate)
                fits = struct('stimtime',num2cell(starts ./ trial.rois.samplingrate),'start',num2cell(starts ./ trial.rois.samplingrate),'inflection',num2cell(inflections ./ trial.rois.samplingrate),'rise_amplitude',[],'onset_time',[],'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],'t_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[],'flowrate_mag',[],'flowrate_diff',[]);
                noise = struct('stimtime',{},'min',{},'max',{},'roi_num',{});
            else
                fits = struct('stimtime',num2cell(starts ./ trial.rois.samplingrate),'start',num2cell(starts ./ trial.rois.samplingrate),'inflection',num2cell(inflections ./ trial.rois.samplingrate),'rise_amplitude',[],'onset_time',[],'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],'t_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[]);
                noise = struct('stimtime',{},'min',{},'max',{},'roi_num',{});
            end
        end

        ends = [starts(2:end)-1 trial.rois.datasize(1)];
        isgood = true(size(fits));
        for n = 1:length(fits)
            fits(n).y_offset = tr(starts(n));
            subtr = tr(starts(n):ends(n)) - fits(n).y_offset;

            %find first local max (within first 200 ms):
            [maxx,maxlag] = max(subtr(1:min(end,floor(0.2 * trial.rois.samplingrate))));
%{
            dtr = diff(tr);
            maxlag = find(dtr(1:end-1) > 0 & 0 >= dtr(2:end),1)+1;
            if isempty(maxlag)
                isgood(n) = false;
                continue
            end
            maxx = tr(maxlag);
%}
            
            estimates = struct;
            %initialize the estimates:
            estimates.rise_amplitude = maxx;
            estimates.onset_time = find(subtr>(maxx.*0.5),1); %midpoint of rise
            estimates.rise_time = find(subtr>(maxx.*0.9),1)-find(subtr>(maxx.*0.1),1);
            if estimates.rise_time == 0
                estimates.rise_time = 1;
            end

            if isempty(maxlag) || isempty(estimates.onset_time) || isempty(estimates.rise_time)
                isgood(n) = false;
                continue
            end

            offset_time = [maxlag+find(subtr(maxlag:end)<(maxx.*0.5+subtr(end).*(1-0.5)),1) estimates.onset_time+3*estimates.rise_time]; %empirically derived default offset time
            estimates.offset_time = offset_time(1); %midpoint of fall

            estimates.fall_time = find(subtr(maxlag:end)<(maxx.*0.1+subtr(end).*(1-0.1)),1)-find(subtr(maxlag:end)<(maxx.*0.9+subtr(end).*(1-0.9)),1);
            if isempty(estimates.fall_time)
                if maxx ~= subtr(end) %use some empirically derived falltimes
                    estimates.fall_time = (length(subtr)-maxlag)*(maxx-subtr(end))/(maxx-subtr(end));
                else
                    estimates.fall_time = 3*estimates.rise_time;
                end
            end
            if estimates.fall_time == 0
                estimates.fall_time = 1;
            end

            estimates.fall_amplitude = maxx - subtr(end);
            if estimates.fall_amplitude < 0
                estimates.fall_amplitude = realmin * 2;
            end
            

            A = dbl_sigmoid_struct2arr(estimates);
            ub = A + abs(A)/2 + realmin;
            lb = A - abs(A)/2 - realmin;

            try
                A = lsqcurvefit(@dbl_sigmoid_arr,A,0:length(subtr)-1,subtr,lb,ub,opt);
                %goodness = xcorr(dbl_sigmoid_arr(A,1:length(subtr)),subtr,0,'coeff');
            catch
                isgood(n) = false;
                continue
            end
            fits(n) = dbl_sigmoid_arr_add2struct(fits(n), A);

            fits(n).onset_time = fits(n).onset_time / trial.rois.samplingrate;
            fits(n).rise_time = fits(n).rise_time / trial.rois.samplingrate;
            fits(n).offset_time = fits(n).offset_time / trial.rois.samplingrate;
            fits(n).fall_time = fits(n).fall_time / trial.rois.samplingrate;

            if fits(n).onset_time > 0.4 || fits(n).fall_amplitude < 0 %|| goodness < 0.98
                isgood(n) = false;
                continue
            end
            
            if isfield(fits(n),'flowrate_mag')
                flowrate = trial.measurement.flowrate;
                rate = flowrate((fits(n).start >= flowrate(1:end-1,1) & fits(n).start < flowrate(2:end,1)),:);
                if size(rate,1) == 1
                    fits(n).flowrate_mag = rate(3);
                    fits(n).flowrate_diff = rate(5);
                elseif  size(rate,1) > 1
                    fits(n).flowrate_mag = rate(1,3);
                    fits(n).flowrate_diff = rate(1,5);
                else
                    fits(n).flowrate_mag = nan;
                    fits(n).flowrate_diff = nan;
                end
            end
            %upsample by factor of 10 to calculate t_10, t_peak, duration
            subtr = dbl_sigmoid(fits(n),(0:length(subtr)*10) / trial.rois.samplingrate / 10) - fits(n).y_offset;
            [maxx,maxlag] = max(subtr);
            fits(n).resp_amplitude = maxx;
            fits(n).t_10 = find(subtr >= (maxx.*0.1),1) / trial.rois.samplingrate / 10;
            fits(n).t_peak = maxlag / trial.rois.samplingrate / 10;
            fits(n).t_50 = find(subtr >= (maxx.*0.5),1) / trial.rois.samplingrate / 10;
            t_50b = find(subtr(maxlag:end) <= (maxx.*0.5),1);
            if isempty(t_50b)
                fits(n).t_50b = NaN;
            else
                fits(n).t_50b = (t_50b + maxlag - 1) / trial.rois.samplingrate / 10;
            end                

            fits(n).end = fits(n).start + fits(n).offset_time + fits(n).fall_time/2;
        end
        fits = fits(isgood);
    end
    
    function init = extract(init)
        init.uid = 'extract_response_fits';
        init.name = 'Response fits extract params';
        init.group = 'Analysis editing tools';
        init.type = 'script';
        init.onExecute = @run;
        init.onRightClick = @rightClick;

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')


            function show_about(varargin)
                msgbox({'This extracts parameters from the dataset, grouping by the protocol detail.','','RMC','19 February 2008'}, init.name)
            end
        end

        function run

            o = interface.getOlfact();
            
            firsttime = o.trials(1).timestamp;
            
            all_amplitudes = cell(size(o.rois));
            all_trialname = cell(size(o.rois));
            all_snifftime = cell(size(o.rois));
            %all_sniffamps = cell(size(o.rois));
            
            for ri = 1:length(o.rois)
            
            %'single shock','schoppa','train','D-17'
            categories = {'unknown'};

            amplitude = {[]};
            trialname = {{}};
            snifftime = {[]};
            %sniffamps = {[]};
            %durations = {[]};
            %risetimes = {[]};

            %add other parameters here
            
            for ti = 1:length(o.trials)
                if (isfield(o.trials(ti).measurement,'response_fits') && ...
                        ~isempty(o.trials(ti).measurement.odor_onoff.odor_onset) && ...
                        strcmp(o.trials(ti).detail.odorant_name,'Hex/Val'))
                    if isfield(o.trials(ti).detail,'Context')
                        [tf, loc] = ismember(o.trials(ti).detail.Context, categories);
                        if ~tf
                            categories{end+1} = o.trials(ti).detail.Context;
                            loc = length(categories);

                            amplitude{loc} = [];
                            trialname{loc} = {};
                            snifftime{loc} = [];
                            %sniffamps{loc} = [];
                            %durations{loc} = [];
                            %risetimes{loc} = [];
                        end
                    else
                        loc = 1;
                    end

                    v = datevec(o.trials(ti).timestamp - firsttime);
                    trialtime = v(4) * 3600 + v(5) * 60 + v(6);
                    
                    snifftimes = o.trials(ti).measurement.stim_times;
                    
                    slow_isis = [diff(snifftimes) > 0, false]; %%%lower that one to 0....it only detects slow sniffs. ///original slow_isis = [diff(snifftimes) > 0.400, false];
                    
                    slow_sniff_times = snifftimes(slow_isis);
                    

                    f = o.trials(ti).measurement.response_fits;
                    for sniff_i = 1:length(snifftimes)
                        if (snifftimes(sniff_i) > o.trials(ti).measurement.odor_onoff.odor_onset && ...
                                snifftimes(sniff_i) < o.trials(ti).measurement.odor_onoff.odor_offset && ...
                                ismember(snifftimes(sniff_i), slow_sniff_times))
                            
                            amplitude{loc} = [amplitude{loc} 0];
                            trialname{loc} = [trialname{loc} o.trials(ti).name];
                            snifftime{loc} = [snifftime{loc} snifftimes(sniff_i) + trialtime]; %extracts absolute time in imaging session
                            %snifftime{loc} = [snifftime{loc} snifftimes(sniff_i)];
                            %sniffamps{loc} = [sniffamps{loc} o.trials(ti).measurement.sniff_amplitudes(sniff_i)];
                            %durations{loc} = [durations{loc} 0];
                            %risetimes{loc} = [risetimes{loc} 0];
                            
                            for fi = 1:length(f)
                                if (f(fi).stimtime == snifftimes(sniff_i) && o.trials(ti).rois.nums(f(fi).roi_num) == ri)
                                    amplitude{loc}(end) = f(fi).resp_amplitude;
                                    %risetimes{loc} = [risetimes{loc} f(fi).rise_time];
                                    %durations{loc} = [durations{loc} f(fi).t_50b-f(fi).t_50]; % durations{loc}(end) = f(fi).t_50b-f(fi).t_50;
                                end
                            end
                        end
                     end

                end
            end
            assignin('base','categories',categories)
            
            means = cellfun(@mean,amplitude);
            stds = cellfun(@std,amplitude);
            lengths = cellfun(@length,amplitude);
            
            disp(['roi ',int2str(o.rois(ri).index),' amplitude:'])
            for ci = 1:length(categories)
                disp([categories{ci} ':  ' num2str(means(ci)) ' +- ' num2str(stds(ci)) ' (N = ' num2str(lengths(ci)) ')'])
            end
            
            %assignin('base','amplitude',amplitude)
            
            %disp('Rise time:')
            %for ci = 1:length(categories)
            %    disp([categories{ci} ':  ' num2str(means(ci)) ' +- ' num2str(stds(ci)) ' (N = ' num2str(lengths(ci)) ')'])
            %end
            %assignin('base','risetimes',risetimes)
            
            

            %assignin('base','amplitude',amplitude)
%{            
            means = cellfun(@mean,durations);
            stds = cellfun(@std,durations);
            lengths = cellfun(@length,risetimes);

            %disp('Duration:')
            %for ci = 1:length(categories)
            %    disp([categories{ci} ':  ' num2str(means(ci)) ' +- ' num2str(stds(ci)) ' (N = ' num2str(lengths(ci)) ')'])
            %end
            %assignin('base','durations',durations)
            
            
            all_amplitudes{ri} = amplitude;
            all_trialname{ri} = trialname;
            all_snifftime{ri} = snifftime;
            all_durations{ri} = durations;
            all_risetimes{ri} = risetimes;
            %all_sniffamps{ri} = sniffamps;
            
            end

            assignin('base','all_amplitudes',all_amplitudes)
            assignin('base','all_trialname',all_trialname)
            assignin('base','all_snifftime',all_snifftime)
            assignin('base','all_durations',all_durations)
            assignin('base','all_risetimes',all_risetimes)
            %assignin('base','all_sniffamps',all_sniffamps)

            assignin('base','durations',durations)
  %}          
            

            all_amplitudes{ri} = amplitude;
            all_trialname{ri} = trialname;
            all_snifftime{ri} = snifftime;
            %all_sniffamps{ri} = sniffamps;
            
            end
%             assignin('base','all_amplitudes',all_amplitudes)
%             assignin('base','all_trialname',all_trialname)
%             assignin('base','all_snifftime',all_snifftime)
            %assignin('base','all_sniffamps',all_sniffamps)
        end
    end
end

function y = dbl_sigmoid_arr(A,t)
    y = A(1)./(exp(-4.4*(t - A(2))./A(3)) + 1) - A(4)./(exp(-4.4*(t - A(5))./A(6)) + 1);
end

function y = dbl_sigmoid(params,t)
    % times are in seconds, amplitudes are divided by RLIs
    y = params.rise_amplitude ./ (exp(-4.4*(t - params.onset_time) ./ params.rise_time) + 1) - params.fall_amplitude ./ (exp(-4.4*(t - params.offset_time) ./ params.fall_time ) + 1) + params.y_offset;
end

function B = dbl_sigmoid_arr_add2struct(B,A)
    B.rise_amplitude = A(1); B.onset_time = A(2); B.rise_time = A(3); B.fall_amplitude = A(4); B.offset_time = A(5); B.fall_time = A(6);
end

function A = dbl_sigmoid_struct2arr(B)
    A = [B.rise_amplitude B.onset_time B.rise_time B.fall_amplitude B.offset_time B.fall_time];
end

