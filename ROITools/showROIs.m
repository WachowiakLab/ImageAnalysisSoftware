function showROIs(rois, im, varargin)
%function showROIs(rois, im, varargin)
%   rois, "struct", including roi(i).mask binary images
%   im, background image (2D, same size as mask)
%   varargin is for an index of which rois to show
%   Note: uses myColors.m

if nargin == 3
    ind = varargin{1};
else
    ind = 1:length(rois);
end
figure('NumberTitle','off','Menubar', 'none','Name','Show ROIs',...
    'Units', 'Normalized', 'Position', [0.2 0.2 0.6 0.7]);
tmpaxe = axes('Units','Normalized','Position',[0 0 1 1]);
if  size(im) ~= size(rois(1).mask)
    errordlg('ROI mask size does not match background image');
    return;
end
imagesc(im);
hold(tmpaxe,'on');
axis(tmpaxe,'image');
axis(tmpaxe,'off');
colormap(gray); % Could make this an input to function
%tmp = prctile(im(:), [1 99]); %this probably ishouldn't be here
%if tmp(2)<=tmp(1); tmp(2)=tmp(1)+1; end;
%set(tmpaxe,'Clim', [tmp(1) tmp(2)]);
% show rois
for r = ind
    ctemp = contourc(double(rois(r).mask), [1,1].*0.5);
    newcolumns = find(ctemp(1,:)==0.5);
    for i = 1:numel(newcolumns)
        ind1 = newcolumns(i)+1;
        if (i+1>numel(newcolumns))
            ind2 = size(ctemp, 2);
        else
            ind2 = newcolumns(i+1)-1;
        end
        line(ctemp(1,ind1:ind2), ctemp(2, ind1:ind2), 'Color', myColors(r), 'LineWidth', 0.5);
        text(mean(ctemp(1,:)),mean(ctemp(2,:)),num2str(r),'Color',myColors(r),'FontSize',14);
    end
end