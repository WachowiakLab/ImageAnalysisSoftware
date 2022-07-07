function [aux1,aux2,aux3,varargout] = loadScanImageStimulus(imfile,frames,varargin)
% [aux1,aux2] = loadScanImageStimulus(imfile,frames,varargin)
%   varargin{1} is odorDuration, used to set odor on/off in aux1 (default is on for 1 frame)
% get the aux signals from scanimage .tif header

flipflop = 0; %change this to 1 to read files with aux inputs reversed (remember to change it back to 0 after!)
aux1 = []; aux2 = [];
slashInd = strfind(imfile,'\');
tempPath = pwd;
cd (imfile(1:slashInd(end)))
if ~isempty(dir('*.h5'))
    file = imfile(slashInd(end)+1:end);
    file(end-8) = [];
    file(end-3:end) = [];
    s=ws.loadDataFile([file '.h5']);
    sweepfieldname=join(["sweep", file(end-3:end)],'_');
    ephys.times = (1/1500.15):(1/1500.15):size(s.(sweepfieldname).analogScans,1)/1500.15; % Sampling rate of 1500.15 Hz set in Wavesurfer to match scanbox ephys
    ephys.odor = s.(sweepfieldname).analogScans(:,1)';
    ephys.sniff = s.(sweepfieldname).analogScans(:,2)';
    ephys.puff = s.(sweepfieldname).analogScans(:,3)';  %Currently actually frame clock from scanimage
    ephys.valence = s.(sweepfieldname).analogScans(:,4)';
    ephys.reward = s.(sweepfieldname).analogScans(:,5)';
    varargout{1} = ephys;
else
    ephys = [];
end
cd(tempPath);
if strcmp(imfile(end-3:end),'.tif') %scanimage .tif file
    tmptiff = Tiff(imfile, 'r');
    try SImeta = tmptiff.getTag('Software');
    catch; SImeta = [];
    end
    SIinfo = tmptiff.getTag('ImageDescription');
    if isempty(SImeta) %old versions, before scanimage 5.2
        if ~isempty(strfind(SIinfo,'scanimage'))
            Channels = getVal_ver5(SIinfo,'scanimage.SI.hChannels.channelSave');
            numChannels=length(Channels);
            frameRate = getVal_ver5(SIinfo,'scanimage.SI.hRoiManager.scanFrameRate');
        elseif ~isempty(strfind(SIinfo,'state'))
            numChannels = getVal(SIinfo,'state.acq.numberOfChannelsSave');
            frameRate = getVal(SIinfo,'state.acq.frameRate');
        else
            disp('Problem reading .tif header, no frameRate found'); return;
        end
    else %version 5.2
        if ~isempty(strfind(SImeta,'SI'))
            Channels = getVal_ver5(SImeta,'SI.hChannels.channelSave');
            numChannels=length(Channels);
            tmpSIinfo = tmptiff.getTag('ImageDescription');
            if ~isempty(tmpSIinfo)
                tmpframes = getVal_ver5(SImeta,'SI.hStackManager.framesPerSlice');
                tmpframes = tmpframes.*numChannels;
                try %note - this provides a more accurate frameRate than the one delivered by SI.hRoiManager.scanFrameRate
                    setDirectory(tmptiff,tmpframes);
                    tmpSIinfo = tmptiff.getTag('ImageDescription');
                    lastframestamp = getVal_ver5(tmpSIinfo,'frameTimestamps_sec');
                    frameRate = (tmpframes-1)/lastframestamp/numChannels;
                    setDirectory(tmptiff,1);
                catch
                    frameRate = getVal_ver5(SImeta,'SI.hRoiManager.scanFrameRate');
                end
            else
                frameRate = getVal_ver5(SImeta,'SI.hRoiManager.scanFrameRate');
            end
        else
            disp('Problem reading .tif header, no frameRate found'); return;
        end
    end
    
    times = 0:1/150:frames/frameRate; %here, current stimulus sampling is 150Hz
    if nargin >2; odorOnFrames = find(times>=varargin{1},1,'first'); %varargin{1} is odorDuration(sec)
    else odorOnFrames = 0;
    end
    aux1.times = times; aux2.times = times; aux3.times = times;
    aux1.signal = zeros(1,length(aux1.times)); %not in header, reserved for odor on/off
    aux2.signal = zeros(1,length(aux2.times)); %auxTrigger1, records sniff signal (on only)
    aux3.signal = zeros(1,length(aux3.times)); %auxTrigger0 in header, records multi-odor spikes
    for i = 1:frames
        tmptiff.setDirectory(i+((i-1)*(numChannels-1)));
        %tmptiff.setDirectory(i);
        try SIinfo = tmptiff.getTag('ImageDescription');
            auxTrigger0 = getAux(SIinfo,'auxTrigger0');
            if ~isempty(auxTrigger0)
                for j = 1:length(auxTrigger0)
                    idx = find(times>=auxTrigger0(j),1,'first'); %find index of next stimulus time after event
                    if flipflop
                        aux2.signal(idx) = 1;
                    else
                        aux3.signal(idx) = 1;
                    end
                end
            end
            auxTrigger1 = getAux(SIinfo,'auxTrigger1');
            if ~isempty(auxTrigger1)
                for j = 1:length(auxTrigger1)
                    idx = find(times>=auxTrigger1(1),1,'first'); %find index of next stimulus time after event
                    if flipflop
                        aux3.signal(idx) = 1;
                    else
                        aux2.signal(idx) = 1;
                    end
                end
            end
        catch
        end
    end
    tmptiff.close();
    if max(aux3.signal) == 0; aux3 = []; end
    if max(aux2.signal) == 0; aux2 = aux1; end
    if isempty(aux3); aux1 = []; end
    %figure out which odor(s) are presented (w/spike encoding)
    if ~isempty(aux3)
        odors = []; nOdors = 0;
        i=2; jump=find(aux3.times>2.1,1,'first'); %8x0.25sec intervals
        while i<length(aux3.signal) %skip first frame in case signal is on at scan start
            if aux3.signal(i)==1 && aux3.signal(i-1)==0 %find odor onset
                aux1.signal(i:i+odorOnFrames) = 1; %create the odor on/off signal
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
    end
    if ~isempty(ephys) && ~isempty(aux1)
        tempIndE = find(diff(ephys.odor)>1,1);
        tempIndA = aux1.times(find(diff(aux1.signal)==1,1));
        tempIndA = find(ephys.times>tempIndA,1)-1;
        tempDiff = tempIndA - tempIndE;
        ephys.odor = [zeros(1,tempDiff+1) ephys.odor];
        ephys.odor(end-tempDiff:end) = [];
        ephys.sniff = [zeros(1,tempDiff+1) ephys.sniff];
        ephys.sniff(end-tempDiff:end) = [];
        ephys.puff = [zeros(1,tempDiff+1) ephys.puff];
        ephys.puff(end-tempDiff:end) = [];
        varargout{1} = ephys;
    end
elseif strcmp(imfile(end-3:end),'.dat')
    load([imfile(1:end-4) '.mat']);
    if isfield(SIinfo,'aux1'); aux1 = SIinfo.aux1; end
    if isfield(SIinfo,'aux2'); aux2 = SIinfo.aux2; end
    if isfield(SIinfo,'aux3'); aux3 = SIinfo.aux3; end
    if max(aux1.signal) == 0; aux1 = []; end
    if max(aux2.signal) == 0; aux2 = []; end
    if max(aux3.signal) == 0; aux3 = []; end
end

    function val = getVal(metadata, field)
        ind1 = strfind(metadata, field);
        if (~isempty(ind1))
            ind2 = strfind(metadata(ind1:end), 13); %find line breaks
            ind2 = ind2(1);
            line = metadata(ind1:ind1+ind2-2);
            val = sscanf(line,[field '=%f']);
        else
            val = [];
        end
    end

    function val = getVal_ver5(metadata, field)
        ind1 = strfind(metadata, field);
        if (~isempty(ind1))
            ind2 = strfind(metadata(ind1:end), 13); %find line breaks
            if isempty(ind2); ind2=strfind(metadata(ind1:end), 10); end %find DOS line breaks
            ind2 = ind2(1);
            line = metadata(ind1:ind1+ind2-2);
            val = sscanf(line,[field ' = %f']);
            if isempty(val); val=sscanf(line,[field ' = [%f;%f]']);end
            %tcrtcrtcr this will fail for >2 channels!
        else
            disp('Error - Invalid metadata field');
            val = 100;
        end
    end
    function val = getAux(metadata, field)
        ind1 = strfind(metadata, field);
        if (~isempty(ind1))
            ind1=ind1+15;
            ind2=strfind(metadata(ind1:end), 13); %find line breaks
            if isempty(ind2); ind2=strfind(metadata(ind1:end), 10); end %DOS line breaks
            ind2=ind2(1);
            line = metadata(ind1:ind1+ind2-3);
            val = sscanf(line,'%f');
        else
            disp('Aux Signal Not Found');
            val = [];
        end
    end

end