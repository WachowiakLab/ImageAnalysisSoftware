function [ts,time,sigmas] = interleaveTrials(time_series,times,stimulus,preStimTime,postStimTime)

%TCR Note: Also, could use location (average Y value) of ROI within each frame to determine times more exactly!
% e.g. [rows,~]=find(tmproi().mask); file().roi().time = ((0:frames-1) + mean(rows)/size(tmpfile.im,2)) ./ tmpfile.frameRate;

%Interleave trials, see: TimeSeries_AverageVsInterleave.ppt for detailed explanation
if isfield(stimulus,'delay') %manually defined stimulus
    delay=stimulus.delay;
    duration=stimulus.duration;
    interval=stimulus.interval;
    trials=stimulus.trials;
    stimTimes=stimulus.times;
    cnt=0;
    for k=1:trials
        if delay+(duration+interval)*(k-1)-preStimTime < 0 || ...
                delay+(duration+interval)*(k-1)+postStimTime > times(end)
            fprintf('Trial #%d discarded\n',k);
        else
            On=find(times >= delay+(duration+interval)*(k-1) - preStimTime,1,'first');
            Off=find(times <= delay+(duration+interval)*(k-1) + postStimTime,1,'last');
            ts(cnt+1:cnt+1+(Off-On)) = time_series(On:Off);
            allt(cnt+1:cnt+1+(Off-On)) = times(On:Off) - (duration+interval)*(k-1)+preStimTime;
            cnt=cnt+1+(Off-On);
        end
    end
    [tmpTimes,newindex]=sort(allt,'ascend');
    ts=ts(newindex);
    %If shifted times match exactly, this doesn't work, try averaging
    if min(diff(tmpTimes))==0; errordlg('Interleaved timeframes line up exactly, use Averaging instead');return; end
    ts=interp1(tmpTimes,ts,stimTimes);
    ts=ts(~isnan(ts));
    time=stimTimes(~isnan(ts));
    sigmas = [];
else %use auxillary stimulus
    stim=stimulus.signal;
    stimTimes=stimulus.times;
    cnt=0;
    for i=2:length(stim) %skip first frame in case signal is on at scan start
        if stim(i)==1 && stim(i-1)==0
            if stimTimes(i)-preStimTime < 0 || stimTimes(i)+postStimTime > times(end)
                fprintf('Trial discarded\n');
            else
                On=find(times >= stimTimes(i) - preStimTime,1,'first');
                Off=find(times <= stimTimes(i) + postStimTime,1,'last');
                ts(cnt+1:cnt+1+(Off-On)) = time_series(On:Off);
                allt(cnt+1:cnt+1+(Off-On)) = times(On:Off) - stimTimes(i)+preStimTime;
                cnt=cnt+1+(Off-On);
            end
        end
    end
    [tmpTimes,newindex]=sort(allt,'ascend');
    ts=ts(newindex);
    %If shifted times match exactly, this doesn't work, try averaging
    if min(diff(tmpTimes))==0; errordlg('Interleaved timeframes line up exactly, use Averaging instead');return; end
    ts=interp1(tmpTimes,ts,stimTimes);
    ts=ts(~isnan(ts));
    time=stimTimes(~isnan(ts));
    sigmas = [];
end