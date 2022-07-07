function [allOdorTrials] = getAllOdorTrials(auxtype,prestimtime,poststimtime,mwfile)
%function [allOdorTrials] = getAllOdorTrials(auxtype,prestimtime,poststimtime,mwfile)
%   NOTE: mwfile.im is not used in this function, so remove this field to reduce memory use
%       e.g. tmp_mwfile = rmfield(mwfile,'im') 
%   This function returns allOdorTrials - all "valid" trials for the given time window
%   allOdorTrials.odors - list of odors present
%   allOdorTrials.odor().trials
%   allOdorTrials.odor().trial().auxindex - index of aux.times for each trial
%   allOdorTrials.odor().trial().imindex - index of imtimes for each trial

auxtypes = getauxtypes;
imtimes = (0:(mwfile.frames-1))./ mwfile.frameRate;
if strcmp(auxtype,auxtypes{1}) %Aux1(odor)
    %note: the current approach includes all odors in allOdorTrials.odors (even if no valid trials),
    %and allows the odor order to be random (in order of presentation but not including repeats)
    %also, see loadScanboxStimulus.m, loadScanImageStimulus.m, loadNeuroplexStimulus.m
    stimtimes = mwfile.aux1.times;
    numstimframes = find(stimtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numstimframes); errordlg('prestimtime + poststimtime > duration of aux.time'); return; end
    half = (imtimes(2)-imtimes(1))/2; % half-Frame(sec), use this to find if stimulus occurs during first half of image frame
    numimframes = find(imtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numimframes); errordlg('prestimtime + poststimtime > totaltime'); return; end
    if isfield(mwfile,'aux1') && ~isempty(mwfile.aux1)
        aux1 = mwfile.aux1.signal(1:length(stimtimes));
    else
        disp('Error: Aux1 signal not found'); return
    end
    if isfield(mwfile,'aux3') && ~isempty(mwfile.aux3)
        allOdorTrials.odors = mwfile.aux3.odors;
        aux3 = mwfile.aux3.signal(1:length(stimtimes));
    else
        allOdorTrials.odors = 0;
        aux3=aux1;
    end
    %find odornumbers for each trial from aux3
    %Our 8bit odor number encoding scheme is weird, but this is how we interpret the odor number signal...
    j=2; trial = 0; odor = []; %skipping first frame in case signal is on at scan start
    jump=find(stimtimes>2.1,1,'first'); %total duration of 0.1sec delay + 8x0.25sec intervals
    while j<length(aux3) 
        if aux3(j)==1 && aux3(j-1)==0 %find odor onset
            trial = trial+1; spikes = '';
            for b = 1:8 %search for 8 x 0.25 second intervals, starting 0.1 sec after trigger pulse
                spike = 0;
                for jj = find(stimtimes>(stimtimes(j)+(b-1)*0.25 + 0.1),1)...
                        : find(stimtimes>(stimtimes(j)+ b*0.25 + 0.1),1)
                    if aux3(jj)==1 && aux3(jj-1)==0
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
            j=j+jump;
        else
            j=j+1;
        end
    end
    %find odor on for each trial and save indexes of aux and imtimes
    for o = 1:length(allOdorTrials.odors)
        allOdorTrials.odor(o).trials = []; %all valid trials for each odor (pre-post stim)
    end
    t = zeros(length(allOdorTrials.odors),1); %t(o) indexes all trials for each odor,
    tt = zeros(length(allOdorTrials.odors),1); %tt(o) indexes all valid trials
    i=2; trial = 0; %skip first frame in case signal is on at scan start
    while i<length(aux1)
        if aux1(i)==1 && aux1(i-1)==0 %find odor onset
            trial = trial+1;
            o = find(odor(trial) == allOdorTrials.odors); %find odor index
            t(o) = t(o) + 1;
            if (stimtimes(i)-prestimtime+half >=0)
                auxind1 = find(stimtimes >= (stimtimes(i)-prestimtime),1,'first');
                auxind2 = auxind1+numstimframes-1;
                imind1 = find(imtimes+half >= (stimtimes(i)-prestimtime),1,'first');
                imind2 = imind1+numimframes-1;
                if auxind2>length(stimtimes) || imind2>length(imtimes)
                    fprintf('Odor %d, trial %d discarded, check post-stimulus time\n', o, t(o));
                else
                    tt(o) = tt(o) + 1;
                    allOdorTrials.odor(o).trials = [allOdorTrials.odor(o).trials t(o)];
                    allOdorTrials.odor(o).trial(tt(o)).auxindex = auxind1:auxind2;
                    allOdorTrials.odor(o).trial(tt(o)).imindex = imind1:imind2;
                end
            else
                fprintf('Odor %d, trial %d discarded, check pre-stimulus time\n', o, t(o));
            end
            i=i+jump; %jump forward
        else
            i=i+1;
        end
    end
