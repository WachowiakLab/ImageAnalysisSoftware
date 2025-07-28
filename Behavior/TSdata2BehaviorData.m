function behaviordata = TSdata2BehaviorData(tsdata,stim2use,prestimtime,poststimtime)
% trialsdata = TSdata2BehaviorData(tsdata,stim2use,prestimtime,poststimtime)
%convert tsdata(time series data) into behaviordata for behavior analysis GUI
%   tsdata - from TimeSeriesAnalysis (e.g. Save App Data); must include stim2use signal
%   stim2use = 'Aux1(odor)' || 'Aux2(sniff)' || 'AuxCombo' || 'Manually Defined Stimulus'
%   prestimtime = double (duration in seconds pre-stimulus signal to include in trial)
%   poststimtime = double (duration in seconds post-stimulus signal to include in trial)
%gets all odortrials, if they are valid in terms of pre-post stim time

behaviordata.stim2use = stim2use;
behaviordata.prestimtime = prestimtime;
behaviordata.poststimtime = poststimtime;
auxtypes = getauxtypes;
allOdorTrials = cell(length(tsdata.file),1);
if strcmp(stim2use,auxtypes{1}) %Aux1(odor)
    for f = 1:length(tsdata.file)
        allOdorTrials{f} = getAllOdorTrials(auxtypes{1},prestimtime,poststimtime,tsdata.file(f));
    end
    stimtimes = tsdata.file(1).aux1.times;
elseif strcmp(stim2use,auxtypes{2}) %Aux2(sniff)
    for f = 1:length(tsdata.file)
        allOdorTrials{f} = getAllOdorTrials(auxtypes{2},prestimtime,poststimtime,tsdata.file(f));
    end
    stimtimes = tsdata.file(1).aux2.times;
elseif strcmp(stim2use,auxtypes{3}) %AuxCombo
    for f = 1:length(tsdata.file)
        allOdorTrials{f} = getAllOdorTrials(auxtypes{3},prestimtime,poststimtime,tsdata.file(f));
    end
    stimtimes = tsdata.file(1).aux_combo.times;
elseif strcmp(stim2use,auxtypes{4}) %Manually Defined Stimulus
    stimtimes = tsdata.file(1).def_stimulus.times;
    for f = 1:length(tsdata.file)
        allOdorTrials{f} = getAllOdorTrials(auxtypes{4},prestimtime,poststimtime,tsdata.file(f));
    end
end
newTS = [];
for f = 1:length(tsdata.file)
    for r = 1:length(tsdata.file(f).roi)
        newTS{f,r}=interp1(tsdata.file(f).roi(r).time,tsdata.file(f).roi(r).series,stimtimes,'pchip');
    end
end
cnt=0;
for f = 1:numel(allOdorTrials)
    odors = allOdorTrials{f}.odors;
    for o = 1:length(allOdorTrials{f}.odor)
        trials = allOdorTrials{f}.odor(o).trials; %all the valid trials
        for t = 1:length(allOdorTrials{f}.odor(o).trial) 
            cnt=cnt+1;
            behaviordata.trials(cnt).dir = tsdata.file(f).dir;
            behaviordata.trials(cnt).name = tsdata.file(f).name;
            behaviordata.trials(cnt).type = tsdata.file(f).type;
            behaviordata.trials(cnt).frameRate = 1/diff(stimtimes(1:2)); %post-interpolation
            behaviordata.trials(cnt).odornumber = odors(o);
            behaviordata.trials(cnt).trialnumber = trials(t);
            index = allOdorTrials{f}.odor(o).trial(t).auxindex;
            behaviordata.trials(cnt).aux1.times = tsdata.file(f).aux1.times(index);
            behaviordata.trials(cnt).aux1.signal = tsdata.file(f).aux1.signal(index);
            behaviordata.trials(cnt).aux2.times = tsdata.file(f).aux1.times(index);
            behaviordata.trials(cnt).aux2.signal = tsdata.file(f).aux1.signal(index);
            %skipping aux3 - odornumber provides this info
            if isfield(tsdata.file(f),'ephys')
                eind1 = find(tsdata.file(f).ephys.times>=stimtimes(index(1)),1,'first');
                eind2 = find(tsdata.file(f).ephys.times<=stimtimes(index(end)),1,'last');
                behaviordata.trials(cnt).ephys.times = tsdata.file(f).ephys.times(eind1:eind2); %...
%                     - tsdata.file(f).ephys.times(eind1); %set to zero based
                behaviordata.trials(cnt).ephys.odor = tsdata.file(f).ephys.odor(eind1:eind2);
                behaviordata.trials(cnt).ephys.sniff = tsdata.file(f).ephys.sniff(eind1:eind2);
                behaviordata.trials(cnt).ephys.puff = tsdata.file(f).ephys.puff(eind1:eind2);
                if isfield(tsdata.file(f).ephys,'lick')
                    behaviordata.trials(cnt).ephys.lick = tsdata.file(f).ephys.lick(eind1:eind2);
                end
                behaviordata.trials(cnt).ephys.reward = tsdata.file(f).ephys.reward(eind1:eind2);
                behaviordata.trials(cnt).ephys.valence = tsdata.file(f).ephys.valence(eind1:eind2);
            end
            for r = 1:length(tsdata.file(f).roi)
                tmpTS=newTS{f,r};
                behaviordata.trials(cnt).roi(r).time = stimtimes(index);
                behaviordata.trials(cnt).roi(r).series = tmpTS(index);
                %tcr - could compute significance threshold or check for significance here e.g.> 2.5std(baseline)
            end
        end
    end
end
