function [im,iminfo,varargout] = loadPrairie(imfile)
% [im,imInfo,varargout] = loadPrairie(filename)
%   filename(char): name of file to be opened (.xml)
%   im(int16): image matrix (Width,Height,Frames)
%   iminfo(struct): ImageDescription stored in file header
%   varargout: Optional output for multichannel data

% Prairie files are organized as separate .tifs for each timeframe
% so, we load the .xml file, get frames and channel number, timestamps
% then, load and stack all the .tifs
    
iminfo = xml2struct(imfile);
[path,~,~] = fileparts(imfile);
%determine lengths
iminfo.frames = length(iminfo.PVScan.Sequence.Frame);
channellength = length(iminfo.PVScan.Sequence.Frame{1, 1}.File);

% channel = 0;
% if channellength > 1 %multiple channels
%     while channel ~= 1 && channel ~= 2
%         channel = str2double(inputdlg('Multiple channels detected, select channel 1 or 2:','Multichannel Data',1,{'1'}));
%         sprintf('channel = %d',channel);
%     end
% end

%create cell of proper size
tifNames = cell(iminfo.frames, channellength);
timestamps = zeros(iminfo.frames,1);

%loop to extract timestamps, either relative or absolute
if (iminfo.PVScan.Sequence.Frame{1, 2}.Attributes.relativeTime>0)
   for i = 1:iminfo.frames
      timestamps(i,1)=str2double(iminfo.PVScan.Sequence.Frame{1, i}.Attributes.relativeTime);
   end
else
   for i = 1:iminfo.frames
      timestamps(i,1)=str2double(iminfo.PVScan.Sequence.Frame{1, i}.Attributes.absoluteTime);
   end  
end
% compute frameRate and dt   TCRTCRTCR NEED TO CHECK UNITS...
iminfo.dt = timestamps(2)-timestamps(1);
iminfo.frameRate = 1/iminfo.dt;

%loop to extract image names for each channel
for j=1:channellength
    for i=1:iminfo.frames
        tifNames{i,j}=iminfo.PVScan.Sequence.Frame{1, i}.File{1, j}.Attributes.filename;
    end
end

%create 3d matrix for each file
for i=1:iminfo.frames
    file = fullfile(path,tifNames{i,1});
    channel1(:,:,i)=imread(file);
end
iminfo.size = size(channel1(:,:,1));

if channellength==2 %&& channel ==2
    for j=1:iminfo.frames
        file = fullfile(path,tifNames{j,2});
        channel2(:,:,j)=imread(file);  
    end
end

% Get the channel selected
% if channel == 1
%     im = channel1;
% elseif channel == 2
%     im = channel2;
% end
if channellength == 1
    im = channel1;
elseif channellength == 2
    im{1} = channel1;
    im{2} = channel2;
end
varargout{:} = []; %fix this for multichannel
clear channel;
