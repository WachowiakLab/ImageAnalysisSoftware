function [startframes,endframes] = findStimulusFrames(stimulus,imTimes,preStart,preEnd,postStart,postEnd)
% [startframes,endframes] = findStimulusFrames(stimulus,imTimes,preStart,preEnd,postStart,postEnd)
%   find startframes and endframes in imtimes from stimulus
%   with stimulus.signal, & stimulus.times
%   with or without stimulus.delay, .duration, .interval, & .trials
%   Note: this does not separate signals for different odors

half = (imTimes(2)-imTimes(1))/2; % half Frame (sec), use this to find tOn if stimulus is in first half of frame
i=2; trials=0;
endframes=[]; startframes=[];
while i<length(stimulus.signal) %skip first frame in case signal is on at scan start
    %note: we use signal >0 instead of signal ==1, in case stimuli are averaged...
    if stimulus.signal(i)>0 && stimulus.signal(i-1)==0 %find odor onset
        trials = trials+1;
        tOn=stimulus.times(i);
        if (tOn+preStart)+half < 0 || (tOn+postEnd)>imTimes(end) %check for complete data
            fprintf('Trial #%d discarded \n',trials); beep; trials = trials-1;
        else
            preOn=find(imTimes+half>=tOn+preStart,1,'first');
            preOff=find(imTimes+half<=tOn+preEnd,1,'last');
            postOn=find(imTimes+half>=tOn+postStart,1,'first');
            postOff=find(imTimes+half<=tOn+postEnd,1,'last');
            startframes = [startframes num2str(preOn) ':' num2str(preOff) ' '];        
            endframes = [endframes num2str(postOn) ':' num2str(postOff) ' '];
        end
        i=i+1;
    else
        i=i+1;
    end
end
