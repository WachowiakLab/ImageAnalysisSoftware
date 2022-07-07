function saveROIs(rois,pathname,filename)
%function saveROIs(rois,pathname,filename)
%   Creates a directory 'pathname/ROIs' and
%   Saves rois image as a .tif file, but using .roi as the file extension
%   example: saveROIs(rois,'','');
if isempty(rois); return; end;
Nroi = length(rois);
filename = [filename '_' date '.roi'];
if ~exist(fullfile(pathname, 'ROIs'), 'dir')
    mkdir(fullfile(pathname, 'ROIs'));
end
[filename,pathname] = uiputfile('*.roi','Select ROI file name', fullfile(pathname, 'ROIs', filename));
if ~filename
    return
end
imwrite(rois(1).mask, fullfile(pathname, filename), 'tif');
for i = 2:Nroi
    imwrite(rois(i).mask, fullfile(pathname, filename), 'tif', 'WriteMode', 'append');
end