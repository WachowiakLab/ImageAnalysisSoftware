function awake_mss2_extensions(interface)

    Sniffing = require('Sniffing');
    Filter = require('Filter');
    
    interface.add(summary(interface.getBlankInitializer()))
    interface.add(deconv_half_width(interface.getBlankInitializer()))
    interface.add(selection_coherence(interface.getBlankInitializer()))
    interface.add(coherence(interface.getBlankInitializer()))

    function init = summary(init)
        init.uid = 'summary';
        init.name = 'Summary times';
        init.group = 'awake_mss2 Scripts';
        init.type = 'script';
        init.onExecute = @run_summary;
        init.onRightClick = @summaryrightClick;

        function summaryrightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')


            function show_about(varargin)
                msgbox({'This gives  .','','RMC','27 July 2007'}, init.name)
            end
        end

        function run_summary

            o = interface.getOlfact(); %assignin('base','o',o);
            odorant_onset_delay = 0.03; %30 ms

            pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));

            t_10 = zeros(length(o.trials),length(o.rois));
            t_10_spread = zeros(length(o.trials),1);
            t_rise = zeros(length(o.trials),length(o.rois));
            t_rise_spread = zeros(length(o.trials),1);
            t_spread = zeros(length(o.trials),1);

            first_sniff_trace = zeros(length(o.trials),100);
            first_resp_trace = zeros(length(o.trials),100);
            
            keep = false(length(o.trials),length(o.rois));
            for t = 1:length(o.trials)
                trial = o.trials(t);
                if can_use_for_this_analysis(trial)
                    
                    % find first response after odorant onset:
                    resps = trial.measurement.response_fits;
                    resps = resps([resps.stimtime] > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                    if isempty(resps)
                        continue
                    end
                    [c,respi] = min([resps.inflection]);

                    %get sniff associated with the response:
                    sniff_index = find(trial.measurement.stim_times == resps(respi).stimtime,1);
                    if isempty(sniff_index) || sniff_index == length(trial.measurement.stim_times)
                        continue
                    end

                    sniff_start = floor(trial.measurement.stim_times(sniff_index)*trial.other.samplingrate);
                    image_start = floor(trial.measurement.stim_times(sniff_index)*trial.rois.samplingrate);

                    first_sniff_trace(t,:) = zscore(Filter.gaussian(trial.other.sniff_pressure(sniff_start+(-20:79)),trial.other.samplingrate,15));

                    %find all responses to this sniff:
                    resps = resps([resps.stimtime] == trial.measurement.stim_times(sniff_index));

                    for respi = 1:length(resps)
                        t_detect = resps(respi).inflection - trial.measurement.stim_times(sniff_index);
                        if t_detect < 0.225 && ...%must be in 0-225 ms window after sniff
                                ~isempty(resps(respi).t_10)
                            t_10(t,trial.rois.nums(resps(respi).roi_num)) = resps(respi).start + resps(respi).t_10 - trial.measurement.stim_times(sniff_index);
                            t_rise(t,trial.rois.nums(resps(respi).roi_num)) = resps(respi).rise_time;
                            keep(t,trial.rois.nums(resps(respi).roi_num)) = true;
                            first_resp_trace(t,:) = first_resp_trace(t,:) + trial.rois.traces(resps(respi).roi_num,image_start+(-20:79))./trial.rois.RLIs(resps(respi).roi_num);
                        end
                    end

                    if any(keep(t,:)) %if there were any good gloms in this trial
                        t_10s = t_10(t,keep(t,:));
                        t_rises = t_rise(t,keep(t,:));

                        t_spread(t) = max(t_10s+t_rises) - min(t_10s);

                        if sum(keep(t,:)) > 5
                            t_10_spread(t) = max(t_10s) - min(t_10s);
                            t_rise_spread(t) = max(t_rises) - min(t_rises);
                        end
                    end
                end
            end

            t_10 = t_10(keep);
            assignin('base','t_10',t_10)
%             figure,make_distribution_plot(t_10, -.05:.01:.300)
            figure,histogram(t_10, -.05:.01:.300)

            t_rise = t_rise(keep);
            assignin('base','t_rise',t_rise)
%             figure,make_distribution_plot(t_rise, 0:.01:.200)
            figure,histogram(t_rise, 0:.01:.200)

            t_10_spread = t_10_spread(t_10_spread > 0);
%             figure,make_distribution_plot(t_10_spread, (0:.01:.250))
            figure,histogram(t_10_spread, (0:.01:.250))
            assignin('base','t_10_spread',t_10_spread)
            
            t_rise_spread = t_rise_spread(t_rise_spread > 0);
            assignin('base','t_rise_spread',t_rise_spread)
%             figure,make_distribution_plot(t_rise_spread, (0:.01:.200))
            figure,histogram(t_rise_spread, (0:.01:.200))

            t_spread = t_spread(t_spread > 0);
            assignin('base','t_spread',t_spread)
%             figure,make_distribution_plot(t_spread, (0:.01:.350))
            figure,histogram(t_spread, (0:.01:.350))

            assignin('base','average_first_sniff',sum(first_sniff_trace) ./ sum(any(keep,2)))
            assignin('base','average_first_response',sum(first_resp_trace) ./ sum(keep(:)))
            
        end
    end

    function keep = can_use_for_this_analysis(trial)
        keep = isfield(trial.measurement,'stim_times') ...
            && trial.rois.samplingrate == 100 && trial.other.samplingrate == 100 ...
            && isfield(trial.measurement,'odor_onoff') && ~isempty(trial.measurement.odor_onoff.odor_onset) ...
            && isfield(trial.measurement,'response_fits') && ~isempty(trial.measurement.response_fits) ...
            && ~ismember(trial.detail.session,{'rcr20a','rcr20b','rcr20c','rcr20d'})...
            && isfield(trial.detail,'odorant_valence') && strcmp(trial.detail.odorant_valence,'-') ...
            ... nothing can have licking within 500 ms of odor on
            && (~isfield(trial.measurement,'licktime') || trial.measurement.licktime < trial.measurement.odor_onoff.odor_onset - 0.5 || trial.measurement.odor_onoff.odor_onset + 0.5 < trial.measurement.licktime);
    end

    function init = deconv_half_width(init)
        init.uid = 'deconv_half_width';
        init.name = 'Deconvolved half width';
        init.group = 'awake_mss2 Scripts';
        init.type = 'script';
        init.onExecute = @run;
        init.onRightClick = @rightClick;

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')


            function show_about(varargin)
                msgbox({'This gives the half-width of the deconvolved response to the first sniff.','','RMC','30 Nov 2007'}, init.name)
            end
        end

        function run
            Deconvolution = require('Deconvolution');
            
            o = interface.getOlfact();
            odorant_onset_delay = 0.03; %30 ms

            pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));

            half_width = zeros(length(o.trials),length(o.rois));

            keep = false(length(o.trials),length(o.rois));
            for t = 1:length(o.trials)
                trial = o.trials(t);
                if can_use_for_this_analysis(trial)

                    % find first response after odorant onset:
                    resps = trial.measurement.response_fits;
                    resps = resps([resps.stimtime] > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                    if isempty(resps)
                        continue
                    end
                    [c,respi] = min([resps.inflection]);

                    %get sniff associated with the response:
                    sniff_index = find(trial.measurement.stim_times == resps(respi).stimtime,1);
                    if isempty(sniff_index) || sniff_index == length(trial.measurement.stim_times)
                        continue
                    end

                    %find all responses to this sniff:
                    resps = resps([resps.stimtime] == trial.measurement.stim_times(sniff_index));
                    
                    if isempty(resps)
                        continue
                    end
                    
                    snifftime = trial.measurement.stim_times(sniff_index);
                    imagebounds = floor((snifftime + [0, 0.6]) .* trial.rois.samplingrate);
                    imagerange = imagebounds(1):imagebounds(2);
                    
                    for respi = 1:length(resps)
                        try
                        t_detect = resps(respi).inflection - snifftime;
                        if t_detect < 0.225 && ...%must be in 0-225 ms window after sniff
                                ~isempty(resps(respi).t_10)
                            %look from time of sniff to 225 after sniff
                            
                            tr = trial.rois.traces(resps(respi).roi_num,imagerange) ./ trial.rois.RLIs(resps(respi).roi_num);
                            deconv_tr = Deconvolution.deconvolve(tr,trial.rois.samplingrate);
                            [maxvalue, localmax] = max(deconv_tr(2:end));
                            difftr = diff(deconv_tr);
                            localmin = find(difftr(1:end-1) <= 0 & difftr(2:end) > 0) - localmax; %find local minima relative to max
                            localmin = [-min(-localmin(localmin < 0)) min(localmin(localmin > 0))] + localmax; %find local min on either side of max
                            minvalues = deconv_tr(localmin+1);
                            halfup = find(deconv_tr(localmax:-1:localmin(1)+1) <= (maxvalue+minvalues(1))*0.5,1);
                            halfdown = find(deconv_tr(localmax+2:localmin(2)+1) <= (maxvalue+minvalues(2))*0.5,1);
                            half_width(t,trial.rois.nums(resps(respi).roi_num)) = (halfdown + halfup) ./ trial.rois.samplingrate;
                            keep(t,trial.rois.nums(resps(respi).roi_num)) = true;
                        end
                        catch
                        end
                    end

                end
            end

            half_width = half_width(keep);
            assignin('base','half_width',half_width)
            figure,make_distribution_plot(half_width, -.05:.01:.300)
            
        end
    end

    function init = coherence(init)
        init.uid = 'coherence';
        init.name = 'All Coherence';
        init.group = 'awake_mss2 Scripts';
        init.type = 'script';
        init.onExecute = @run;
        init.onRightClick = @rightClick;

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')


            function show_about(varargin)
                msgbox({'This runs the coherence stuff.','','RMC','13 Dec 2007'}, init.name)
            end
        end

        pre_odor_noise_thresh = [];
        
        function run
            o = interface.getOlfact();
            odorant_onset_delay = 0.03; %30 ms

            if isempty(pre_odor_noise_thresh)
                pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));
            end
            
            coherences = zeros(length(o.trials),length(o.rois));
            frequencies = zeros(length(o.trials),length(o.rois));
            exists = false(length(o.trials),length(o.rois));
            keep = false(length(o.trials),length(o.rois));
            isfast = false(length(o.trials),1);
            isslow = false(length(o.trials),1);
            
            for t = 1:length(o.trials)
                trial = o.trials(t);
                if can_use_for_this_analysis(trial)
                    
                    postodor_sniffs = trial.measurement.stim_times(trial.measurement.odor_onoff.odor_onset <= trial.measurement.stim_times & trial.measurement.stim_times <= trial.measurement.odor_onoff.odor_offset);
                    
                    % find first response after odorant onset:
                    resps = trial.measurement.response_fits;
                    resps = resps([resps.stimtime] > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                    if isempty(resps)
                        continue
                    end
                    [c,respi] = min([resps.inflection]);
                    gloms = unique([resps(resps(respi).stimtime == [resps.stimtime]).roi_num]);
                    
                    %get sniff associated with the response:
                    sniff_index = find(postodor_sniffs == resps(respi).stimtime,1);
                    if isempty(sniff_index) || sniff_index == length(postodor_sniffs)
                        continue
                    end
                    
                    
                    
                    postodor_sniffs = postodor_sniffs(sniff_index:end);
                    
                    %determine whether it's a fastsniffing trial
                    postodor_fastsniffs = Sniffing.find_fast_sniffs(postodor_sniffs);
                    if any(postodor_fastsniffs)
                        first_fastsniff = find(postodor_fastsniffs,1);
                        first_slowsniff = find(~postodor_fastsniffs(first_fastsniff:end),1) + first_fastsniff - 1;
                        start_time = postodor_sniffs(max(first_fastsniff,2));
                        end_time = postodor_sniffs(first_slowsniff);
                        if isempty(end_time)
                            end_time = postodor_sniffs(end);
                        end
                        isfast(t) = true;
                    elseif length(postodor_sniffs) < 3 
                        continue
                    else
                        if all(diff(postodor_sniffs(2:end))) >= 0.4 %all sniffing less than 2.5 Hz
                            isslow(t) = true; %determine whether it's a slowsniffing trial
                        end
                        start_time = postodor_sniffs(2);
                        end_time = postodor_sniffs(end);
                    end
                    
                    
                    sniffindexrange = floor([start_time end_time] .* trial.other.samplingrate);
                    sniffs = trial.measurement.stim_times(start_time < trial.measurement.stim_times & trial.measurement.stim_times < end_time);
                    meansniffrate = 1 / mean(diff(sniffs));
                    
                    snifftrace = Sniffing.fake_sniff_trace([0 (sniffs-start_time).*trial.other.samplingrate], diff(sniffindexrange)+1, trial.other.samplingrate);

                    imageindexrange = floor([start_time end_time] .* trial.rois.samplingrate);
                    
                    keep(t,trial.rois.nums(gloms)) = true;

                    for g = 1:length(trial.rois.nums)
                        imagetrace = zscore(trial.rois.traces(g,imageindexrange(1):imageindexrange(2)));
                        imagetrace = hpf(imagetrace,trial.rois.samplingrate,4,0.2);
                        [data,freqs] = mscohere(snifftrace,imagetrace,[],[],[],trial.rois.samplingrate);
                        [v, ind] = min(abs(freqs - meansniffrate)); %find index of nearest freq value
                        coherences(t,trial.rois.nums(g)) = data(ind);
                        frequencies(t,trial.rois.nums(g)) = meansniffrate;
                        exists(t,trial.rois.nums(g)) = true;
                    end

                end
            end
            
            %find gloms for each odorant:
            trials = o.trials;
            odornames = arrayfun(@(s) {sprintf('%g%% %s',s.odorant_concentration,s.odorant_name)},[trials.detail]);
            [uniq_odors, b, odor_ind] = unique(odornames);
            %keep = false(length(o.trials),length(o.rois));
            for od_i = 1:length(uniq_odors)
                keep_gloms = sum(keep(odor_ind == od_i,:)) > 1;
                keep(odor_ind == id_i,:) = keep_gloms;
            end
            
            fastcoh = coherences(bsxfun(@and,keep,isfast));
            slowcoh = coherences(bsxfun(@and,keep,~isfast));
            
            assignin('base','coherence',coherences(keep))
            assignin('base','frequencies',frequencies(keep))
            
%            assignin('base','coherences',coherences)
%            assignin('base','isfast',isfast)
            assignin('base','fastcoh',fastcoh)
            assignin('base','slowcoh',slowcoh)
            
        end
        
    end

    function init = selection_coherence(init)
        init.uid = 'selection_coherence';
        init.name = 'Coherence of Selection';
        init.group = 'awake_mss2 Scripts';
        init.type = 'script';
        init.onExecute = @run;
        init.onRightClick = @rightClick;

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')


            function show_about(varargin)
                msgbox({'This calculates the coherence between the sniff trace and the selected calcium signal.','','RMC','13 Dec 2007'}, init.name)
            end
        end

        function run
            o = interface.getOlfact();
            t = interface.getCurrentTrial(); disp(t)
            ri = interface.getCurrentRois(); disp(ri)
            row = -interface.get('selection_row'); disp(row);
            timewindow = interface.get('selection_range');
            
            if isempty(row) || isempty(timewindow) || timewindow(2)-timewindow(1) == 0 || row < 1
                disp('Please select a trace')
                return
            end
            
            glom = ri(row);
            
            sniffindexrange = floor(timewindow.*o.trials(t).other.samplingrate);
            imageindexrange = floor(timewindow.*o.trials(t).rois.samplingrate);
            sniffs = o.trials(t).measurement.stim_times(timewindow(1) < o.trials(t).measurement.stim_times & o.trials(t).measurement.stim_times < timewindow(2));
            meansniffrate = 1 / mean(diff(sniffs));
            
            %snifftrace = zscore(o.trials(t).other.sniff_pressure(sniffindexrange(1):sniffindexrange(2)));
            snifftrace = Sniffing.fake_sniff_trace((sniffs-timewindow(1)).*o.trials(t).other.samplingrate, diff(sniffindexrange)+1, o.trials(t).other.samplingrate);
            
            
            imagetrace = zscore(o.trials(t).rois.traces(glom,imageindexrange(1):imageindexrange(2)));
            imagetrace = hpf(imagetrace,o.trials(t).rois.samplingrate,4,0.2);
            
            figure,subplot(3,1,1),plot(snifftrace),hold all,plot(imagetrace,'Color','red')
            
            h = spectrum.periodogram('rectangular');
            hopts = psdopts(h);
            
            nfft = (length(snifftrace)+1)/2;
            f = (o.trials(t).rois.samplingrate/2)/nfft*(0:nfft-1);          % Generate frequency vector

            set(hopts,'Fs',o.trials(t).rois.samplingrate,'FreqPoints','User Defined','FrequencyVector',f(f>0),'SpectrumType','TwoSided');

            subplot(3,1,2),msspectrum(h,snifftrace,hopts);hold all,im = msspectrum(h,imagetrace,hopts);
            im = plot(im);
            set(im,'Color','red')
            
            subplot(3,1,3),mscohere(snifftrace,imagetrace,[],[],[],o.trials(t).rois.samplingrate)
            hold all
            [data,freqs] = mscohere(snifftrace,imagetrace,[],[],[],o.trials(t).rois.samplingrate);
            
            [v, ind] = min(abs(freqs - meansniffrate)); %find index of nearest freq value
            coh = data(ind);
            scatter(meansniffrate,coh);
            ylim([0,1])
            
            figure(100),hold all
            scatter(meansniffrate,coh);
            ylim([0,1])
        end
    end
    
    
end



function make_distribution_comparision_plots(novel,nonnovel,bins)
    v1 = hist(novel,bins) ./ length(novel);
    v2 = hist(nonnovel,bins) ./ length(nonnovel);
%{
    [x y] = cumprob(novel,true);
    [ax, h1, h2] = plotyy(bins',[v1; v2]',x,y,'bar','plot');
    set(h1(1),'FaceColor','red')
    set(h1(2),'FaceColor','blue')
    set(h1,'BarWidth',1)
    set(h2,'Color','red')
    hold(ax(1),'all'),hold(ax(2),'all')
    [x y] = cumprob(nonnovel,true);
    plot(ax(2),x,y,'Color','blue')
    [h, p] = kstest2(novel, nonnovel);
    xlabel(['novel: ' num2str(median(novel)*1000) ' +/- ' num2str(std(novel)*1000) ...
        ', nonnovel: ' num2str(median(nonnovel)*1000) ' +/- ' num2str(std(nonnovel)*1000) ...
        ' ms, KS test: p = ' num2str(p)])
%}
    ax(1) = axes;
    hold(ax(1),'all')
    
    bar(bins',[v1;v2]','BarWidth',1)
    ylabel('count')
    
    [h, p] = kstest2(novel, nonnovel);
    xlabel(['novel: ' num2str(median(novel)*1000) ' +/- ' num2str(std(novel)*1000) ...
        ', nonnovel: ' num2str(median(nonnovel)*1000) ' +/- ' num2str(std(nonnovel)*1000) ...
        ' ms, KS test: p = ' num2str(p)])

    ax(2) = axes('YAxisLocation','right','Color','none','XTick',[]);
    hold(ax(2),'all')

    [x y] = cumprob(novel,true);
    plot(x,y,'Color','red');
    [x y] = cumprob(nonnovel,true);
    plot(x,y,'Color','blue')
    ylabel('cumulative probability')
    linkaxes(ax,'x')

end