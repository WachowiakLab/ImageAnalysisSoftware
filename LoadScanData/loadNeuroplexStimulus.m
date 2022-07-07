function [varargout] = loadNeuroplexStimulus(imfile,varargin)
% [varargout] = loadNeuroplexStimulus(imfile,varargin)
%       varargout{1} is aux1 - odor on/off
%       varargout{2} is aux2 - sniff on/off
%       varargout{3} is aux3 - multiodor spike encoding
%       varargin{1} is aux2bncmap - see assignNeuroplexBNC.m

%see: http://www.redshirtimaging.com/support/dfo.html for info on Neuroplex
sizeA = 2560; % # of integers of header info
fid = fopen(imfile);
header = fread(fid, sizeA, 'int16');
frames = header(5); xpix = header(385); ypix = header(386);
skipbytes = 2*(sizeA+ypix*xpix*frames); %2bytes per int16
fseek(fid,skipbytes,'bof'); %skip over the image bytes
dat = fread(fid,inf, 'int16');
fclose(fid);

deltaT = header(389); 
if deltaT >= 10; deltaT = deltaT*header(391); end %note: header(391) is called the "dividing factor"
deltaT = deltaT/1000000;%microsec to sec
frameRate = 1/deltaT;

% Get BNC signals
if nargin>1; aux2bncmap = varargin{1}; else; aux2bncmap = assignNeuroplexBNC; end
numBNC = 8; %number of bnc channels - all 8 are saved
bncRatio = header(392); %ratio of bnc frames to optical frames (tcr: I think this should be 4-32)
cnt = 1;
for s = 1:numBNC
    bnc(s,:) = dat(cnt:cnt-1+(bncRatio*frames));
    cnt = cnt+bncRatio*frames;
end

varargout = cell(1,nargout-2);
%AUX1 is the odor on/off signal
if aux2bncmap(1) > 0
    tmp1 = qprctile(bnc(aux2bncmap(1),:),[1 99.9]);
    AUX1 = bnc(aux2bncmap(1),:)>tmp1(1)+0.25*(tmp1(2)-tmp1(1));
    aux1.times = 0:1/150:frames/frameRate; %resample to 150Hz
    aux1.signal = zeros(1,length(aux1.times));
    for i = 2:length(AUX1)
        if AUX1(i)>AUX1(i-1) %on
            tmp = find(aux1.times>=i*deltaT/bncRatio);
            aux1.signal(tmp:end) = 1;
        elseif AUX1(i)<AUX1(i-1) %off
            tmp = find(aux1.times>=i*deltaT/bncRatio);
            aux1.signal(tmp:end) = 0;
        end
    end
    varargout{1} = aux1;
end
%AUX2 is the sniff on/off signal
if aux2bncmap(2) > 0
    tmp2 = qprctile(bnc(aux2bncmap(2),:),[1 99.9]);
    AUX2 = bnc(aux2bncmap(2),:)>tmp2(1)+0.25*(tmp2(2)-tmp2(1));
    aux2.times = 0:1/150:frames/frameRate; %resample to 150Hz
    aux2.signal = zeros(1,length(aux2.times));
    for i = 2:length(AUX2)
        if AUX2(i)>AUX2(i-1) %on
            tmp = find(aux2.times>=i*deltaT/bncRatio);
            aux2.signal(tmp:end) = 1;
        elseif AUX2(i)<AUX2(i-1) %off
            tmp = find(aux2.times>=i*deltaT/bncRatio);
            aux2.signal(tmp:end) = 0;
        end
    end
    varargout{2} = aux2;
end
%AUX3 is the multiodor spike signal
if aux2bncmap(3) > 0
    tmp3 = qprctile(bnc(aux2bncmap(3),:),[1 99.9]);
    AUX3 = bnc(aux2bncmap(3),:)>tmp3(1)+0.25*(tmp3(2)-tmp3(1));
    aux3.times = 0:1/150:frames/frameRate; %resample to 150Hz
    aux3.signal = zeros(1,length(aux3.times));
    for i = 2:length(AUX3)
        if AUX3(i)>AUX3(i-1) %on
            tmp = find(aux3.times>=i*deltaT/bncRatio);
            aux3.signal(tmp:end) = 1;
        elseif AUX3(i)<AUX3(i-1) %off
            tmp = find(aux3.times>=i*deltaT/bncRatio);
            aux3.signal(tmp:end) = 0;
        end
    end
    %which odor(s) are presented in aux3 (w/spike encoding)
    if ~isempty(aux3)
        odors = []; nOdors = 0;
        i=2; jump=find(aux3.times>2.1,1,'first'); %8x0.25sec intervals
        while i<length(aux3.signal) %skip first frame in case signal is on at scan start
            if aux3.signal(i)==1 && aux3.signal(i-1)==0 %find odor onset
                spikes = '';
                for b = 1:8 %search for 8 x ~.1 second intervals, starting 0.1 sec after trigger pulse
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
                        odors(nOdors)=odor;
                    end
                end
                i=i+jump; %jump forward 1sec
            else
                i=i+1;
            end
        end
        aux3.odors = odors;
    end
    varargout{3} = aux3;
end