function alignMeanImages_MWLab(varargin)
 %add optional varargin = datatype, path, filename{},aux2bncmap
 
%This program aligns selected image files by comparing the mean z-stack
% and, then saves the resulting shifts as .align files...
%   -if .align file already exists, the mean aligned file is loaded and used and ...
%   any new shifts are then applied to the existing .align file
%   Inputs:
%   varargin{1} is datatype {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};
%   varargin{2} is file path used for all files
%   varargin{3} is a cell containing filenames
%   varargin{4} (optional) is aux2bnc map used to load 'neuroplex' files

typestr = getdatatypes;
if nargin
    datatype = varargin{1};
    if max(strcmp(datatype,typestr))==0; disp('Invalid data type'); return; end
    pathname = varargin{2};
    filename = varargin{3};
    if ~iscell(filename) || numel(filename) < 2; disp('Invalid filename, must be a cell of file names'); return; end
    if strcmp(datatype,typestr{4}) %neuroplex
        if nargin == 4
            aux2bncmap = varargin{4};
        else
            aux2bncmap = assignNeuroplexBNC;
        end
    end
else
    %select files
    [typeval,ok]= listdlg('PromptString','Select Data Type','SelectionMode','single','ListString',...
        typestr);
    if ok == 0
        return;
    else
        datatype = typestr{typeval};
    end
    switch datatype
        case typestr{1} %'scanimage'
            ext = {'*.tif;*.dat','Scanimage Files';'*.*','All Files'};
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)','MultiSelect', 'On');
        case typestr{2} %'scanbox'
            ext = '.sbx';
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)','MultiSelect', 'On');
        case typestr{3} %'prairie'
            errordlg('This doesn''t work'); return;
        case typestr{4} %'neuroplex'
            ext = '.da';
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)','MultiSelect', 'On');
            aux2bncmap = assignNeuroplexBNC;
        case typestr{5} %'tif' %Standard .tif
            ext = '.tif';
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'On');
    end
    if ok == 0; return; end
    if ischar(filename)
        errordlg('Error: Select more than 1 file next time!');
    end
end

%check file sizes (xy dimension) and numChannels
[imsize(1),imsize(2),imsize(3)] = getImageSize(datatype,fullfile(pathname,filename{1}));
numChannels = getNumChannels(datatype,fullfile(pathname,filename{1}));
numframes = zeros(1,numel(filename)); numframes(1)=imsize(3);
for i = 2:numel(filename)
    [tmpsize(1),tmpsize(2),tmpsize(3)] = getImageSize(datatype,fullfile(pathname,filename{i}));
    if ~isequal(imsize(1:2),tmpsize(1:2))
        errordlg('File sizes do not match');
        return;
    end
    numframes(i)=tmpsize(3);
    if ~isequal(numChannels,getNumChannels(datatype,fullfile(pathname,filename{i})))
        errordlg('Number of channels does not match');
        return;
    end
end
if numChannels >1; disp('Using Channel #1 to align multi-channel files'); end

%check for existing .align file, if it exists use (m) the mean aligned image
% if not .align file, then load file and compute mean
image2align = zeros(imsize(1),imsize(2),numel(filename));
old = cell(numel(filename),1);
for i = 1:numel(filename)
    dot = strfind(filename{i},'.');
    alignfile = fullfile(pathname,[filename{i}(1:dot) 'align']);
    if numChannels == 1 && exist(alignfile,'file')==2
        old{i} = load(alignfile,'-mat');
        image2align(:,:,i)=old{i}.m;
        if ~isfield(old{i},'idx')
            old{i}.idx = 1:size(old{i}.T,1); %just in case it was a version that didn't save idx
        end
    else
        if strcmp(datatype,typestr{4})
            mwfile = loadFile_MWLab(datatype,pathname,filename{i},aux2bncmap);
        else
            mwfile = loadFile_MWLab(datatype,pathname,filename{i});
        end
        if iscell(mwfile.im); image2align(:,:,i) = mean(mwfile.im{1},3);
        else; image2align(:,:,i)= mean(mwfile.im,3);
        end
        old{i}.m = image2align(:,:,i);
        old{i}.T = zeros(size(mwfile.im,3),2);
        old{i}.idx = 1:size(mwfile.im,3);
        clear mwfile; %clear files from memory to avoid memory overload
    end
end

%align mean image stack
[~,~,Tgroup] = alignImage_MWLab(image2align,1:numel(filename));

%save shifts by including them in existing .align files or creating new .align file
for i = 1:numel(filename)
    dot = strfind(filename{i},'.');
    alignfile = fullfile(pathname,[filename{i}(1:dot) 'align']);
    if exist(alignfile,'file')==2
        if ~isempty(find(Tgroup(i,:)~=0,1)) %only store .align if there's a shift
            idx = 1:numframes(i);
            T(1:numframes(i),1)=Tgroup(i,1);
            T(1:numframes(i),2)=Tgroup(i,2);
            m = circshift(old{i}.m,Tgroup(i,:));            
            for ii = 1:numframes(i)
                tmp = find(old{i}.idx==ii);
                if ~isempty(tmp)
                    T(ii,1)=T(ii,1)+old{i}.T(tmp,1);
                    T(ii,2)=T(ii,2)+old{i}.T(tmp,2);
                end
            end
            save(alignfile,'m','T','idx');
        else
            fprintf('File %s was not shifted, .align file not changed\n',filename{i});
        end
    else %create new .align file with group shift results
        idx = 1:numframes(i);
        T(1:numframes(i),1)=Tgroup(i,1);
        T(1:numframes(i),2)=Tgroup(i,2);
        m = circshift(old{i}.m,Tgroup(i,:));
        save(alignfile,'m','T','idx');
    end
end