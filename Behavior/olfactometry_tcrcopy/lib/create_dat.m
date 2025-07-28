function create_dat(da_filename, basetime, resptime, binsize, comment, dat_filename)
    imp = import_da(da_filename);
    
    baselineT = basetime:basetime+binsize-1;
    responseT = resptime:resptime+binsize-1;
    
    basemap = squeeze(mean(double(imp.data(baselineT,:,:)),1));
    respmap = squeeze(mean(double(imp.data(responseT,:,:)),1));
    
    fid = fopen(dat_filename, 'w', 'b');
    
    c = repmat(' ',1,500); %make empty comment
    c(1:min(length(comment),500)) = comment(1:min(length(comment),500)); %fill it in appropriately
    
    fseek(fid,0,'bof');
    fwrite(fid, c, 'char');   %bytes 0-499: comment
    fwrite(fid, 0, 'uint8');  %byte  500: omit mask NOT saved (for now)
    fwrite(fid, length(basemap), 'uint16'); %bytes 501-2: size
    fwrite(fid, [baselineT(1) baselineT(end) responseT(1) responseT(end)], 'uint16'); %bytes 503-510
    fwrite(fid, 0, 'uint8'); %fill in the extra byte (data starts at byte 512)
    
    fwrite(fid, basemap, 'float32');
    fwrite(fid, respmap-basemap, 'float32');
    fwrite(fid, ones(size(basemap)), 'float32');    
    fclose(fid);
end
