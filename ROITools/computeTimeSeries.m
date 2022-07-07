function data = computeTimeSeries(data,roidata)
%function data = computeTimeSeries(data,roidata)
%  This function loads MWLab data and an roi file, and computes time series data (time-shifted based on roi location)
%  "data" is MWLab datafile, with data.file().im & data.file().frameRate
%       Note: doesn't work if data.im is a cell, create separate files for two-channel data first
%  roidata is MWLab roi struct, with roi().mask binary images
%  output is "data" with time series, e.g. data.file(#).roi(#).(time,series)
%  example: data = ComputeTimeSeries(TSdata.file(1),TSdata.roi)

if ~isfield(data,'file'); disp('data.file not found'); return; end
roiIndex=cell(1,length(roidata));
roiRowPosition=cell(1,length(roidata));
for r = 1:length(roidata) %do this first, same for all files
    roiIndex{r} = find(roidata(r).mask);
    [rows,~]=find(roidata(r).mask);
    roiRowPosition{r} = mean(rows)/size(roidata(1).mask,1);
end
for f = 1:length(data.file)
    frames = size(data.file(f).im,3);
    tmpbar = waitbar(0,'Computing timeseries data');
    %temporal resolution precision is increased using roi centroid row positions (double check this for your data if it matters)
    for r = 1:length(roidata)
        data.file(f).roi(r).time = ((0:frames-1) + roiRowPosition{r}) ./ data.file(f).frameRate; %files may have different framerates
    end
    for i = 1:frames
        if mod(i,100)==0; waitbar(i/frames,tmpbar);end
        tmpim = data.file(f).im(:,:,i);
        for r = 1:length(roidata)
            data.file(f).roi(r).series(1,i) = mean(tmpim(roiIndex{r})); %compute mean value in ROI
        end
        clear tmpim;
    end
    close(tmpbar);
end
   