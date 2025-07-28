function o = import_ext(filepath)
% meant to open extracted datafiles generated in Matt's labview program.
% modified from analysis_software\matlab\read_ext.m file
% does basically the same thing, but returns a structure with the data
if nargin == 0
    [filename, pathstr] = uigetfile(['',{'*.ext','EXTracted data file (*.ext)'}],'Choose EXT file');
    if isequal(filename,0)
        o = [];
        return
    end
else
    [pathstr, name, ext, versn] = fileparts(filepath);
    filename = [name,ext,versn];
end
try
    fid = fopen(fullfile(pathstr, filename), 'r', 'b'); %big-endian format
    fseek(fid,0,'bof'); %seek the begining of file
catch
    warning('ReadExt:missingFile',['The selected file was not found: ' fullfile(pathstr, filename)])
    o = [];
    return
end

globals = fread(fid, 4, 'int16');  %read in numfils, numrois, numpoints, then sample rate (in Hz)
o.numfiles=globals(1);
o.numrois=globals(2);
o.numpoints=globals(3);
o.samprate=globals(4);
o.Xposits = fread(fid, o.numrois, 'int16');  %read list of X positions
o.Yposits = fread(fid, o.numrois, 'int16');  %read list of Y positions
for n = 1:o.numfiles
    file = fgetl(fid);
	o.filelist(n) = {file(file > 0)};
end
o.filelist = strtrim(o.filelist);
for n = 1:o.numfiles
    odor = fgetl(fid);
	o.odorlist(n) = {odor(odor > 0)};
end
o.odorlist = strtrim(o.odorlist);

o.concs=fread(fid, o.numfiles, 'int16') ./ 1000;         %read in concentration values
o.acqtimes=fread(fid, o.numfiles, 'uint32');    %read in acq times in seconds.
o.valence=fread(fid, o.numfiles, 'uint8');    %reads 0 if S-, 1 if S+
o.licktimes=fread(fid, o.numfiles, 'int16');    %reads licktimes. 0 if no lick. this is frame of first lick
o.odortraces=fread(fid, [o.numpoints, o.numfiles], 'int16');  %reads in odortraces
o.snifftraces=fread(fid, [o.numpoints, o.numfiles], 'int16');  %reads in snifftraces
o.allsignal=zeros(o.numpoints+1, o.numrois, o.numfiles);  %holder to start concatenating below
for n = 1:o.numfiles
	o.allsignal(:,:,n)=fread(fid, [o.numpoints+1, o.numrois], 'int16');  %reads traces from all rois in each file (NOTE! 1st pt is RLIs)
end
for n = 1:o.numfiles
    comment = fgetl(fid);
	o.comments(n) = {comment(comment > 0)};
end
o.comments=strtrim(o.comments);

fclose(fid);
o.rlis=o.allsignal(1,:,:);   %rlis now - one dimension is rois, other is files.