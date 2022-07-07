function Maps = makeMaps(tmpdata, stim2use, baseTimes, respTimes, varargin)
%function Maps = makeMaps(tmpdata, stim2use, baseTimes, respTimes)
%make response maps struct based on inputs provided
%tmpdata struct must include:
%   tmpdata.name, tmpdata.dir, tmpdata.type (used for auxcombo - odor duration)
%   tmpdata.file.im, (this program only makes maps for tmpdata.file(1).im)
%       *does not work on multi-channel images saved as cell, convert to separate files*
%   tmpdata.frameRate
%   tmpdata.(aux1,aux2,aux3,def_stimulus) as required by stim2use specification
%
%   stim2use: character string which must match 1 of these:
%           {'Aux1(odor)', 'Aux2(sniff)', 'AuxCombo', 'Defined Stimulus'};
%
%   baseTimes: time window(sec) around stimulus used to average baseline images, example [-3.0 0.0]
%   respTimes: time window(sec) around stimulus used to average response images, example [0.5 3.5]

if isempty(tmpdata.im); fprintf('tmpdata must include image stack (load using loadFileMWLab)'); return; end
if iscell(tmpdata.im); fprintf('tmpdata.im cannot be a cell, separate channels into files'); return; end
Maps.file.type = tmpdata.type; Maps.file.name = tmpdata.name; Maps.file.dir = tmpdata.dir;
if isfield(tmpdata,'size'); Maps.file.size = tmpdata.size; end
Maps.file.frameRate = tmpdata.frameRate;
if isfield(tmpdata,'frames'); Maps.file.frames = tmpdata.frames; end
Maps.basetimes = baseTimes;
Maps.resptimes = respTimes;
stimstr = getauxtypes;
Maps.stim2use = stim2use;
imTimes=(0:(size(tmpdata.im,3)-1))./tmpdata.frameRate; %time at start of each timeframe
half = (imTimes(2)-imTimes(1))/2; % half Frame (sec), used to grab frame if stimulus is in first half of frame

if strcmp(Maps.stim2use,stimstr{1}) %aux1
    if ~isfield(tmpdata,'aux1'); disp('aux1 signal not found'); return; end
    aux1 = tmpdata.aux1.signal; stimtimes = tmpdata.aux1.times;
    if isfield(tmpdata,'aux3') && ~isempty(tmpdata.aux3)
        Maps.file.odors = sort(tmpdata.aux3.odors);
        aux3 = tmpdata.aux3.signal;
    else
        Maps.file.odors = 0;
        aux3=aux1;
    end
    %find odor numbers for each trial
    j = 1; trial = 0; odor = [];
    jump = find(stimtimes>2.1,1,'first'); %8x0.25sec intervals
    while j<length(aux3) %skip first frame in case signal is on at scan start
        if aux3(j)>0 && aux3(j-1)==0 %find odor onset
            trial = trial+1; spikes = '';
            for b = 1:8 %search for 8 x 0.25 second intervals, starting 0.1 sec after trigger pulse
                spike = 0;
                for jj = find(stimtimes>(stimtimes(j)+(b-1)*0.25 + 0.1),1)...
                        : find(stimtimes>(stimtimes(j)+ b*0.25 + 0.1),1)
                    if aux3(jj)>0 && aux3(jj-1)==0
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
            odor(trial) = bin2dec(spikes);
            j=j+jump; %jump forward
        else
            j=j+1;
        end
    end
    %find odor on for each trial and store data
    for o = 1:length(Maps.file.odors)
        Maps.file.odor(o).trials = []; %all valid trials for each odor (pre-post stim)
        t(o) = 0; tt(o) = 0; %t(o) indexes all trials for each odor, tt(o) indexes valid trials
    end
    i=2; trial = 0; %skip first frame in case signal is on at scan start
    while i<length(aux1)
        if aux1(i)>0 && aux1(i-1)==0 %find odor onset
            trial = trial+1;
            o = find(odor(trial) == Maps.file.odors); %find odor index
            t(o) = t(o) + 1;
            if stimtimes(i)+baseTimes(1)+half >= 0 %include full length trials
                ind1=find(imTimes + half >= (stimtimes(i)+baseTimes(1)),1,'first');
                ind2=find(imTimes + half <= (stimtimes(i)+baseTimes(2)),1,'last');
                ind3=find(imTimes + half >= (stimtimes(i)+respTimes(1)),1,'first');
                ind4=find(imTimes + half <= (stimtimes(i)+respTimes(2)),1,'last');
                if stimtimes(i)+respTimes(2)>imTimes(end)
                    fprintf('Odor %d, trial %d discarded, check post-stimulus time\n', o, t(o));
                else
                    tt(o) = tt(o) + 1;
                    Maps.file.odor(o).trials = [Maps.file.odor(o).trials t(o)];
                    Maps.file.odor(o).trial(tt(o)).baseframes = ind1:ind2;
                    Maps.file.odor(o).trial(tt(o)).respframes = ind3:ind4;
                    Maps.file.odor(o).trial(tt(o)).baseim = single(mean(tmpdata.im(:,:,ind1:ind2),3));
