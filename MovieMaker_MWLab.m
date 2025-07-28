function hMM = MovieMaker_MWLab(varargin)
% movieMaker_MWLab(varargin)
% This program is for viewing and making .avi movies
tmppath=which('movieMaker_MWLab');
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
guiname = [pathparts{end} '/' guiname];

prev = findobj('Name',guiname);
if ~isempty(prev); close(prev); end

MMdata = []; allOdorTrials = [];
%typestr = {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};
typestr = getdatatypes;
% auxstr = {'Aux1(odor)','Aux2(Sniff)','AuxCombo','Defined Stimulus','-Select Stimulus-'};
auxstr = [getauxtypes' '-Select Stimulus-'];
defaultNumFrames = 250; %this helps prevent accidental processing and preview of full-length data files

%load previous settings file
try
    load(fullfile(guipath,'MMsettings.mat'),'-mat','MMsettings');
catch
end
if ~exist('MMsettings','var')
    MMsettings.oldpath = '';
    MMsettings.cmapval = 1;
    MMsettings.lpfiltstr = '0.75';
    MMsettings.delaystr = '4'; MMsettings.durstr = '8'; MMsettings.intstr = '32'; MMsettings.trialstr = '8';
    MMsettings.prestimstr = '4.0'; MMsettings.poststimstr = '8.0';
    MMsettings.FOstartstr = '0'; MMsettings.FOendstr = '4';
    MMsettings.fMaskstr = '0';  
end



%figure setup
Width = 796; Height = 512;
hFig_Movie = figure('NumberTitle','off','Name',guiname,'position',[100 100 Width Height], ...
    'CloseRequestFcn',@CB_CloseFig,'Color',[0.5 0.5 0.5]);
hAx_Movie = axes(hFig_Movie,'Units','pixels','Position',[0 0 Width Height],'Visible','off');
%controls
BGC = [204 255 153]./255;
hMM = figure('NumberTitle','off','Name','MWLab Movie Controls','Units',...
    'Pixels','Position',[100 Height+185 Width 250],'Color',BGC,'CloseRequestFcn',@CB_CloseFig);

%LoadFile
uicontrol(hMM,'Tag','LoadImageFile','Style','pushbutton','String','Load Image File','Units',...
    'Normalized','Position',[0.01 0.89 0.3 0.1],'Callback',@CBLoad);
hName = uicontrol(hMM,'Tag','Filename','Style','text','String','','Units',...
    'Normalized','Position',[0.32 0.89 0.67 0.1]);
%Colormap
cmapstrings = getcmaps;
uicontrol(hMM,'Tag','ColormapLabel', 'Style', 'text', 'String', 'Colormap: ','Units','normalized', ...
    'Position',[0.01 0.75 0.1 0.08],'BackgroundColor',BGC);
hCMAP = uicontrol(hMM,'Tag','Colormap','Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [0.1 0.75 0.1 0.1], 'String', cmapstrings,'Callback', @CBcmap, 'Value', MMsettings.cmapval,'FontSize',10);
%Cmin/Cmax
hCAxisAuto = uicontrol(hMM,'Tag','AutoCaxis','Style','checkbox','String','Auto Caxis (0.02-99.8%)',...
    'BackgroundColor',BGC, 'Units','normalized','Position',[0.02 0.64 0.19 0.1], 'Value', 1, 'Callback', @CBcaxis);
uicontrol(hMM,'Style', 'text', 'String', 'Cmin: ','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.01 0.55 0.05 0.08],'HorizontalAlignment','Right');
hCmin = uicontrol(hMM,'Style', 'edit', 'String', '0','Units','normalized',...
    'BackgroundColor',[1 1 1],'Position',[0.06 0.56 0.05 0.08],'HorizontalAlignment','Right', ...
    'Callback',@CBcaxis, 'Enable', 'Off');
hMin = uicontrol(hMM,'Style', 'text', 'String', '(0)','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.115 0.55 0.07 0.08],'HorizontalAlignment','Left');
uicontrol(hMM,'Style', 'text', 'String', 'Cmax: ','Units','normalized',...
    'BackgroundColor',BGC,'Position',[0.16 0.55 0.05 0.08],'HorizontalAlignment','Right');
hCmax = uicontrol(hMM, 'Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.21 0.56 0.06 0.08],'HorizontalAlignment','Right', ...
    'Callback',@CBcaxis, 'Enable', 'Off');
hMax = uicontrol(hMM, 'Style', 'text', 'String', '(1)','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.275 0.55 0.07 0.08],'HorizontalAlignment','Left');  
hDF_CminLabel = uicontrol(hMM,'Style', 'text', 'String', 'dF/F Cmin: ','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.01 0.45 0.07 0.08],'HorizontalAlignment','Right', ...
    'Visible', 'Off');
hDF_Cmin = uicontrol(hMM,'Style', 'edit', 'String', '0','Units','normalized',...
    'BackgroundColor',[1 1 1],'Position',[0.08 0.46 0.06 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CBcaxis, 'Enable','off', 'Visible', 'Off');
hDF_CmaxLabel = uicontrol(hMM,'Style', 'text', 'String', 'dF/F Cmax: ','Units','normalized',...
    'BackgroundColor',BGC,'Position',[0.15 0.45 0.08 0.08],'HorizontalAlignment','Right', ...
    'Visible', 'Off');
hDF_Cmax = uicontrol(hMM,'Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.23 0.46 0.06 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CBcaxis, 'Enable', 'off', 'Visible', 'Off');

%Spatial Filter
hLPFROI = uicontrol(hMM,'Tag','FilterbyROI','Style', 'checkbox', 'Value', 0,'Units','normalized', ...
    'Position',[0.02 0.44 0.19 0.1],'Callback', @CB_LPF, 'BackgroundColor', BGC, 'String', 'Filter ROIs only?');
hLPF = uicontrol(hMM,'Tag','Filter','Style', 'checkbox', 'Value', 0,'Units','normalized', ...
    'Position',[0.02 0.34 0.19 0.1],'Callback', @CB_LPF, 'BackgroundColor', BGC, 'String', 'Spatial Filter (2D Gauss) @');
hLPFradius = uicontrol(hMM,'Tag','FilterRadius', 'Style', 'edit', 'String',MMsettings.lpfiltstr,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.21 0.35 0.05 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CB_LPF);
uicontrol(hMM,'Style', 'text', 'String', 'pixels','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.265 0.34 0.05 0.08],'HorizontalAlignment','Left');
%Stimulus Options
hAux = uicontrol(hMM,'Tag','Aux','Style','popupmenu','String',auxstr, 'Value', numel(auxstr), ...
    'Units','Normalized', 'Position', [0.02 0.22 0.23 0.1],'Callback', @CBSelectStimulus);
%tcrtcr set visibility here?
othervisible = 'off'; durvisible = 'off';
hDelay = uicontrol(hMM,'Style', 'edit', 'String', MMsettings.delaystr,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.02 0.12 0.04 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CBSelectStimulus,'Visible',othervisible);
hDelayLabel = uicontrol(hMM,'Style', 'text', 'String', 'Initial Delay(sec)','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.06 0.1 0.12 0.1],'HorizontalAlignment','Left','Visible',othervisible);
hDuration = uicontrol(hMM,'Style', 'edit', 'String', MMsettings.durstr,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.02 0.02 0.04 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CBSelectStimulus,'Visible',durvisible);
hDurationLabel = uicontrol(hMM,'Style', 'text', 'String', 'Duration(sec)','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.06 0.01 0.12 0.08],'HorizontalAlignment','Left','Visible',durvisible);
hInterval = uicontrol(hMM,'Style', 'edit', 'String', MMsettings.intstr,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.18 0.12 0.04 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CBSelectStimulus,'Visible',othervisible);
hIntervalLabel = uicontrol(hMM,'Style', 'text', 'String', 'Interval(sec)','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.22 0.1 0.15 0.1],'HorizontalAlignment','Left','Visible',othervisible);
hTrials = uicontrol(hMM,'Style', 'edit', 'String', MMsettings.trialstr,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.18 0.02 0.04 0.08],'HorizontalAlignment','Right', ...
    'Callback', @CBSelectStimulus,'Visible',othervisible);
hTrialsLabel = uicontrol(hMM,'Style', 'text', 'String', '# Trials','Units','normalized' ...
    ,'BackgroundColor',BGC,'Position',[0.22 0.01 0.15 0.08],'HorizontalAlignment','Left','Visible',othervisible);

%Load ROIs
uicontrol(hMM,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.33 0.74 0.2 0.12],...
    'String', 'Load ROIs File','Callback', @CBloadROIs);
hRoiList = uicontrol(hMM,'Style','listbox','Units','normalized','Position',[0.331 0.24 0.2 0.5],...
    'Value', 1,'BackgroundColor',[1 1 1],'Max', 100,'Min',1,'FontSize',10,'Callback',@CBTSPlot);
hRoiOverlay = uicontrol(hMM,'Style','checkbox','String','Show ROI(s) Overlay','BackgroundColor',BGC,...
    'Units','Normalized','Position',[0.351 0.13 0.16 0.1],'Callback',@CBRoiOverlay,'Enable','off');
hTSPlot = uicontrol(hMM,'Style','checkbox','String','Show TimeSeries Plot','BackgroundColor',BGC,...
    'Units','Normalized','Position',[0.351 0.03 0.16 0.1],'Callback',@CBTSPlot,'Enable','off');

%Average Trials Movie
hAvgTrials = uicontrol(hMM,'Style','checkbox','String','Average Trials Movie',...
    'BackgroundColor',BGC,'Units','Normalized','Position',[0.57 0.74 0.18 0.12], ...
    'Callback',@CBAvgTrials,'Enable','off');
if ismember(hAux.Value,[1 2 3 4]); hAvgTrials.Enable = 'on'; end
hTrialsList = uicontrol(hMM,'Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [0.551 0.24 0.2 0.5], 'Value', 1, 'BackgroundColor', [1 1 1], 'Max', 100,'Min', 0, 'FontSize',10);
uicontrol(hMM,'Style','text','String','Pre-Stimulus time(sec):','BackgroundColor',BGC,...
    'Units','normalized','Position',[0.545 0.11 0.155 0.1]);
hPreStim = uicontrol(hMM,'Style','edit','String',MMsettings.prestimstr,'Units','normalized',...
    'Position',[0.7 0.12 0.05 0.1],'Callback',@CBSelectStimulus);
uicontrol(hMM,'Style','text','String','Post-Stimulus time(sec):','BackgroundColor',BGC,...
    'Units','normalized','Position',[0.545 0.01 0.155 0.1]);
hPostStim = uicontrol(hMM,'Style','edit','String',MMsettings.poststimstr,'Units','normalized',...
    'Position',[0.7 0.02 0.05 0.1],'Callback',@CBSelectStimulus);

%deltaF/FO settings
movietypestr = {'Raw Fluorescence','DeltaF/F0','Overlay DeltaF/FO'};
hMovieType = uicontrol(hMM,'Tag','MovieType','Style','popupmenu','String',movietypestr,...
    'Units','Normalized','Position',[0.78 0.74 0.2 0.12],'Callback',@CBMovieType,'Value',1);
hFO_startLabel = uicontrol(hMM,'Style','text','String','F0 window (sec):','Units','normalized','Position',...
    [0.77 0.64 0.12 0.08],'BackgroundColor',BGC,'Visible','off');
hFO_start = uicontrol(hMM,'Style','edit','Units','normalized','Position',[0.89 0.65 0.04 0.08],...
    'String',MMsettings.FOstartstr,'Visible','off');
hFO_endLabel = uicontrol(hMM,'Style','text','String','to' ,'Units','Normalized','Position',...
    [0.93 0.64 0.02 0.08],'BackgroundColor',BGC,'Visible','off');
hFO_end = uicontrol(hMM,'Style','edit','Units','normalized','Position',[0.95 0.65 0.04 0.08],...
    'String',MMsettings.FOendstr,'Visible','off');
hfMask_label = uicontrol(hMM,'Tag','fmasklabel','Style','text','Units','normalized','Position',...
    [0.77 0.54 0.05 0.07], 'String', 'F mask:','BackgroundColor',BGC,'Visible','off');
hfMask_slider = uicontrol(hMM,'Tag','fmaskslider','Style','Slider','Units','Normalized','Position',...
    [0.82 0.54 0.12 0.08],'Callback',@CBsetFmask,'Visible','off');
hfMask_edit = uicontrol(hMM,'Tag','fmaskedit', 'Style', 'edit', 'Units', 'normalized', 'Position', ...
    [0.95 0.54 0.04 0.08], 'String', MMsettings.fMaskstr, 'Callback',@CBsetFmask,'Visible','off');

%Overlay Thresholding, Cmin/Cmax Options
overlaystr = 'Enter % or value and the other will update automatically. Enter a negative value to compute bottom % and show suppression';
hOverlayLabel_1 = uicontrol(hMM,'Style','text','String','Overlay:','Units','normalized','Position',...
    [0.76 0.41 0.06 0.08],'BackgroundColor',BGC,'tooltipstring',overlaystr,'Visible','off');
hOverlayPct = uicontrol(hMM,'Tag','OverlayPct','Style','edit','Units','normalized','Position',[0.82 0.43 0.04 0.08],...
    'String','2.0','Callback',@CBoverlay,'Visible','off');
hOverlayLabel_2 = uicontrol(hMM,'Style','text','String','(%)','Units','normalized','Position',...
    [0.86 0.41 0.03 0.08],'BackgroundColor',BGC,'tooltipstring',overlaystr,'Visible','off');
hOverlayVal = uicontrol(hMM,'Tag','OverlayVal','Style','edit','Units','normalized','Position',[0.89 0.43 0.05 0.08],...
    'String','0.0','Callback',@CBoverlay,'Visible','off');
hOverlayLabel_3 = uicontrol(hMM,'Style','text','String','(value)','Units','normalized','Position',...
    [0.94 0.41 0.05 0.08],'BackgroundColor',BGC,'tooltipstring',overlaystr,'Visible','off');

uicontrol(hMM,'Style','text','String','--------------------------------------',...
    'Units','Normalized','Position',[0.765 0.38 0.22 0.05],'BackgroundColor',BGC);
%choose frames, preview, save
uicontrol(hMM,'Style','text','String','Frames:','Units','Normalized',...
    'BackgroundColor',BGC,'Position',[0.76 0.28 0.07 0.08]);
hStartF = uicontrol(hMM,'Style','edit','String','0','Units','Normalized',...
    'Position',[0.825 0.29 0.04 0.08]);
uicontrol(hMM,'Style','text','String','to','Units','Normalized',...
    'BackgroundColor',BGC,'Position',[0.87 0.28 0.02 0.08]);
hEndF = uicontrol(hMM,'Style','edit','String','0','Units','Normalized',...
    'Position',[0.89 0.29 0.04 0.08]);
hLastF = uicontrol(hMM,'Style','text','String','of 0','Units','Normalized',...
    'BackgroundColor',BGC,'HorizontalAlignment','left','Position',[0.935 0.28 0.05 0.08]);
hSlider = uicontrol(hMM,'Style','slider','Units','Normalized','Position',[0.765 0.21 0.22 0.05],...
    'Callback',@CBrefreshImage);
%Preview/Save
uicontrol(hMM,'Style','pushbutton','String','Preview','Units',...
    'Normalized','Position',[0.76 0.02 0.11 0.15],'Callback',@CBPreviewSave);    
uicontrol(hMM,'Style','pushbutton','String','Save','Units',...
    'Normalized','Position',[0.88 0.02 0.11 0.15],'Callback',@CBPreviewSave);   

%%
if nargin > 0
    tmpdata = varargin{1};
    MMdata.file = tmpdata.file;
    hName.String = fullfile(MMdata.file.dir,MMdata.file.name);
    [Height,Width,Frames] = size(MMdata.file.im);
    FrameRate = MMdata.file.frameRate;
    bLoadNow = 1; clear tmpdata;
    CBLoad;
else
    bLoadNow = 0;
end
hMM.UserData = MMdata;
%%
function CB_CloseFig(~,~)
    MMsettings.cmapval = hCMAP.Value;
    MMsettings.lpfiltstr = hLPFradius.String;
    MMsettings.delaystr = hDelay.String;
    MMsettings.durstr = hDuration.String;
    MMsettings.intstr = hInterval.String;
    MMsettings.trialstr = hTrials.String;
    MMsettings.prestimstr = hPreStim.String;
    MMsettings.poststimstr = hPostStim.String;
    MMsettings.FOstartstr = hFO_start.String;
    MMsettings.FOendstr = hFO_end.String;
    MMsettings.fMaskstr = hfMask_edit.String;
    save(fullfile(guipath,'MMsettings.mat'),'MMsettings');
    clear MMsettings;
    
    delete(hMM);
    delete(hFig_Movie);
%     clearvars -global hMM;
end
function CBLoad(~,~)
    if bLoadNow
        bLoadNow = 0;
    else
        [typeval,ok]= listdlg('PromptString','Select Data Type','SelectionMode','single','ListString',typestr);
        if ~ok; return; end
        type = typestr{typeval};
        pathname = MMsettings.oldpath;
        switch type
            case 'scanimage' %ScanImage .tif (aka MWScope)
                ext = {'*.tif;*.dat','Scanimage Files';'*.*','All Files'};
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
            case 'scanbox'
                ext = '.sbx';
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
            case 'prairie'
                ext = '.xml'; %might try using uigetfolder for multiple files
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
            case 'neuroplex'
                ext = {'*.da;*.tsm','Neuroplex Files'};
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
            case 'tif' %Standard .tif
                ext = '.tif';
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'Off');
        end
        if ok == 0; return; end
        if isfield(MMdata,'file'); MMdata=rmfield(MMdata,'file'); end
        MMdata.file = loadFile_MWLab(type,pathname,filename);
        MMsettings.oldpath = MMdata.file.dir;
        dot = strfind(MMdata.file.name,'.');
        alignfile = fullfile(MMdata.file.dir,[MMdata.file.name(1:dot) 'align']);
        use = 'No';
        if exist(alignfile,'file')==2
            use = questdlg('An alignment (.align) file found, Would you like to use it?','Align file','Yes','No','Yes');
        end
        if iscell(MMdata.file.im)
            channel = questdlg('Two-channel data, choose a channel:','Two-Channel Data','channel 1','channel 2','channel1');
            if strcmp(channel,'channel 1')
                tmpim = MMdata.file.im{1}; MMdata.file = rmfield(MMdata.file,'im'); MMdata.file.im = tmpim; clear tmpim;
                dot = strfind(MMdata.file.name,'.');
                MMdata.file.name = [MMdata.file.name(1:dot-1) '_ch1' MMdata.file.name(dot:end)];
            elseif strcmp(channel,'channel 2')
                tmpim = MMdata.file.im{2}; MMdata.file = rmfield(MMdata.file,'im'); MMdata.file.im = tmpim;
                dot = strfind(MMdata.file.name,'.');
                MMdata.file.name = [MMdata.file.name(1:dot-1) '_ch2' MMdata.file.name(dot:end)];
            else; MMdata.file = []; return;
            end
        end
        if strcmp(use,'Yes')
            tmp = load(alignfile,'-mat');
            T = tmp.T; idx = tmp.idx;
            %apply shifts
            for f = 1:length(idx)
                MMdata.file.im(:,:,idx(f)) = circshift(MMdata.file.im(:,:,idx(f)),T(f,:));
            end
            MMdata.file.name = [MMdata.file.name(1:dot-1) '_aligned' MMdata.file.name(dot:end)]; %oddly, this is done before _ch#
        end
        hName.String = fullfile(MMdata.file.dir,MMdata.file.name);
        [Height,Width,Frames] = size(MMdata.file.im);
        FrameRate = MMdata.file.frameRate;
    end
    %reset controls
    hFig_Movie.Position = [100 100 Width Height];
    hAx_Movie.Position = [0 0 Width Height];
    hCAxisAuto.Value = 1; hLPF.Value = 0;
    hAux.Value = numel(auxstr); othervisible = 'off'; durvisible = 'off';
    hRoiOverlay.Value = 0; hTSPlot.Value = 0;
    hAvgTrials.Value = 0; hAvgTrials.Enable = 'off';
    hTrialsList.String = ''; hTrialsList.Max = 100;
    hMovieType.Value = 1;
    hStartF.String = '1'; hLastF.String = num2str(Frames);
    hEndF.String = num2str(min(defaultNumFrames,Frames)); %num2str(Frames);
    hSlider.Max = min(defaultNumFrames,Frames); hSlider.Value = 1; hSlider.Min = 1;
    hSlider.SliderStep = [1 10]./(hSlider.Max-hSlider.Min);
    CBMovieType;
    hMM.UserData = MMdata;
end
function CBcmap(~, ~) %change colormap
    if ismember(hMovieType.Value,[2 3])
        colormap(hAx_Movie, gray(256));
        val = get(hCMAP, 'Value');
        hAx_DeltaF = findobj(hFig_Movie,'Tag','DeltaF');
        colormap(hAx_DeltaF,[cmapstrings{val} '(256)']);
    else
        val = get(hCMAP, 'Value');
        colormap(hAx_Movie,[cmapstrings{val} '(256)']);
    end
end
function CBcaxis(~,~)
    if ~isfield(MMdata,'current') || isempty(MMdata.current); return; end
    hAx_DeltaF = findobj(hFig_Movie,'Tag','DeltaF');
    if hCAxisAuto.Value
        hCmin.Enable = 'Off';
        hCmax.Enable = 'Off';
        a = MMdata.currentPRCT; %computed in updateMovie and saved
        hCmin.String = sprintf('%d',round(a(1)));
        hCmax.String = sprintf('%d',round(a(2)));
        if ~isempty(hAx_DeltaF)
            hDF_Cmin.Enable = 'Off';
            hDF_Cmax.Enable = 'Off';
            b = MMdata.DF_PRCT; %computed in updateMovie and saved
            hDF_Cmin.String = sprintf('%.2f',b(1));
            hDF_Cmax.String = sprintf('%.2f',b(2));
        end
    else % manual cmin/cmax
        hCmin.Enable = 'On';
        hCmax.Enable = 'On';
        a(1) = str2double(hCmin.String);
        a(2) = str2double(hCmax.String);
        if ~isempty(hAx_DeltaF)
            hDF_Cmin.Enable = 'On';
            hDF_Cmax.Enable = 'On';
            b(1) = str2double(hDF_Cmin.String);
            b(2) = str2double(hDF_Cmax.String);
        end
    end
    hAx_Movie.CLim = [a(1) a(2)];
    if hMovieType.Value == 1
        val = get(hCMAP, 'Value');
        axes(hAx_Movie); colormap(hAx_Movie,[cmapstrings{val} '(256)']);
    else
        axes(hAx_Movie); colormap(hAx_Movie, gray(256))
    end
    if ~isempty(hAx_DeltaF)
        hAx_DeltaF.CLim = [b(1) b(2)];
        val = get(hCMAP, 'Value');
        axes(hAx_DeltaF); colormap(hAx_DeltaF,[cmapstrings{val} '(256)']);
    end
end

function CB_LPF(~,~)
    if isfield(MMdata,'current') && ~isempty(MMdata.current)
        updateMovie;
    end
end
function CBSelectStimulus(~,~)
    if hAux.Value == 1
        othervisible = 'off'; durvisible = 'off'; hAvgTrials.Enable = 'on';
    elseif hAux.Value == 2
        othervisible = 'off'; durvisible = 'off'; hAvgTrials.Enable = 'on';
    elseif hAux.Value == 3
        if isfield(MMdata,'file') && isfield(MMdata.file,'type') && strcmp(MMdata.file.type,'scanimage')
            othervisible = 'off'; durvisible = 'on'; hAvgTrials.Enable = 'on';
            odorDuration = str2double(hDuration.String);
            MMdata.file.aux_combo = doAuxCombo(MMdata.file.aux1,MMdata.file.aux2,odorDuration);
        else
            othervisible = 'off'; durvisible = 'off';
            if isfield(MMdata,'file'); MMdata.file.aux_combo = doAuxCombo(MMdata.file.aux1,MMdata.file.aux2); end
        end
    elseif hAux.Value == 4
        othervisible = 'on'; durvisible = 'on'; hAvgTrials.Enable = 'on';
        if isfield(MMdata,'file') && isfield(MMdata.file,'frameRate')
            delay = str2double(hDelay.String);
            duration = str2double(hDuration.String);
            interval = str2double(hInterval.String);
            trials = str2double(hTrials.String);
            trials = min(trials,floor((Frames/FrameRate-delay+interval)/(duration+interval)));
            hTrials.String = num2str(trials);
            endT = Frames/FrameRate;
            deltaT=1/150; %Note: Stimulus sampling rate is set at 150 Hz
            MMdata.file.def_stimulus = defineStimulus(0,endT,deltaT,delay,duration,interval,trials);
        end
    else % -select stimulus-
        othervisible = 'off'; durvisible = 'off'; hAvgTrials.Enable = 'off';
    end
    hDelay.Visible = othervisible; hDelayLabel.Visible = othervisible;
    hDuration.Visible = durvisible; hDurationLabel.Visible = durvisible;
    hInterval.Visible = othervisible; hIntervalLabel.Visible = othervisible;
    hTrials.Visible = othervisible; hTrialsLabel.Visible = othervisible;
    
    if ismember(hAux.Value, [1 2 3 4]) && isfield(MMdata,'current') && ~isempty(MMdata.current)
        %%%
        prestimtime = str2num(hPreStim.String);
        poststimtime = str2num(hPostStim.String);
        auxtype = auxstr{hAux.Value};
        [allOdorTrials] = getAllOdorTrials(auxtype,prestimtime,poststimtime,MMdata.file);
        cnt=0; trialstr = {};
        odors = allOdorTrials.odors;
        for o = 1:length(odors)
            trials = allOdorTrials.odor(o).trials;
            for t = trials
                cnt=cnt+1;
                trialstr{cnt} = ['Odor' num2str(odors(o)) 'Trial' num2str(t)];
            end
        end
        if isempty(trialstr)
            hAvgTrials.Value = 0; hAvgTrials.Enable = 'off';
            hTrialsList.String = ''; hTrialsList.Max = 100; 
        else
            hTrialsList.Max = length(trialstr);
            hTrialsList.Value = 1:length(trialstr);
            hTrialsList.String = trialstr;
        end
    else
        hAvgTrials.Value = 0;
        hTrialsList.String = ''; hTrialsList.Max = 100; %tcr why 100?
        if isfield(MMdata,'currentAux'); MMdata = rmfield(MMdata,'currentAux'); end
    end
    
    if hAvgTrials.Value
        updateMovie;
    else
        CBrefreshImage;
    end
end


function CBloadROIs(~,~)
    if ~isfield(MMdata,'current') || isempty(MMdata.current); return; end
    set(hRoiList,'String','');
    MMdata.roi = [];
    MMdata.roi = loadROIs(MMdata.file.dir);
    if ~isempty(MMdata.roi)
        if ~isequal([Height Width],size(MMdata.roi(1).mask))
            errordlg('New ROIs size does not match image size'); uiwait;
            MMdata = rmfield(MMdata,'roi'); return;
        end
        hRoiOverlay.Enable = 'on';
        hTSPlot.Enable = 'on';
    end
    %update rois listbox
    if isfield(MMdata,'roi') && ~isempty(MMdata.roi)    
        roistr = cell(numel(MMdata.roi),1);
        for i = 1:numel(MMdata.roi)
            tmpcl = myColors(i).*255;
            roistr{i} = ['<HTML><FONT color=rgb(' ...
                num2str(tmpcl(1)) ',' num2str(tmpcl(2)) ',' num2str(tmpcl(3)) ')>' ['ROI #' num2str(i)] '</Font></html>'];
        end
        hRoiList.String = roistr;
        hRoiList.Value = 1;
    else
        hRoiList.String = '';
    end
end

function CBRoiOverlay(~,~)
    if ismember(hMovieType.Value,[2 3])
        tmpax = findobj(hFig_Movie,'Tag','DeltaF');
    else
        tmpax = hAx_Movie;
    end
    axes(tmpax);
    hold(tmpax,'on');
    %delete old contour lines
    if ~isfield(MMdata,'roi') || isempty(MMdata.roi)
        return;
    else
        rois = hRoiList.Value;
        for r = 1:length(MMdata.roi)
            if isfield(MMdata.roi(r),'text')
                delete(MMdata.roi(r).text);
            end
            if isfield(MMdata.roi(r),'line')
                delete(MMdata.roi(r).line);
            end
        end
        if hRoiOverlay.Value
            for r = rois
                [ctemp,MMdata.roi(r).line] = contour(MMdata.roi(r).mask, 1, 'LineColor',myColors(r),'LineWidth',2);   
                MMdata.roi(r).text = text(mean(ctemp(1,:)),mean(ctemp(2,:)),['ROI # ' num2str(r)],...
                    'Color',myColors(r),'FontSize',14);
            end
        end
    end
    hold(tmpax,'off');
    hAx_light = findobj(hFig_Movie,'Tag','light');
    if ~isempty(hAx_light); axes(hAx_light); end
end
function CBTSPlot(~,~)
    if ~isfield(MMdata,'roi') || isempty(MMdata.roi); return; end
    hAx_TSPlot = findobj(hFig_Movie,'Tag','TSPlot');
    if ~isempty(hAx_TSPlot)
        delete(hAx_TSPlot);
    end
    if hTSPlot.Value
        %compute (using MMdata.current)
        tmpbar = waitbar(0,'Computing timeseries data');
        for r = 1:length(MMdata.roi)
            roiIndex{r} = find(MMdata.roi(r).mask>0.5);
            MMdata.roi(r).time = []; MMdata.roi(r).series = [];
        end
        tmpFrames = size(MMdata.current,3);
        for i = 1:tmpFrames
            waitbar(i/tmpFrames,tmpbar);
            if ismember(hMovieType.Value,[2 3])
                tmpframeim = MMdata.deltaF(:,:,i);
            else
                tmpframeim = MMdata.current(:,:,i);
            end
            for r = 1:length(MMdata.roi)
                MMdata.roi(r).time(1,i) = (i-1)/FrameRate;
                MMdata.roi(r).series(1,i) = mean(tmpframeim(roiIndex{r})); %compute mean value in ROI
            end
        end
        close(tmpbar);
        %plot
        hMM.Position = [100 Height+230 796 200];
        hFig_Movie.Position = [100 100 Width Height+50];
        hAx_Movie.Position = [0 0 Width Height];
        hAx_TSPlot = axes(hFig_Movie,'Units','pixels','Position',[0 Height Width 50]);
        startf = str2num(hStartF.String); endf = str2num(hEndF.String);
        times = (0:(endf-startf))./FrameRate; %start at zero no matter which frames are selected
        Xspace = .05*(times(end)-times(1)); %layout w/space on left and right
        hAx_TSPlot.XLim = ([times(1)-Xspace times(end)+Xspace]);
        hAx_TSPlot.Color = 'black';
        tmpmin = inf; tmpmax = -inf;
        rois = hRoiList.Value;
        for r = rois
            hold(hAx_TSPlot,'on');
            tmpmin = min(tmpmin,min(MMdata.roi(r).series(:))); tmpmax = max(tmpmax,max(MMdata.roi(r).series(:)));
            MMdata.roi(r).plot = plot(hAx_TSPlot,times,MMdata.roi(r).series,'Color',myColors(r));
        end
        
        Yspace = 0.05*(tmpmax-tmpmin);
        tmpmin = tmpmin-Yspace; tmpmax = tmpmax+Yspace;
        frame = uint16(round(hSlider.Value) - str2num(hStartF.String)+1);
        MMdata.timeline = plot(hAx_TSPlot,[times(frame) times(frame)],[tmpmin tmpmax],'w');
        hAx_TSPlot.YLim = ([tmpmin tmpmax]);
        hAx_TSPlot.Color = 'black';
        %show stimulus
        if ~hAux.Value == numel(auxstr) %
            %normalize aux signal between tmpmax and tmpmin-Yspace so no green appears along y-axis
            aux = tmpmin-Yspace + (MMdata.currentAux.signal - min(MMdata.currentAux.signal))*(tmpmax-tmpmin+Yspace)/...
                (max(MMdata.currentAux.signal)-min(MMdata.currentAux.signal));
            if isfield(MMdata.currentAux,'duration') %show signal on over duration
                stimperiod = MMdata.currentAux.times(2)-MMdata.currentAux.times(1);
                onFrames = floor(MMdata.currentAux.duration/stimperiod);
                i=2;
                while i<length(MMdata.currentAux.times)
                    if MMdata.currentAux.signal(i)>0 && MMdata.currentAux.signal(i-1)==0
                        aux(i:i+onFrames)=max(aux);
                        i = i+onFrames;
                    else
                        i = i+1;
                    end
                end
            end
            tshift = 0.0;
            if hAvgTrials.Value
                tOn = MMdata.currentAux.times(find(aux>min(aux),1,'first'));
                tshift = str2double(hPreStim.String)-tOn;
            end
            tmpPlot = area(hMM.hAx_TSPlot,MMdata.currentAux.times+tshift, aux, 'EdgeColor','green','FaceColor','green',...
                'FaceAlpha',.3,'Basevalue', min(aux));
            uistack(tmpPlot,'bottom');
        end
        hAx_TSPlot.Tag = 'TSPlot';
        set(hAx_TSPlot,'LineWidth',1.0,'YTickLabel',{},'XTickLabel',{});%,'FontSize',6,'YColor','none','Box','off');
    else
        hMM.Position = [100 Height+180 796 200];
        hFig_Movie.Position = [100 100 Width Height];
        hAx_Movie.Position = [0 0 Width Height];
        if isfield(MMdata,'timeline'); MMdata = rmfield(MMdata,'timeline'); end
    end
    CBRoiOverlay;
end

function CBAvgTrials(~,~)
    if ~hAvgTrials.Value
        hLastF.String = ['of ' num2str(Frames)];
        hEndF.String = num2str(defaultNumFrames); %num2str(Frames); %select only first 150 frames, ~10sec
    end
    updateMovie;
end

function CBMovieType(~,~)
    if ismember(hMovieType.Value,[2 3])
        hFO_start.Visible = 'on'; hFO_startLabel.Visible = 'on';
        hFO_end.Visible = 'on'; hFO_endLabel.Visible = 'on';
        hfMask_label.Visible = 'on'; hfMask_slider.Visible = 'on'; hfMask_edit.Visible = 'on';
        hDF_Cmin.Visible = 'on'; hDF_CminLabel.Visible = 'on';
        hDF_Cmax.Visible = 'on'; hDF_CmaxLabel.Visible = 'on';
        if hCAxisAuto.Value; hDF_Cmin.Enable = 'off'; hDF_Cmax.Enable = 'off';
    	else; hDF_Cmin.Enable = 'on'; hDF_Cmax.Enable = 'on';
        end
        if hMovieType.Value == 2
            hOverlayPct.Visible = 'off'; hOverlayVal.Visible = 'off';
            hOverlayLabel_1.Visible = 'off'; hOverlayLabel_2.Visible = 'off'; hOverlayLabel_3.Visible = 'off';
        else
            hOverlayPct.Visible = 'on'; hOverlayVal.Visible = 'on';
            hOverlayLabel_1.Visible = 'on'; hOverlayLabel_2.Visible = 'on'; hOverlayLabel_3.Visible = 'on';
        end
    else
        hFO_start.Visible = 'off'; hFO_startLabel.Visible = 'off';
        hFO_end.Visible = 'off'; hFO_endLabel.Visible = 'off';
        hfMask_label.Visible = 'off'; hfMask_slider.Visible = 'off'; hfMask_edit.Visible = 'off';
        hDF_Cmin.Visible = 'off'; hDF_Cmin.Enable = 'off'; hDF_CminLabel.Visible = 'off';
        hDF_Cmax.Visible = 'off'; hDF_Cmax.Enable = 'off'; hDF_CmaxLabel.Visible = 'off';
        hOverlayPct.Visible = 'off'; hOverlayVal.Visible = 'off';
        hOverlayLabel_1.Visible = 'off'; hOverlayLabel_2.Visible = 'off'; hOverlayLabel_3.Visible = 'off';
    end
    updateMovie;
end
function CBsetFmask(~,~) 
    if ~isfield(MMdata,'deltaF') || isempty(MMdata.deltaF); return; end
    clicked = hMM.CurrentObject;
    if strcmp(clicked.Tag,'fmaskslider')
        tmpval = round(clicked.Value);
    else
        tmpval = round(str2double(hfMask_edit.String));
        if tmpval<hfMask_slider.Min; tmpval=hfMask_slider.Min; end
        if tmpval>hfMask_slider.Max; tmpval=hfMask_slider.Max; end
        hfMask_slider.Value = tmpval;
    end
    hfMask_edit.String = num2str(tmpval);
    updateMovie;
end

function CBoverlay(~,~)
    if ~isfield(MMdata,'deltaF') || isempty(MMdata.deltaF); return; end
    clicked = hMM.CurrentObject;
    tmpbar = waitbar(0,'Computing Cutoff Value');
    if strcmp(clicked.Tag,'OverlayPct')
        overlaypct = str2double(hOverlayPct.String);
        if overlaypct >= 0
            tmpvals = MMdata.deltaF(~isnan(MMdata.deltaF));
            overlayval = qprctile(tmpvals(:),100-overlaypct);
%             overlaypct = qprctile(MMdata.deltaF(:),100-tmp);
        else
            tmpvals = MMdata.deltaF(~isnan(MMdata.deltaF));
            overlayval = qprctile(tmpvals(:),-overlaypct);
%             overlaypct = qprctile(MMdata.deltaF(:),-tmp);
        end
        overlayval = round(overlayval,3);
        MMdata.overlayval = overlayval;
        hOverlayVal.String = sprintf('%.1f',overlayval);
    elseif strcmp(clicked.Tag,'OverlayVal')
        MMdata.overlayval = str2double(hOverlayVal.String);
        tmpvals = MMdata.deltaF(~isnan(MMdata.deltaF));
        tmp = sort(tmpvals(:));
%         tmp = sort(MMdata.deltaF(:));
        overlaypct = 100-100*(find(tmp>=MMdata.overlayval,1,'first')/length(tmp));
        hOverlayPct.String = sprintf('%.1f',overlaypct);
    end
    close(tmpbar);
    CBrefreshImage;
end
function updateMovie
    % gets image stack or average trials movie and ...
    if ~isfield(MMdata,'file') || isempty(MMdata.file); return; end
    %grab stimulus if selected
    if isfield(MMdata,'currentAux'); MMdata = rmfield(MMdata,'currentAux');end
    if hAux.Value == 1
        MMdata.currentAux = MMdata.file.aux1;
    elseif hAux.Value == 2
        MMdata.currentAux = MMdata.file.aux2;
    elseif hAux.Value == 3
        MMdata.currentAux = MMdata.file.aux_combo;
    elseif hAux.Value == 4
        MMdata.currentAux = MMdata.file.def_stimulus;
    else
        MMdata.currentAux = [];
    end
    %get MMdata.file.im -or- average the selected trials
    if hAvgTrials.Value
        selected = hTrialsList.Value;
        cnt = 0;
        for o = 1:length(allOdorTrials.odor)
            for t = 1:length(allOdorTrials.odor(o).trial)
                cnt = cnt+1;
                if max(cnt==selected)
                    if cnt == selected(1)
                        tmpstack = double(MMdata.file.im(:,:,allOdorTrials.odor(o).trial(t).imindex));
                    else
                        tmpstack = tmpstack + double(MMdata.file.im(:,:,allOdorTrials.odor(o).trial(t).imindex));
                    end
                end
            end
        end
        tmpstack = tmpstack./length(selected);
        %modify (timeshift) stimulus for avg trials
        if ~isempty(MMdata.currentAux)
            prestimtime = str2double(hPreStim.String);
            trialframes = size(tmpstack,3); duration = (trialframes-1)./FrameRate;
            %poststimtime = str2num(hPostStim.String); %use trialframes to make sure you get enough of the stimulus 
            checkpreframes = find(MMdata.currentAux.times >= prestimtime,1,'first');
            On = find(MMdata.currentAux.signal>0,1,'first');
            if On < checkpreframes
                i=checkpreframes;
                while i<length(MMdata.currentAux.signal)
                    if MMdata.currentAux.signal(i)>0 && MMdata.currentAux.signal(i-1)==0
                        On=i; break;
                    end
                    i=i+1;
                end
            end
            tOn = MMdata.currentAux.times(On);
            stimstart = find(MMdata.currentAux.times >= tOn-prestimtime,1,'first');
            stimend = find(MMdata.currentAux.times > tOn+-prestimtime+duration,1,'first')-1;
            MMdata.currentAux.times = MMdata.currentAux.times(stimstart:stimend)-MMdata.currentAux.times(stimstart);
            MMdata.currentAux.signal = MMdata.currentAux.signal(stimstart:stimend);
        end
    else
        tmpstack = MMdata.file.im;
    end
    tmpFrames = size(tmpstack,3);
    %fix frames if out of range
    hLastF.String = ['of ' num2str(tmpFrames)];
    if str2double(hStartF.String)<1 || str2double(hStartF.String)>tmpFrames; hStartF.String = '1'; end
    if str2double(hEndF.String)<1 || str2double(hEndF.String)>tmpFrames; hEndF.String = num2str(tmpFrames); end
    hSlider.Max = str2double(hEndF.String); hSlider.Value = str2double(hStartF.String);
    hSlider.Min = str2double(hStartF.String);
    hSlider.SliderStep = [1 10]./(hSlider.Max-hSlider.Min);
    %grab frames
    startf = str2double(hStartF.String); endf = str2double(hEndF.String);
    tmpstack=tmpstack(:,:,startf:endf);
    %extract stimulus to match selected frames
    if ~isempty(MMdata.currentAux)
        tStartf = (startf-1)/FrameRate; tStopf = (endf-1)/FrameRate;
        stimstart = find(MMdata.currentAux.times >= tStartf,1,'first');
        stimend = find(MMdata.currentAux.times > tStopf,1,'first')-1;
        if isempty(stimend); stimend = length(MMdata.currentAux.times); end
        MMdata.currentAux.times = MMdata.currentAux.times(stimstart:stimend)-tStartf;
        MMdata.currentAux.signal = MMdata.currentAux.signal(stimstart:stimend);
    end
    %filter
    if hLPF.Value
        sigma = str2double(hLPFradius.String);
        tmpbar = waitbar(0,'Filtering');
        if hLPFROI.Value
            allROIs = zeros(size(tmpstack,1),size(tmpstack,2));
            for r = 1:size(MMdata.roi,2)
               allROIs = allROIs + MMdata.roi(r).mask;
            end
            backG = allROIs*-1+1;
            for f = 1:size(tmpstack,3)
                waitbar(f/size(tmpstack,3));
                tempF = tmpstack(:,:,f);
                tempF1 = imfilter_spatialLPF(tempF,sigma);
                tmpstack(:,:,f) = tempF1.*uint16(allROIs) + tempF.*uint16(backG);
            end
        else
            for f = 1:size(tmpstack,3)
                waitbar(f/size(tmpstack,3));
                tmpstack(:,:,f) = imfilter_spatialLPF(tmpstack(:,:,f),sigma);
            end
        end
        close(tmpbar);
        waitfor(tmpbar);
    end
    if isfield(MMdata,'current'); MMdata = rmfield(MMdata,'current'); end
    %adjust cmin/cmax and display image
    hold(hAx_Movie,'off');
    imagesc(hAx_Movie,tmpstack(:,:,1));
    set(hAx_Movie,'Visible','off','DataAspectRatio',[1 1 1],'DataAspectRatioMode','manual');
    tmpmin = min(tmpstack(:)); tmpmax = max(tmpstack(:));
    hMin.String = sprintf('(%d)',round(tmpmin));
    hMax.String = sprintf('(%d)',round(tmpmax));
    if str2double(hCmax.String)>tmpmax; hCmax.String = num2str(round(tmpmax)); end
    tmpbar = waitbar(0,'computing caxis values');
    MMdata.currentPRCT = qprctile(tmpstack(:), [0.2 99.8]);
    close(tmpbar);
    MMdata.current = tmpstack;
    %tcrtcr not sure if this is needed here. call CBcaxis instead?
    if hCAxisAuto.Value
        hCmin.Enable = 'Off';
        hCmax.Enable = 'Off';
        a = MMdata.currentPRCT;
        if a(2) == a(1); a(2) = a(1)+1; end  %just in case the image is all zeros
        hCmin.String = sprintf('%d',round(a(1)));
        hCmax.String = sprintf('%d',round(a(2)));
    else % manual cmin/cmax
        hCmin.Enable = 'On';
        hCmax.Enable = 'On';
        a(1) = str2double(hCmin.String);
        if a(1)<tmpmin; a(1)=tmpmin; hCmin.String = sprintf('%d',round(a(1))); end
        if a(1)>tmpmax; a(1)=tmpmin; hCmin.String = sprintf('%d',round(a(1))); end
        a(2) = str2double(hCmax.String);
        if a(2) == a(1); a(2) = a(1)+1; hCmax.String = sprintf('%d',round(a(2))); end  %just in case the image is all zeros
        if a(2)<tmpmin; a(2)=tmpmax; hCmax.String = sprintf('%d',round(a(2))); end
        if a(2)>tmpmax; a(2)=tmpmax; hCmax.String = sprintf('%d',round(a(2))); end
    end
    hAx_Movie.CLim = [a(1) a(2)];
    
    %overlay deltaf movie
    if isfield(MMdata,'deltaF'); MMdata=rmfield(MMdata,'deltaF'); end
    hAx_DeltaF = findobj(hFig_Movie,'Tag','DeltaF');
    if ~isempty(hAx_DeltaF); delete(hAx_DeltaF); end
    if ismember(hMovieType.Value,[2 3])
        %convert raw fluorescence movie to grayscale
        colormap(hAx_Movie, gray(256));
        %compute deltaF movie
        tmptimes = (0:(size(tmpstack,3)-1))./FrameRate;
        fstart = find(tmptimes >= str2double(hFO_start.String),1,'first');
        fend = find(tmptimes <= str2double(hFO_end.String),1,'last');
        tmpFO = MMdata.current(:,:,fstart:fend); 
        FO = mean(tmpFO,3);
        tmpFO = FO(~isnan(FO(:)));
        if str2double(hfMask_edit.String) < round(min(tmpFO)); hfMask_edit.String = num2str(round(min(tmpFO))); end
        if str2double(hfMask_edit.String) > round(mean(tmpFO)); hfMask_edit.String = num2str(round(mean(tmpFO))); end
        fMask = str2double(hfMask_edit.String);
        if isnan(fMask); fMask = round(min(tmpFO)); hfMask_edit.String = num2str(fMask); end
        set(hfMask_slider,'Min', round(min(tmpFO)),'Max', round(mean(tmpFO)), 'Value', fMask);
        hfMask_slider.SliderStep = [max(.01,1/(hfMask_slider.Max-hfMask_slider.Min)) .1];
        for f = 1:size(MMdata.current,3)
%             MMdata.deltaF(:,:,f) = 100*(double(MMdata.current(:,:,f))-FO)./FO;
            tmpframe = double(MMdata.current(:,:,f));
            tmpframe(FO>fMask) = 100*(tmpframe(FO>fMask)-FO(FO>fMask))./FO(FO>fMask);
            tmpframe(FO<=fMask) = nan;
            MMdata.deltaF(:,:,f) = tmpframe;
        end
        %reset caxis and overlay threshold values
        if hMovieType.Value == 2
            hAx_Movie.Children.AlphaData = zeros(size(hAx_Movie.Children.CData)); %make raw F axes invisible
            overlaypct = 0;
            MMdata.overlayval = min(MMdata.deltaF(:));
%             MMdata.DF_PRCT = qprctile(MMdata.deltaF(:),[0.2 99.8]);
            tmpvals = MMdata.deltaF(~isnan(MMdata.deltaF));
            MMdata.DF_PRCT = prctile(tmpvals(:),[0.2 99.8]);
            if hCAxisAuto.Value
                dflim = MMdata.DF_PRCT;
                hDF_Cmin.String = num2str(dflim(1));
                hDF_Cmax.String = num2str(dflim(2));
            else
                dflim(1) = str2double(hDF_Cmin.String);
                dflim(2) = str2double(hDF_Cmax.String);
            end
        else %overlay df/fo
            hAx_Movie.Children.AlphaData = ones(size(hAx_Movie.Children.CData)); %make raw F axes visible
            overlaypct = str2double(hOverlayPct.String);
            if overlaypct >= 0
%                 pcts = qprctile(MMdata.deltaF(:),[0.2 99.8 100-overlaypct]);
                tmpvals = MMdata.deltaF(~isnan(MMdata.deltaF));
                pcts = prctile(tmpvals(:),[0.2 99.8 100-overlaypct]);
                MMdata.DF_PRCT = [pcts(1) pcts(2)];
            else
%                 pcts = qprctile(MMdata.deltaF(:),[0.2 99.8 -overlaypct]);
                tmpvals = MMdata.deltaF(~isnan(MMdata.deltaF));
                pcts = prctile(tmpvals(:),[0.2 99.8 -overlaypct]);
                MMdata.DF_PRCT = [pcts(1) pcts(2)];
            end
            MMdata.overlayval = pcts(3);
            hOverlayVal.String = sprintf('%.1f',MMdata.overlayval);
            if hCAxisAuto.Value
                dflim = MMdata.DF_PRCT;
                hDF_Cmin.String = num2str(dflim(1));
                hDF_Cmax.String = num2str(dflim(2));
            else
                dflim(1) = str2double(hDF_Cmin.String);
                dflim(2) = str2double(hDF_Cmax.String);
            end
        end
        hDF_Cmin.String = sprintf('%.1f',dflim(1)); hDF_Cmax.String = sprintf('%.1f',dflim(2));
        %display deltaF or deltaFoverlay
        hAx_DeltaF = axes(hFig_Movie,'Units','pixels','Position',[0 0 Width Height],'Tag','DeltaF');
        imagesc(hAx_DeltaF,MMdata.deltaF(:,:,1)); hAx_DeltaF.Tag = 'DeltaF'; %axis image; axis off;
        %tcrtcr fix this - all nan alfa = 0
        tmpdffim = MMdata.deltaF(:,:,1);
        alfa = ones(size(tmpdffim));
        alfa(isnan(tmpdffim)) = 0;
        if hMovieType.Value == 3
%             alfa = MMdata.deltaF(:,:,1);
            if overlaypct >= 0
                alfa(alfa<MMdata.overlayval)=0; %alfa(alfa>=MMdata.overlayval) = 1; 
            else %show suppression
                alfa(alfa>=MMdata.overlayval)=0; alfa(alfa<MMdata.overlayval)=1;
            end
        end
        hAx_DeltaF.Children.AlphaData = alfa;
        %set dF/F caxis values
        caxis(hAx_DeltaF,dflim);
        val = get(hCMAP, 'Value'); colormap(hAx_DeltaF,[cmapstrings{val} '(256)']);
        hAx_DeltaF.Color = 'none'; hAx_DeltaF.Visible = 'off';
    else
        axes(hAx_Movie);
        val = get(hCMAP, 'Value'); colormap(hAx_Movie,[cmapstrings{val} '(256)']);
    end
    CBTSPlot; %this also does CBRoiOverlay
    IndicatorLight;
    hMM.UserData = MMdata;
end

function IndicatorLight
    hAx_light = findobj(hFig_Movie,'Tag','light');
    if ~isempty(hAx_light); delete(hAx_light); end
    radius = 14;
    trueframe = round(hSlider.Value);
    frame = uint16(round(hSlider.Value) - str2num(hStartF.String)+1);
    startf = str2num(hStartF.String); endf = str2num(hEndF.String);
    times = (0:(endf-startf))./FrameRate;  
    if isfield(MMdata,'currentAux') && ~isempty(MMdata.currentAux)
        hAx_light = axes(hFig_Movie,'Tag','light','Units','pixels','Position',[Width-2.5*radius Height-2.5*radius 2*radius 2*radius]);
        sphere(hAx_light,radius); hold(hAx_light,'on');
        cylinder(hAx_light,1,radius);
        hAx_light.Tag = 'light'; hAx_light.Visible = 'off';
        hAx_light.Children(1).EdgeColor = [.5 .5 .5];
        hAx_light.Children(1).LineWidth = 2;
        hAx_light.Children(2).FaceColor = [.5 .5 .5];
        if isfield(MMdata.currentAux,'duration')
            signal = MMdata.currentAux.signal;
            stimperiod = MMdata.currentAux.times(2)-MMdata.currentAux.times(1);
            onFrames = floor(MMdata.currentAux.duration/stimperiod);
            i=2;
            while i<length(MMdata.currentAux.times)
                if MMdata.currentAux.signal(i)>0 && MMdata.currentAux.signal(i-1)==0
                    signal(i:i+onFrames)=max(signal);
                    i = i+onFrames;
                else
                    i = i+1;
                end
            end
        else
            signal = MMdata.currentAux.signal;
        end
        if ismember(hAux.Value, [2 3]) %show light when sniff occurs during frame
            tmp1 = find(MMdata.currentAux.times >= double((frame-1))./FrameRate,1,'first');
            tmp2 = find(MMdata.currentAux.times >= double(frame)./FrameRate,1,'first');
            if max(signal(tmp1:tmp2)) > 0; hAx_light.Children(2).FaceColor = 'green';
            else; hAx_light.Children(2).FaceColor = [.5 .5 .5];
            end
        else
            tmp = find(MMdata.currentAux.times >= times(frame),1,'first');
            if signal(tmp) > 0; hAx_light.Children(2).FaceColor = 'green';
            else; hAx_light.Children(2).FaceColor = [.5 .5 .5];
            end
        end
        hAx_light.Children(2).LineStyle = 'none';
        hAx_light.Children(2).FaceLighting = 'gouraud';
        set(hAx_light,'Visible','off'); %axis off; axis image;
        H = light(hAx_light); %shifts tmpax.Children(+1)
        H.Position = [-1 0 1];
        hAx_light.CameraPosition = [0 0 10];
    end
    hClock = findobj(hFig_Movie,'Tag','Clock');
    if ~isempty(hClock); delete(hClock); end
    if ismember(hMovieType.Value,[2 3])
        hAx_DeltaF = findobj(hFig_Movie,'Tag','DeltaF');
        text(hAx_DeltaF,Width-2.5*radius-10,1.5*radius,[sprintf('%.2f',times(frame)) ' sec'],'Color','white','FontSize',14,...
            'HorizontalAlignment','right','Tag','Clock');
    else
        text(hAx_Movie,Width-2.5*radius-10,1.5*radius,[sprintf('%.2f',times(frame)) ' sec'],'Color','white','FontSize',14,...
            'HorizontalAlignment','right','Tag','Clock');
    end
    %uistack(hMM.Ax_light,'bottom');
end
function CBrefreshImage(~,~)
    if ~isfield(MMdata,'current') || isempty(MMdata.current); updateMovie; return; end
    frame = uint16(round(hSlider.Value) - str2num(hStartF.String)+1);
    hAx_Movie.Children(end).CData = MMdata.current(:,:,frame);
    if ismember(hMovieType.Value,[2 3])
        hAx_DeltaF = findobj(hFig_Movie,'Tag','DeltaF');
        dffimage = MMdata.deltaF(:,:,frame);
        hAx_DeltaF.Children(end).CData = dffimage; %hAx_DeltaF.Visible = 'off';
        %AlphaData - nan values are always set transparent, values <
        %overlayval are set transparent if hMovieType.Value == 3
        alfa = ones(size(dffimage));
        alfa(isnan(dffimage)) = 0;
        if hMovieType.Value == 3
            overlaypct = str2double(hOverlayPct.String);
%             alfa = MMdata.deltaF(:,:,frame);
            if overlaypct >= 0
                alfa(dffimage<MMdata.overlayval)=0; %alfa(alfa>=MMdata.overlayval) = 1; 
            else %show suppression - hide everything above abs(overlaypct)
                alfa(alfa>=MMdata.overlayval) = 0; alfa(alfa<MMdata.overlayval)=1;
            end
            
        end
        hAx_DeltaF.Children(end).AlphaData = alfa;
        if hMovieType.Value == 2
            hAx_Movie.Children.AlphaData = zeros(size(hAx_Movie.Children.CData));
        else
            hAx_Movie.Children.AlphaData = ones(size(hAx_Movie.Children.CData));
        end
    end
    CBTSPlot;
    if isfield(MMdata,'timeline') && ~isempty(MMdata.timeline)
        startf = str2num(hStartF.String); endf = str2num(hEndF.String);
        times = (0:(endf-startf))./FrameRate;
        MMdata.timeline.XData = [times(frame) times(frame)];
    end
    IndicatorLight;
end

function CBPreviewSave(~,~)
    updateMovie;
    if ~isfield(MMdata,'current') || isempty(MMdata.current); return; end
    clicked = hMM.CurrentObject;
    if strcmp(clicked.String,'Save'); bSave = 1; else; bSave = 0; end
    if bSave
        % .avi format
        tmpname = [fullfile(MMdata.file.dir,MMdata.file.name) '.avi'];
        [moviename, moviepath] = uiputfile(tmpname, 'Save movie file(s)');
        moviename = fullfile(moviepath,moviename);
        vidObj = VideoWriter(moviename, 'Uncompressed AVI');
%         vidObj.FrameRate = str2double(inputdlg('Enter Frame/sec for movie (current value shown below):',...
%             'Get Frame Rate',1,{num2str(IAdata.currentframeRate)}));
        vidObj.FrameRate = FrameRate;
        open(vidObj);
        tmpbar = waitbar(0,'writing .avi movie');
    end
    tmpim = MMdata.current;
    startf = str2num(hStartF.String); endf = str2num(hEndF.String);
    times = (0:(endf-startf))./FrameRate;
    if isfield(MMdata,'currentAux') && isfield(MMdata.currentAux,'duration')
        signal = MMdata.currentAux.signal;
        stimperiod = MMdata.currentAux.times(2)-MMdata.currentAux.times(1);
        onFrames = floor(MMdata.currentAux.duration/stimperiod);
        i=2;
        while i<length(MMdata.currentAux.times)
            if MMdata.currentAux.signal(i)>0 && MMdata.currentAux.signal(i-1)==0
                signal(i:i+onFrames)=max(signal);
                i = i+onFrames;
            else
                i = i+1;
            end
        end
    elseif isfield(MMdata,'currentAux') && ~isempty(MMdata.currentAux)
        signal = MMdata.currentAux.signal;
    end
    hAx_light = findobj(hFig_Movie,'Tag','light');
    for f = 1:size(tmpim,3)
        hAx_Movie.Children(end).CData = tmpim(:,:,f);
        if isfield(MMdata,'currentAux') && ~isempty(MMdata.currentAux)
            if ismember(hAux.Value,[2 3]) %show light when sniff occurs during frame
                tmp1 = find(MMdata.currentAux.times >= double(f-1)./FrameRate,1,'first');
                tmp2 = find(MMdata.currentAux.times >= double(f)./FrameRate,1,'first');
                if max(signal(tmp1:tmp2)) > 0; hAx_light.Children(3).FaceColor = 'green';
                else; hAx_light.Children(3).FaceColor = [.5 .5 .5];
                end
            else
                tmp = find(MMdata.currentAux.times >= times(f),1,'first');
                if signal(tmp) > 0; hAx_light.Children(3).FaceColor = 'green';
                else; hAx_light.Children(3).FaceColor = [.5 .5 .5];
                end
            end
        end
        if isfield(MMdata,'deltaF')
            hAx_DeltaF = findobj(hFig_Movie,'Tag','DeltaF');
            hAx_DeltaF.Children(end).CData = MMdata.deltaF(:,:,f);
            if hMovieType.Value == 2
                overlaypct = 0;
            else
                overlaypct = str2double(hOverlayPct.String);
                %don't recompute MMdata.overlayval here!
            end
            alfa = MMdata.deltaF(:,:,f);
            if overlaypct >= 0
                alfa(alfa<MMdata.overlayval)=0; alfa(alfa>=MMdata.overlayval)=1;
            else %show suppression
                alfa(alfa>=MMdata.overlayval)=0; alfa(alfa<MMdata.overlayval)=1;
            end
            hAx_DeltaF.Children(end).AlphaData = alfa;
        end
        if isfield(MMdata,'timeline') && ~isempty(MMdata.timeline); MMdata.timeline.XData = [times(f) times(f)]; end
        h_Clock = findobj(hFig_Movie,'Tag','Clock');
        if ~isempty(h_Clock); h_Clock.String = [sprintf('%.2f',times(f)) ' sec']; end
        if bSave
            drawnow;
            F = getframe(hFig_Movie);
            [X,map]=frame2im(F);
            writeVideo(vidObj, X);
        else
            pause(1/FrameRate);
        end
        hSlider.Value = startf+f-1;
    end
    if bSave
        close(tmpbar);
        close(vidObj);
    end
%     %reset at frame 1
%     hAx_Movie.Children(end).CData = tmpim(:,:,1);
%     if isfield(hMM,'currentAux') && ~isempty(MMdata.currentAux)
%         tmp = find(MMdata.currentAux.times >= times(1),1,'first');
%         if MMdata.currentAux.signal(tmp) > 0
%             hMM.Ax_light.Children(3).FaceColor = 'green';
%         else
%             hMM.Ax_light.Children(3).FaceColor = [.5 .5 .5];
%         end
%     end
%     if isfield(hMM,'timeline') && ~isempty(hMM.timeline); hMM.timeline.XData = [times(1) times(1)]; end
%     if isfield(hMM,'clock'); hMM.clock.String = [sprintf('%.1f',times(1)) ' sec']; end
%     if isfield(hMM,'deltaF')
%         hMM.Ax_DeltaF.Children.CData = hMM.deltaF(:,:,1);
%         overlaypct = str2double(hThreshold.String);
%         alfa = hMM.deltaF(:,:,1);
%         alfa(alfa>=overlaypct) = 1; alfa(alfa<overlaypct)=0;
%         hMM.Ax_DeltaF.Children.AlphaData = alfa;
%     end
end

end