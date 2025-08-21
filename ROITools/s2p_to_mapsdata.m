%% to make ROIs from suite2P output, load in fall.mat, then modify existing corresponding MapsData file
% make 2D array of all zeros of same size as image (512 x796?)
% for each suite2P ROI val (i.e., stat structure that is a cell), read xpic
% and ypix fields, set these vals to 1 in blank image.
function [MapsDatas2p] = s2p_to_mapsdata(MapsData,stat,iscell,deadcolumns) 
%note: deadcolumns comes from suite2p output log and should be used to
%shift ROI positions to align with sbx files.
MapsDatas2p=MapsData;
statcells=stat(find(iscell(:,1)));
%statcells=cell2mat(statcells);  %convert to structure array.
for i = 1:length(statcells)
    statcellstruct=statcells{i};
    mask=zeros(MapsData.file(1).size);
    for j=1:statcellstruct.npix
        if statcellstruct.soma_crop(j)
            mask(statcellstruct.ypix(j),statcellstruct.xpix(j)+deadcolumns)=1;
        else end
    end
    MapsDatas2p.roi(i).mask=mask;
end
end