function [aux1,aux2,aux3] = loadScanboxStimulus(sbxinfo,varargin)
% [aux1,aux2] = loadScanboxStimulus(sbxinfo)
% get the auxillary signals from scanbox info
% varargin{1} = odorDuration(sec) - used for odor encoding

%scanbox auxillary (TTL) signals are acquired/sampled at every line of every frame of image,
%we decided to resample the signal at 150Hz
times = 0:1/150:(sbxinfo.max_idx+1)/sbxinfo.frameRate;
if nargin>1; odorOnFrames = find(times>=varargin{1},1,'first'); %varargin{1} is odorDuration(sec)
else; odorOnFrames = 1;
end
aux1.times = times; aux2.times = times;
aux1.signal = zeros(1,length(aux1.times)); %TTL1, records odor presentation (on/off)
aux2.signal = zeros(1,length(aux2.times)); %TTL0, records sniff signal (on only)
for i = 1:length(sbxinfo.event_id)
    if sbxinfo.frame(i) == 0 && sbxinfo.line(i) == 0
        %ignore this event, ttl1 may record an accidental signal in the first frame of the scan
    else
        %compute time of event (note info.frames starts at 0)
        time = (sbxinfo.frame(i)/sbxinfo.frameRate) + (sbxinfo.line(i)/sbxinfo.resfreq);
        idx = find(times>=time,1,'first'); %find index of next stimulus time after event
        if ~isempty(idx)
            if sbxinfo.scanbox_version == 3
                if sbxinfo.event_id(i) == 4 %currently, aux2(sniff) only records rise
                    aux1.signal(idx:end) = 1;
                elseif sbxinfo.event_id(i) == 1
                    aux2.signal(idx) = 1;
                elseif sbxinfo.event_id(i) == 8 %currently, aux1(odor) records both rise and fall
                    aux1.signal(idx:end) = 0;
                elseif sbxinfo.event_id(i) == 9 %both signals detected simultaneously
                    aux2.signal(idx) = 1;
                    if idx==1 || aux1.signal(idx-1) == 0
                        aux1.signal(idx:end) = 1;
                    else
                        aux1.signal(idx:end) = 0;
                    end
                else
                    errordlg('bad event_id');
                    aux2 = []; aux1 = [];
                    return;
                end
            else
                if sbxinfo.event_id(i) == 1 %currently, aux2(sniff) only records rise
                    aux2.signal(idx) = 1;
                elseif sbxinfo.event_id(i) == 2 %currently, aux1(odor) records both rise and fall
                    if idx==1 || aux1.signal(idx-1) == 0
                        aux1.signal(idx:end) = 1;
                    else
                        aux1.signal(idx:end) = 0;
                    end
                elseif sbxinfo.event_id(i) == 3 %both signals detected simultaneously
                    aux2.signal(idx) = 1;
                    if idx==1 || aux1.signal(idx-1) == 0
                        aux1.signal(idx:end) = 1;
                    else
                        aux1.signal(idx:end) = 0;
                    end
                else
                    errordlg('bad event_id');
                    aux2 = []; aux1 = [];
                    return;
                end
            end
        end
    end
end
%tcr: multi-odor encoding not set up on scanbox yet
aux3 = aux1;
bspikes = 0; newaux1signal= zeros(size(aux1.signal)); %reset aux1.signal to new aux1 w/out spikes if spikes are found
% aux3.odors = 0;
if isempty(aux3); aux1 = []; end
%figure out which odor(s) are presented (w/spike encoding)
if ~isempty(aux3)
    odors = []; nOdors = 0;
    i=2; jump=find(aux3.times>2.1,1,'first'); %8x0.25sec intervals
    while i<length(aux3.signal) %skip first frame in case signal is on at scan start
        if aux3.signal(i)==1 && aux3.signal(i-1)==0 %find odor onset
            newaux1signal(i:i+odorOnFrames) = 1; %create the odor on/off signal
            spikes = '';
            for b = 1:8 %search for 8 x ~.1 second intervals, starting 0.1sec after trigger pulse
                spike = 0;
                for j = find(aux3.times>(aux3.times(i)+(b-1)*0.25 + 0.1),1)...
                        : find(aux3.times>(aux3.times(i)+ b*0.25 + 0.1),1)
                    if aux3.signal(j)==1 && aux3.signal(j-1)==0
                        spike = 1;
                    end
                end
                if spike
                    spikes = [spikes '1'];
                else
                    spikes = [spikes '0'];
                end
            end
            spikes = flip(spikes); %bit order is smallest to largest!
            odor = bin2dec(spikes);
            if odor~= 0; bspikes = 1; end
            if isempty(odors)
                nOdors = 1;
                odors(1) = odor; 
            else
                if ~max(odor == odors)
                    nOdors = nOdors+1;
                    odors(nOdors)= odor; %add 1 for correct indexing
                end
            end
            i=i+jump; %jump forward
        else
            i=i+1;
        end
    end
    aux3.odors = odors;
    if bspikes; aux1.signal = newaux1signal; end
end
