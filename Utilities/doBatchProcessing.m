%%Generalized Batch Processing Script 5/30/2019

%%optional: hardcode datatype, path, and file names
typestr = getdatatypes; %run getdatatypes to see options for datatype
datatype = '';
fpath = '';
fnames = {''};

%%settings - adjust as desired based on your preliminary image analysis
%alignment settings, note: only do AlignMeanImages_MWLab.m if all the images are of the same field-of-view/magnification/etc.
bAlignFiles = true; %align image frames within each file (see AlignImages_MWLab.m)
bAlignMeanFiles= false; %align mean images across all files (see AlignMeanImages_MWLab.m)

%time series settings
bComputeTSdata = false; %compute ROI timeseries data if ROIs file is available
roispath = ''; %path of rois file (optional) - you will select rois file if bComputeTSdata = true and this is empty
roisfile = ''; %name of rois file (optional) - you will select rois file if bComputeTSdata = true and this is empty

%difference maps settings
bMakeMaps = false; %make difference maps data struct (MapsData - see MapsAnalysis for more info)
auxtypes = getauxtypes; %run getauxtypes to see options for stim2use
MapsData.stim2use = auxtypes{1}; %'Aux1(odor)','Aux2(sniff)', 'AuxCombo(sniff w/odor)', or 'Define Stimulus Manually'
if strcmp(MapsData.stim2use,auxtypes{3}) %AuxCombo(sniff w/odor): odor duration(secs) 
    odorDuration = 4; %(technically this is only needed for aux1 signal without odor duration. But I made it required here so you can use any odorDuration)
elseif strcmp(MapsData.stim2use,auxtypes{4}) %Define Stimulus Manually
    delay = 4; duration = 4; interval = 36; maxtrials = 50; %maxtrials typically does not exceed 12 for odor trials
    %the defineStimulus program will figure out exactly how many trials based on the file length,frameRate, and parameters
end
MapsData.basetimes = [-3.0 0.0]; %pre-stimulus times for baseline images
MapsData.resptimes = [0.0 3.0]; %post-stimulus times for response images

%%start
%get datatype
if isempty(datatype)
    [typeval,ok]= listdlg('PromptString','Select Data Type','SelectionMode','single','ListString',...
        typestr);
    if ok == 0; return; end; clear ok;
    datatype = typestr{typeval}; clear typeval;
end

%get pathname & filenames
if isempty(fpath) || isempty(fnames{1})
    switch datatype
        case typestr{1} %scanimage
            ext = {'*.tif;*.dat','Scanimage Files';'*.*','All Files'};
            [fnames, fpath, ok] = uigetfile(ext, 'Select data file(s)', fpath, 'MultiSelect', 'On');
        case typestr{2} %'scanbox'
            ext = '.sbx';
            [fnames, fpath, ok] = uigetfile(ext, 'Select data file(s)', fpath, 'MultiSelect', 'On');
        case typestr{3} %'prairie'
            ext = '.xml'; %might try using uigetfolder for multiple files
            [fnames, fpath, ok] = uigetfile(ext, 'Select data file(s)', fpath, 'MultiSelect', 'Off');
        case typestr{4} %'neuroplex'
            ext = '.da';
            [fnames, fpath, ok] = uigetfile(ext, 'Select data file(s)', fpath, 'MultiSelect', 'On');
        case typestr{5} %'tif'
            ext = '.tif';
            [fnames, fpath, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'On');
    end
    if ok == 0; return; end; clear ok ext;
    if ~iscell(fnames)
        tmpname=fnames; clear fnames;
        fnames{1}=tmpname;
    end
end
if strcmp(datatype,typestr{4}) %neuroplex, get bnc map
    aux2bncmap = assignNeuroplexBNC;
end

%load rois file  - this is used for all files (could put it in loop and have different rois for each file)
if bComputeTSdata || ~isempty(roisfile) %need rois for time series
    if isempty(roisfile)
        [roisfile,roispath] = uigetfile('*.roi','Select ROI file name', fullfile(fpath, 'ROIs'));
    end
    rois = loadROIs(roispath,roisfile); %results saved/updated in .align file
    if isempty(rois); disp('error: no rois found'); return; end
else
    rois = [];
end

