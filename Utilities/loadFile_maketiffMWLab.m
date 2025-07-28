function newfilename = loadFile_maketiffMWLab(varargin)
% MWfile = loadFile_MWLab(varargin)
% varargin (optional)
%   #1)datatype: 'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'
%   #2)pathname: directory of files
%   #3)filename: character string
%   #4)if scanimage: odorOnDuration: scalar value of how long odor is on in seconds
%      if neuroplex: aux2bncmap: vector mapping aux signals to bnc inputs for neuroplex
% MWfile: MWLab image file data structure 
%   #1)MWdata.type (datatype, as shown above)
%   #2)MWdata.name (filenames, "cell" as shown above)
%   #3)MWdata.dir (path)
%   #4)MWdata.image (1 channel - matrix, >1 channel - cell of image matrices)
%   Also, frameRate

MWfile = struct;
typestr = getdatatypes; % {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};
% get datatype 
if nargin > 0
    datatype = varargin{1};
    if ~max(strcmp(datatype,typestr))
        errordlg({'Datatype must be:',char(typestr)});
        return;
    end
else
    [type,ok]= listdlg('SelectionMode','single','PromptString','Select Data Type','SelectionMode','single','ListString',...
        typestr);
    if ok == 0
        return;
    end
    datatype=typestr{type};
end
MWfile.type=datatype;

%get pathname & filename
if nargin > 2
    pathname = varargin{2};
    if nargin >= 3
        if ischar(varargin{3}); filename = varargin{3}; else; errordlg('Filename must be character string'); end
        if nargin == 4 && strcmp(datatype,'scanimage'); odorOnDuration = varargin{4};
        elseif nargin == 4 && strcmp(datatype,'neuroplex'); aux2bncmap = varargin{4};
        elseif nargin>4; errordlg('Incorrect number of input arguments');
        end
    end
else
    if nargin == 2; pathname = varargin{2}; else pathname = ''; end
    switch datatype
        case typestr{1} %'scanimage'
            ext = {'*.tif;*.dat','Scanimage Files';'*.*','All Files'};
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
        case typestr{2} %'scanbox'
            ext = '.sbx';
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
        case typestr{3} %'prairie'
            ext = '.xml'; %might try using uigetfolder for multiple files
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
        case typestr{4} %'neuroplex'
            ext = {'*.da;*.tsm','Neuroplex Files'};
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
        case typestr{5} %'tif'
            ext = '.tif';
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'Off');
    end
    if ok == 0; return; end   
end
MWfile.dir = pathname;
MWfile.name = filename;
fname=filename(1:end-4);
%Load images (need to work on dealing with multichannel data!)
switch datatype
    case 'scanimage'
        if nargin > 3
            [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2,MWfile.aux3,MWfile.ephys] = ...
                loadScanImage(fullfile(MWfile.dir,MWfile.name),odorOnDuration);
        else
            [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2,MWfile.aux3,MWfile.ephys] = ...
                loadScanImage(fullfile(MWfile.dir,MWfile.name));
        end
        if isempty(MWfile.aux3); MWfile = rmfield(MWfile,'aux3'); end
        if isempty(MWfile.ephys); MWfile = rmfield(MWfile,'ephys'); end
        MWfile.size = tmpinfo.size; MWfile.frames = tmpinfo.frames; MWfile.frameRate = tmpinfo.frameRate;
    case 'scanbox'
%         [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2,MWfile.aux3] = ...
        [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2,MWfile.aux3, MWfile.ephys] = ...
            loadScanbox(fullfile(MWfile.dir,MWfile.name));
        if isempty(MWfile.aux3); MWfile = rmfield(MWfile,'aux3'); end
        if isempty(MWfile.ephys); MWfile = rmfield(MWfile,'ephys'); end
        MWfile.size = tmpinfo.size; MWfile.frames = tmpinfo.frames; MWfile.frameRate = tmpinfo.frameRate;
    case 'prairie'
        [MWfile.im,tmpinfo] = loadPrairie(fullfile(MWfile.dir,MWfile.name));
        MWfile.size = tmpinfo.size; MWfile.frames = tmpinfo.frames; MWfile.frameRate = tmpinfo.frameRate;
    case 'neuroplex'
        if nargin > 3
            [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2,MWfile.aux3] = ...
                loadNeuroplex(fullfile(MWfile.dir,MWfile.name),aux2bncmap);
        else
            [MWfile.im,tmpinfo,MWfile.aux1,MWfile.aux2,MWfile.aux3] = ...
                loadNeuroplex(fullfile(MWfile.dir,MWfile.name));
        end
        if isempty(MWfile.aux3); MWfile = rmfield(MWfile,'aux3'); end
        MWfile.size = tmpinfo.size; MWfile.frames = tmpinfo.frames; MWfile.frameRate = tmpinfo.frameRate;
    case 'tif'
        wait = waitbar(1/numel(MWfile.name),'Loading File');
        tmpinfo = imfinfo(fullfile(MWfile.dir,MWfile.name), 'tif');
        MWfile.im = zeros(tmpinfo(1).Height,tmpinfo(1).Width,numel(tmpinfo));
        for i = 1:numel(tmpinfo)
            MWfile.im(:,:,i) = imread(fullfile(MWfile.dir,MWfile.name), 'tif', 'Index', i, 'info', tmpinfo);
        end
        MWfile.size = [size(MWfile.im,1) size(MWfile.im,2)]; MWfile.frames = size(MWfile.im,3);
        answer = inputdlg('Enter frame rate (Hz)','Frame Rate', 1, {'10.0'});
        if isempty(answer); return; end
        MWfile.frameRate = str2double(answer); %frameRate(sec)            
        close(wait);
    otherwise
        return;
end
    wait = waitbar(0,'Writing File');
    newfilename=[pathname fname '.tif'];
    for f = 1:MWfile.frames
        waitbar(f/MWfile.frames,wait);
        q = squeeze(MWfile.im(:,:,f));
        imwrite(q, newfilename,'tif','writemode','append');
    end    
    close(wait);
 end
