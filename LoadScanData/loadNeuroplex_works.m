function [im,iminfo,varargout] = loadNeuroplex(imfile,varargin)
% [im,imInfo,varargout] = loadNeuroplex(filename)
%   imfile(char): name of file to be opened (.tif)
%     varargin{1}: aux2bncmap, vector mapping BNC to aux signals(varargout)
%   im(uint16): image matrix (Width,Height,Frames)
%   iminfo(struct): ImageDescription stored in file header
%   varargout: Optional output for stimulus signals
%       varargout{1} is aux1 - odor on/off
%       varargout{2} is aux2 - sniff on/off
%       varargout{3} is aux3 - multiodor spike encoding

if strcmp(imfile(end-2:end),'.da')
    %see: http://www.redshirtimaging.com/support/dfo.html for info on Neuroplex
    sizeA = 2560; % # of integers of header info
    fid = fopen(imfile);
    header = fread(fid, sizeA, 'int16');
    dat = fread(fid, inf, 'int16');
    fclose(fid);
    iminfo.frames = header(5);
    xpix = header(385);
    ypix = header(386);
    iminfo.size = [ypix xpix];
    
    deltaT = header(389); 
    if deltaT >= 10; deltaT = deltaT*header(391); end %note: header(391) is called the "dividing factor"
    deltaT = deltaT/1000000;%microsec to sec
    iminfo.frameRate = 1/deltaT;
    
    im = zeros(ypix,xpix,iminfo.frames);
    cnt = 1;
    for i = 1:ypix
        for j = 1:xpix
            im(i,j,1:iminfo.frames) = dat(cnt:cnt+iminfo.frames-1);
            cnt = cnt+iminfo.frames;
        end
    end
    numBNC = 8; %number of bnc channels - all 8 are saved
    bncRatio = header(392); %ratio of bnc frames to optical frames (tcr: this should be 4-32)
    for s = 1:numBNC
        bnc(s,:) = dat(cnt:cnt-1+(bncRatio*iminfo.frames));
        cnt = cnt+bncRatio*iminfo.frames;
    end
else
    sizeA = 2880; % # of integers of header info
    [tmppath,tmpname,~] = fileparts(imfile);
    tsmfid = fopen(fullfile(tmppath,[tmpname,'.tsm']));
    header = fread(tsmfid, sizeA,'uint8=>char');
    dat = fread(tsmfid, inf, 'int16');
    fclose(tsmfid);
    %convert header to iminfo
    for i = 1:36
        %headers consist of 36x80byte "cards" w/keyword, value, (optional comment)
        %last keyword is "END", the rest of header is empty
        ctmp = textscan(header(i*80-79:i*80),'%s %s','Delimiter','=');
        if ~isempty(ctmp{1}) && ~isequal(strip(ctmp{1}{1}),'END')
            iminfo.(strip(ctmp{1}{1})) = strip(ctmp{2}{1});
        end
    end
    iminfo.frames = str2double(iminfo.NAXIS3);
    xpix = str2double(iminfo.NAXIS1);
    ypix = str2double(iminfo.NAXIS2);
    iminfo.size = [ypix,xpix];
    
    deltaT = str2double(iminfo.EXPOSURE);
    iminfo.frameRate = 1/deltaT;
    
    im = zeros(ypix,xpix,iminfo.frames);
    cnt = 1;
    for i = 1:iminfo.frames
        im(1:ypix,1:xpix,i) = reshape(dat(cnt:cnt+ypix*xpix-1),[ypix,xpix]);
        im(:,:,i) = im(:,:,i)'; %rotate to match original
        cnt = cnt+ypix*xpix;
    end
    %get aux signals from tbn file
    %tbnfid = fopen(fullfile(tmppath,[tmpname,'.tbn']));
    [tbnfid, errmsg] = fopen(fullfile(tmppath,[tmpname,'.tbn']));
    if ~isempty(errmsg) %no .tbn file
        errordlg('Aux data .tbn file not found');
        numBNC = 0;
        bncRatio = 0;
        tbndat = [];
        bnc = [];
    else
        numBNC = abs(fread(tbnfid,1,'int16')); %value stored as negative for NI plug-in
        bncRatio = fread(tbnfid,1,'int16');
        tbndat = fread(tbnfid,inf,'double');
        fclose(tbnfid);
    end
    tbncnt = 1;
    for s = 1:numBNC
        bnc(s,:) = tbndat(tbncnt:tbncnt-1+(bncRatio*iminfo.frames));
        tbncnt = tbncnt+bncRatio*iminfo.frames;
    end
end
%assignin('base','bncsigs',bnc);
threshold = 0.1; %MW added and changed code: this still binarizes signal but simply based on absolute threshold for TTL pulses.

%MW note: shoudl edit so that the raw data gets assigned to ephys variable
%here...Aug 2024
%ephys.framenum = B(1,:);
ephys.framenum = [1:bncRatio*iminfo.frames]; %MW modified
ephys.samplerate=iminfo.frameRate*bncRatio; %MW added. This is actual samplerate
ephys.origtimes=(0:1/ephys.samplerate:length(ephys.framenum)/ephys.samplerate);  %these are actual times.
ephys.origtimes=ephys.origtimes(1:length(ephys.framenum));
resamprate = 150; % this value was set manually in the scanbox config file - change to match your data
fprintf('Using %d Hz Sampling Rate for Ephys data.\n',resamprate);
ephys.times = (0:1/resamprate:length(ephys.framenum)/ephys.samplerate);
ephys.times = ephys.times(1:end-1);

