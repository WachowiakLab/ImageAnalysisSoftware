function fast_sniffing_novelty_extensions(interface)

    Sniffing = require('Sniffing');

    interface.add(fastsniff_highlighter(interface.getBlankInitializer()))
    interface.add(exploratory_sniff_novelty_summary(interface.getBlankInitializer()))
    interface.add(cumulative_sniff_count(interface.getBlankInitializer()))
    interface.add(delay_to_exploratory_sniffing(interface.getBlankInitializer()))
    interface.add(response_latency_by_novelty(interface.getBlankInitializer()))
    interface.add(activity_odor_vs_sniff(interface.getBlankInitializer()))
    interface.add(report_licktimes(interface.getBlankInitializer()))

    function init = report_licktimes(init)
        init.uid = 'report_licktimes';
        init.name = 'Licktimes';
        init.group = 'fastsniff_response_time Scripts';
        init.type = 'script';
        init.onExecute = @run;

        function run
            o = interface.getOlfact();
            licktimes = zeros(1,length(o.trials));
            for ti = 1:length(o.trials)
                t = o.trials(ti);
                if isfield(t.detail,'odorant_valence') && strcmp(t.detail.odorant_valence,'+') && ...
                        isfield(t.measurement,'licked') && strcmp(t.measurement.licked,'licked') && ...
                        isfield(t.measurement,'odor_onoff') && ~isempty(t.measurement.odor_onoff.odor_onset) && ...
                        isfield(t.measurement,'stim_times')
                    postodor = t.measurement.stim_times > t.measurement.odor_onoff.odor_onset;
                    postodor_sniffs = t.measurement.stim_times(postodor);
                    if ~isempty(postodor_sniffs)
                        licktimes(ti) = t.measurement.licktime - postodor_sniffs(1);
                    end
                end
            end
            assignin('base','licktimes',licktimes(licktimes > 0))
        end

    end

    function init = fastsniff_highlighter(init)
        init.uid = 'fastsniff_highlighter';
        init.name = 'Highlight fast sniffing';
        init.group = 'Views';
        init.prerequisites = {'default_view'};
        init.onDrawView = @fastsniff_highlighterdrawView;
        init.onRightClick = @fastsniff_highlighterrightClick;

        highlight_color = [.8 .8 .3];
        separate_prePost_odor = true;

        function fastsniff_highlighterrightClick(menu)
            uimenu(menu, 'Label', 'Set highlight color', 'Callback', @show_options);
            if separate_prePost_odor
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Separately calculate pre/post odor', 'Checked', checked, 'Callback', @toggle_separate_prePost_odor);
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function toggle_separate_prePost_odor(varargin)
                separate_prePost_odor = ~separate_prePost_odor;
                interface.forceRedrawView()
            end
            function show_about(varargin)
                msgbox({'This highlights fast sniffing.','','RMC','24 July 2007'}, init.name)
            end
            function show_options(varargin)
                highlight_color = uisetcolor(highlight_color,'Select color');
                interface.forceRedrawView()
            end
        end

        function fastsniff_highlighterdrawView(drawaxes)
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            if isfield(trial.measurement,'stim_times')
                if separate_prePost_odor && isfield(trial.measurement,'odor_onoff') && ~isempty(trial.measurement.odor_onoff.odor_onset)
                    preodor = trial.measurement.stim_times < trial.measurement.odor_onoff.odor_onset;
                    make_highlights(trial.measurement.stim_times(preodor),drawaxes)
                    make_highlights(trial.measurement.stim_times(~preodor),drawaxes)
                    %tcr - note that some preodor sniffs still get drawn (if Sniffing.m NSecs is too low)
                    %and all post odor off sniffs as well
                else
                    make_highlights(trial.measurement.stim_times,drawaxes);
                end
            end
        end

        function make_highlights(stim_times,drawaxes)
            isfast = Sniffing.find_fast_sniffs(stim_times);
            for si = 1:length(isfast)
                if isfast(si)
                    line([stim_times(si) stim_times(si)],get(drawaxes,'YLim'),'Color',highlight_color,'LineWidth',3,'Parent',drawaxes,'Userdata',-600,'Tag','full_height');
                end
            end
        end
    end

    function init = exploratory_sniff_novelty_summary(init)
        init.uid = 'exploratory_sniff_novelty_summary';
        init.name = 'Exploratory sniff summary';
        init.group = 'fastsniff_response_time Scripts';
        init.type = 'script';
        init.onExecute = @run_exploratory_sniff_novelty_summary;
        init.onRightClick = @exploratory_sniff_novelty_summaryrightClick;

        show_fraction_text = true;
        show_distributions = false;

        function exploratory_sniff_novelty_summaryrightClick(menu)
            if show_fraction_text
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Summarize exploratory sniff fractions', 'Checked', checked, 'Callback', @toggle_show_fraction_text);
            if show_distributions
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Show histograms of sniff frequency distributions', 'Checked', checked, 'Callback', @toggle_show_distributions);

            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function toggle_show_fraction_text(varargin)
                show_fraction_text = ~show_fraction_text;
            end
            function toggle_show_distributions(varargin)
                show_distributions = ~show_distributions;
            end

            function show_about(varargin)
                msgbox({'This analyzes the presence of fast (exploratory) sniffing in novel/non-novel trials.','','RMC','25 July 2007'}, init.name)
            end
        end


        function run_exploratory_sniff_novelty_summary
            o = interface.getOlfact();

            novelty_types = {'novel', 'second presentation', 'third presentation', 'non-novel', 'learned', 'unclassified'};
            n_ts = {'novel', 'second', 'third', 'non_novel', 'learned', 'unclassified'};
            counts = struct;
            totals = struct;
            isis = struct;
            avg_post_isi = nan(size(o.trials));
            avg_pre_isi = nan(size(o.trials));
            for fi = 1:length(novelty_types) %initialize everything to zero
                counts.(n_ts{fi}).pre = 0;
                totals.(n_ts{fi}).pre = 0;
                isis.(n_ts{fi}).pre = {};
                counts.(n_ts{fi}).post = 0;
                totals.(n_ts{fi}).post = 0;
                isis.(n_ts{fi}).post = {};
            end
            length_of_exploratory_sniff_bout = zeros(size(o.trials));
            number_of_sniffs_in_bout = zeros(size(o.trials));
            novelty = cell(size(o.trials));
            for t = 1:length(o.trials)
                trial = o.trials(t);
                if isfield(trial.measurement,'stim_times')
                    if isfield(trial.measurement,'odor_onoff') && ~isempty(trial.measurement.odor_onoff.odor_onset)
                        preodor = trial.measurement.stim_times < trial.measurement.odor_onoff.odor_onset;
                        preodor_sniffs = trial.measurement.stim_times(preodor);
                        pre = any(Sniffing.find_fast_sniffs(preodor_sniffs));
                        postodor_sniffs = trial.measurement.stim_times(~preodor);
                        postodor_fastsniffs = Sniffing.find_fast_sniffs(postodor_sniffs);
                        post = any(postodor_fastsniffs);
                        if post
                            first_fastsniff = find(postodor_fastsniffs,1);
                            first_slowsniff = find(~postodor_fastsniffs(first_fastsniff:end),1) + first_fastsniff - 1;
                            if isempty(first_slowsniff)
                                first_slowsniff = length(postodor_fastsniffs);
                            end
                            number_of_sniffs_in_bout(t) = first_slowsniff - first_fastsniff;
                            length_of_exploratory_sniff_bout(t) = postodor_sniffs(first_slowsniff) - postodor_sniffs(first_fastsniff);
                        end
                    else
                        preodor_sniffs = trial.measurement.stim_times;
                        pre = any(Sniffing.find_fast_sniffs(preodor_sniffs));
                        post = [];
                    end
                    if isfield(trial.detail,'novelty')
                        switch trial.detail.novelty
                            case 'novel'
                                n_t = 'novel';
                            case 'second presentation'
                                n_t = 'second';
                            case 'third presentation'
                                n_t = 'third';
                            case 'non-novel'
                                n_t = 'non_novel';
                            case 'learned'
                                n_t = 'learned';
                            otherwise
                                n_t = 'unclassified';
                        end
                    else
                        n_t = 'unclassified';
                    end
                    novelty{t} = n_t;
                    counts.(n_t).pre = counts.(n_t).pre + pre;
                    totals.(n_t).pre = totals.(n_t).pre + 1;
                    isis.(n_t).pre{end+1} = diff(preodor_sniffs);
                    avg_pre_isi(t) = mean(diff(preodor_sniffs));
                    if ~isempty(post)
                        counts.(n_t).post = counts.(n_t).post + post;
                        totals.(n_t).post = totals.(n_t).post + 1;
                        isis.(n_t).post{end+1} = diff(postodor_sniffs);
                        avg_post_isi(t) = mean(diff(postodor_sniffs));
                    end
                end
            end

            assignin('base','novel_length_of_exploratory_sniff_bout',length_of_exploratory_sniff_bout(strcmp(novelty,'novel')))
            assignin('base','novel_number_of_sniffs_in_bout',number_of_sniffs_in_bout(strcmp(novelty,'novel')))
            assignin('base','avg_pre_isi',avg_pre_isi)
            assignin('base','avg_post_isi',avg_post_isi)
            assignin('base','novelty',novelty)


            maxwidth = max(cellfun(@length,novelty_types));
            disp(' ')
            disp('Exploratory sniffing summary data')
            disp(' ')
            if show_fraction_text
                disp('Fraction of trials showing exploratory sniffing:')
                disp(['Type' repmat(' ',1,maxwidth+1) 'Pre-odor' sprintf('\t\t\t\t') 'During odorant presentation'])
                for fi = 1:length(novelty_types)
                    disp([novelty_types{fi} repmat(' ',1,maxwidth+5-length(novelty_types{fi})) ...
                        num2str(counts.(n_ts{fi}).pre) '/' num2str(totals.(n_ts{fi}).pre) ...
                        ' = ' num2str(counts.(n_ts{fi}).pre / totals.(n_ts{fi}).pre) sprintf('\t\t') ...
                        num2str(counts.(n_ts{fi}).post) '/' num2str(totals.(n_ts{fi}).post) ...
                        ' = ' num2str(counts.(n_ts{fi}).post / totals.(n_ts{fi}).post)]);
                end
                disp(' ')
            end
            if show_distributions
                figure('Name','Sniff frequency distributions')
                bins = 0:.2:10;
                for fi = 1:length(novelty_types)
                    subplot(length(novelty_types),2,fi*2-1)
                    isis.(n_ts{fi}).pre = [isis.(n_ts{fi}).pre{:}];
                    hist(1./isis.(n_ts{fi}).pre,bins)
                    if fi == 1
                        title('Pre-odor')
                    end
                    xlim([min(bins) max(bins)])
                    if fi == length(novelty_types)
                        xlabel('sniff frequency (Hz)')
                    end
                    ylabel(novelty_types{fi})
                    subplot(length(novelty_types),2,fi*2)
                    isis.(n_ts{fi}).post = [isis.(n_ts{fi}).post{:}];
                    hist(1./isis.(n_ts{fi}).post,bins)
                    if fi == 1
                        title('During odorant presentation')
                    end
                    xlim([min(bins) max(bins)])
                    if fi == length(novelty_types)
                        xlabel('sniff frequency (Hz)')
                    end
                end
                assignin('base','isis',isis)
                disp('Intersniff intervals (in seconds) saved to variable ''isis''')

                %%%%For Fig 1 B/C:
                bins = 0:.05:1.6;

                figure, hold all

                dist = isis.novel.post;
                dist = dist(dist < 1.6);
                [n,x] = hist(dist,bins);
                plot(x,n./length(dist),'Color','black','DisplayName', 'novel post')

                dist = [isis.third.post isis.non_novel.post];
                dist = dist(dist < 1.6);
                [n,x] = hist(dist,bins);
                plot(x,n./length(dist),'Color','black','DisplayName', 'third+ post')

                dist = [isis.non_novel.pre isis.novel.pre isis.second.pre isis.third.pre isis.learned.pre isis.unclassified.pre];
                dist = dist(dist < 1.6);
                [n,x] = hist(dist,bins);
                plot(x,n./length(dist),'Color','red','DisplayName', 'all pre')

                dist = [isis.learned.post];
                dist = dist(dist < 1.6);
                [n,x] = hist(dist,bins);
                plot(x,n./length(dist),'Color','blue','DisplayName', 'learned post')
                %%%%

            end
        end
    end

    novel_types = {'novel'};
    nonnovel_types = {'learned'};%{'third presentation', 'non-novel'};

    function keep = can_use_for_this_analysis(trial, use_imaged_data)
        keep = isfield(trial.measurement,'stim_times') ...
            && isfield(trial.measurement,'odor_onoff') && ~isempty(trial.measurement.odor_onoff.odor_onset) ...
            && isfield(trial.detail,'novelty') ...
            && (~use_imaged_data || (... requirements for trial if imaged data is being used
            isfield(trial.measurement,'response_fits') && ...
            ~isempty(trial.measurement.response_fits) && ...
            ~ismember(trial.detail.session,{'rcr20a','rcr20b','rcr20c','rcr20d'})...
            )) ...
            && ((isfield(trial.detail,'odorant_valence') && strcmp(trial.detail.odorant_valence,'-')) ||  ismember(trial.detail.novelty,novel_types)) ...
            && ~any(Sniffing.find_fast_sniffs(trial.measurement.stim_times(trial.measurement.odor_onoff.odor_onset-4 < trial.measurement.stim_times & trial.measurement.stim_times < trial.measurement.odor_onoff.odor_onset))) ...
            ... nothing can have PRE-odor fast sniffing within 4 secs of odor onset
            && ((ismember(trial.detail.novelty,novel_types) ...
            ...            && any(Sniffing.find_fast_sniffs(trial.measurement.stim_times(trial.measurement.stim_times >= trial.measurement.odor_onoff.odor_onset))) ...
            ... but the novel trials have to have POST-odor fast sniffing
            ) || ismember(trial.detail.novelty,nonnovel_types) || ismember(trial.detail.novelty,{'novel binary ratio'}) ) ...
            ... nothing can have licking within 500 ms of odor on
            && (~isfield(trial.measurement,'licktime') || (trial.measurement.licktime < trial.measurement.odor_onoff.odor_onset - 0.5 || trial.measurement.odor_onoff.odor_onset + 0.5 < trial.measurement.licktime));

    end


    function init = cumulative_sniff_count(init)
        init.uid = 'cumulative_sniff_count';
        init.name = 'Cumulative sniff count';
        init.group = 'fastsniff_response_time Scripts';
        init.type = 'script';
        init.onExecute = @run;
        init.onRightClick = @rightClick;

        use_odor_on = false;

        function rightClick(menu)
            if use_odor_on
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Use odor on instead of first sniff after odor on', 'Checked', checked, 'Callback', @toggle_use_odor_on);

            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function toggle_use_odor_on(varargin)
                use_odor_on = ~use_odor_on;
            end
            function show_about(varargin)
                msgbox({'This compares cumulative sniff counts for novel/non-novel trials.','','RMC','25 July 2007'}, init.name)
            end
        end

        calculation_sampling_frequency = 100; %Hz

        function run
            calculation_sampling_frequency = 200; %Hz
            o = interface.getOlfact();
            odorant_onset_delay = 0.03; %30 ms
            %            if use_imaged_responses
            %                pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));
            %            end

            %go through and find the alignment points for each trial:
            post = zeros(1,length(o.trials));
            alignment_times = zeros(1,length(o.trials));
            for t = 1:length(o.trials)
                trial = o.trials(t);
                %                if can_use_for_this_analysis(trial,use_imaged_responses)
                if can_use_for_this_analysis(trial,false)
                    %                     if use_imaged_responses
                    %                         resps = trial.measurement.response_fits;
                    %                         resps = resps([resps.inflection] >= trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                    %                         if isempty(resps)
                    %                             continue
                    %                         end
                    %                         [c,respi] = min([resps.inflection]);
                    %                         alignment_time = resps(respi).stimtime;
                    if use_odor_on
                        alignment_time = trial.measurement.odor_onoff.odor_onset;
                    else
                        alignment_time = trial.measurement.stim_times(find(trial.measurement.stim_times >= trial.measurement.odor_onoff.odor_onset+odorant_onset_delay,1));
                    end
                    if ~isempty(alignment_time)
                        alignment_times(t) = alignment_time;
                        post(t) = trial.trial_length - alignment_time;
                    end
                end
            end
            use_trials = find(alignment_times > 0);

            % sample alignments at calculation_sampling_frequency
            alignment_times = floor(alignment_times * calculation_sampling_frequency);

            pre_margin = min(alignment_times(use_trials));
            post_margin = floor(min(post(use_trials) * calculation_sampling_frequency));

            cumsniff_trace = zeros(length(use_trials), pre_margin + post_margin + 1);
            novelty = cell(1,length(use_trials));

            for ti = 1:length(use_trials)
                trial = o.trials(use_trials(ti));
                novelty{ti} = trial.detail.novelty;
                % sample sniffs at calculation_sampling_frequency
                sniffs = floor(trial.measurement.stim_times * calculation_sampling_frequency) + pre_margin - alignment_times(use_trials(ti));
                sniffs = sniffs(0 < sniffs & sniffs < pre_margin+post_margin);
                cumsniff_trace(ti,:) = cumsniff_trace(ti,:) - sum(sniffs < pre_margin);
                for si = 1:length(sniffs)
                    cumsniff_trace(ti,sniffs(si):end) = cumsniff_trace(ti,sniffs(si):end) + 1;
                end
            end

            novel = cumsniff_trace(ismember(novelty, novel_types),:);
            nonnovel = cumsniff_trace(ismember(novelty, nonnovel_types),:);

            nc = size(novel);
            nnc = size(nonnovel);
            %calc means/SE
            novelSE = std(novel) / sqrt(nc(1));
            nonnovelSE = std(nonnovel) / sqrt(nnc(1));

            % CALCULATE P-VALUE! (use full novel and nonnovel matrices)
            [h, p_value] = ttest2(novel,nonnovel);
            p_value(isnan(p_value)) = 1;

            disp(['N = ' num2str(nc(1)) ' novel, ' num2str(nnc(1)) ' learned'])
            novel = mean(novel);
            nonnovel = mean(nonnovel);

            timesc = (-pre_margin:post_margin) ./ calculation_sampling_frequency;

            patchx = [timesc fliplr(timesc)];

            figure
            ax(1) = axes;
            hold(ax(1),'all')

            patch(patchx,[novel+2*novelSE fliplr(novel-2*novelSE)],'red','FaceAlpha',0.3,'LineStyle','none')
            patch(patchx,[nonnovel+2*nonnovelSE fliplr(nonnovel-2*nonnovelSE)],'blue','FaceAlpha',0.3,'LineStyle','none')

            plot(timesc,novel,'red')
            plot(timesc,nonnovel,'blue')
            %            if use_imaged_responses
            %                xlabel('time after first effective sniff after odorant onset')
            if use_odor_on
                xlabel('time after odorant onset')
            else
                xlabel('time after first sniff after odorant onset')
            end

            ylabel('cumulative sniff count')

            ax(2) = axes('YAxisLocation','right','YScale','log','Color','none','XTick',[]);
            hold(ax(2),'all')
            plot(timesc,p_value,'black')
            plot(timesc,0.01*ones(size(timesc)),'black')
            ylabel('p-value')
            linkaxes(ax,'x')
        end
    end

    function init = delay_to_exploratory_sniffing(init)
        init.uid = 'delay_to_exploratory_sniffing';
        init.name = 'Delays to exploratory sniffing';
        init.group = 'fastsniff_response_time Scripts';
        init.type = 'script';
        init.onExecute = @run_delay_to_exploratory_sniffing;
        init.onRightClick = @delay_to_exploratory_sniffingrightClick;

        use_imaged_responses = false;
        find_prior_isi = false;

        function delay_to_exploratory_sniffingrightClick(menu)
            if use_imaged_responses
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Use first response instead of first sniff after odor', 'Checked', checked, 'Callback', @toggle_use_imaged_responses);
            if find_prior_isi
                checked = 'on';
            else
                checked = 'off';
            end
            uimenu(menu, 'Label', 'Find prior intersniff interval', 'Checked', checked, 'Callback', @toggle_find_prior_isi);

            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function toggle_use_imaged_responses(varargin)
                use_imaged_responses = ~use_imaged_responses;
            end
            function toggle_find_prior_isi(varargin)
                find_prior_isi = ~find_prior_isi;
            end

            function show_about(varargin)
                msgbox({'This compares the first intersniff intervals (or optionally the prior) for novel and non-novel trials, based on the first sniff after odorant presentation (or optionally the first glomerular response).','','RMC','27 July 2007'}, init.name)
            end
        end


        function run_delay_to_exploratory_sniffing
            o = interface.getOlfact();
            odorant_onset_delay = 0.03; %30 ms
            if use_imaged_responses
                pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));
                which_sniff = zeros(1,length(o.trials));
                %                odorant_on_to_first_sniff_interval = zeros(1,length(o.trials));
            end
            isis = zeros(1,length(o.trials));
            novelty = cell(1,length(o.trials));
            shows_fast_sniffing = false(1,length(o.trials));

            for t = 1:length(o.trials)
                trial = o.trials(t);
                if can_use_for_this_analysis(trial,use_imaged_responses)
                    % find first sniff after odorant onset:
                    first_sniff_index = find(trial.measurement.stim_times >= trial.measurement.odor_onoff.odor_onset+odorant_onset_delay,1);
                    if ~isempty(first_sniff_index)
                        if use_imaged_responses
                            resps = trial.measurement.response_fits;
                            resps = resps([resps.inflection] >= trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                            if isempty(resps)
                                continue
                            end
                            [c,respi] = min([resps.inflection]);
                            new_first_sniff_index = find(trial.measurement.stim_times == resps(respi).stimtime);
                            if isempty(new_first_sniff_index)
                                continue
                            end
                            which_sniff(t) = new_first_sniff_index - first_sniff_index + 1;
                            %if which_sniff(t) > 2
                            %    disp(trial.name)
                            %end
                            %odorant_on_to_first_sniff_interval(t) = trial.measurement.stim_times(first_sniff_index) - trial.measurement.odor_onoff.odor_onset - odorant_onset_delay;
                            first_sniff_index = new_first_sniff_index;
                        end
                        if find_prior_isi
                            if first_sniff_index > 1
                                isis(t) = trial.measurement.stim_times(first_sniff_index) - trial.measurement.stim_times(first_sniff_index-1);
                            end
                        else
                            if first_sniff_index < length(trial.measurement.stim_times)
                                isis(t) = trial.measurement.stim_times(first_sniff_index+1) - trial.measurement.stim_times(first_sniff_index);
                            end
                        end
                        if isis(t) > 0
                            novelty{t} = trial.detail.novelty;
                        end
                        shows_fast_sniffing(t) = any(Sniffing.find_fast_sniffs(trial.measurement.stim_times(trial.measurement.stim_times >= trial.measurement.odor_onoff.odor_onset)));
                    end
                    %                 elseif isfield(trial.detail,'novelty') && strcmp(trial.detail.novelty,'learned') && isfield(trial.detail,'odorant_valence') && strcmp(trial.detail.odorant_valence,'-')
                    %                     if isfield(trial.measurement,'odor_onoff') && ~isempty(trial.measurement.odor_onoff.odor_onset) && isfield(trial.measurement,'licktime') && (trial.measurement.licktime > trial.measurement.odor_onoff.odor_onset - 0.5 && trial.measurement.odor_onoff.odor_onset + 0.5 > trial.measurement.licktime)
                    %                         disp(['excluded ' trial.detail.novelty ' trial due to licking: ' trial.name])
                    %                     else
                    %                         disp(['excluded ' trial.detail.novelty ' trial: ' trial.name])
                    %                     end
                end
            end

            if use_imaged_responses
                which_sniff = which_sniff(isis > 0);
                %               odorant_on_to_first_sniff_interval = odorant_on_to_first_sniff_interval(isis > 0);
            end



            trials = find(isis > 0);
            novelty = novelty(isis > 0);
            isis = isis(isis > 0);

            %novel = isis(ismember(novelty,novel_types));
            novel = isis(ismember(novelty,{'novel','novel binary ratio'}));
            novel_trials = trials(ismember(novelty,{'novel','novel binary ratio'}));
            nonnovel = isis(ismember(novelty,nonnovel_types));

            assignin('base','novel',novel)
            assignin('base','novel_trials',novel_trials)
            assignin('base','nonnovel',nonnovel)
            assignin('base','shows_fast_sniffing',shows_fast_sniffing(novel_trials))

            figure
            make_distribution_comparison_plots(novel,nonnovel,0:.05:3)

            %ROC plot
            tf = [true(size(novel)) false(size(nonnovel))];
            [Y,idx] = sort([novel nonnovel]);
            tf = tf(idx);

            no = cumsum(tf)/sum(tf);
            nno = cumsum(~tf)/sum(~tf);

            figure(3), hold all,plot([0 nno 1],[0 no 1])
            xlabel('nonnovel')
            ylabel('novel')

            if use_imaged_responses
                disp('Distribution of sniffs used (after odorant onset):')
                disp('Novel trials:')
                total = sum(which_sniff > 0 & ismember(novelty,novel_types));
                for ws = 1:max(which_sniff)
                    n = sum(which_sniff == ws & ismember(novelty,novel_types));
                    disp([int2str(ws) ': ' int2str(n) '/' int2str(total) ' = ' num2str(n/total)])
                end
                disp('Non-novel trials:')
                total = sum(which_sniff > 0 & ismember(novelty,nonnovel_types));
                for ws = 1:max(which_sniff)
                    n = sum(which_sniff == ws & ismember(novelty,nonnovel_types));
                    disp([int2str(ws) ': ' int2str(n) '/' int2str(total) ' = ' num2str(n/total)])
                end
                %                assignin('base','used_sniff_1',odorant_on_to_first_sniff_interval(which_sniff == 1));
                %                assignin('base','used_sniff_2',odorant_on_to_first_sniff_interval(which_sniff == 2));
                %                figure
                %                make_distribution_comparison_plots(odorant_on_to_first_sniff_interval(which_sniff == 1),odorant_on_to_first_sniff_interval(which_sniff == 2),0:0.05:0.65);
            end
        end

    end

    function init = response_latency_by_novelty(init)
        init.uid = 'response_latency_by_novelty';
        init.name = 'Response latencies by novelty';
        init.group = 'fastsniff_response_time Scripts';
        init.type = 'script';
        init.onExecute = @run_response_latency_by_novelty;
        init.onRightClick = @response_latency_by_noveltyrightClick;

        function response_latency_by_noveltyrightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function show_about(varargin)
                msgbox({'This finds the distribution of detection and processing times based on the start (or optionally the peak) of the first glomerular response.','','RMC','31 July 2007'}, init.name)
            end
        end


        function run_response_latency_by_novelty
            o = interface.getOlfact();
            odorant_onset_delay = 0.03; %30 ms

            pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));

            t_sniff1_to_onset = zeros(1,length(o.trials));
            t_sniff1_to_avg_onset = zeros(1,length(o.trials));
            t_onset_to_sniff2 = zeros(1,length(o.trials));
            t_sniff1_to_t90 = zeros(1,length(o.trials));
            t_t90_to_sniff2 = zeros(1,length(o.trials));
            t_sniff1_to_peak_avgd_wvfm = zeros(1,length(o.trials));
            t_t50_avgd_wvfm_to_sniff2 = zeros(1,length(o.trials));
            t_t90_avgd_wvfm_to_sniff2 = zeros(1,length(o.trials));

            t_all_onset_to_sniff2 = sparse(length(o.trials),length(o.rois));
            t_all_sniff1_to_t90 = sparse(length(o.trials),length(o.rois));
            t_all_t90_to_sniff2 = sparse(length(o.trials),length(o.rois));
            keep_rois = false(length(o.trials),length(o.rois));

            keep = false(1,length(o.trials));
            gloms = zeros(1,length(o.trials));

            novelty = cell(1,length(o.trials));
            [novelty{:}] = deal('');
            novel_counter = 0;
            for t = 1:length(o.trials)
                trial = o.trials(t);
                if can_use_for_this_analysis(trial,true)
                    if strcmp(trial.detail.novelty,'learned')
                        novel_counter = novel_counter + 1;
                    end
                    %use the first sniff after the odorant onset:
                    sniff_index = find(trial.measurement.stim_times > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay,1);
                    if isempty(sniff_index) || sniff_index == length(trial.measurement.stim_times)
                        continue
                    end

                    % find first response to this sniff:
                    resps = trial.measurement.response_fits;
                    resps = resps([resps.stimtime] == trial.measurement.stim_times(sniff_index) & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                    if isempty(resps)
                        continue
                    end
                    [c,respi] = min([resps.inflection]);

                    %find the sniff associated with the response:
                    %sniff_index = find(trial.measurement.stim_times == resps(respi).stimtime,1);
                    %find all responses to this sniff:
                    allresps = resps;%([resps.stimtime] == trial.measurement.stim_times(sniff_index));


                    if ~isempty(resps(respi).t_10)
                        t_sniff1_to_onset(t) = resps(respi).inflection - trial.measurement.stim_times(sniff_index);
                        if t_sniff1_to_onset(t) < 0.225 %onset of first response must be in 0-225 ms window after sniff
                            keep(t) = true;
                        else
                            continue
                        end

                        gloms(t) = resps(respi).roi_num;

                        t_sniff1_to_avg_onset(t) = mean([allresps.inflection]) - trial.measurement.stim_times(sniff_index);

                        t_onset_to_sniff2(t) = trial.measurement.stim_times(sniff_index + 1) - resps(respi).inflection;

                        t90 = resps(respi).start + resps(respi).t_10 + resps(respi).rise_time;
                        t_sniff1_to_t90(t) = t90 - trial.measurement.stim_times(sniff_index);
                        t_t90_to_sniff2(t) = trial.measurement.stim_times(sniff_index + 1) - t90;

                        %make averaged waveform:
                        traces = zscore(trial.rois.traces([allresps.roi_num], floor(trial.measurement.stim_times(sniff_index) * trial.rois.samplingrate):end)');
                        tr = mean(traces,2);

                        dtr = diff(tr);
                        peak = find(dtr(11:end-1) > 0 & dtr(12:end) <= 0, 1) + 11;
                        pmin = peak - find(dtr(peak-1:-1:1) < 0 & dtr(peak:-1:2) >= 0, 1) + 1;
                        if isempty(pmin)
                            pmin = 1;
                        end

                        peakamp = tr(peak);
                        pminamp = tr(pmin);
                        isi = trial.measurement.stim_times(sniff_index + 1) - trial.measurement.stim_times(sniff_index);

                        t_sniff1_to_peak_avgd_wvfm(t) = peak / trial.rois.samplingrate;
                        t_t50_avgd_wvfm_to_sniff2(t) = isi - (find(tr > (0.5*pminamp + 0.5*peakamp), 1) / trial.rois.samplingrate);
                        t_t90_avgd_wvfm_to_sniff2(t) = isi - (find(tr > (0.1*pminamp + 0.9*peakamp), 1) / trial.rois.samplingrate);

                        for respi = 1:length(allresps)
                            if ~isempty(allresps(respi).t_10)
                                t_all_onset_to_sniff2(t,allresps(respi).roi_num) = trial.measurement.stim_times(sniff_index + 1) - allresps(respi).inflection;
                                t90 = allresps(respi).start + allresps(respi).t_10 + allresps(respi).rise_time;
                                t_all_sniff1_to_t90(t,allresps(respi).roi_num) = t90 - trial.measurement.stim_times(sniff_index);
                                t_all_t90_to_sniff2(t,allresps(respi).roi_num) = trial.measurement.stim_times(sniff_index + 1) - t90;
                                keep_rois(t,allresps(respi).roi_num) = true;
                            end
                        end

                    end

                    novelty{t} = trial.detail.novelty;
                end
            end

            display(novel_counter)

            novel_dataset = strcmp(novelty,'novel');
            %            learned_dataset = strcmp(novelty,'learned');
            pooled_dataset = ismember(novelty,{'novel','learned'});

            novel_trials = o.trials(novel_dataset);
            assignin('base','novel_trials',{novel_trials.name})

            pooled_t_sniff1_to_onset = t_sniff1_to_onset(keep & pooled_dataset);
            %            pooled_t_sniff1_to_avg_onset = t_sniff1_to_avg_onset(keep & pooled_dataset);
            %            novel_t_sniff1_to_t90 = t_sniff1_to_t90(keep & novel_dataset);
            %            pooled_t_sniff1_to_peak_avgd_wvfm = t_sniff1_to_peak_avgd_wvfm(keep & pooled_dataset);
            trials = o.trials(keep & pooled_dataset);
            source_for_pooled_earliest_measurements = struct('trials',{{trials.name}'},'session',{arrayfun(@(t) {t.detail.session}, trials)'},'odorant',{arrayfun(@(t) {t.detail.odorant_name}, trials)'},'gloms',gloms(keep & pooled_dataset)','isnovel',novel_dataset(keep & pooled_dataset)');

            novel_t_onset_to_sniff2 = t_onset_to_sniff2(keep & novel_dataset);
            %            novel_t_t90_to_sniff2 = t_t90_to_sniff2(keep & novel_dataset);
            novel_t_t50_avgd_wvfm_to_sniff2 = t_t50_avgd_wvfm_to_sniff2(keep & novel_dataset);
            novel_t_t90_avgd_wvfm_to_sniff2 = t_t90_avgd_wvfm_to_sniff2(keep & novel_dataset);
            trials = o.trials(keep & novel_dataset);
            source_for_novel_averaged_measurements = struct('trials',{{trials.name}'},'session',{arrayfun(@(t) {t.detail.session}, trials)'},'odorant',{arrayfun(@(t) {t.detail.odorant_name}, trials)}');

            novel_t_all_sniff1_to_t90 = full(t_all_sniff1_to_t90(bsxfun(@and,keep_rois,(keep & novel_dataset)')));
            pooled_t_all_sniff1_to_t90 = full(t_all_sniff1_to_t90(bsxfun(@and,keep_rois,(keep & pooled_dataset)')));
            novel_t_all_onset_to_sniff2 = full(t_all_onset_to_sniff2(bsxfun(@and,keep_rois,(keep & novel_dataset)')));
            novel_t_all_t90_to_sniff2 = full(t_all_t90_to_sniff2(bsxfun(@and,keep_rois,(keep & novel_dataset)')));
            trials = o.trials(keep & novel_dataset);
            source_for_novel_earliest_measurements = struct('trials',{{trials.name}'},'session',{arrayfun(@(t) {t.detail.session}, trials)'},'odorant',{arrayfun(@(t) {t.detail.odorant_name}, trials)'},'gloms',gloms(keep & novel_dataset)');
            [tr, gl] = find(bsxfun(@and,keep_rois,(keep & novel_dataset)'));
            trials = o.trials(tr);
            source_for_novel_all_measurements = struct('trials',{{trials.name}'},'session',{arrayfun(@(t) {t.detail.session}, trials)'},'odorant',{arrayfun(@(t) {t.detail.odorant_name}, trials)'},'gloms',gl);

            [tr, gl] = find(bsxfun(@and,keep_rois,(keep & pooled_dataset)'));
            trials = o.trials(tr);
            source_for_pooled_all_measurements = struct('trials',{{trials.name}'},'session',{arrayfun(@(t) {t.detail.session}, trials)'},'odorant',{arrayfun(@(t) {t.detail.odorant_name}, trials)'},'gloms',gl);


            assignin('base','pooled_t_sniff1_to_onset', pooled_t_sniff1_to_onset)
            assignin('base','pooled_t_all_sniff1_to_t90',pooled_t_all_sniff1_to_t90)
            assignin('base','novel_t_all_sniff1_to_t90',novel_t_all_sniff1_to_t90)
            assignin('base','novel_t_onset_to_sniff2', novel_t_onset_to_sniff2)
            assignin('base','novel_t_all_onset_to_sniff2', novel_t_all_onset_to_sniff2)
            assignin('base','novel_t_all_t90_to_sniff2', novel_t_all_t90_to_sniff2)
            assignin('base','novel_t_t50_avgd_wvfm_to_sniff2',novel_t_t50_avgd_wvfm_to_sniff2)
            assignin('base','novel_t_t90_avgd_wvfm_to_sniff2', novel_t_t90_avgd_wvfm_to_sniff2)
            assignin('base','source_for_pooled_earliest_measurements',source_for_pooled_earliest_measurements)
            assignin('base','source_for_pooled_all_measurements',source_for_pooled_all_measurements)
            assignin('base','source_for_novel_earliest_measurements',source_for_novel_earliest_measurements)
            assignin('base','source_for_novel_all_measurements',source_for_novel_all_measurements)
            assignin('base','source_for_novel_averaged_measurements',source_for_novel_averaged_measurements)
            return
            figure,make_distribution_plot(pooled_t_sniff1_to_onset,0:0.025:.3)
            %            figure,make_distribution_plot(pooled_t_sniff1_to_avg_onset,0:0.01:.3)
            %            figure,make_distribution_plot(pooled_t_sniff1_to_t90,0:0.01:.5)
            %            figure,make_distribution_plot(pooled_t_sniff1_to_peak_avgd_wvfm,0:0.025:.4)

            %            figure,make_distribution_plot(novel_t_onset_to_sniff2,-0.1:0.05:.3)
            %            figure,make_distribution_plot(novel_t_t90_to_sniff2,-0.5:0.05:.25)

            figure,make_distribution_plot(novel_t_onset_to_sniff2,-0.2:0.05:.35)
            figure,make_distribution_plot(novel_t_all_onset_to_sniff2,-0.05:0.025:.35)
            figure,make_distribution_plot(novel_t_all_t90_to_sniff2,-0.25:0.025:.25)

            figure,make_distribution_plot(novel_t_t50_avgd_wvfm_to_sniff2,-0.2:0.05:.35)
            figure,make_distribution_plot(novel_t_t90_avgd_wvfm_to_sniff2,-0.2:0.05:.35)

        end
    end

    function init = activity_odor_vs_sniff(init)
        init.uid = 'activity_odor_vs_sniff';
        init.name = 'Input activity plots';
        init.group = 'fastsniff_response_time Scripts';
        init.type = 'script';
        init.onExecute = @run;
        init.onRightClick = @rightClick;

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')

            function show_about(varargin)
                msgbox({'This plots the first glomerular response in imaged trials, relative to odor onset, as well as first sniff.','','RMC','14 November 2007'}, init.name)
            end
        end


        function run
            o = interface.getOlfact();
            odorant_onset_delay = 0.03; %30 ms

            pre_odor_noise_thresh = get_pre_odor_noise_thresh(o,1:length(o.rois));

            keep = false(1,length(o.trials));
            odor_aligned_image = zeros(400,0);
            odor_aligned_sniffs = zeros(1,0);
            sniff_aligned_image = zeros(400,0);
            sniff_aligned_odor = zeros(1,0);

            for t = 1:length(o.trials)
                trial = o.trials(t);
                if can_use_for_this_analysis(trial,true) && trial.rois.samplingrate == 100

                    % find first response after odorant onset:
                    resps = trial.measurement.response_fits;
                    resps = resps([resps.stimtime] > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay & [resps.rise_amplitude] > pre_odor_noise_thresh(trial.rois.nums([resps.roi_num])));
                    if isempty(resps)
                        continue
                    end
                    [c,respi] = min([resps.inflection]);

                    %use the first sniff after the odorant onset:
                    sniff_index = find(trial.measurement.stim_times > trial.measurement.odor_onoff.odor_onset+odorant_onset_delay,1);
                    if isempty(sniff_index) || sniff_index == length(trial.measurement.stim_times)
                        continue
                    end
                    
                    t_detect = resps(respi).inflection - trial.measurement.stim_times(sniff_index);
                    t_odor_to_sniff = trial.measurement.stim_times(sniff_index) - trial.measurement.odor_onoff.odor_onset;
                    t_prev_sniff_to_odor = trial.measurement.odor_onoff.odor_onset - trial.measurement.stim_times(sniff_index - 1);
                    
                    if t_detect < 0.225 && ...%response must be in 0-225 ms window after sniff
                            t_odor_to_sniff > 0.15 && ...%sniff must be > 150 ms after odor onset
                            t_prev_sniff_to_odor > 0.1 % and prev sniff must be > 100 ms before odor onset

                        onset_samp_num = floor(trial.measurement.odor_onoff.odor_onset*trial.rois.samplingrate);
                        sniff_samp_num = floor(trial.measurement.stim_times(sniff_index)*trial.rois.samplingrate);

                        odor_aligned_sniffs(end+1) = t_odor_to_sniff;
                        sniff_aligned_odor(end+1) = -t_odor_to_sniff;

                        resps = resps([resps.stimtime] == trial.measurement.stim_times(sniff_index));
                        
                        for respi = 1:length(resps)
                            pre_odor = mean(trial.rois.traces(resps(respi).roi_num,1:onset_samp_num) ./ trial.rois.RLIs(resps(respi).roi_num));
                            odor_aligned_image(:,end+1) = (trial.rois.traces(resps(respi).roi_num,onset_samp_num+(-200:199)) ./ trial.rois.RLIs(resps(respi).roi_num) - pre_odor) ./ resps(respi).rise_amplitude;
                            sniff_aligned_image(:,end+1) = (trial.rois.traces(resps(respi).roi_num,sniff_samp_num+(-200:199)) ./ trial.rois.RLIs(resps(respi).roi_num) - pre_odor) ./ resps(respi).rise_amplitude;
                        end
                        keep(t) = true;
                    end
                end
            end
            trials = o.trials(keep);
            source = struct('trials',{{trials.name}},'odorant',{arrayfun(@(t){t.detail.odorant_name},trials)},'session',{arrayfun(@(t){t.detail.session},trials)});

            assignin('base','odor_aligned_image_traces',odor_aligned_image)
            assignin('base','sniff_aligned_image_traces',sniff_aligned_image)
            assignin('base','time_to_sniff',odor_aligned_sniffs)
            assignin('base','source',source)
            %return

            siz = size(sniff_aligned_image);
            N = siz(2);
            display(N)


            figure, hold all
            plot(-2000:10:1990,mean(odor_aligned_image,2))
            plot(-2000:10:1990,mean(odor_aligned_image,2)+(std(odor_aligned_image,0,2)./sqrt(N)))
            plot(-2000:10:1990,mean(odor_aligned_image,2)-(std(odor_aligned_image,0,2)./sqrt(N)))
            scatter(odor_aligned_sniffs.*1000,zeros(size(odor_aligned_sniffs)),'+')
            xlim([-200 400])
            ylim([-0.2 0.9])
            
            figure, hold all
            plot(-2000:10:1990,mean(sniff_aligned_image,2))
            plot(-2000:10:1990,mean(sniff_aligned_image,2)+(std(sniff_aligned_image,0,2)./sqrt(N)))
            plot(-2000:10:1990,mean(sniff_aligned_image,2)-(std(sniff_aligned_image,0,2)./sqrt(N)))
            scatter(sniff_aligned_odor.*1000,zeros(size(sniff_aligned_odor)),'+')
            xlim([-200 400])
            ylim([-0.2 0.9])
            
            
            return
            odor_aligned_image_traces = odor_aligned_image;

            %execute this code:
            N = 330;
            t = -2000:10:1990;
            post_trace = odor_aligned_image_traces(0 < t & t < 150,:);
            pre_trace = odor_aligned_image_traces(-100 < t & t <= 0,:);
            [v peak_n] = max(mean(post_trace,2));

            s_post = var(post_trace(peak_n,:),1,2);
            s_post_bar = s_post ./ N;
            s_pre = mean(var(pre_trace,1,2));
            s_pre_bar = s_pre ./ N;
            
            post_bar = mean(post_trace(peak_n,:),2);
            pre_bar = mean(mean(pre_trace,2));
            
            t_stat = (post_bar - pre_bar) ./ sqrt(s_pre_bar + s_post_bar);
            
            p_value = tcdf(-t_stat,N);
            display(p_value)
            
        end
    end
end