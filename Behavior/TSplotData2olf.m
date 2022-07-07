function TSplotData2olf(TSdata,plotdata)

o = olfact; %empty olfactometry object, needs olfactometry directory in path

for r = 1:length(TSdata.roi)
    o.rois(r).name = [];
    o.rois(r).source = [];
    o.rois(r).index = r;
    o.rois(r).points = find(TSdata.roi(r).mask);
    [row,col] = find(TSdata.roi(r).mask);
    Ypos = (mean(row)); Xpos = (mean(col));
    o.rois(r).position = [Xpos Ypos];
    o.rois(r).measurement = [];
    o.rois(r).measurement_param = [];
    o.rois(r).detail = [];
end


cnt = 0;
for f = 1:length(plotdata.file)
    o.trials(f).rois.nums = '';
    for oo = 1:length(plotdata.file(f).roi(1).odor)
        for t = 1:length(plotdata.file(f).roi(1).odor(oo).trial)
            cnt = cnt+1;
            o.trials(cnt).name = [plotdata.file(f).name(1:end-4) '_odor' ...
                num2str(plotdata.file(f).roi(1).odor(oo).number) '_trial' ...
                num2str(plotdata.file(f).roi(1).odor(oo).trial(t).number)];
            o.trials(cnt).numtrialavg = 1;
            o.trials(cnt).trial_length = plotdata.file(f).roi(1).odor(1).trial(t).time(end);
            o.trials(cnt).rois.samplingrate = 150; %all trials interpolated to 150Hz in TimeSeriesAnalysis
            o.trials(cnt).rois.datasize = [length(plotdata.file(f).roi(1).odor(1).trial(t).time) 1 1];
            o.trials(cnt).rois.nums = []; o.trials(cnt).rois.traces = []; o.trials(cnt).rois.RLIs = [];
            for r = 1:length(plotdata.file(f).roi)
                o.trials(cnt).rois.nums = [o.trials(cnt).rois.nums r];
                o.trials(cnt).rois.traces(r,:) = plotdata.file(f).roi(r).odor(oo).trial(t).series;
                o.trials(cnt).rois.RLIs(r,1) = 1; %this could be added later - depends on deltaF settings
            end
            o.trials(cnt).other.samplingrate = 1000; %fixed ephys sampling rate
%             o.trials(cnt).other.odor_onoff = TSdata.file(f).ephys.odor; %wrong signal! this is the whole thing, not trials
%             o.trials(cnt).other.sniff_thermo = TSdata.file(f).ephys.sniff;
%             o.trials(cnt).other.puff = TSdata.file(f).ephys.puff; %not sure if this will work
            o.trials(cnt).other.odor_onoff = plotdata.file(f).ephys.odors(oo).trials(t).odor;
            o.trials(cnt).other.sniff_thermo = plotdata.file(f).ephys.odors(oo).trials(t).sniff;
            o.trials(cnt).other.puff = plotdata.file(f).ephys.odors(oo).trials(t).puff; %not sure if this will work
            index_on = find(plotdata.file(f).ephys.odors(oo).trials(t).odor>2.5,1,'first'); %find 0to5Volt rise
            o.trials(cnt).measurement.odor_onoff.odor_onset = plotdata.file(f).ephys.odors(oo).trials(t).times(index_on);
            index_off = index_on+find(plotdata.file(f).ephys.odors(oo).trials(t).odor(index_on:end)<2.5,1,'first');
            o.trials(cnt).measurement.odor_onoff.odor_offset = plotdata.file(f).ephys.odors(oo).trials(t).times(index_off);
            %olf.trials(cnt).measurement.licktime = 2.03;
            %olf.trials(cnt).measurement.licked = '';
            %olf.trials(cnt).measurement_param.odor_onoff.thresh = 0.1;
            %olf.trials(cnt).measurement_param.lick_min = 3;
            %olf.trials(cnt).measurement_param.lick_max = 8;
            %olf.trial(cnt).detail.comment = '';
            %olf.trial(cnt).detail.session = '';
            %olf.trial(cnt).detail.odorant_name = '';
            %olf.trial(cnt).detail.odorant_concentration = '';
            %olf.trial(cnt).detail.odorant_valence = '';
%             olf.trial(cnt).import.preptype = '';
%             olf.trial(cnt).import.source.type = '';
%             olf.trial(cnt).import.source.BNCs = {'odor_onoff', 'sniff', 'puff'};
%             olf.trial(cnt).import.source.digits_in_trial_number = 2;
%             olf.trial(cnt).import.source.da_dir = '';
%             olf.trial(cnt).import.source.det_dir = '';

        end
    end
end

[olffile,olfpath] = uiputfile('test.olf');
save(fullfile(olfpath,olffile),'o','-mat');