%                     Maps.file.odor(o).trial(tt(o)).stdbaseim = std(single(tmpdata.im(:,:,ind1:ind2)),0,3);
                    Maps.file.odor(o).trial(tt(o)).respim = single(mean(tmpdata.im(:,:,ind3:ind4),3));
%                     Maps.file.odor(o).trial(tt(o)).stdrespim = std(single(tmpdata.im(:,:,ind3:ind4)),0,3);
                    %FYI: consider using Z-score, or Welch's t-test for comparison metric
                    %Zscore = (respim-baseim)/stdbaseim
                    %Wscore = (respim-baseim)/sqrt(stdbaseim^2+stdrespim^2) -> for equal number of frames in base/resp
                end
            else
                fprintf('Odor %d, trial %d discarded, check pre-stimulus time\n', o, t(o));
            end
            i=i+jump; %jump forward
        else
            i=i+1;
        end
    end
elseif strcmp(Maps.stim2use,stimstr{2}) %aux2
    aux2 = tmpdata.aux2.signal;
    stimtimes = tmpdata.aux2.times;
    Maps.file.odors = 0; %aux 2 alone contains no odor info
    Maps.file.odor.trials = [];
    i=2;  t=0; tt = 0; %t indexes all trials for each odor, tt indexes valid trials
    while i<length(aux2) %skip first frame in case signal is on at scan start
        if aux2(i)>0 && aux2(i-1)==0 %find odor onset
            t = t+1;
            if stimtimes(i)+baseTimes(1)+half >= 0 %include full length trials
                ind1=find(imTimes + half >= (stimtimes(i)+baseTimes(1)),1,'first');
                ind2=find(imTimes + half <= (stimtimes(i)+baseTimes(2)),1,'last');
                ind3=find(imTimes + half >= (stimtimes(i)+respTimes(1)),1,'first');
                ind4=find(imTimes + half <= (stimtimes(i)+respTimes(2)),1,'last');                
                if stimtimes(i)+respTimes(2) >imTimes(end)
                    fprintf('Trial %d discarded, check post-stimulus time\n', t);
                else
                    tt = tt+1;
                    Maps.file.odor.trials = [Maps.file.odor.trials t];
                    Maps.file.odor.trial(tt).baseframes = ind1:ind2;
                    Maps.file.odor.trial(tt).respframes = ind3:ind4;
                    Maps.file.odor.trial(tt).baseim = single(mean(tmpdata.im(:,:,ind1:ind2),3));
                    Maps.file.odor.trial(tt).respim = single(mean(tmpdata.im(:,:,ind3:ind4),3));
                end
            else
                fprintf('Trial %d discarded, check pre-stimulus time\n', t);
            end
        end
        i=i+1;
    end
elseif strcmp(Maps.stim2use,stimstr{3}) %auxcombo
    if ~isfield(tmpdata,'aux1'); disp('aux1 signal not found'); return; end
    aux1 = tmpdata.aux1.signal; stimtimes = tmpdata.aux1.times;
    if isfield(tmpdata,'aux3') && ~isempty(tmpdata.aux3)
        Maps.file.odors = sort(tmpdata.aux3.odors);
        aux3 = tmpdata.aux3.signal;
    else
        Maps.file.odors = 0;
        aux3=aux1;
    end
    if isfield(tmpdata,'aux_combo')
        aux_combo = tmpdata.aux_combo.signal;
    elseif isfield(tmpdata,'aux2') %combine aux1 w/aux2 to make aux_combo
        ind = find(tmpdata.aux2.signal > 0); %sniff indices
        ind2 = tmpdata.aux1.signal(ind) == 1; %subset of sniff indices with odor on
        aux_combo = zeros(size(tmpdata.aux2.signal));
        aux_combo(ind(ind2))= 1;
    else; disp('aux2 signal not found'); return;
    end
    %find odor numbers for each trial
    j = 1; trial = 0; odor = [];
    jump = find(stimtimes>2.1,1,'first'); %8x0.25sec intervals
    while j<length(aux3) %skip first frame in case signal is on at scan start
        if aux3(j)>0 && aux3(j-1)==0 %find odor onset
            trial = trial+1; spikes = '';
            for b = 1:8 %search for 8 x 0.25 second intervals, starting 0.1 sec after trigger pulse
                spike = 0;
                for jj = find(stimtimes>(stimtimes(j)+(b-1)*0.25 + 0.1),1)...
                        : find(stimtimes>(stimtimes(j)+ b*0.25 + 0.1),1)
                    if aux3(jj)>0 && aux3(jj-1)==0
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
            odor(trial) = bin2dec(spikes);
            j=j+jump; %jump forward
        else
            j=j+1;
        end
    end
    %find odor on for each trial and store data
    for o = 1:length(Maps.file.odors)
        Maps.file.odor(o).trials = []; %all valid trials for each odor (pre-post stim)
        t(o) = 0; tt(o) = 0; %t(o) indexes all trials for each odor, tt(o) indexes valid trials
    end
    i=2; trial = 0;
    while i<length(aux1) %skip first frame in case signal is on at scan start
        if aux1(i)==1 && aux1(i-1)==0 %find odor onset
            trial = trial+1;
            o = find(odor(trial) == Maps.file.odors); %find odor index
            %while odor is "on", look for sniffs
            if isfield(tmpdata.aux_combo,'odorDuration')
                onFrames = floor(tmpdata.aux_combo.odorDuration/(stimtimes(2)-stimtimes(1)));
            else %scanbox stimulus
                onFrames = find(aux1(i:end) == 0,1,'first')-1;
            end
            for ii = i:min(i+onFrames-1, length(stimtimes)) %don't go past end of file!
                if aux_combo(ii) > 0 && aux_combo(ii-1) == 0
                    t(o)=t(o)+1;
                    if stimtimes(i)+baseTimes(1)+half >= 0 %include full length trials
                        ind1=find(imTimes + half >= (stimtimes(ii)+baseTimes(1)),1,'first');
                        ind2=find(imTimes + half <= (stimtimes(ii)+baseTimes(2)),1,'last');
                        ind3=find(imTimes + half >= (stimtimes(ii)+respTimes(1)),1,'first');
                        ind4=find(imTimes + half <= (stimtimes(ii)+respTimes(2)),1,'last');
                        if stimtimes(ii)+respTimes(2)>imTimes(end)
                            fprintf('Odor %d, trial %d discarded, check post-stimulus time\n', o, t(o));
                        else
                            tt(o) = tt(o)+1;
                            Maps.file.odor(o).trials = [Maps.file.odor(o).trials t(o)];
                            Maps.file.odor(o).trial(tt(o)).baseframes = ind1:ind2; 
                            Maps.file.odor(o).trial(tt(o)).respframes = ind3:ind4;
                            Maps.file.odor(o).trial(tt(o)).baseim = single(mean(tmpdata.im(:,:,ind1:ind2),3));
                            Maps.file.odor(o).trial(tt(o)).respim = single(mean(tmpdata.im(:,:,ind3:ind4),3));
                        end
                    else
                        fprintf('Odor %d, trial %d discarded, check pre-stimulus time\n', o, t(o));
                    end
                end
            end
            i=i+jump; %jump forward
        else
            i=i+1;
        end
    end
