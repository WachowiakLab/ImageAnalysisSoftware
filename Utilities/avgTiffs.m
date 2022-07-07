function avgTiffs(varargin)
% function avgTiffs(varargin)
% Computes the average (mean) of multiple .tif files of the same size and saves output file
%  - varargin can be empty - in which case you select files
%  - or, varargin can be a list of files ('fileA','fileB',...) in the current directory

% MWLab, Tom Rust, Feb 2015

%get files
if nargin == 0
    [filenames, path] = uigetfile('.tif', 'Select file(s)', 'MultiSelect', 'On');
else
    path = '';
    [filenames] = varargin;
end

%read first image
imfile = fullfile(path, filenames{1});
tifInfo = imfinfo(imfile, 'tif');

xpix = tifInfo(1).Width;
ypix = tifInfo(1).Height;
zpix = numel(tifInfo); 

tmpim = zeros(ypix,xpix,zpix); %dimensions to match image
tmp = waitbar(0,'Reading Files');
for i = 1:zpix
    tmpim(:,:,i) = imread(imfile, 'tif', 'Index', i, 'info', tifInfo);
end
meanStack = double(tmpim); %add first image into average
clear tmpim;
waitbar(1/numel(filenames));

%read additional images
for n = 2:numel(filenames)
    imfile = fullfile(path, filenames{n});
    tifInfo = imfinfo(imfile, 'tif');
    if tifInfo(1).Width ~= xpix || tifInfo(1).Height ~= ypix || numel(tifInfo)~= zpix
        errordlg('File Sizes Do Not Match');
        return;
    end
    for i = 1:numel(tifInfo)
        tmpim(:,:,i) = imread(imfile, 'tif', 'Index', i, 'info', tifInfo);
    end
    meanStack = meanStack + double(tmpim); %add image into average
    clear tmpim;
    waitbar(n/numel(filenames));
end
close(tmp);
meanStack = meanStack./(numel(filenames));

%write image
outfn = [path 'average'];
[fn,path] = uiputfile('*.tif','Select file name', outfn);
if ~fn(1)
    return;
end
imwrite(uint16(meanStack(:,:,1)), fullfile(path, fn), 'tif');
for k = 2:zpix
    imwrite(uint16(meanStack(:,:,k)), fullfile(path, fn), 'tif', ...
        'writemode', 'append');
end
msgbox('Operation Successful!');