% Get BNC signals
varargout = cell(1,nargout-2);
if ~isempty(bnc)
    if nargin>1; aux2bncmap = varargin{1}; else; aux2bncmap = assignNeuroplexBNC; end
    %assignin('base','aux2bncmap',aux2bncmap);
    %AUX1 is the odor on/off signal
    %binarizes odor on/off signal.
    if aux2bncmap(1) > 0
        %ephys.odor = bnc(aux2bncmap(1),:);  %mw added
        ephys.odor=interp1(ephys.origtimes,bnc(aux2bncmap(1),:),ephys.times);
        %need to resample to 150 Hz:
        tmp1 = qprctile(bnc(aux2bncmap(1),:),[1 99.9]);
        %AUX1 = bnc(aux2bncmap(1),:)>tmp1(1)+0.25*(tmp1(2)-tmp1(1));
        AUX1 = bnc(aux2bncmap(1),:)>threshold;
        aux1.times = 0:1/150:iminfo.frames/iminfo.frameRate; %resample to 150Hz
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
    %AUX2 is the sniff on/off signal or valence signal (ephys)
    if aux2bncmap(2) > 0
        ephys.valence=interp1(ephys.origtimes,bnc(aux2bncmap(2),:),ephys.times);
        ephys.trachea=ephys.valence; %MW added these two lines just to make code work. Prob never use ephys.trachea in this context.
        ephys.reward=ephys.valence; %MW added - just  aplaceholder, 8/24. Not enough BNC channels for NP files.
        tmp2 = qprctile(bnc(aux2bncmap(2),:),[1 99.9]);
        %AUX2 = bnc(aux2bncmap(2),:)>tmp2(1)+0.25*(tmp2(2)-tmp2(1));
        AUX2 = bnc(aux2bncmap(2),:)>threshold;
        aux2.times = 0:1/150:iminfo.frames/iminfo.frameRate; %resample to 150Hz
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
    
    
    %assignin('base','aux3',aux3);
    %AUX3 is the multiodor spike signal or licking signal (for ephys)
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
                onindex=find(aux1.signal,1); %find start index of odor onset
                aux3.signal(onindex)=1; %this signals odor on. 
                aux3.signal(onindex+16)=1; % should make odor code = 1
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
            
        end
        aux3.odors = odors;
        varargout{3} = aux3;
    else varargout{3} = [];
    end
            %below is code to put licking into aux3, which makes no sense
            %so don't do it.
%         else       %else encode licking into aux3 
%             %tmp3 = qprctile(bnc(aux2bncmap(3),:),[1 99.9]);
%             %AUX3 = bnc(aux2bncmap(3),:)>tmp3(1)+0.25*(tmp3(2)-tmp3(1));
%             AUX3 = bnc(aux2bncmap(3),:)>threshold;
% %             aux3.times = 0:1/150:iminfo.frames/iminfo.frameRate; %resample to 150Hz
% %             aux3.signal = zeros(1,length(aux3.times));
%             for i = 2:length(AUX3)
%                 if AUX3(i)>AUX3(i-1) %on
%                     tmp = find(aux3.times>=i*deltaT/bncRatio);
%                     aux3.signal(tmp:end) = 1;
%                 elseif AUX3(i)<AUX3(i-1) %off
%                     tmp = find(aux3.times>=i*deltaT/bncRatio);
%                     aux3.signal(tmp:end) = 0;
%                 end
%             end
%             varargout{3} = newAux3;    

    %%%%read in bnc 4. added by MW 11/9/23
    if aux2bncmap(4) > 0
        %ephys.sniff = bnc(aux2bncmap(4),:);  %mw added - assuming that sniff record is on BNC4
        ephys.sniff=interp1(ephys.origtimes,bnc(aux2bncmap(4),:),ephys.times);
        tmp4 = qprctile(bnc(aux2bncmap(4),:),[1 99.9]);
        %AUX4 = bnc(aux2bncmap(4),:)>tmp4(1)+0.25*(tmp4(2)-tmp4(1));
        AUX4 = bnc(aux2bncmap(4),:)>threshold;
        aux4.times = 0:1/150:iminfo.frames/iminfo.frameRate; %resample to 150Hz
        aux4.signal = zeros(1,length(aux4.times));
        for i = 2:length(AUX4)
            if AUX4(i)>AUX4(i-1) %on
                tmp = find(aux4.times>=i*deltaT/bncRatio);
                aux4.signal(tmp:end) = 1;
            elseif AUX4(i)<AUX4(i-1) %off
                tmp = find(aux4.times>=i*deltaT/bncRatio);
                aux4.signal(tmp:end) = 0;
            end
        end
        varargout{4} = aux4;
        else
        varargout{4} = [];
    end
    %%%%end MW added part
%     assignin('base','ephystest',ephys);
%     assignin('base','aux4',aux4);
    varargout{5}=ephys;
    
    %TCR:March,2023 - set up valence to odor conversion here! Just
%     %uncomment to implement.
%     aux3 = varargout{3};
%     if aux3.odors == 0  && ~isempty(ephys) %Only works if no odors are present & ephys exists
%         bTmp = questdlg("Do you want to use the ePhys.Valence signal to encode odors?");
%         if bTmp
%             [newAux3]= ePhysValence2Odors(aux3,ephys);
%             varargout{3} = newAux3;
%         end
%     end
    
end

% Read and subtract dark frame
darkFrame = dat(cnt:cnt-1+xpix*ypix);
darkFrame = reshape(darkFrame, [xpix ypix]);
darkFrame = darkFrame'; %permute x,y
for f = 1:iminfo.frames
    im(:,:,f) = im(:,:,f)-darkFrame;
end
im=uint16(im);
%neuroplex image values typically range from -10 to 1000, values <10 are mostly background noise...
%so negative values are safely truncated in int16>uint16 conversion (might want to double check from time to time)