elseif strcmp(auxtype,auxtypes{2}) %Aux2(Sniff) (does not include odor#/aux3 info for now)
    stimtimes = mwfile.aux2.times;
    numstimframes = find(stimtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numstimframes); errordlg('prestimtime + poststimtime > duration of aux.time'); return; end
    half = (imtimes(2)-imtimes(1))/2; % half-Frame(sec), use this to find if stimulus is in first half of frame
    numimframes = find(imtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numimframes); errordlg('prestimtime + poststimtime > totaltime'); return; end
    if isfield(mwfile,'aux2') && ~isempty(mwfile.aux2)
        aux2 = mwfile.aux2.signal(1:length(stimtimes));
    else
        disp('Error: Aux2 signal not found'); return
    end
    allOdorTrials.odors = 0; %aux 2 alone contains no odor info
    allOdorTrials.odor.trials = [];
    i=2;  t=0; tt = 0; %t indexes all trials for each odor, tt indexes valid trials
    while i<length(aux2) %skip first frame in case signal is on at scan start
        if aux2(i)>0 && aux2(i-1)==0 %find sniff onset
            t = t+1;
            if (stimtimes(i)-prestimtime+half >=0)
                auxind1 = find(stimtimes>=(stimtimes(i)-prestimtime),1,'first');
                auxind2 = auxind1+numstimframes-1;
                imind1 = find(imtimes+half>=stimtimes(i)-prestimtime,1,'first');
                imind2 = imind1+numimframes-1;
                if imind1<1 || imind2>length(imtimes) || auxind1<1 || auxind2>length(stimtimes)
                    fprintf('Trial %d discarded, check post-stimulus time\n', t);
                else
                    tt = tt+1;
                    allOdorTrials.odor.trials = [allOdorTrials.odor.trials t];
                    allOdorTrials.odor.trial(tt).auxindex = auxind1:auxind2;
                    allOdorTrials.odor.trial(tt).imindex = imind1:imind2;
                end
            else
                fprintf('Trial %d discarded, check pre-stimulus time\n', t);
            end
        end
        i=i+1;
    end
elseif strcmp(auxtype,auxtypes{3}) %AuxCombo
    stimtimes = mwfile.aux_combo.times;
    numstimframes = find(stimtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numstimframes); errordlg('prestimtime + poststimtime > duration of aux.time'); return; end
    half = (imtimes(2)-imtimes(1))/2; % half-Frame(sec), use this to find if stimulus is in first half of frame
    numimframes = find(imtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numimframes); errordlg('prestimtime + poststimtime > totaltime'); return; end
    if isfield(mwfile,'aux_combo') && ~isempty(mwfile.aux_combo)
        aux_combo = mwfile.aux_combo.signal(1:length(stimtimes));
    else
        disp('Error: aux_combo signal not found'); return
    end
    if isfield(mwfile,'aux1') && ~isempty(mwfile.aux1)
        aux1 = mwfile.aux1.signal(1:length(stimtimes));
    else
        disp('Error: Aux1 signal not found'); return
    end
    if isfield(mwfile,'aux3') && ~isempty(mwfile.aux3)
        allOdorTrials.odors = mwfile.aux3.odors;
        aux3 = mwfile.aux3.signal(1:length(stimtimes));
    else
        allOdorTrials.odors = 0;
        aux3 = aux1;
    end
    %find odornumbers for each trial
    j=2; trial = 0; odor = [];
    jump=find(stimtimes>2.1,1,'first'); %8x0.25sec intervals
    while j<length(aux3) %skip first frame in case signal is on at scan start
        if aux3(j)==1 && aux3(j-1)==0 %find odor onset
            trial=trial+1; spikes = '';
            for b = 1:8 %search for 8 x ~.1 second intervals, starting 0.1 sec after trigger pulse
                spike = 0;
                for jj = find(stimtimes>(stimtimes(j)+(b-1)*0.25 + 0.1),1)...
                        : find(stimtimes>(stimtimes(j)+ b*0.25 + 0.1),1)
                    if aux3(jj)==1 && aux3(jj-1)==0
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
            j=j+jump;
        else
            j=j+1;
        end
    end
    % go through aux1, find odors, check aux_combo for trials
    for o = 1:length(allOdorTrials.odors)
        allOdorTrials.odor(o).trials = []; %all valid trials for each odor (pre-post stim)
    end
    t = zeros(length(allOdorTrials.odors),1); %t(o) indexes all trials for each odor,
    tt = zeros(length(allOdorTrials.odors),1); %tt(o) indexes all valid trials
    i=2; trial = 0;
    while i<length(aux1) %skip first frame in case signal is on at scan start
        if aux1(i)==1 && aux1(i-1)==0 %find odor onset
            trial=trial+1;         
            o = find(odor(trial) == allOdorTrials.odors); %find odor index
            %while odor is "on", look for sniffs
            if strcmp(mwfile.type,'scanimage') && strcmp(mwfile.name(end-2:end),'tif')
                odorDuration = mwfile.aux_combo.odorDuration;
                onFrames = floor(odorDuration/(stimtimes(2)-stimtimes(1)));
            else %scanbox stimulus
                onFrames = find(aux1(i:end) == 0,1,'first')-1; %this works if aux1 and aux3 are aligned
            end
            for ii = i:min(i+onFrames-1, length(stimtimes)) %don't go past end of file!
                if aux_combo(ii) > 0 && aux_combo(ii-1) == 0
                    t(o)=t(o)+1;
                    if (stimtimes(ii)-prestimtime+half >=0)
                        auxind1 = find(stimtimes>=(stimtimes(ii)-prestimtime),1,'first');                        
                        auxind2 = auxind1+numstimframes-1;
                        imind1 = find(imtimes+half>=(stimtimes(ii)-prestimtime),1,'first');                        
                        imind2 = imind1+numimframes-1;
                        if auxind2>length(stimtimes) || isempty(imind2) || imind2>length(imtimes)
                            fprintf('Odor %d, trial %d discarded, check post-stimulus time\n', o, t(o));
                        else
                            tt(o) = tt(o)+1;
                            allOdorTrials.odor(o).trials = [allOdorTrials.odor(o).trials t(o)];
                            allOdorTrials.odor(o).trial(tt(o)).auxindex = auxind1:auxind2;
                            allOdorTrials.odor(o).trial(tt(o)).imindex = imind1:imind2;
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
elseif strcmp(auxtype,auxtypes{4}) %Defined Stimulus
    stimtimes = mwfile.def_stimulus.times;
    numstimframes = find(stimtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numstimframes); errordlg('prestimtime + poststimtime > duration of aux.time'); return; end
    def_stim = mwfile.def_stimulus.signal;
    half = (imtimes(2)-imtimes(1))/2; % half-Frame(sec), use this to find if stimulus is in first half of frame
    numimframes = find(imtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
    if isempty(numimframes); errordlg('prestimtime + poststimtime > totaltime'); return; end
    allOdorTrials.odors = 0; %def_stim contains no odor info
    allOdorTrials.odor.trials=[];
    i=2; t=0; tt=0; 
    while i<length(def_stim) %skip first frame in case signal is on at scan start
        if def_stim(i)>0 && def_stim(i-1)==0 %find odor onset
            t=t+1;
            if (stimtimes(i)-prestimtime+half >=0)
                auxind1 = find(stimtimes >= (stimtimes(i)-prestimtime),1,'first');
                auxind2 = auxind1+numstimframes-1;
                imind1=find(imtimes+half>=stimtimes(i)-prestimtime,1,'first');
                imind2 = imind1+numimframes-1;
                if auxind1<1 || auxind2>length(stimtimes) || imind1<1 || imind2>length(imtimes) 
                    fprintf('Trial %d discarded, check post-stimulus time\n', t);
                else
                    tt = tt+1;
                    allOdorTrials.odor.trials = [allOdorTrials.odor.trials t];
                    allOdorTrials.odor.trial(tt).auxindex = auxind1:auxind2;
                    allOdorTrials.odor.trial(tt).imindex = imind1:imind2;
                end
            else
                fprintf('Trial %d discarded, check pre-stimulus time\n', t);
            end
        end
        i=i+1;
    end
end
%     assignin('base','AllOdorTrials',allOdorTrials);
end
