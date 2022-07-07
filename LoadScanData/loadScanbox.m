function [im,iminfo,varargout] = loadScanbox(imfile)
% [im,imInfo,varargout] = loadScanBox(filename)
%   filename(char): name of file to be opened (.sbx)
%   im(int16): image matrix (Width,Height,Frames)
%   iminfo(struct): ImageDescription stored in file header
%   varargout: Optional output for multichannel data

imfile = imfile(1:end-4);
[~,iminfo] = mysbxread(imfile,0,0);
iminfo.frames = iminfo.max_idx+1;
iminfo.frameRate = iminfo.resfreq / iminfo.recordsPerBuffer;
im = [];
[q,~] = mysbxread(imfile,0,iminfo.frames);
if size(q,1) == 1
    im = squeeze(q);
    iminfo.size = size(im(:,:,1));
elseif size(q,1) == 2 %multichannel
    im{1} = squeeze(q(1,:,:,:));
    im{2} = squeeze(q(2,:,:,:));
    iminfo.size = size(im{1}(:,:,1));
end

slashInd = strfind(imfile,'\');
tempPath = pwd;
cd (imfile(1:slashInd(end)))
d = dir([imfile(slashInd(end)+1:end) '.sbx']);
monthList = {'Mar-2020','Apr-2020','May-2020','Jun-2020','Jul-2020','Aug-2020','Oct-2020','Nov-2020'};
cd (tempPath);
%varargout for multichannel and stimulus signal
nout = max(2,nargout)-2; %number of extra outputs
if nout > 0
    varargout=cell(1,nout);
    for n = 1:nout; varargout{n} = []; end
    %first get a more accurate imaging framerate from the ephys framecounter signal
    if nout>3
        samprate = 150; % this value is set manually in the scanbox config file - change to match your data
        ephys = loadScanboxEphys([imfile '.ephys'],samprate);
        if ~isempty(ephys)
            istart = find(ephys.framenum == 1,1,'first');
            iend = find(ephys.framenum == iminfo.frames,1,'first');
            fprintf('Scanbox framerate = %f\n',iminfo.frameRate);
            % Use below if data recorded on scanbox between 3/20 and 11/20
            if iminfo.scanbox_version == 3 && sum(strcmp(d.date(4:11),monthList))             
                iminfo.frameRate = 150*iminfo.frames/(iend-istart)/4;
            else
                iminfo.frameRate = 150*iminfo.frames/(iend-istart);
            end
            fprintf('New frameRate based on ephys = %f\n',iminfo.frameRate);
            ephys.times = ephys.times - ephys.times(find(ephys.framenum == 1,1,'first'));
        end
        varargout{4}=ephys;
    end
    if isfield(iminfo,'event_id') && ~isempty(iminfo.event_id)
        [varargout{1},varargout{2},varargout{3}] = loadScanboxStimulus(iminfo); % gets auxillary inputs (odor, sniff)
    end
end