function [im,tmpinfo,varargout] = loadScanImage(imfile,varargin)
% [im,imInfo,varargout] = loadScanImage(filename)
%   filename(char): name of file to be opened (.tif, or .dat)
%       varargin{1} is odorOnDuration (optional)
%   im(uint16): image matrix (Height,Width,Frames)
%   -or- im{} is a cell if two-channel data.
%   tmpinfo(struct): ImageDescription stored in file header
%   varargout: Optional output variable for stimulus signals
% Example: [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2] = loadScanImage(fullfile(MWfile.dir,MWfile.name));
%Scanimage data is recorded as int16 as of version 5.0, and includes negative values. In order to avoid problems
%	in deltaF/F calculations and to be consistent with other data, we convert to uint16 in loadScanimage.m by subtracting
%	the median of the minimum values in each of the first 60 timeframes(~4s at 15 frames/s). Additional background subtraction
%	can be done by selecting an ROI in an inactive area. Note that this could lead to problems if there is a strong negative
%	shift in the baseline fluorescence signal, and should always be kept in mind as a potential source of error.

% scan image files have this order of precedence - Channels, then Frames, then Slices
% see: https://openwiki.janelia.org/wiki/pages/viewpage.action?pageId=8684079#ImageFileStorage&amp;Format%28r3.6%29-FileHeader
%info = imfinfo(imfile, 'tif'); %tcrtcrtcr this is slow - see fastloadtiff for better way!
%SIinfo = info.ImageDescription;