elseif strcmp(Maps.stim2use,stimstr{4}) %definestim
    if ~isfield(tmpdata,'def_stimulus'); disp('Defined stimulus not found'); return; end
    def_stim = tmpdata.def_stimulus.signal; stimtimes = tmpdata.def_stimulus.times;
    Maps.file.odors = 0; %def_stim contains no odor info
    Maps.file.odor.trials=[];
    i=2; t=0; tt=0;
    while i<length(def_stim) %skip first frame in case signal is on at scan start
        if def_stim(i)>0 && def_stim(i-1)==0 %find odor onset
            t=t+1;
            if stimtimes(i)+baseTimes(1)+half >= 0 %include full length trials
                ind1=find(imTimes + half >= (stimtimes(i)+baseTimes(1)),1,'first');
                ind2=find(imTimes + half <= (stimtimes(i)+baseTimes(2)),1,'last');
                ind3=find(imTimes + half >= (stimtimes(i)+respTimes(1)),1,'first');
                ind4=find(imTimes + half <= (stimtimes(i)+respTimes(2)),1,'last');                
                if stimtimes(i)+respTimes(2)>imTimes(end)
                    fprintf('Trial %d discarded, check post-stimulus time\n', t);
                else
                    tt = tt+1;
                    Maps.file.odor.trials = [Maps.file.odor.trials t];
                    Maps.file.odor.trial(tt).baseframes = ind1:ind2;
                    Maps.file.odor.trial(tt).respframes = ind3:ind4;
                    Maps.file.odor.trial(tt).baseim = single(mean(tmpdata.im(:,:,ind1:ind2),3));
                    Maps.file.odor.trial(tt).respim = single(mean(tmpdata.im(:,:,ind3:ind4),3));
                end
            else
                fprintf('Trial %d discarded, check pre-stimulus time\n', t);
            end
        end
        i=i+1;
    end       
else; fprintf('Input value stim2use must match these options:\n'); fprintf('%s, ',stimstr{:}); fprintf('\n');
end

% Compute 10th percentile image (this takes a long time! 97%)
% for f = 1:length(Maps.file)
%     for i = 1:size(tmpdata.im,1) %calculate by row to reduce memory usage
%         Maps.file(f).tenthprctileim(i,:) = single(prctile(tmpdata.im(i,:,:), 10, 3));
%     end
% end
bempty = 1; %check if any maps were made
for f = 1:length(Maps.file)
    for o = 1:length(Maps.file(f).odor)
        if isfield(Maps.file(f).odor(o),'trial')
            for t = 1:length(Maps.file(f).odor(o).trial)
                if ~isempty(Maps.file(f).odor(o).trial(t))
                    bempty = 0;
                end
            end
        end
    end
end
if bempty == 1; Maps = []; disp('No maps were made.'); end
clear tmpdata;