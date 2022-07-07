function ROIpositions = centroids_RegGUI(varargin)
% function ROIpositions = centroids_RegGUI(registration)
%   varargin - can provide rois().mask and registration struct if desired
%   rois - struct of 2D binary mask images, e.g. roi(1:n).mask
%   registration struct with fields: mag, xpos, ypos, rotation (see RegistrationGUI_MWLab.m)
%   Xpos - vector (nx1) of centroid X positions in normalized units(0-1)
%   Ypos - vector (nx1) of centroid Y positions in normalized units
% output: ROIpositions is a table with globalX, globalY columns for each roi

if nargin ~= 2
    rois = loadROIs;
    [regfile,regpath] = uigetfile('*.mwlab_reg','Load MWLab Registration File (*.mwlab_reg)');
    tmp=load(fullfile(regpath,regfile),'-mat');
    reg  = tmp.registration;
else
    rois = varargin{1};
    reg = varargin{2};
end

% Determine centroid of ROI from ROI Mask
Ypos = zeros(length(rois),1);
Xpos = zeros(length(rois),1);
for r = 1:length(rois)
    roinames{r} = ['ROI# ' num2str(r)];
    tmpmask = rois(r).mask;
    if reg.pixelsize(1) < reg.pixelsize(2) %stretch the image in Y to make pixels same size
        tmpmask = imresize(tmpmask,[size(tmpmask,1)*reg.pixelsize(2)/reg.pixelsize(1) size(tmpmask,2)]);
    elseif reg.pixelsize(2) < reg.pixelsize(1) %stretch in X (not currently used
        tmpmask = imresize(tmpmask,[size(tmpmask,1) size(tmpmask,2)*reg.pixelsize(1)/reg.pixelsize(2)]);
    end
    [ii,jj] = find(tmpmask); %Identifies all non-zero rows & columns. [row,col] = find()
    Ypos(r) = (mean(ii)) - size(tmpmask,1)/2; %mean of rows is Ypos
    Xpos(r) = (mean(jj)) - size(tmpmask,2)/2; %mean of cols is Xpos
end
%convert to micrometers
if ~isempty(reg.zoom) && isfinite(str2double(reg.zoom)); reg.pixelsize=reg.pixelsize./str2double(reg.zoom); end
Ypos = Ypos.*min(reg.pixelsize); %use min(pixelsize) since image is already stretched.
Xpos = Xpos.*min(reg.pixelsize);

%account for rotation angle
globalY = Xpos*sind(reg.rotation)-Ypos*cosd(reg.rotation);
globalX = Xpos*cosd(reg.rotation)+Ypos*sind(reg.rotation);
%add center of image position
globalY = reg.ypos + globalY;
globalX = reg.xpos + globalX;
% disp([globalX,globalY]);
ROIpositions = table(globalX,globalY,'VariableNames',{'Xpos','Ypos'},'RowNames',roinames);
