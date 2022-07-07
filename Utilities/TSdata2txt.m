function TSdata2txt(TSdata)
% function TSdata2txt(TSdata)
% you get TSdata from the "save App Data" button in
% TimeSeriesAnalysis_MWLab (after you load the mydata.mat file)

if isempty(TSdata.file); return; end
for f = 1:length(TSdata.file)
    fid = fopen([TSdata.file(f).name(1:end-3) '_tsdata.txt'], 'w');
    % top row of .txt file are labels
    fprintf(fid,'%5s\t','Times');
    %12s\r\n','x','exp(x)');
    for r = 1:numel(TSdata.roi)
        fprintf(fid,'ROI#%d\t',r);
    end
    fprintf(fid,'\n'); %end of line
    for i = 1:length(TSdata.file(f).roi(1).time)
        fprintf(fid,'%4.4f\t',TSdata.file(f).roi(1).time(i));
        for rr = 1:numel(TSdata.roi)
            fprintf(fid,'%7.4f\t',TSdata.file(f).roi(rr).series(i));
        end
        if i < length(TSdata.file(f).roi(1).time)
            fprintf(fid,'\n'); %end of line
        end
    end
    fclose(fid);
end