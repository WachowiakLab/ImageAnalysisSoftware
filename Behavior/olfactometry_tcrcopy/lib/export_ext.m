function varargout = export_ext(o, filepath)
% meant to write extracted datafiles in the format used by Matt's labview program.
% modified from analysis_software\matlab\read_ext.m file
% writes the data from the structure o
% no validation!

if nargout > 0
    varargout{1} = false;
end
if nargin < 2
    [filename, pathstr] = uiputfile(['',{'*.ext','EXTracted data file (*.ext)'}],'Save EXT file as...');
    if isequal(filename,0)
        return
    end
else
    [pathstr, name, ext, versn] = fileparts(filepath);
    filename = [name,ext,versn];
end
try
    fid = fopen(fullfile(pathstr, filename), 'w', 'b'); %big-endian format

    fwrite(fid, [o.numfiles, o.numgloms, o.numpoints, o.samprate], 'int16');
    fwrite(fid, o.Xposits, 'int16');  %list of X positions
    fwrite(fid, o.Yposits, 'int16');  %list of Y positions
    for n = 1:o.numfiles
        fprintf(fid, '%s\n', o.filelist{n});
    end
    for n = 1:o.numfiles
        fprintf(fid, '%s\n', o.odorlist{n});
    end

    fwrite(fid, o.concs * 1000, 'int16');         %concentration values
    fwrite(fid, o.acqtimes, 'uint32');    %acq times in seconds.
    fwrite(fid, o.valence, 'uint8');    %0 if S-, 1 if S+
    fwrite(fid, o.licktimes, 'int16');    %licktimes. 0 if no lick. this is frame of first lick
    fwrite(fid, o.odortraces, 'int16');  %odortraces
    fwrite(fid, o.snifftraces, 'int16');  %snifftraces
    for n = 1:o.numfiles
        fwrite(fid, o.allsignal(:,:,n), 'int16');  %traces from all gloms in each file (NOTE! 1st pt is RLIs)
    end
    for n = 1:o.numfiles
        fprintf(fid, '%s\n', o.comment{n});
    end

    fclose(fid);

    if nargout > 0
        varargout{1} = true; %file writing was successful
    end
catch
    error(['The file could not be written: ' fullfile(pathstr, filename)])
end