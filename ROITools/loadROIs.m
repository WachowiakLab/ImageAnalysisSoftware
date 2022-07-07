function rois = loadROIs(varargin)
%function rois = loadROIs(varargin)
%   varargin{1} is file path
%   varargin{2} is file name
%   loads a .tif file with binary mask images into rois(i).mask
%   -or- uses scanbox realtime.mat file
rois = struct([]);
if nargin>=1; pathname = varargin{1}; else; pathname = ''; end
%look for *_realtime.mat(scanbox filetype), otherwise just look for */ROIs/*roi
if nargin == 2
    newpathname = pathname;
    filename = varargin{2};
else
    if ~isempty(dir(fullfile(pathname,'*_realtime.mat')))
        [filename,newpathname] = uigetfile({'*realtime.mat;*.roi','ROI files'},'Select *.roi or realtime.mat file', pathname);
    else
        [filename,newpathname] = uigetfile('*.roi','Select ROI file name', fullfile(pathname, 'ROIs'));
    end
    if filename == 0; return; end
end
roifile = fullfile(newpathname,filename);
if strcmp(roifile(end-3:end),'.mat')
    realtime = load(fullfile(newpathname,filename)); %loads the roipix variable
    [imsize(1),imsize(2)] = getImageSize('scanbox',fullfile(newpathname,[filename(1:end-13) '.sbx']));
    for i = 1:numel(realtime.roipix)
        rois(i).mask = zeros(imsize(1),imsize(2));
        rois(i).mask((realtime.roipix{i})) = 1;
    end
    clear roipix;
else
    info = imfinfo(roifile, 'tif');
    for i = 1:numel(info)
        rois(i).mask = double(imread(roifile, 'tif', i));
        rois(i).mask = rois(i).mask./max(max(rois(i).mask));
    end
end