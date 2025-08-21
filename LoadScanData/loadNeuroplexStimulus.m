function [varargout] = loadNeuroplexStimulus(imfile,varargin)
% [varargout] = loadNeuroplexStimulus(imfile,varargin)
%       varargout{1} is aux1 - odor on/off [should be valence]
%       varargout{2} is aux2 - sniff on/off
%       varargout{3} is aux3 - multiodor spike encoding or licking
%       varargin{1} is aux2bncmap - see assignNeuroplexBNC.m
if strcmp(imfile(end-2:end),'.da')
    %see: http://www.redshirtimaging.com/support/dfo.html for info on Neuroplex
    sizeA = 2560; % # of integers of header info
    fid = fopen(imfile);
    header = fread(fid, sizeA, 'int16');
    frames = header(5); xpix = header(385); ypix = header(386);
    skipbytes = 2*(sizeA+ypix*xpix*frames); %2bytes per int16
    fseek(fid,skipbytes,'bof'); %skip over the image bytes to get to aux signals
    dat = fread(fid,inf, 'int16');
    fclose(fid);
    
    deltaT = header(389); 
    if deltaT >= 10; deltaT = deltaT*header(391); end %note: header(391) is called the "dividing factor"
    deltaT = deltaT/1000000;%microsec to sec
    frameRate = 1/deltaT;
    numBNC = 8; %number of bnc channels - all 8 are saved
    bncRatio = header(392); %ratio of bnc frames to optical frames (tcr: I think this should be 4-32)
else
    % read header of tsm file to get frameRate
    [tmppath,tmpname,~] = fileparts(imfile);
    sizeA = 2880; % # of integers of header info
    tsmfid = fopen(fullfile(tmppath,[tmpname,'.tsm']));
    header = fread(tsmfid, sizeA,'uint8=>char');
    fclose(tsmfid);
    %convert header to tsminfo (incompletely here)
    for i = 1:36
        %headers consist of 36x80byte "cards" w/keyword, value, (optional comment)
        %last keyword is "END", the rest of header is empty
        ctmp = textscan(header(i*80-79:i*80),'%s %s','Delimiter','=');
        if ~isempty(ctmp{1}) && ~isequal(strip(ctmp{1}{1}),'END')
            tsminfo.(strip(ctmp{1}{1})) = strip(ctmp{2}{1});
        end
    end
    %iminfo.frames = str2double(iminfo.NAXIS3);
    frames = str2double(tsminfo.NAXIS3);    
    deltaT = str2double(tsminfo.EXPOSURE);
    frameRate = 1/deltaT;
    %get aux signals from tbn file
    tbnfid = fopen(fullfile(tmppath,[tmpname,'.tbn']));
    numBNC = abs(fread(tbnfid,1,'int16')); %value stored as negative for NI plug-in
    disp(numBNC);
    bncRatio = fread(tbnfid,1,'int16');
    dat = fread(tbnfid,inf,'double');
    fclose(tbnfid);
end
%below if for *.tsm files
% Get BNC signals
if nargin>1; aux2bncmap = varargin{1}; else; aux2bncmap = assignNeuroplexBNC; end
cnt = 1;
for s = 1:numBNC
    bnc(s,:) = dat(cnt:cnt-1+(bncRatio*frames));
    cnt = cnt+bncRatio*frames;
end
%assignin('base','bncsigsall',dat);

%MW note: shoudl edit so that the raw data gets assigned to ephys variable
%here...Aug 2024
ephys.framenum = [1:bncRatio*frames]; %MW modified
ephys.samplerate=iminfo.frameRate*bncRatio; %MW added. This is actual samplerate
ephys.origtimes=(0:1/ephys.samplerate:length(ephys.framenum)/ephys.samplerate);  %these are actual times.
ephys.origtimes=ephys.origtimes(1:length(ephys.framenum));
resamprate = 150; % this value was set manually in the scanbox config file - change to match your data
fprintf('Using %d Hz Sampling Rate for Ephys data.\n',resamprate);
ephys.times = (0:1/resamprate:length(ephys.framenum)/ephys.samplerate);
ephys.times = ephys.times(1:end-1);

%ephys.odor = B(2,:);
%ephys.trachea = B(3,:);
%ephys.sniff = B(4,:);
% ephys.lick = B(5,:);
% ephys.puff = B(6,:);
% ephys.reward = B(7,:);
% ephys.valence = B(8,:);
%%%%%%%%%%%%%%%%%%
varargout = cell(1,nargout-2);
%AUX1 is the odor on/off signal
threshold = 0.1; %make sure min is zero using a thresold assuming that high is 5 V
if aux2bncmap(1) > 0
    ephys.odor=interp1(ephys.origtimes,bnc(aux2bncmap(1),:),ephys.times);
    tmp1 = qprctile(bnc(aux2bncmap(1),:),[1 99.9]);
    %AUX1 = bnc(aux2bncmap(1),:)>tmp1(1)+0.25*(tmp1(2)-tmp1(1));
    
    AUX1 = bnc(aux2bncmap(1),:)>threshold;
    aux1.times = 0:1/150:frames/frameRate; %resample to 150Hz
    aux1.signal = zeros(1,length(aux1.times));
    AUX1times=0:deltaT/bncRatio:iminfo.frames/iminfo.frameRate;  %generate timepts for aux1 signal
    aux1.signal=interp1(AUX1times,[0, double(AUX1)],aux1.times,'previous');   %mw added - alternate way.
    % for i = 2:length(AUX1)
    %     if AUX1(i)>AUX1(i-1) %on
    %         tmp = find(aux1.times>=i*deltaT/bncRatio);
    %         aux1.signal(tmp:end) = 1;
    %     elseif AUX1(i)<AUX1(i-1) %off
    %         tmp = find(aux1.times>=i*deltaT/bncRatio);
    %         aux1.signal(tmp:end) = 0;
    %     end
    % end
    varargout{1} = aux1;