%image alignment, note: if only bAlignFiles is true, do it inside loop so files are only loaded once
if bAlignFiles && bAlignMeanFiles
    %%%%%%MW added to allow specifying start frames for aligning
     answer = inputdlg('Enter start frame for alignment','start frame',1,{'10'});
        if isempty(answer); return; end
        startframe = str2double(answer); %frameRate(sec)            
     %%%%%%%%%%%%%%%%%%%%%%%%   
    disp('Aligning Image Files');
    tmpbar = waitbar(0,'Aligning Image Files');
    for f = 1:numel(fnames)
        waitbar(f/numel(fnames),tmpbar);
        %delete any old alignment files
        iDot = strfind(fnames{f},'.'); alignfile = fullfile(fpath,[fnames{f}(1:iDot) 'align']);
        if exist(alignfile,'file')==2; delete(alignfile); end; clear iDot alignfile;
        if strcmp(datatype,typestr{4}) %'neuroplex'
            tmpdata = loadFile_MWLab(datatype,fpath,fnames{f},aux2bncmap);
        else
            tmpdata = loadFile_MWLab(datatype,fpath,fnames{f});
        end
        idx=1:tmpdata.frames;
        alignImage_MWLab(tmpdata,idx(startframe:end)); %results saved in .align file
        clear tmpdata;
    end
    close(tmpbar);
end

%mean image alignment
if bAlignMeanFiles
    disp('Aligning Files using Mean Images');
    tmpbar = waitbar(0,'Aligning Mean Images');
    if strcmp(datatype,typestr{4})
        alignMeanImages_MWLab(datatype,fpath,fnames,aux2bncmap);
    else
        alignMeanImages_MWLab(datatype,fpath,fnames);
    end
    close(tmpbar);
end

%main data processing
 %%%%%%MW added to allow specifying start frames for aligning
        answer = inputdlg('Enter start frame for alignment','start frame',1,{'1'});
        if isempty(answer); return; end
        startframe = str2double(answer); %frameRate(sec)            
 %%%%%%%%%%%%%%%%%%%%%%%%   

ff = 0; %keep track of files with two-channels
tmpbar = waitbar(0,'Processing Data Files');
for f = 1:numel(fnames)
    fprintf('Processing data file: %s\n',fnames{f});
    waitbar(f/numel(fnames),tmpbar);
    if strcmp(datatype,typestr{4}) %'neuroplex'
        tmpdata = loadFile_MWLab(datatype,fpath,fnames{f},aux2bncmap);
    else
        tmpdata = loadFile_MWLab(datatype,fpath,fnames{f});
    end
    idx=1:tmpdata.frames;  %MW added june 2023
    if iscell(tmpdata.im); ff=ff+2; else; ff=ff+1; end
    %apply alignments if .align file exists
    iDot = strfind(tmpdata.name,'.'); if isempty(iDot); iDot=length(tmpdata.name); end
    alignfile = fullfile(tmpdata.dir,[tmpdata.name(1:iDot) 'align']);
    if bAlignFiles && ~bAlignMeanFiles %in this case we do alignment inside processing loop
        disp('Aligning Image File');
        %delete old alignment files
        if exist(alignfile,'file')==2; delete(alignfile); end;
        [tmpdata,~,~] = alignImage_MWLab(tmpdata,idx(startframe:end)); %results saved in .align file
        
