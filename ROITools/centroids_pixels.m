function ROIpositions = centroids_pixels(varargin)
% function [X,Y] = centroids(varargin)
%   varargin - can provide rois().mask and registration struct if desired
%   rois - struct of 2D binary mask images, e.g. roi(1:n).mask
% output: ROIpositions is a table with Xpos, Ypos columns for each roi
%   Xpos - centroid X positions in pixel units
%   Ypos - centroid Y positions in pixel units

if nargin
    rois = varargin{1};
else
    rois = loadROIs;
end
% Determine centroid of ROI from ROI Mask
Ypos = zeros(length(rois),1);
Xpos = zeros(length(rois),1);
for r = 1:length(rois)
    roinames{r} = ['ROI# ' num2str(r)];
    [ii,jj] = find(rois(r).mask); %Identifies all non-zero columns and rows - ROIs
    Ypos(r) = mean(ii); 
    Xpos(r) = mean(jj);
end
ROIpositions = table(Xpos,Ypos,'VariableNames',{'Xpos','Ypos'},'RowNames',roinames);
