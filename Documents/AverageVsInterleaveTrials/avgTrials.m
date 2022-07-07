function [ts,time,sigmas] = avgTrials(time_series,times,stimulus,preStimTime,postStimTime)

if ~isfield(stimulus,'signal') || ~isfield(stimulus,'times')
    errordlg('stimulus must include stimulus.signal & stimulus.times');
    return;
end

if isfield(stimulus,'delay') %manually defined stimulus
    delay=stimulus.delay;
    duration=stimulus.duration;
    interval=stimulus.interval;
    trials=stimulus.trials;
    stimTimes=stimulus.times;
    %stimulus=stimulus.signal;
    % upsample time_series to match stimulus times using interpolation
    newTS=interp1(times,time_series,stimTimes,'pchip'); %"pchip" is a Shape-preserving piecewise cubic interpolation - MW's choice!
    %preStimTime=str2double(get(hTS.preStimTime,'String'));
    preFrames = find(stimTimes>preStimTime, 1, 'first')-1; %#frames to grab before stimulus
    numFrames = find(stimTimes>(preStimTime+postStimTime), 1, 'first')-1; %total #frames to grab
    if isempty(numFrames); errordlg('preStimTime + postStimTime > totalTime'); return; end
    %pull out values for each trial
    newTS_trials = NaN*zeros(numFrames, trials);
    for k = 1:trials
        On=find(stimTimes>delay+(duration+interval)*(k-1),1,'first');
        if isempty(On); fprintf('Trial #%d discarded\n',k);
        else
            ind1 = On-preFrames;
            ind2 = ind1+numFrames;
            if ind1<1 || ind2>length(stimTimes)
                fprintf('Trial #%d discarded\n',k);
            else
                newTS_trials(1:numFrames+1, k) = newTS(ind1:ind2);
            end
        end
    end
    ts = nanmean(newTS_trials,2);
    time = stimTimes(1:numFrames+1)';
    sigmas(1,:) = ts+1.96.*std(newTS_trials, 0, 2)./sqrt(size(newTS_trials, 2)); %confidence intervals
    sigmas(2,:) = ts-1.96.*std(newTS_trials, 0, 2)./sqrt(size(newTS_trials, 2)); %confidence intervals
   
else %and for auxillary stimulus
    stim=stimulus.signal;
    stimTimes=stimulus.times;
    newTS=interp1(times,time_series,stimTimes,'pchip'); %"pchip" is a Shape-preserving piecewise cubic interpolation - MW's choice!
    preFrames = find(stimTimes>preStimTime, 1, 'first')-1; %#frames to grab before stimulus
    numFrames = find(stimTimes>(preStimTime+postStimTime), 1, 'first')-1; %total #frames to grab
    trial=0;
    for i=2:length(stim) %skip first frame in case signal is on at scan start
        if stim(i)>0 && stim(i-1)==0 %use stim>0 in case of averaged aux signals
            ind1=i-preFrames;
            ind2=ind1+numFrames;
            if ind1<1 || ind2>length(stimTimes)
                fprintf('Trial discarded\n');
            else
                trial=trial+1;
                newTS_trials(1:numFrames+1, trial) = newTS(ind1:ind2);
            end
        end
    end
    ts = nanmean(newTS_trials,2);
    time = stimTimes(1:numFrames+1)';
    sigmas(1,:) = ts+1.96.*std(newTS_trials, 0, 2)./sqrt(size(newTS_trials, 2)); %confidence intervals
    sigmas(2,:) = ts-1.96.*std(newTS_trials, 0, 2)./sqrt(size(newTS_trials, 2)); %confidence intervals
end








