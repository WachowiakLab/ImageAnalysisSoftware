function convertScanImageTif2Dat(varargin)
% convertScanImage2Dat(varargin)
%   -converts ScanImage .tif files to .dat/.mat for faster processing 
%   -varargin(optional) is for filename(s) input (output is to same directory)
%   -output is saved binary data file (uint16, .dat) + header file(.mat) 
%   -note: .dat is a made up file extension for identification purposes only

if nargin == 0 % interactively select file(s) and output path
    ext = '.tif';
    [filename, pathname, ok] = uigetfile(ext, 'Select file(s)', 'MultiSelect', 'On');
    if ok == 0; return; end
    outpath = uigetdir(pathname,'Choose a Directory to Save Converted Files');
else % read filenames from command line
    if nargin == 1
        if ~exist(varargin{1},'file')
            errordlg(sprintf('File %s does not exist',varargin{1})); return;
        end
        [pathname,name,ext] = fileparts(varargin{1});
        filename = [name ext];
    else
        for i = 1:nargin
            if ~exist(varargin{i},'file')
                errordlg(sprintf('File %s does not exist',varargin{i})); return;
            end
            [pathname,name,ext] = fileparts(varargin{i});
            filename{i} = [name ext];
        end
    end
    outpath=pathname;
end
% odorOnDuration = str2double(inputdlg('For how long is the odor on (sec)?','Enter Odor Duration',1));
if ischar(filename)
    [tmpim,tmpinfo] = loadScanImage(fullfile(pathname,filename));
    SIinfo = tmpinfo;
    if iscell(tmpim)
        SIinfo.numChannels = 2;
        fileID = fopen(fullfile(outpath,[filename(1:end-4) '.dat']),'w');
        fwrite(fileID,tmpim{1},'uint16');
        fwrite(fileID,tmpim{2},'uint16');
        fclose(fileID);
    else
        SIinfo.numChannels = 1;
        fileID = fopen(fullfile(outpath,[filename(1:end-4) '.dat']),'w');
        fwrite(fileID,tmpim,'uint16');
        fclose(fileID);
    end
    tmptiff = Tiff(fullfile(pathname,filename), 'r');
    try SImeta = tmptiff.getTag('Software');
    catch
        SImeta = [];
    end
    if isempty(SImeta) %old versions, before scanimage 5.2
        SIinfo.ImageDescription = tmptiff.getTag('ImageDescription');
    else %version 5.2
        SIinfo.ImageDescription = SImeta;
    end
    tmptiff.close;
%     [SIinfo.aux1,SIinfo.aux2,SIinfo.aux3]=loadScanImageStimulus(fullfile(pathname,filename),SIinfo.frames,odorOnDuration);
    [SIinfo.aux1,SIinfo.aux2,SIinfo.aux3]=loadScanImageStimulus(fullfile(pathname,filename),SIinfo.frames);
    save(fullfile(outpath,[filename(1:end-4) '.mat']),'SIinfo');
    clear tmpim SIinfo;
    fprintf('Finished converting %s\n',fullfile(outpath,[filename(1:end-4) '.dat']));
else
    for i = 1:length(filename)
        [tmpim,tmpinfo] = loadScanImage(fullfile(pathname,filename{i}));
        SIinfo = tmpinfo;
        if iscell(tmpim)
            SIinfo.numChannels = 2;
            fileID = fopen(fullfile(outpath,[filename{i}(1:end-4) '.dat']),'w');
            fwrite(fileID,tmpim{1},'uint16');
            fwrite(fileID,tmpim{2},'uint16');
            fclose(fileID);
        else
            SIinfo.numChannels = 1;
            fileID = fopen(fullfile(outpath,[filename{i}(1:end-4) '.dat']),'w');
            fwrite(fileID,tmpim,'uint16');
            fclose(fileID);
        end        
        tmptiff = Tiff(fullfile(pathname,filename{i}), 'r');
        try SImeta = tmptiff.getTag('Software');
        catch
            SImeta = [];
        end
        if isempty(SImeta) %old versions, before scanimage 5.2
            SIinfo.ImageDescription = tmptiff.getTag('ImageDescription');
        else %version 5.2
            SIinfo.ImageDescription = SImeta;
        end
        tmptiff.close;
%         [SIinfo.aux1,SIinfo.aux2,SIinfo.aux3]=loadScanImageStimulus(fullfile(pathname,filename{i}),SIinfo.frames,odorOnDuration);
        [SIinfo.aux1,SIinfo.aux2,SIinfo.aux3]=loadScanImageStimulus(fullfile(pathname,filename{i}),SIinfo.frames);
        save(fullfile(outpath,[filename{i}(1:end-4) '.mat']),'SIinfo');
        clear tmpim SIinfo;
        fprintf('Finished converting %s\n',fullfile(outpath,[filename{i}(1:end-4) '.dat']));
    end
end