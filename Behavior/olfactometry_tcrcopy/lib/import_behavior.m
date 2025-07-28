function o = import_behavior(filepath)
    % modified from Aladin's SniffBehavior\fn_load_data.m
    if nargin == 0
        [filename, pathstr] = uigetfile({'*','Behavior Files'},'Choose behavior file','E:\data\behavior');
        if isequal(filename,0)
            o = [];
            return
        end
    else
        [pathstr, name, ext] = fileparts(filepath);
        filename = [name,ext];
    end
    try
        fid = fopen(fullfile(pathstr, filename),'r','b');
        fseek(fid,0,'bof');
    catch
        warning('ImportDa:missingFile','The file was not found.')
        o = [];
        return
    end
    
    %{
    Header structure:
        245-byte string = comment + date/time
        (with some leeway)
    	byte 246 = scale factor (I16)
        byte 248 = num channels (byte int)
        byte 249  = num bytes of data type
        byte 250 - 251 = scan rate (I16)
        byte 251 - 255 - num pts (U32)
        byte 256 on = data
    %}
    
    %since header is not always the same, we have to do some guessing:
    %following determines where the comment ends and header starts. then it
    %positions the file for reading
    for filepos = 244:265
        fseek(fid, filepos, 'bof');
        scaleFactor = fread(fid, 1, 'int16');   %use these two to test
        numChan = fread(fid, 1, 'int8');
        if 100 < scaleFactor && scaleFactor < 5000 && 3 < numChan && numChan < 10
            break
        end
    end

    fseek(fid, 0, 'bof');
    o.filename = filename;
    o.comment = strtrim(fread(fid, 228,'*char')');
    o.timestamp = datenum(fread(fid, 19,'*char')','mm/dd/yyyy:HH:MM AM');

    fseek(fid,filepos,'bof');
    scalefactor = fread(fid, 1, 'int16');
    fread(fid, 1, 'uint8'); %num channels (incorrect)
    fread(fid, 1, 'int8'); %num bytes
    o.samprate = fread(fid, 1, 'int16');
    fread(fid, 1, 'uint32'); %num points (incorrect)
    data = fread(fid, inf, 'int16') ./ scalefactor;

    fclose(fid);
    
    %figure out how many channels 
    %(assume greatest autocorrelation between samples from same channel)
    
    b = xcorr(data(1:1000),10);
    [m,numchannels] = max(b(12:end));

    o.data = reshape(data,numchannels,[])';
    o.datasize = size(o.data);
end