%        outputs: varargout{1} = aligned image
%                varargout{2} = (m) mean aligned image
%                varargout{3} = (T) frame shifts matrix (1:frames, [rowshift, colshift])
%      example: [newim, m, T] = alignImage_MWLab(oldim)

        tmpdata.name = [tmpdata.name(1:iDot-1) '_aligned' tmpdata.name(iDot:end)];
    elseif exist(alignfile,'file')==2 %apply any alignments done previously
        tmp = load(alignfile,'-mat');
        %apply shifts
        for i = 1:length(tmp.idx)
            if iscell(tmpdata.im)
                tmpdata.im{1}(:,:,tmp.idx(i)) = circshift(tmpdata.im{1}(:,:,tmp.idx(i)),tmp.T(i,:));
                tmpdata.im{2}(:,:,tmp.idx(i)) = circshift(tmpdata.im{2}(:,:,tmp.idx(i)),tmp.T(i,:));
            else
                tmpdata.im(:,:,tmp.idx(i)) = circshift(tmpdata.im(:,:,tmp.idx(i)),tmp.T(i,:));
            end
        end
        tmpdata.isAligned = 1; clear tmp;
        tmpdata.name = [tmpdata.name(1:iDot-1) '_aligned' tmpdata.name(iDot:end)];
        clear i;
    end
    clear iDot alignfile;
    %compute time series (TSdata)
    if bComputeTSdata
        TSdata.roi = rois;
        if iscell(tmpdata.im)
            TSdata.file(ff-1).type = tmpdata.type; TSdata.file(ff).type = tmpdata.type;
            TSdata.file(ff-1).size = tmpdata.size; TSdata.file(ff).size = tmpdata.size;
            TSdata.file(ff-1).frames = tmpdata.frames; TSdata.file(ff).frames = tmpdata.frames;
            TSdata.file(ff-1).frameRate = tmpdata.frameRate; TSdata.file(ff).frameRate = tmpdata.frameRate;
            TSdata.file(ff-1).dir = tmpdata.dir; tmpdata.file(ff).dir= tmpdata.dir;
            iDot = strfind(tmpdata.name,'.');
            TSdata.file(ff-1).name = [tmpdata.name(1:iDot-1) '_ch1' tmpdata.name(iDot:end)];
            TSdata.file(ff).name = [tmpdata.name(1:iDot-1) '_ch2' tmpdata.name(iDot:end)];
            if isfield(tmpdata,'aux1') && ~isempty(tmpdata.aux1); TSdata.file(ff-1).aux1 = tmpdata.aux1; TSdata.file(ff).aux1 = tmpdata.aux1; end
            if isfield(tmpdata,'aux2') && ~isempty(tmpdata.aux2); TSdata.file(ff-1).aux2 = tmpdata.aux2; TSdata.file(ff).aux2 = tmpdata.aux2; end
            if isfield(tmpdata,'aux3') && ~isempty(tmpdata.aux3); TSdata.file(ff-1).aux3 = tmpdata.aux3; TSdata.file(ff).aux3 = tmpdata.aux3; end
            if isfield(tmpdata,'ephys') && ~isempty(tmpdata.ephys); TSdata.file(ff-1).ephys = tmpdata.ephys; TSdata.file(ff).ephys = tmpdata.ephys; end
            TSdata.file(ff-1).roi = []; TSdata.file(ff).roi = [];
            
            tmpTSdata.file = TSdata.file(ff-1:ff);
            tmpTSdata.file(1).im = tmpdata.im{1}; tmpTSdata.file(2).im = tmpdata.im{2};
            tmpTSdata = computeTimeSeries(tmpTSdata,TSdata.roi);
            tmpTSdata.file = rmfield(tmpTSdata.file,'im');
            TSdata.file(ff-1:ff) = tmpTSdata.file;
            clear tmpTSdata;
        else
            TSdata.file(ff).type = tmpdata.type;
            TSdata.file(ff).size = tmpdata.size;
            TSdata.file(ff).frames = tmpdata.frames;
            TSdata.file(ff).frameRate = tmpdata.frameRate;
            TSdata.file(ff).dir = tmpdata.dir;
            TSdata.file(ff).name = tmpdata.name;
            if isfield(tmpdata,'aux1') && ~isempty(tmpdata.aux1); TSdata.file(ff).aux1 = tmpdata.aux1; end
            if isfield(tmpdata,'aux2') && ~isempty(tmpdata.aux2); TSdata.file(ff).aux2 = tmpdata.aux2; end
            if isfield(tmpdata,'aux3') && ~isempty(tmpdata.aux3); TSdata.file(ff).aux3 = tmpdata.aux3; end
            if isfield(tmpdata,'ephys') && ~isempty(tmpdata.ephys); TSdata.file(ff).ephys = tmpdata.ephys; end
            TSdata.file(ff).roi = [];
            
            tmpTSdata.file = TSdata.file(ff);
            tmpTSdata.file.im = tmpdata.im;
            tmpTSdata = computeTimeSeries(tmpTSdata,TSdata.roi);
            tmpTSdata.file = rmfield(tmpTSdata.file,'im');
            TSdata.file(ff) = tmpTSdata.file;
            clear tmpTSdata;
        end
    end
    %make difference maps
    if bMakeMaps
        MapsData.roi = rois;
        if strcmp(MapsData.stim2use,auxtypes{3}) %AuxCombo(sniff w/odor)
            tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2,odorDuration);
            MapsData.odorDuration = odorDuration;
        elseif strcmp(MapsData.stim2use,auxtypes{4}) %manually defined stimulus
            startT = 0; endT = tmpdata.frames/tmpdata.frameRate; deltaT = 1/150; %150Hz aux signal
            tmpdata.def_stimulus = defineStimulus(startT,endT,deltaT,delay,duration,interval,maxtrials);
            MapsData.def_stimulus= tmpdata.def_stimulus;
        end
        if iscell(tmpdata.im)
            iDot = strfind(tmpdata.name,'.');
            %channel 1
            MapsData.file(ff-1).type = tmpdata.type;
            MapsData.file(ff-1).name = [tmpdata.name(1:iDot-1) '_ch1' tmpdata.name(iDot:end)];
            MapsData.file(ff-1).dir = tmpdata.dir;
            MapsData.file(ff-1).size = tmpdata.size;
            MapsData.file(ff-1).frameRate = tmpdata.frameRate; MapsData.file(ff-1).frames = size(tmpdata.im{1},3);
            MapsData.file(ff-1).odors = []; MapsData.file(ff-1).odor = [];
            tmpdata1 = rmfield(tmpdata,'im'); tmpdata1.im = tmpdata.im{1};
            tmpMaps = makeMaps(tmpdata1, MapsData.stim2use, MapsData.basetimes, MapsData.resptimes);
            MapsData.file(ff-1).odors = tmpMaps.file.odors; MapsData.file(ff-1).odor = tmpMaps.file.odor;
            clear tmpdata1 tmpMaps;
            %channel 2
            MapsData.file(ff).type = tmpdata.type;
            MapsData.file(ff).name = [tmpdata.name(1:iDot-1) '_ch2' tmpdata.name(iDot:end)];
            MapsData.file(ff).dir = tmpdata.dir;
            MapsData.file(ff).size = tmpdata.size;
            MapsData.file(ff).frameRate = tmpdata.frameRate; MapsData.file(ff).frames = size(tmpdata.im{2},3);
            MapsData.file(ff).odors = []; MapsData.file(ff).odor = [];
            tmpdata2 = rmfield(tmpdata,'im'); tmpdata2.im = tmpdata.im{2};
            tmpMaps = makeMaps(tmpdata2, MapsData.stim2use, MapsData.basetimes, MapsData.resptimes);
            MapsData.file(ff).odors = tmpMaps.file.odors; MapsData.file(ff).odor = tmpMaps.file.odor;
            clear tmpdata2 tmpMaps;
        else
            MapsData.file(ff).type = tmpdata.type;
            MapsData.file(ff).name = tmpdata.name;
            MapsData.file(ff).dir = tmpdata.dir;
            MapsData.file(ff).size = tmpdata.size;
            MapsData.file(ff).frameRate = tmpdata.frameRate; MapsData.file(ff).frames = size(tmpdata.im,3);
            MapsData.file(ff).odors = []; MapsData.file(ff).odor = [];
            tmpMaps = makeMaps(tmpdata, MapsData.stim2use, MapsData.basetimes, MapsData.resptimes);
            MapsData.file(ff).odors = tmpMaps.file.odors; MapsData.file(ff).odor = tmpMaps.file.odor;
            clear tmpMaps;
        end
    end
    clear tmpdata;
end
close(tmpbar); clear tmpbar;

if bComputeTSdata
    TimeSeriesAnalysis_MWLab(TSdata);
%     [tsfn,tspath,ok] = uiputfile('*.mat','Select Time Series Data file name', 'myTSdata.mat');
%     if ~ok; return; end
%     save(fullfile(tspath, tsfn), 'TSdata')
end
if bMakeMaps
    MapsAnalysis_MWLab(MapsData);
%     [mapsfn,mapspath,ok] = uiputfile('*.mat','Select MapsData file name', 'myMapsData.mat');
%     if ~ok; return; end
%     save(fullfile(mapspath, mapsfn), 'MapsData')
end
clear f ff;
clear typestr datatype fpath fnames rois;
clear bAlignFiles bAlignMeanFiles bComputeTSdata;
clear roispath roisfile bMakeMaps auxtypes aux2bncmap;