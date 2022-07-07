function ROIpositions = centroids_norm(rois)
% function ROIpositions = centroids_norm(rois)
%   rois - struct of 2D binary mask images, e.g. roi(1:n).mask
% output: ROIpositions is a table with Xpos, Ypos columns for each roi
%   Xpos - centroid X positions in normalized units(0-1)
%   Ypos - centroid Y positions in normalized units(0-1)

%by Jonathan Sullivan, May 2015 - T.Rust 2019
% Determine center of ROI from ROI Mask
Xpos = zeros(length(rois),1);
Ypos = zeros(length(rois),1);
for r = 1:length(rois)
    roinames{r} = ['ROI# ' num2str(r)];
    [ii,jj] = find(rois(r).mask); %Identifies all non-zero columns and rows - ROIs
    Xpos(r) = (mean(ii)); 
    Ypos(r) = (mean(jj));
end
%normalize centroid. Divide by image dimensions.
Xpos = Xpos./size(rois(1).mask,1);
Ypos = Ypos./size(rois(1).mask,2);

ROIpositions = table(Xpos,Ypos,'VariableNames',{'Xpos','Ypos'},'RowNames',roinames);
