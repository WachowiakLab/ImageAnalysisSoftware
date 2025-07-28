function o = import_da(filepath)
    % modified from analysis_software\matlab\read_NP.m file
    % does basically the same thing, but returns a structure with the data
    if nargin == 0
        [filename, pathstr] = uigetfile(['',{'*.da','Neuroplex data files (*.da)'}],'Choose *.da file');
        if isequal(filename,0)
            o = [];
            return
        end
    else
        [pathstr, name, ext] = fileparts(filepath);
        filename = [name,ext];
    end
    try
        fid = fopen(fullfile(pathstr, filename));
        fseek(fid,0,'bof');
    catch
        warning('ImportDa:missingFile','The file was not found.')
        o = [];
        return
    end

    o.filename = filename;
    A = fread(fid, 400,'uint16'); %Reads 400 16-bit unsigned integers
    o.numtrialavg = A(2);
    if o.numtrialavg < 1
        o.corrupted = true;
        o.numsamples = 0; o.frameinterval = 0; o.samplingrate = 0; o.acquisition_time = 0; o.BNCfactor = 0;
        o.timestamp = 0;
        o.comment = '(file corrupted)';
        o.BNCs = []; o.data = [];
    else
        o.corrupted = false;
        o.numsamples = A(5);
        num_cols = A(385);
        num_rows = A(386);
        %Num_Pixels = A(97); %referring to 8 BNCs?
        o.frameinterval = A(389)/1000*A(391); %in msec (A(391) is the dividing factor)
        o.samplingrate = 1000/o.frameinterval; %Hz
        o.acquisition_time = o.numsamples * o.frameinterval; %in msec
        o.BNCfactor = A(392);
        if o.BNCfactor == 0;
            o.BNCfactor = 1;
        end

        fseek(fid,26,'bof');
        o.timestamp = datenum(fread(fid,16,'*char',1)','HH:MM:SSddmmmyy',2000);
        
        fseek(fid,256,'bof');
        o.comment = deblank((fread(fid,159,'*char',1))');

        fseek(fid,5120,'bof');
        data = fread(fid,[o.numsamples,num_cols*num_rows],'*int16');

        o.BNCs = fread(fid, [o.numsamples*o.BNCfactor,8], '*int16')';

        dark_frame = repmat(fread(fid,num_cols*num_rows,'*int16')',o.numsamples,1);
        data = data - dark_frame;

        o.data = reshape(data, o.numsamples, num_cols, num_rows);
    end
    fclose(fid);
end