end
%AUX2 is the valence signal for NP as of aug 2024
if aux2bncmap(2) > 0   
    ephys.valence = bnc(aux2bncmap(2),:);  %MW added sept 2024
    ephys.trachea=ephys.valence; %MW added these two lines just to make code work. Prob never use ephys.trachea in this context.
    ephys.reward=ephys.valence; %MW added - just  aplaceholder, 8/24. Not enough BNC channels for NP files.
    tmp2 = qprctile(bnc(aux2bncmap(2),:),[1 99.9]);
    %AUX2 = bnc(aux2bncmap(2),:)>tmp2(1)+0.25*(tmp2(2)-tmp2(1));
    AUX2 = bnc(aux2bncmap(2),:)>threshold;
    aux2.times = 0:1/150:frames/frameRate; %resample to 150Hz
    aux2.signal = zeros(1,length(aux2.times));
    AUX2times=0:deltaT/bncRatio:iminfo.frames/iminfo.frameRate;  %generate timepts for aux1 signal
    aux2.signal=interp1(AUX2times,[0, double(AUX2)],aux2.times,'previous');   %mw added - alternate way.
    % for i = 2:length(AUX2)
    %     if AUX2(i)>AUX2(i-1) %on
    %         tmp = find(aux2.times>=i*deltaT/bncRatio);
    %         aux2.signal(tmp:end) = 1;
    %     elseif AUX2(i)<AUX2(i-1) %off
    %         tmp = find(aux2.times>=i*deltaT/bncRatio);
    %         aux2.signal(tmp:end) = 0;
    %     end
    % end
    varargout{2} = aux2;        
end

%copied from loadNeuroplex
if aux2bncmap(3) >0;
        odorIDflag=[];  odors = []; nOdors = 0;  
        ephys.lick=interp1(ephys.origtimes,bnc(aux2bncmap(3),:),ephys.times);
        ephys.puff=ephys.lick; %MW added - just  aplaceholder, 8/24. Not enough BNC channels for NP files.
        aux3.times = 0:1/150:iminfo.frames/iminfo.frameRate; %resample to 150Hz
        aux3.signal = zeros(1,length(aux3.times));
        if aux2bncmap(3) == 5; odorIDflag=1; end %this is if truly odorgun signal on AUX 3.
        if aux2bncmap(5) == 1  %this will encode valence into odor ID 
            odorIDflag=1; %just set marker to odor ID encoding
            if max(aux2.signal) > 0
                onindices=find(diff(aux1.signal) == 1); %find start indices of odor onset (in case are multiple odor pulses)
                aux3.signal(onindices)=1; %this signals odor on. 
                aux3.signal(onindices+16)=1; % should make odor code = 1
            end
        end
        if odorIDflag
            %now do the odor ID/decoding part           
            i=2; jump=find(aux3.times>2.1,1,'first'); %8x0.25sec intervals
            while i<length(aux3.signal) %skip first frame in case signal is on at scan start
                if aux3.signal(i)==1 && aux3.signal(i-1)==0 %find odor onset
                    spikes = '';
                    for b = 1:8 %search for 8 x ~.1 second intervals, starting 0.1 sec after trigger pulse
                        spike = 0;
                        for j = find(aux3.times>(aux3.times(i)+(b-1)*0.25 + 0.1),1)...
                                : find(aux3.times>(aux3.times(i)+ b*0.25 + 0.1),1)
                            if aux3.signal(j)==1 && aux3.signal(j-1)==0
                                spike = 1
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
                            odors(nOdors)=odor;
                        end
                    end
                    i=i+jump; %jump forward 1sec
                else
                    i=i+1;
                end
            end
            
        end
        aux3.odors = odors;
        varargout{3} = aux3;
    else varargout{3} = [];
end

    %%%%read in bnc 4. added by MW 11/9/23
    if aux2bncmap(4) > 0
        ephys.sniff=interp1(ephys.origtimes,bnc(aux2bncmap(4),:),ephys.times);
        tmp4 = qprctile(bnc(aux2bncmap(4),:),[1 99.9]);
       % AUX4 = bnc(aux2bncmap(4),:)>tmp4(1)+0.25*(tmp4(2)-tmp4(1));
        %ephys.sniff = bnc(aux2bncmap(4),:);  %mw added - assuming that sniff record is on BNC4
        AUX4 = bnc(aux2bncmap(4),:)>threshold;
        %aux4.times = 0:1/150:iminfo.frames/iminfo.frameRate; %resample to
        %150Hz. this is old version
        aux4.times = 0:1/150:frames/frameRate; %resample to 150Hz
        aux4.signal = zeros(1,length(aux4.times));
        AUX4times=0:deltaT/bncRatio:iminfo.frames/iminfo.frameRate;  %generate timepts for aux1 signal
        aux4.signal=interp1(AUX4times,[0, double(AUX4)],aux4.times,'previous');   %mw added - alternate way. 
        % for i = 2:length(AUX4)    %mw commented out for now, this
        % binarizes sniff signal, seems unnecessary and confusing for awake
        % data, at least...
        %     if AUX4(i)>AUX4(i-1) %on
        %         tmp = find(aux4.times>=i*deltaT/bncRatio);
        %         aux4.signal(tmp:end) = 1;
        %     elseif AUX4(i)<AUX4(i-1) %off
        %         tmp = find(aux4.times>=i*deltaT/bncRatio);
        %         aux4.signal(tmp:end) = 0;
        %     end
        % end
        varargout{4} = aux4;
        else
        varargout{4} = [];
    end
    %%%%end MW added part
    varargout{5}=ephys;
end