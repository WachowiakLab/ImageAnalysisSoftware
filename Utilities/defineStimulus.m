function [stimulus] = defineStimulus(startT,endT,deltaT,delay,duration,interval,maxtrials)
%[stimulus] = defineStimulus(startT,endT,deltaT,delay,duration,interval,trials)
% define a repetitive binary stimulus signal, returns:
%   stimulus.times, and
%   stimulus.signal

stimulus.times = startT:deltaT:endT;
stimulus.signal = zeros(size(stimulus.times));
trials=min(maxtrials,floor((endT-startT-delay+interval)/(duration+interval)));
for n = 1:trials
    tOn = delay+(n-1)*(duration+interval);
    ind1 = find(stimulus.times>tOn,1,'first');
    ind2 = find(stimulus.times<=tOn+duration,1,'last');
    stimulus.signal(ind1:ind2)=1;
end
stimulus.delay=delay;
stimulus.duration=duration;
stimulus.interval=interval;
stimulus.trials=trials;