if strcmp(imfile(end-2:end),'tif') %scanimage .tif file
    tmptiff = Tiff(imfile, 'r');
    imsize(1) = tmptiff.getTag('ImageLength');
    if isempty(imsize(1)); tmptiff.getTag('Length'); end
    imsize(2) = tmptiff.getTag('ImageWidth');
    if isempty(imsize(2)); tmptiff.getTag('Width'); end
    tmpinfo.size = imsize;
    try SImeta = tmptiff.getTag('Software');
    catch
        SImeta = [];
    end
    if isempty(SImeta) %old versions, before scanimage 5.2
        SIinfo = tmptiff.getTag('ImageDescription');
        %         if contains(SIinfo,'scanimage.SI4.') %version 4.0
        if ~isempty(strfind(SIinfo,'scanimage.SI4.')) %version 4.0
            Channels = getVal_ver5(SIinfo,'scanimage.SI4.channelsSave');
            numChannels=length(Channels);
            frameRate = getVal_ver5(SIinfo,'scanimage.SI4.scanFrameRate');
            %         elseif contains(SIinfo,'scanimage.SI.') %older version
        elseif ~isempty(strfind(SIinfo,'scanimage.SI.')) %older version
            Channels = getVal_ver5(SIinfo,'scanimage.SI.hChannels.channelSave');
            numChannels=length(Channels);
            frameRate = getVal_ver5(SIinfo,'scanimage.SI.hRoiManager.scanFrameRate');
            %         elseif contains(SIinfo,'state')
        elseif ~isempty(strfind(SIinfo,'state'))
            numChannels = getVal(SIinfo,'state.acq.numberOfChannelsSave');
            frameRate = getVal(SIinfo,'state.acq.frameRate');
        else
            warndlg('Problem reading header');
            numChannels = 1;
        end
    else %version 5.2
        %         if contains(SImeta,'SI')
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
            warndlg('Problem reading header');
            numChannels = 1;
        end
    end
    %fprintf('Total number of channels detected: %d\n',numChannels);
    if ~isempty(SImeta)
        frames = getVal_ver5(SImeta,'SI.hStackManager.framesPerSlice');
        imsize(3)=frames;
    elseif numChannels && ~isempty(strfind(SIinfo,'scanimage.SI4.')) %contains(SIinfo,'scanimage.SI4.') %tcr: see if this works for >1 channel...
        frames = getVal_ver5(SIinfo,'scanimage.SI4.acqNumFrames');
        imsize(3)=frames;
    elseif numChannels && ~isempty(strfind(SIinfo,'scanimage.SI.')); %contains(SIinfo,'scanimage.SI.') %tcr: see if this works for >1 channel...
        frames = getVal_ver5(SIinfo,'scanimage.SI.hStackManager.framesPerSlice');
        imsize(3)=frames;
    else
        frames = 0;
        while true
            frames = frames + 1;
            if tmptiff.lastDirectory(), break; end
            try tmptiff.nextDirectory(); catch; break; end
        end
        imsize(3) = frames/numChannels;
    end
    tmpinfo.frames = imsize(3);
    tmpinfo.frameRate = frameRate;
    tmptiff.close(); clear tmptiff;
    %read all Channels - it is nearly same speed to only read selected channel
    im = fastloadtiff(imfile);
    %if scan was stopped prematurely, frames might be less than what was stated in header
    if size(im,3)/numChannels < imsize(3); imsize(3)=size(im,3)/numChannels; tmpinfo.frames = imsize(3); end
    
    %multiChannel
    numout = max(2,nargout)-2; %number of extra outputs
    if numout > 0
        varargout=cell(1,numout);
        for n = 1:numout; varargout{n} = []; end
    end
    if numChannels > 1
        for i = 1:imsize(3)
            for ch = 1:numChannels
                tmpim{ch}(:,:,i) = im(:,:,(ch-1)+i+((i-1)*(numChannels-1)));
            end
        end
        clear im;
        if numChannels == 2
            im = tmpim; clear tmpim;
        else
            disp('not set up for >2 channels'); return;
        end
    end
    
    %Convert to uint16, shift baseline to above zero by subtracting median of min of first 100 frames
    %This get's important when you compute deltaF/F, and negative values of F can cause the signal to be flipped
    if iscell(im) %two-channel
        for ch = [1 2]
            for i = 1:min(60,imsize(3)) %just use first 60 frames (~4sec@15Hz) for speed (unless <60 frames)
                tmpim = im{ch}(:,:,i); tfmin(i)= min(tmpim(:)); clear tmpim;
            end
            offset=median(tfmin); clear tfmin;
            im{ch} = uint16(single(im{ch})-single(offset));
        end
    else
        if isa(im,'int16')
            for i = 1:60 %just use first 60 frames (~4sec@15Hz) for speed
                tmpim = im(:,:,i); tfmin(i)= min(tmpim(:)); clear tmpim;
            end
            offset=median(tfmin); clear tfmin;
            im = uint16(single(im)-single(offset));
        end
    end
    %varargout for multichannel and stimulus signal
    numout = max(2,nargout)-2; %number of extra outputs
    tempPath = pwd;
    slashInd = strfind(imfile,'\');
    cd(imfile(1:slashInd(end)))
    ephysOn = dir('*.h5');
    cd(tempPath)
    if isempty(ephysOn)
        if numout > 0
            
            varargout=cell(1,numout);
            for n = 1:numout;varargout{n} = [];end
            if nargin>1
                odorOnDuration = varargin{1};
                [varargout{1},varargout{2},varargout{3}] = loadScanImageStimulus(imfile,imsize(3),odorOnDuration); % gets auxillary inputs (odor, sniff)
            else; [varargout{1},varargout{2},varargout{3}] = loadScanImageStimulus(imfile,imsize(3));
            end
        end
        else
            if numout > 0
                
                varargout=cell(1,numout);
                for n = 1:numout;varargout{n} = [];end
                if nargin>1
                    odorOnDuration = varargin{1};
                    [varargout{1},varargout{2},varargout{3},varargout{4}] = loadScanImageStimulus(imfile,imsize(3),odorOnDuration); % gets auxillary inputs (odor, sniff)
                else; [varargout{1},varargout{2},varargout{3},varargout{4}] = loadScanImageStimulus(imfile,imsize(3));
                end
            end
    end
    elseif strcmp(imfile(end-2:end),'dat')
        load([imfile(1:end-4) '.mat']);
        tmpinfo.size = SIinfo.size;
        tmpinfo.frames = SIinfo.frames;
        tmpinfo.frameRate = SIinfo.frameRate;
        imsize = [tmpinfo.size tmpinfo.frames];
        fileID = fopen(imfile,'r');
        if isfield(SIinfo,'numChannels')
            if SIinfo.numChannels == 1
                im = fread(fileID,imsize(1)*imsize(2)*imsize(3),'uint16=>uint16');
                im = reshape(im,imsize);
            else
                im{1} = fread(fileID,imsize(1)*imsize(2)*imsize(3),'uint16=>uint16');
                im{2} = fread(fileID,imsize(1)*imsize(2)*imsize(3),'uint16=>uint16');
                im{1} = reshape(im{1},imsize); im{2} = reshape(im{2},imsize);
            end
        else
            im = fread(fileID,imsize(1)*imsize(2)*imsize(3),'uint16=>uint16');
            im = reshape(im,imsize);
        end
        fclose(fileID);
        %varargout for multichannel and stimulus signal
        numout = max(2,nargout)-2; %number of extra outputs
        if numout > 0
            varargout=cell(1,numout);
            for n = 1:numout;varargout{n} = [];end
            varargout{1}=SIinfo.aux1;
            if numout>1; varargout{2}=SIinfo.aux2; end
            if numout>2; if isfield(SIinfo,'aux3'); varargout{3}=SIinfo.aux3; else; varargout{3} = []; end; end
            
        end
    end
    
    function val = getVal(metadata, field)
    ind1 = strfind(metadata, field);
    if (~isempty(ind1))
        ind2 = strfind(metadata(ind1:end), 13); %find line breaks
        ind2 = ind2(1);
        line = metadata(ind1:ind1+ind2-2);
        val = sscanf(line,[field '=%f']);
    else
        %disp('Error - Invalid metadata field');
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
        %disp('Error - Invalid metadata field');
        val = [];
    end
    end
    
end