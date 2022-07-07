function hIA = ImageAnalysis_MWLab(varargin)
% hIA = ImageAnalysis_MWLab(varargin)
% GUI for Flourescence Microscopy Image Analysis
% hIA is the GUI figure handle, IAdata is stored as hIA.UserData.IAdata
% if varargin is empty, just opens the GUI
% else varargin must be: (datatype, path, filename(s))
%   where datatype is 'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'
%   (see loadFile_MWLab.m for more info)
%
% EXAMPLE:
% ImageAnalysis_MWLab('scanimage','Nov1412-CCK-GC3reporter_ScanImage\','a0001.tif')

%% -------------------------------------------------------------------------
% Created/ Last Edited by:
% Thomas Rust: Change in Progress...
% Thomas Rust: November, 2018 (added IAsettings.mat, discontinued Global Variables)
%              IAdata is now stored as hIA.UserData.IAdata
% -------------------------------------------------------------------------
% Notes:
%   -The current version is designed to load only 1 image stack (or average of selected images)
%    in order to reduce the memory load due to large(>5GB) data files
%   -Global variables have been eliminated. IAdata is stored/updated as hIA.UserData.IAdata
%   -Background subtraction is now applied to TimeSeries data or MapsData,
%   (not to UInt16 image stack)
%
% Suggestions for future work:
%   -update code to an object-oriented programming style
%   -improve where to send mouse focus after <enter> or <tab> key press in uicontrols
%   -add/move some features to the menubar (e.g. batch functions)
%   -add back in an auto ROI feature (Scanbox method, CellSort1.0 or other)
%   -merge movieMaker with this program
%
%   -------------------------------------------------------------------------
%%
% Definitions
tmppath=which('ImageAnalysis_MWLab');
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
figurename = [pathparts{end} '/' guiname];

prev = findobj('Name',figurename);
if ~isempty(prev); close(prev); end

typestr = getdatatypes;

%load previous settings file
try
    load(fullfile(guipath,'IAsettings.mat'),'-mat','IAsettings');
catch
end
if ~exist('IAsettings','var')
    IAsettings.datatypeval = 1;
    IAsettings.path = '.';
    IAsettings.cmapvalue=1;
    IAsettings.fig1_bright = 0.1;
    IAsettings.fig1_lpf_radius = 0.75;
    IAsettings.fig2_lpf_radius = 0.75;
    IAsettings.preStimTime = [-4.0 0.0];
    IAsettings.postStimTime = [0.0 4.0];
    IAsettings.Fmaskstr = '0';
end
% Read command line arguments
if nargin > 0 && nargin < 3
    errordlg(sprintf('Incorrect number of input arguments;\nType "help ImageAnalysisMWLab" for more info!'));
    return;
end
if nargin == 0
    bLoadNow = 0; %binary, 0 indicates that data not loaded on opening
    IAdata.type = '';
    IAdata.file(1).dir = '';
    IAdata.file(1).name = '';
else
    bLoadNow = 1; %binary, 1 indicates that data loaded on opening
    IAdata.type = varargin{1};
    if nargin == 3
        IAdata.file(1).name = varargin{3}; %Filename, not including path (optional)
        IAdata.file(1).dir = varargin{2}; %Path to Data (optional)
    else
        for arg = 3:nargin
            IAdata.file(arg-2).dir = varargin{2}; %only allows 1 directory as input
            IAdata.file(arg-2).name = varargin{arg};
            %check image sizes match
            if arg == 3; [imsize(1),imsize(2)] = getImageSize(IAdata.type,...
                    fullfile(IAdata.file(arg-2).dir,IAdata.file(arg-2).name));
            else
                [tmpsize(1),tmpsize(2)] = getImageSize(IAdata.type,...
                    fullfile(IAdata.file(arg-2).dir,IAdata.file(arg-2).name));
                if ~isequal(imsize(1:2),tmpsize(1:2))
                    uiwait(errordlg('File sizes do not match','modal'));
                    IAdata.file = []; IAdata.roi = [];
                    bLoadNow = 0;
                end
            end
        end
    end
end
%%
% GUI figure setup
BGCol = [204 255 255]/255; %GUI Background Color
hIA = figure('NumberTitle','off','Name',figurename,'Units',...
        'Normalized','Position', [0.0276 0.05 0.9448 0.85],'Color',...
        BGCol,'CloseRequestFcn',@CB_CloseFig);
hIA.UserData.IAdata = IAdata;
set(hIA, 'DefaultAxesLineWidth', 2, 'DefaultAxesFontSize', 12); %Used by axes objects with plots
hmenu = uimenu(hIA,'Text','GUI Settings');
uimenu(hmenu,'Text','Save Settings','Callback',@CBSaveSettings);
uimenu(hmenu,'Text','Load Settings','Callback',@CBLoadSettings);

%Left Image Panel
uipanel(hIA,'Tag','Im1Panel','Units','Normalized','BackgroundColor',[0.5 0.5 0.5],...
    'Position', [0.075 0.28 0.36 0.6]);

%Right Image Panel
uipanel(hIA,'Tag','Im2Panel','Units','Normalized','BackgroundColor',[0.5 0.5 0.5],...
    'Position', [0.585 0.28 0.36 0.6]);
uicontrol(hIA, 'Style', 'text', 'HorizontalAlignment','center','String', {'Above image is computed from current image stack (left)';...
    'with image stack processing only (no suppress bright pixels or spatial filter)'},'Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.59 .22 .33 .05],'FontSize',12,'FontWeight','bold');

%Panel for plot of Total F vs timeframe
uicontrol(hIA, 'Style','text','String','Total Fluorescence vs Time(sec)','Units','normalized','Position',...
    [0.015 0.89 0.055 0.05],'BackgroundColor',BGCol);
uipanel(hIA,'Tag','fPlotPanel','Units','Normalized','BackgroundColor',[0.5 0.5 0.5],...
    'Position', [0.075 0.89 0.36 0.09]);

%List of Colormaps
cmapstrings = getcmaps;
uicontrol(hIA,'Style', 'text', 'String', 'Colormaps: ','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Fontsize',11,'Position',[0.01 0.835 0.055 0.025]);
uicontrol(hIA,'Tag','cmaplist','Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [0.005 0.8 0.065 0.03], 'String', cmapstrings,'Callback', @CBcmap, ...
    'Value',IAsettings.cmapvalue, 'BackgroundColor', [1 1 1],'FontSize',11);

% Two-Channel Data selection
uicontrol(hIA,'Tag','channel_list','Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [0.005 0.3 .065 0.05], 'String', {'channel 1'; 'channel 2'}, 'Callback', ...
    @CBchannel, 'Min', 1, 'Max', 2, 'Value', 1, 'Visible', 'off');

%Timeframe controls
uicontrol(hIA,'Tag','play_button','Style', 'togglebutton',  'Units', 'normalized', 'Position', ...
    [0.03 0.215 .045 0.05], 'String', 'Play','FontWeight','Bold', 'Callback', ...
    @CBplayFig1, 'Min', 0, 'Max', 1, 'Value', 0);
uicontrol(hIA,'Tag','speedcontrol','Style', 'checkbox', 'String', 'Speed Control','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.02 0.18 0.07 0.025],'HorizontalAlignment', ...
    'Left', 'FontSize', 10, 'FontWeight', 'normal');
uicontrol(hIA,'Tag','speedslider','Style','slider','min',1,'max',100,'value',50,'sliderstep',[1/99 1/99],...
    'Units','normalized','Position',[0.01 0.15 0.07 0.025]);
uicontrol(hIA,'Tag','frame_slider','Style', 'Slider', 'Units', 'normalized', 'Position', ...
    [.087 0.24 0.345 0.02], 'Min', 1, 'Max', 1.4, 'Value', 1, 'SliderStep', [1 1], ...
    'Callback', @CBframeSliderFig1, 'BackgroundColor', [1 1 1]);
uicontrol(hIA,'Tag','frame_text','Style', 'text', 'String', 'Frame # ','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.09 0.205 .2 .025],'HorizontalAlignment','Left');
uicontrol(hIA,'Tag','frameRate_text','Style', 'text', 'String', 'FrameRate:','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.22 0.205 .2 .025],'HorizontalAlignment','Left');
uicontrol(hIA,'Tag','duration_text','Style', 'text', 'String', 'Duration:','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.36 0.205 .2 .025],'HorizontalAlignment','Left');

%%Panel Under Left Image
leftPanel = uipanel(hIA,'Tag','leftPanel','Units', 'normalized', 'Position',[0.087, 0.015, 0.345, 0.185]);
tempcol = get(leftPanel, 'BackgroundColor');
uicontrol(leftPanel,'Style', 'text', 'String', 'Current image: ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.01 .8 .15 .2],'HorizontalAlignment','Right');
uicontrol(leftPanel,'Tag','name_text','Style', 'text', 'String', IAdata.file(1).name,'Units','normalized', ...
    'BackgroundColor', [1 1 1],'Position',[0.02 .75 .5 .15],'HorizontalAlignment' ...
    ,'Left', 'FontSize', 11, 'FontWeight','Bold');
uicontrol(leftPanel,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [0.55 0.72 .25 .2], 'String', 'Load Selected Image(s)','FontWeight','Bold', 'Callback', ...
    @CBloadSelected);
%Save options
uicontrol(leftPanel,'Style','pushbutton','Units','normalized','Position',...
    [0.83 0.72 0.15 0.2],'String','Save Movie','FontWeight','Bold','Callback',...
    @CBsaveFig1Stack,'TooltipString','Save image stack as .tif or .avi movie');
%suppress bright pixels
uicontrol(leftPanel,'Tag','suppressbright','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.01 0.52 0.55 0.15],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFig1, 'BackgroundColor', tempcol, 'String', 'Suppress bright pixels');
uicontrol(leftPanel,'Tag','fig1_bright','Style', 'edit', 'String', IAsettings.fig1_bright,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.26 0.52 0.05 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFig1);
uicontrol(leftPanel,'Style', 'text', 'String', '%(replace w/ local median)','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.32 0.5 0.25 0.12],'HorizontalAlignment','Left');
%spatial filter
uicontrol(leftPanel,'Tag','fig1_lpf','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.01 0.35 0.25 0.15],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFig1, 'BackgroundColor', tempcol, 'String', 'Spatial Filter (2D Gauss) @');
uicontrol(leftPanel,'Tag','fig1_lpf_radius','Style', 'edit', 'String', IAsettings.fig1_lpf_radius,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.26 0.35 0.05 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFig1);
uicontrol(leftPanel,'Style', 'text', 'String', 'pixels','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.32 0.32 0.05 0.12],'HorizontalAlignment','Left');
%Cmin/Cmax Thresholding Options
uicontrol(leftPanel,'Tag','stack_auto','Style', 'radiobutton',  'Units', 'normalized', 'Position', ...
    [0.01 0.09 0.16 0.16], 'String','<html><center>Auto Caxis<br>(0.02-99.8%)','FontWeight','Bold', 'Min', 0, 'Max', 1, ...
    'BackgroundColor', tempcol, 'Value', 1, 'Callback', @CBdrawFig1);
uicontrol(leftPanel,'Style', 'text', 'String', 'Cmin: ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.17 0.18 0.08 0.1],'HorizontalAlignment','Right');
uicontrol(leftPanel,'Style', 'text', 'String', 'Cmax: ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.17 0.03 0.08 0.1],'HorizontalAlignment','Right');
uicontrol(leftPanel,'Tag','stack_blackpix','Style', 'edit', 'String', '0','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.25 0.18 0.1 0.125],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFig1, 'Enable', 'Off');
uicontrol(leftPanel,'Tag','stack_whitepix','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.25 0.03 0.1 0.125],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFig1, 'Enable', 'Off');
uicontrol(leftPanel,'Tag','stack_min','Style', 'text', 'String', '(Stack Min = 0)','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.36 0.18 0.15 0.1],'HorizontalAlignment','Left');
uicontrol(leftPanel,'Tag','stack_max','Style', 'text', 'String', '(Stack Max = 0)','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.36 0.03 0.17 0.1],'HorizontalAlignment','Left');
%image alignment
alignpanel = uipanel(leftPanel,'Tag','alignPanel','Units','Normalized','Position', [0.55 0.2 0.43 0.45], ...
    'BackgroundColor',[1 1 1]);
uicontrol(alignpanel,'Style','text','String','Image Stack Alignment','FontWeight','Bold', ...
    'BackgroundColor',[1 1 1], 'Units','Normalized','Position',[.01 .75 .9 .2]);
uicontrol(alignpanel,'Tag','align_checkbox','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.1 0.5 0.5 0.2],'HorizontalAlignment','Right', ...
    'Callback', @CBalign, 'String', 'Align Time Frames','Enable','on',...
    'TooltipString',sprintf(['Shift selected timeframes to align with last frame of image (see alignImage_MWLab.m)\n'...
    '2-channel data is currently aligned using the first channel, then results are applied to both']));
uicontrol(alignpanel,'Tag','savealign_checkbox','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.6 0.5 0.7 0.2],'HorizontalAlignment','Right', ...
    'String', 'Save .align','Enable','on', 'TooltipString','Save alignments to .align file)');
uicontrol(alignpanel,'Tag','alignStart','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.13 0.12 0.15 0.2],'HorizontalAlignment','Right');
uicontrol(alignpanel,'Style', 'text', 'String', 'startFrame','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.3 0.12 0.25 0.2],'HorizontalAlignment','Left');
uicontrol(alignpanel,'Tag','alignEnd','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.57 0.12 0.15 0.2],'HorizontalAlignment','Right');
uicontrol(alignpanel,'Style', 'text', 'String', 'endFrame','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.75 0.12 0.25 0.2],'HorizontalAlignment','Left');

%%Panel Under Right Image
rightPanel = uipanel(hIA,'Tag','rightPanel','Units', 'normalized', 'Position', [0.587, 0.015, 0.345, 0.185]);
%frame selection
uicontrol(rightPanel,'Style', 'text', 'String', 'Start frame(s): ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.01 0.815 0.125 0.125],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Style', 'text', 'String', 'End frame(s): ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.01 0.65 0.125 0.125],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Tag','startframes','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.15 0.835 0.16 0.125],'HorizontalAlignment','Right', ...
    'Callback', @drawFig2);
uicontrol(rightPanel,'Tag','endframes','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.15 0.675 0.16 0.125],'HorizontalAlignment','Right', ...
    'Callback', @drawFig2);
%automatically find start and end timeframes from stimulus
uipanel(rightPanel,'Tag','getstimframesPanel','Units','Normalized','Position', [0.01 0.1 0.3 0.5],'BackgroundColor',[1 1 1]);
uicontrol(rightPanel,'Tag','stim2frames','Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [0.02 0.42 0.28 0.15], 'String', 'Get Stimulus TimeFrames','FontWeight','Bold', 'Enable','off',...
    'Callback', @CBfindStimulusFrames);
uicontrol(rightPanel,'Tag','preStimStart','Style', 'edit', 'String', IAsettings.preStimTime(1),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.02 0.27 0.04 0.1],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Style', 'text', 'String', 'to','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.065 0.26 0.025 0.1],'HorizontalAlignment','Left');
uicontrol(rightPanel,'Tag','preStimEnd','Style', 'edit', 'String', IAsettings.preStimTime(2),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.09 0.27 0.04 0.1],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Style', 'text', 'String', '(secs) pre-Stimulus','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.135 0.26 0.17 0.1],'HorizontalAlignment','Left');
uicontrol(rightPanel,'Tag','postStimStart','Style', 'edit', 'String', IAsettings.postStimTime(1),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.02 0.14 0.04 0.1],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Style', 'text', 'String', 'to','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.065 0.13 0.025 0.1],'HorizontalAlignment','Left');
uicontrol(rightPanel,'Tag','postStimEnd','Style', 'edit', 'String', IAsettings.postStimTime(2),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.09 0.14 0.04 0.1],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Style', 'text', 'String', '(secs) post-Stimulus','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.135 0.13 0.17 0.1],'HorizontalAlignment','Left');
%display modes
modestr{1} = '-Select Display Mode-'; modestr{2} = 'Mean (Start frame : End frame)';
modestr{3} = 'Mean (Start frames)'; modestr{4} = 'Mean (End frames)';
modestr{5} = 'DeltaF: mean(End frames) - mean(Start frames)';
modestr{6} = 'DeltaF: Current Frame (shown left) - mean(Start frames)';
modestr{7} = '10th percentile (All frames)';
modestr{8} = 'DeltaF: mean(End frames) -10th percentile(All frames)';
modestr{9} = 'Max (Start frame : End frame)';
% modestr{10} = 'Standard Deviation (Start:End frames)';
% modestr{11} = 'Median (Start:End frames)';
uicontrol(rightPanel,'Tag','fig2_mode','Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [0.34 0.835 0.32 0.125], 'String', modestr,'Callback', @drawFig2, 'Value', 1, 'BackgroundColor', [1 1 1]);
%spatial filter right image
uicontrol(rightPanel,'Tag','fig2_lpf','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.34 0.675 0.25 0.125],'HorizontalAlignment','Right', ...
    'Callback', @drawFig2, 'BackgroundColor', tempcol, 'String', '2D Gauss Filter @');
uicontrol(rightPanel,'Tag','fig2_lpf_radius','Style', 'edit', 'String', IAsettings.fig2_lpf_radius,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.515 0.675 0.05 0.125],'HorizontalAlignment','Right', ...
    'Callback', @drawFig2);
uicontrol(rightPanel,'Style', 'text', 'String', 'pixels','Units','normalized' ...
    ,'BackgroundColor',tempcol, 'Position',[0.57 0.65 0.05 0.125], 'HorizontalAlignment','Left');
%apply background subtraction to deltaF/F - hide this until both df mode & normalize are selected
uicontrol(rightPanel,'Tag','subtractBG','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.34 0.52 0.27 0.125],'HorizontalAlignment','Left', ...
    'Callback', @drawFig2, 'String', 'Background subtraction, ROI #', ...
    'TooltipString',sprintf(['While making the images shown above, subtract mean of a background region\n'...
    'from all pixels of the original image at each timeframe\n']));
uicontrol(rightPanel,'Tag','BGROI','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.61 0.52 0.05 0.125],'HorizontalAlignment','Right', ...
    'Callback', @drawFig2);
% deltaF/F - hide this until df mode is selected
uicontrol(rightPanel,'Tag','dividebyF','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.34 0.37 0.35 0.125], 'HorizontalAlignment','Right', ...
    'BackgroundColor', tempcol, 'String', 'Divide by F (deltaF/F*100%), where:','Callback', @drawFig2);
Fstr{1}= 'F = Mean (Start frames)'; Fstr{2} = 'F = 10th Percentile (All frames)';
uicontrol(rightPanel,'Tag','Ftype','Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.37 0.22 0.29 0.125],...
    'String', Fstr, 'Max', 0, 'Min', 0, 'Value', 1, 'BackgroundColor', [1 1 1],'Callback', @drawFig2);
%apply min value mask to deltaF/F - hide this until both df mode & normalize are selected
uicontrol(rightPanel,'Tag','adjustFmask','Style', 'text', 'Value', 0,'Units','normalized' ...
    ,'Position',[0.34 0.03 0.08 0.125], 'String', 'F Mask:', 'HorizontalAlignment', 'left', ...
    'BackgroundColor', tempcol);
uicontrol(rightPanel,'Tag','Fmask_slider','Style', 'slider', 'Units','normalized','BackgroundColor',tempcol,...
    'Position',[0.41 0.05 0.2 0.12],'HorizontalAlignment','Right', 'Callback', @CBsetFmask,...
    'TooltipString','Avoid divide by zero errors and reduces background noise','Min',1,'Max',2,'Value',1);
uicontrol(rightPanel,'Tag','Fmask_edit','Style', 'edit', 'String', IAsettings.Fmaskstr,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.61 0.05 0.05 0.125],'HorizontalAlignment','Right', ...
    'Callback', @CBsetFmask);

%this could depend on settings file!
set(findobj(hIA,'Tag','dividebyF'),'Visible','off'); set(findobj(hIA,'Tag','Ftype'),'Visible','off');
set(findobj(hIA,'Tag','adjustFmask'),'Visible','off');
set(findobj(hIA,'Tag','Fmask_slider'),'Visible','off');
set(findobj(hIA,'Tag','Fmask_edit'),'Visible','off');

%Cmin/Cmax
uicontrol(rightPanel,'Style', 'text', 'String', 'Cmin: ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.67 0.835 0.08 0.1],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Style', 'text', 'String', 'Cmax: ','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.67 0.675 0.08 0.1],'HorizontalAlignment','Right');
uicontrol(rightPanel,'Tag','black_pix','Style', 'edit', 'String', '0','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.75 0.835 0.1 0.125],'HorizontalAlignment','Right', ...
    'Callback', @CBsetFig2Clim, 'Enable', 'Off');
uicontrol(rightPanel,'Tag','white_pix','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.75 0.675 0.1 0.125],'HorizontalAlignment','Right', ...
    'Callback', @CBsetFig2Clim, 'Enable', 'Off');
uicontrol(rightPanel,'Tag','auto','Style', 'radiobutton',  'Units', 'normalized', 'Position', ...
    [0.7 0.5 0.25 0.15], 'String', 'Auto Caxis (0.2-99.8%)','FontWeight','Bold', 'Min', 0, 'Max', 1, ...
    'BackgroundColor', tempcol, 'Value', 1, 'Callback', @CBsetFig2Clim);
uicontrol(rightPanel,'Tag','cmapmin','Style', 'text', 'String', '(Min = 0)','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.86 0.835 0.14 0.1],'HorizontalAlignment','Left');
uicontrol(rightPanel,'Tag','cmapmax','Style', 'text', 'String', '(Max = 0)','Units','normalized' ...
    ,'BackgroundColor',tempcol,'Position',[0.86 0.675 0.14 0.1],'HorizontalAlignment','Left');
%save image or .avi movie
uicontrol(rightPanel,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [0.78 0.25 0.18 0.18], 'String', 'Save Image','FontWeight','Bold', 'Callback', ...
    @CBsaveFig2,'TooltipString','Save above image as .tif or .txt image');
uicontrol(rightPanel,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
    [0.72 0.04 0.24 0.15], 'String','Save DeltaF .avi movie','FontWeight','Bold','Callback', ...
    @CBsaveDeltaF_AVI,'TooltipString',sprintf(['Save a difference map .avi movie (current frame - mean start frames)\n'...
    'Divide by F & 2D Gauss filters are applied if boxes are checked.\nValues are scaled from 0-255(uint8)'])');
%Process: Movie Maker
uicontrol(hIA,'Style','pushbutton','Units','normalized','Position',...
    [0.585 0.90 0.12 0.06],'String','Movie Maker','FontWeight','Bold','Callback',...
    @CBmovieMaker,'TooltipString','Open current image stack in MovieMaker_MWLab');
%Batch Process: TimeSeriesAnalysis
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.715 0.90 0.12 0.06], ... %.585
    'String','Time Series Analysis', 'FontWeight','Bold','Callback', @CBbatchTimeSeriesAnalysis, ...
    'TooltipString',sprintf([...
    '"Image stack alignment" will be performed on each selected file\n'...
    'in the same manner as for the current image, using the settings...\n'...
    'selected in the box (below left). Creates TimeSeriesAnalysis_MWLab data.\n'...
    'Filter settings (suppress bright pixels, 2D gaussian) are not applied.']));
%Batch Process: MapsAnalysis
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.845 0.90 0.10 0.06],...
    'String','<html><center>Maps Analysis', 'FontWeight','Bold','Callback', @CBmapsAnalysis, ...
    'TooltipString',sprintf([...
    '"Image stack alignment" will be performed on each selected file\n'...
    'in the same manner as for the current image, using the settings\n'...
    'selected in the box (below left). Creates MapsAnalysis_MWLab data.\n'...
    'using current auxiliary signal, pre-stimulus and post-stimulus times.\n'...
    'Filter settings (suppress bright pixels, 2D gaussian) are not applied.']));
%Filenames Listbox
uicontrol('Style', 'text', 'String', 'Image file(s): ','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.46 .965 .1 .025],'FontSize',12,'FontWeight','bold');
filenamestr=cell(length(IAdata.file),1); for ff = 1:length(IAdata.file); filenamestr{ff}=IAdata.file(ff).name; end
uicontrol(hIA,'Tag','name_listbox','Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [0.46 0.715 0.1 0.25], 'String', filenamestr, 'Value', 1, 'BackgroundColor', [1 1 1], ...
    'Max', length(IAdata.file), 'Min', 0, 'FontSize',10);
if ismember(IAdata.type,typestr)
    IAsettings.datatypeval = find(strcmp(IAdata.type,typestr));
end
uicontrol(hIA,'Tag','dataType','Style', 'popupmenu',  'Units', 'normalized', 'Position', ...
    [0.46 0.69 0.1 0.02], 'String', typestr,'FontWeight','Bold', 'Max', 0, 'Min', 0, ...
    'Value', IAsettings.datatypeval, 'Callback', @CBdataType);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.46 0.655 0.05 0.03],...
    'String', 'Add File(s)', 'FontWeight', 'Bold', 'Callback', @CBaddFiles);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.51 0.655 0.05 0.03],...
    'String', 'Clear File(s)','FontWeight','Bold', 'Callback', @CBclearFiles)
uicontrol(hIA,'Tag','fileInfo','Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [0.46 0.623 0.1 0.03], 'String', 'File info','FontWeight','Bold', 'Callback', ...
    @CBgetFileInfo);

%ROIs Listbox & Tools
uicontrol('Style', 'text', 'String', 'ROI(s): ','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.46 .595 .1 .02],'FontSize',12,'FontWeight','bold');
uicontrol(hIA,'Tag','roi_listbox','Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [0.46 0.39 0.1 0.2], 'Value', 1, 'BackgroundColor', [1 1 1], 'Max', 100,...
    'Min', 0, 'FontSize',10);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.46 0.345 0.05 0.04],...
    'String', 'Draw ROI', 'FontWeight', 'Bold', 'Callback', @CBdrawROI);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.51 0.345 0.05 0.04],...
    'String', 'Load ROIs','FontWeight','Bold', 'Callback', @CBloadROIs);
%tcr could make this button do Background ROI
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.46 0.305 0.05 0.04],...
    'String', 'Auto ROIs','FontWeight', 'Bold', 'Callback', {@autoROI_button_fcn,gcf}, 'Enable','off');
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.51 0.305 0.05 0.04],...
    'String', 'Shift ROI(s)', 'Fontweight', 'Bold', 'Callback', @CBshiftROIsButton_fcn);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.46 0.265 0.05 0.04],...
    'String', 'Clear All ROIs','FontWeight','Bold', 'Callback', @CBclearROIs);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.51 0.265 0.05 0.04],...
    'String', 'Delete ROI(s)','FontWeight','Bold', 'Callback', @CBdeleteROIs);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.46 0.225 0.05 0.04],...
    'String', 'Save All ROIs','FontWeight','Bold', 'Callback', @CBsaveROI_button_fcn);
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.51 0.225 0.05 0.04],...
    'String', 'Plot ROIs','FontWeight','Bold', 'Callback', @CBplotROIs);

%Aux/Stimulus
auxpanel = uipanel(hIA,'Tag','auxPanel','Units','Normalized','Position', [0.45 0.015 0.12 0.185]);
uicontrol(auxpanel, 'Style', 'text', 'String', 'Select Auxiliary Signal:','Units','Normalized',...
    'Position',[0.1 0.85 .8 0.12]);
% auxstr = {'Aux1 (odor)','Aux2 (sniff)','Aux Combo','Define Stimulus Manually','none selected'};
auxstr = [getauxtypes' 'none selected'];
uicontrol(auxpanel,'Tag','Aux','Style', 'popupmenu', 'Value', 1, 'Units', 'normalized', ...
    'Position',[0.1 0.7 .8 0.15],'String',auxstr,'FontWeight','Bold',...
    'Callback',@CBselectStimulus);
uicontrol(auxpanel,'Tag','delay','Style', 'edit', 'String', '4','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.55 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off');
uicontrol(auxpanel,'Tag','delaylabel','Style', 'text', 'String', 'Initial Delay(sec)','Units','normalized' ...
    ,'Position',[0.41 0.54 0.7 0.10],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(auxpanel,'Tag','duration','Style', 'edit', 'String', '2','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.4 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off'); %tcrtcr: if used for scanbox - enable on and backgroundcolor green
uicontrol(auxpanel,'Tag','durationlabel','Style', 'text', 'String', 'Duration(sec)','Units','normalized' ...
    ,'Position',[0.41 0.39 0.7 0.10],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(auxpanel,'Tag','interval','Style', 'edit', 'String', '3','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.25 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off');
uicontrol(auxpanel,'Tag','intervallabel','Style', 'text', 'String', 'Interval(sec)','Units','normalized' ...
    ,'Position',[0.41 0.24 0.7 0.10],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(auxpanel,'Tag','trials','Style', 'edit', 'String', '4','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.1 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off');
uicontrol(auxpanel,'Tag','trialslabel','Style', 'text', 'String', '# Trials','Units','normalized' ...
    ,'Position',[0.41 0.09 0.7 0.10],'HorizontalAlignment','Left', 'Visible', 'off');

% Load Data Files if present
if bLoadNow == 1
    CBaddFiles;
end

%% Nested Callback functions
function CB_CloseFig(~,~)
    %save settings file
    updateSettings;
    save(fullfile(guipath,'IAsettings.mat'),'IAsettings');
    %close and clear
    delete(hIA);
end
function CBSaveSettings(~, ~)
    updateSettings;
    [setfile,setpath] = uiputfile(fullfile(guipath,'myIAsettings.mat'));
    save(fullfile(setpath,setfile),'IAsettings');
end
function updateSettings
    IAsettings.datatypeval = get(findobj(hIA,'Tag','dataType'),'Value');
    IAsettings.path = IAdata.file(1).dir;
    IAsettings.cmapvalue =  get(findobj(hIA,'Tag','cmaplist'), 'Value');
    IAsettings.fig1_bright = get(findobj(hIA,'Tag','fig1_bright'),'string');
    IAsettings.fig1_lpf_radius = get(findobj(hIA,'Tag','fig1_lpf_radius'),'String');
    IAsettings.fig2_lpf_radius = get(findobj(hIA,'Tag','fig2_lpf_radius'),'String');
    preStart=str2double(get(findobj(hIA,'Tag','preStimStart'),'String'));
    preEnd=str2double(get(findobj(hIA,'Tag','preStimEnd'),'String'));
    IAsettings.preStimTime = [preStart preEnd];
    postStart=str2double(get(findobj(hIA,'Tag','postStimStart'),'String'));
    postEnd=str2double(get(findobj(hIA,'Tag','postStimEnd'),'String'));
    IAsettings.postStimTime = [postStart postEnd];
    IAsettings.Fmaskstr = get(findobj(hIA,'Tag','Fmask_edit'),'String');
end
function CBLoadSettings(~, ~)
    [setfile,setpath] = uigetfile(fullfile(guipath,'*.mat'));
    try
        load(fullfile(setpath,setfile),'-mat','IAsettings');
        if isempty(IAdata.file) || isempty(IAdata.file(1).dir)
            set(findobj(hIA,'Tag','dataType'),'Value',IAsettings.datatypeval);
        end
        val = IAsettings.cmapvalue; set(findobj(hIA,'Tag','cmaplist'), 'Value',val); CBcmap;
        set(findobj(hIA,'Tag','fig_bright'),'String',num2str(IAsettings.fig1_bright));
        set(findobj(hIA,'Tag','fig1_lpf_radius'),'String',num2str(IAsettings.fig1_lpf_radius));
        set(findobj(hIA,'Tag','fig2_lpf_radius'),'String',num2str(IAsettings.fig2_lpf_radius));
        set(findobj(hIA,'Tag','preStimStart'),'String',num2str(IAsettings.preStimTime(1)));
        set(findobj(hIA,'Tag','preStimEnd'),'String',num2str(IAsettings.preStimTime(2)));
        set(findobj(hIA,'Tag','postStimStart'),'String',num2str(IAsettings.postStimTime(1)));
        set(findobj(hIA,'Tag','postStimEnd'),'String',num2str(IAsettings.postStimTime(2)));
        set(findobj(hIA,'Tag','Fmask_edit'),'String',IAsettings.Fmaskstr);
    catch
    end
end
function CBaddFiles(~, ~) %do not load images here!
    if bLoadNow == 1 %load data straight from command line
        bLoadNow = 0; cnt = 0;
    else
        IAdata.type = typestr{get(findobj(hIA,'Tag','dataType'),'Value')};
        %get pathname & filenames
        if ~isempty(IAdata.file(1).dir); pathname = IAdata.file(1).dir; else; pathname = IAsettings.path; end
        switch IAdata.type
            case 'scanimage' %ScanImage .tif (aka MWScope)
                ext = {'*.tif;*.dat','Scanimage Files';'*.*','All Files'};
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'On');
            case 'scanbox'
                ext = '.sbx';
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'On');
            case 'prairie'
                ext = '.xml'; %might try using uigetfolder for multiple files
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'Off');
            case 'neuroplex'
                ext = '.da';
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'On');
                IAdata.aux2bncmap = assignNeuroplexBNC;
            case 'tif' %Standard .tif
                ext = '.tif';
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'On');
        end
        if ok == 0; return; end
        if ~isempty(IAdata.file(end).name)
            cnt = length(IAdata.file);
            [imsize(1),imsize(2)] = getImageSize(IAdata.type,fullfile(IAdata.file(1).dir,IAdata.file(1).name));
        else
            cnt = 0;
            if ischar(filename); [imsize(1),imsize(2)] = getImageSize(IAdata.type,fullfile(pathname,filename));
            else; [imsize(1),imsize(2)] = getImageSize(IAdata.type,fullfile(pathname,filename{1}));
            end
        end
        if ischar(filename) %add 1 file to list
            if cnt > 0 %check new file same size as existing
                [tmpsize(1),tmpsize(2)] = getImageSize(IAdata.type,fullfile(pathname,filename));
                if ~isequal(imsize(1:2),tmpsize(1:2))
                    uiwait(errordlg('File sizes do not match','modal'));
                    return;
                end
            end
            IAdata.file(cnt+1).name = filename;
            IAdata.file(cnt+1).dir = pathname;
        else %add more than 1 file to list
            for mm = 1:length(filename)
                if mm == 1 && cnt > 0 || mm > 1
                    [tmpsize(1),tmpsize(2)] = getImageSize(IAdata.type,fullfile(pathname,filename{mm}));
                    if ~isequal(imsize(1:2),tmpsize(1:2))
                        errordlg('File sizes do not match');
                        return;
                    end
                end
            end
            for mm = 1:length(filename) %add the images 
                IAdata.file(cnt+mm).name = filename{mm};
                IAdata.file(cnt+mm).dir = pathname;
            end
        end
    end
    % update filename and selected files listbox
    filenamestr=cell(length(IAdata.file),1); for fff = 1:length(IAdata.file); filenamestr{fff}=IAdata.file(fff).name; end
    if cnt == 0 %load file only if no previous
        set(findobj(hIA,'Tag','name_listbox'),'String',filenamestr,'Max',numel(IAdata.file),'Value',1);
        CBloadSelected; 
    else
        set(findobj(hIA,'Tag','name_listbox'),'String',filenamestr,'Max',numel(IAdata.file));
    end
    hIA.UserData.IAdata = IAdata;
end

function CBdataType(~,~)
    if ~isempty(IAdata.file(1).name)
        if ismember(IAdata.type,typestr)
            IAsettings.datatypeval = find(strcmp(IAdata.type,typestr));
        else; IAsettings.datatypeval = 1;
        end
        set(findobj(hIA,'Tag','dataType'),'Value', IAsettings.datatypeval);
    end
end

function CBloadSelected(~,~)
    %this function loads the selected files and averages them if >1 selected
    if isempty(IAdata.file(1).name); set(findobj(hIA,'Tag','Aux'),'Value', 1); CBselectStimulus; CBdrawFig1; return; end
    set(findobj(hIA,'Tag','alignStart'),'Enable','on','string','1');set(findobj(hIA,'Tag','alignEnd'),'Enable','on','string','1');
    %load selected files
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    if numel(selected) == 1
        tmpend = strfind(IAdata.file(selected).name,'(');
        if strcmp(IAdata.type,'neuroplex') && isfield(IAdata,'aux2bncmap') && ~isempty(IAdata.aux2bncmap)
            if ~isempty(tmpend)
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected).dir,IAdata.file(selected).name(1:tmpend-1),IAdata.aux2bncmap);
            else
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected).dir,IAdata.file(selected).name,IAdata.aux2bncmap);
            end
        else
            if ~isempty(tmpend)
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected).dir,IAdata.file(selected).name(1:tmpend-1));
            else
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected).dir,IAdata.file(selected).name);
            end
        end
        set(findobj(hIA,'Tag','channel_list'),'Value',1);
        if iscell(newfile.im)
            set(findobj(hIA,'Tag','channel_list'),'Visible','on');
        else; set(findobj(hIA,'Tag','channel_list'),'Visible','off');
        end
        if isfield(IAdata,'currentimage'); IAdata = rmfield(IAdata,'currentimage'); end %current image is a cell if 2-channels are present!
        IAdata.currentimage = newfile.im;
        IAdata.currentimagename = IAdata.file(selected).name;
        IAdata.currentframeRate = newfile.frameRate;
        IAsettings.path = IAdata.file(selected).dir;
        IAdata.currentAux1 = []; IAdata.currentAux2 = []; %reset aux signals
        if isfield(IAdata,'currentAux3'); IAdata = rmfield(IAdata,'currentAux3'); end
        if isfield(IAdata,'currentEphys'); IAdata = rmfield(IAdata,'currentEphys'); end
        if isfield(IAdata,'def_stimulus'); IAdata=rmfield(IAdata,'def_stimulus'); end
%         set(findobj(hIA,'Tag','Aux'),'Value', 1);
%         set(findobj(hIA,'Tag','stim2frames'),'Enable','off');
        if isfield(newfile,'aux1') && ~isempty(newfile.aux1)
            IAdata.currentAux1 = newfile.aux1;
        else
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [1,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
        end
        if isfield(newfile,'aux2') && ~isempty(newfile.aux2)
            IAdata.currentAux2 = newfile.aux2;
        else
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [2,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
        end
        if isfield(newfile,'aux3') && ~isempty(newfile.aux3)
            IAdata.currentAux3 = newfile.aux3;
        end
        if isfield(newfile,'ephys') && ~isempty(newfile.ephys)
            IAdata.currentEphys = newfile.ephys;
        end
        clear newdata;
    else
        tmpend = strfind(IAdata.file(selected(1)).name,'(');
        if strcmp(IAdata.type,'neuroplex') && isfield(IAdata,'aux2bncmap') && ~isempty(IAdata.aux2bncmap)
            if ~isempty(tmpend)
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(1)).dir,IAdata.file(selected(1)).name(1:tmpend-1),IAdata.aux2bncmap);
            else
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(1)).dir,IAdata.file(selected(1)).name,IAdata.aux2bncmap);
            end
        else
            if ~isempty(tmpend)
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(1)).dir,IAdata.file(selected(1)).name(1:tmpend-1));
            else
                newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(1)).dir,IAdata.file(selected(1)).name);
            end
        end
        if iscell(newfile.im)
            set(findobj(hIA,'Tag','channel_list'),'Visible','on');
        else
            set(findobj(hIA,'Tag','channel_list'),'Visible','off');
        end
        if isfield(IAdata,'currentimage');IAdata = rmfield(IAdata,'currentimage');end
        IAdata.currentimage = newfile.im;
        IAdata.currentimagename = 'mean_selected';
        IAdata.currentframeRate = newfile.frameRate;
        IAdata.currentAux1 = []; IAdata.currentAux2 = []; %reset aux signals
        if isfield(IAdata,'currentAux3'); IAdata=rmfield(IAdata,'currentAux3'); end
        if isfield(IAdata,'currentEphys'); IAdata=rmfield(IAdata,'currentEphys'); end
        if isfield(IAdata,'def_stimulus'); IAdata=rmfield(IAdata,'def_stimulus'); end
        set(findobj(hIA,'Tag','Aux'),'Value', 1);
        if isfield(newfile,'aux1')  && ~isempty(newfile.aux1) %tcr: here, we decided to average the stimulus for multiple files
            IAdata.currentAux1 = newfile.aux1; aux1count = 1;
        end
        if isfield(newfile,'aux2') && ~isempty(newfile.aux2)
            IAdata.currentAux2 = newfile.aux2; aux2count = 1;
        end
        if isfield(newfile,'aux3') && ~isempty(newfile.aux3)
            IAdata.currentAux3 = newfile.aux3; aux3count = 1;
        end
        %tcr-ephys
        if isfield(newfile,'ephys') && ~isempty(newfile.ephys)
            disp('Ephys Data is ignored.... Lets not mess around with averaging multiple ephys files! -TCR');
        end
        for n = 2:numel(selected)
            tmpend = strfind(IAdata.file(selected(n)).name,'(');
            if strcmp(IAdata.type,'neuroplex') && isfield(IAdata,'aux2bncmap') && ~isempty(IAdata.aux2bncmap)
                if ~isempty(tmpend)
                    newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(n)).dir,IAdata.file(selected(n)).name(1:tmpend-1),IAdata.aux2bncmap);
                else
                    newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(n)).dir,IAdata.file(selected(n)).name,IAdata.aux2bncmap);
                end
            else
                if ~isempty(tmpend)
                    newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(n)).dir,IAdata.file(selected(n)).name(1:tmpend-1));
                else
                    newfile = loadFile_MWLab(IAdata.type,IAdata.file(selected(n)).dir,IAdata.file(selected(n)).name);
                end
            end
            %check size/framerate match!
            if ~isequal(newfile.frameRate,IAdata.currentframeRate); errordlg('FrameRate mismatch error'); return; end
            if iscell(newfile.im)
                if ~isequal(size(newfile.im{1}),size(IAdata.currentimage{1})); errordlg('File size mismatch error'); return; end
                IAdata.currentimage{1} = IAdata.currentimage{1} + newfile.im{1};
                IAdata.currentimage{2} = IAdata.currentimage{2} + newfile.im{2};
            else
                if ~isequal(size(newfile.im),size(IAdata.currentimage)); errordlg('File size mismatch error'); return; end
                IAdata.currentimage = IAdata.currentimage + newfile.im;
            end
            if isfield(newfile,'aux1') && ~isempty(newfile.aux1) && ~isempty(IAdata.currentAux1) %average stimulus
                IAdata.currentAux1.signal = IAdata.currentAux1.signal + newfile.aux1.signal;
                aux1count = aux1count+1;
            else; IAdata.currentAux1 = []; %if any are missing - don't average
            end
            if isfield(IAdata,'currentAux2') && ~isempty(newfile.aux2) && ~isempty(IAdata.currentAux2) %average stimulus
                IAdata.currentAux2.signal = IAdata.currentAux2.signal + newfile.aux2.signal; aux2count = aux2count+1;
            else; IAdata.currentAux2 = [];
            end
            if isfield(IAdata,'currentAux3') && ~isempty(newfile.aux3) && ~isempty(IAdata.currentAux3) %average stimulus
                IAdata.currentAux3.signal = IAdata.currentAux3.signal + newfile.aux3.signal; aux3count = aux3count+1;
            else; if isfield(IAdata,'currentAux3'); IAdata.currentAux3 = []; end
            end
        end
        if iscell(IAdata.currentimage)
            IAdata.currentimage{1} = IAdata.currentimage{1}./numel(selected);
            IAdata.currentimage{2} = IAdata.currentimage{2}./numel(selected);
        else
            IAdata.currentimage = IAdata.currentimage./numel(selected);
        end
        if isfield(IAdata,'currentAux1')&& ~isempty(IAdata.currentAux1)
            IAdata.currentAux1.signal = IAdata.currentAux1.signal./aux1count;
        else
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [1,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
        end
        if isfield(IAdata,'currentAux2')&& ~isempty(IAdata.currentAux2)
            IAdata.currentAux2.signal = IAdata.currentAux2.signal./aux2count;
        else
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [2,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String'))); end
        end
        if isfield(IAdata,'currentAux3') && ~isempty(IAdata.currentAux3)
            IAdata.currentAux3.signal = IAdata.currentAux3.signal./aux3count;
        end
        IAsettings.path = IAdata.file(selected(1)).dir;
        clear newdata;
    end
    set(findobj(hIA,'Tag','subtractBG'),'enable','on');
    if get(findobj(hIA,'Tag','align_checkbox'),'Value'); CBalign; end
    %put image info in gui
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    stackmin = min(tmpim(:)); stackmax = max(tmpim(:));
    set(findobj(hIA,'Tag','stack_min'), 'String', sprintf('Stack Min = %.0f',stackmin));
    set(findobj(hIA,'Tag','stack_max'), 'String', sprintf('Stack Max = %.0f',stackmax));
    set(findobj(hIA,'Tag','stack_blackpix'), 'String',stackmin);
    set(findobj(hIA,'Tag','stack_whitepix'), 'String',stackmax);   
    frames = size(tmpim,3);
    if frames>1
        set(findobj(hIA,'Tag','frame_slider'), 'Max', frames);
        set(findobj(hIA,'Tag','frame_slider'), 'SliderStep', [1./(frames-1) 1./(frames-1)]);
    else
        set(findobj(hIA,'Tag','frame_slider'), 'Max', 1.25);
        set(findobj(hIA,'Tag','frame_slider'), 'SliderStep', [1 1]); 
    end
    set(findobj(hIA,'Tag','frame_slider'), 'Value',1);
    set(findobj(hIA,'Tag','frame_text'), 'String', sprintf('Frame # 1/%d (%0.3f Sec)',frames,0.0));
    set(findobj(hIA,'Tag','frameRate_text'), 'String', sprintf('FrameRate: %0.3f (Frames/Sec)',IAdata.currentframeRate));
    set(findobj(hIA,'Tag','duration_text'), 'String', sprintf('Duration: %0.3f (Sec)',frames/IAdata.currentframeRate));
    if strcmp(get(findobj(hIA,'Tag','alignEnd'),'Enable'),'on'); set(findobj(hIA,'Tag','alignEnd'),'String',num2str(frames)); end
    %update plot/image
    hIA.UserData.IAdata = IAdata;
    CBselectStimulus;
    CBdrawFig1;
end

function CBalign(~,~)
    if ~isfield(IAdata,'currentimage') || isempty(IAdata.currentimage)
        set(findobj(hIA,'Tag','align_checkbox'),'Value',0); set(findobj(hIA,'Tag','align_checkbox'),'enable','off');
        set(findobj(hIA,'Tag','savealign_checkbox'),'value',0,'enable','off');
        return;
    end
    if get(findobj(hIA,'Tag','align_checkbox'),'value')
        startF = str2num(get(findobj(hIA,'Tag','alignStart'),'String'));
        endF = str2num(get(findobj(hIA,'Tag','alignEnd'),'String'));
        idx=startF:endF;
        T=[];
        %check for existing .align file or scanbox info.aligned
        selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
        dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename); end
        alignfile = fullfile(IAdata.file(selected).dir,[IAdata.currentimagename(1:dot) 'align']);
        useit = 0;
        if exist(alignfile,'file')==2
            tmp = load(alignfile,'-mat');
            m=tmp.m; T = tmp.T;
            if ~isempty(T) && isequal(idx,tmp.idx)
                use = questdlg('Existing .align file found, Would you like to use it?',...
                    'Use existing?','Yes','No','Yes');
                if strcmp(use,'Yes'); useit = 1; end
            end
        end
        if ~useit
            if iscell(IAdata.currentimage); [~,m,T] = alignImage_MWLab(IAdata.currentimage{1},idx);
            else; [~,m,T] = alignImage_MWLab(IAdata.currentimage,idx); end
        end
        %apply shifts
        for f = 1:length(idx)
            if iscell(IAdata.currentimage)
                IAdata.currentimage{1}(:,:,idx(f)) = circshift(IAdata.currentimage{1}(:,:,idx(f)),T(f,:));
                IAdata.currentimage{2}(:,:,idx(f)) = circshift(IAdata.currentimage{2}(:,:,idx(f)),T(f,:));
            else
                IAdata.currentimage(:,:,idx(f)) = circshift(IAdata.currentimage(:,:,idx(f)),T(f,:));
            end
        end
        IAdata.currentisAligned = 1;
        if get(findobj(hIA,'Tag','savealign_checkbox'),'value')
            %save results - if you do this, then the file will reload using saved alignments, so you can't undo it in the GUI
            selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
            if length(selected)==1
                dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename)+1; end
                name = [IAdata.currentimagename(1:dot) 'align'];
                save(fullfile(IAdata.file(selected).dir,name),'m','T','idx');
            else
                disp('More than 1 file selected, .align not saved');
            end
        end
        %update gui
        IAdata.currentimagename = [IAdata.currentimagename(1:dot-1) '_aligned' IAdata.currentimagename(dot:end)];
        if iscell(IAdata.currentimage)
            tmpstack = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
            stackmin = min(tmpstack(:)); stackmax = max(tmpstack(:));
        else
        	stackmin = min(IAdata.currentimage(:)); stackmax = max(IAdata.currentimage(:));
        end
        set(findobj(hIA,'Tag','stack_min'), 'String', sprintf('Stack Min = %.0f',stackmin));
        set(findobj(hIA,'Tag','stack_max'), 'String', sprintf('Stack Max = %.0f',stackmax));
        %update displayed images
        hIA.UserData.IAdata = IAdata;
        CBselectStimulus;
        CBdrawFig1;
    else
        hIA.UserData.IAdata = IAdata;
        CBloadSelected; 
    end
end

function CBclearFiles(~,~) %clear selected files from list
   if isempty(IAdata.file); return; end
   selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
   keep = setdiff(1:length(IAdata.file),selected);
   IAdata.file = IAdata.file(keep);
   if isempty(IAdata.file) || isempty(IAdata.file(1).name) %clean up to start over
       IAdata.file(1).name = ''; IAdata.file(1).dir = '';
       IAdata.currentimage = zeros(10,10);
       IAdata.currentimagename = [];
       if isfield(IAdata,'currentAux1'); IAdata.currentAux1 = []; end
       if isfield(IAdata,'currentAux2'); IAdata.currentAux2 = []; end
       if isfield(IAdata,'currentAux3'); IAdata.currentAux3 = []; end
       if isfield(IAdata,'currentEphys'); IAdata = rmfield(IAdata,'currentEphys'); end
       if isfield(IAdata,'def_stimulus'); IAdata = rmfield(IAdata,'def_stimulus'); end
       if isfield(IAdata,'aux2bncmap'); IAdata = rmfield(IAdata,'aux2bncmap'); end
       set(findobj(hIA,'Tag','name_listbox'),'Value',0);
       set(findobj(hIA,'Tag','Aux'),'Value',1);
       hIA.UserData.IAdata = IAdata;
       CBselectStimulus;
       CBdrawFig1;
   end
   filenamestr=cell(length(IAdata.file),1); for fff = 1:length(IAdata.file); filenamestr{fff}=IAdata.file(fff).name; end
   set(findobj(hIA,'Tag','name_listbox'),'String',filenamestr,'Max',numel(IAdata.file),'Value',1);
%    CBloadSelected;
    hIA.UserData.IAdata = IAdata;
end
function CBselectStimulus(~,~)
    %check that stimulus is present
    if ~isfield(IAdata,'file') || isempty(IAdata.file(1).name); CBplotFvsT; return; end
    if ~isfield(IAdata,'currentAux1') || isempty(IAdata.currentAux1)
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [1,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
    end
    if ~isfield(IAdata,'currentAux2') || isempty(IAdata.currentAux2)
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [2,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
    end
    if get(findobj(hIA,'Tag','Aux'),'Value') == 3
        if strcmp(IAdata.type,'scanimage') %scanimage (only gets "on" signal for odor - need to input duration)
            odorDuration = str2double(get(findobj(hIA,'Tag','duration'),'String'));
            IAdata.currentAuxCombo = doAuxCombo(IAdata.currentAux1,IAdata.currentAux2,odorDuration);            
        else
            IAdata.currentAuxCombo = doAuxCombo(IAdata.currentAux1,IAdata.currentAux2);
        end
    elseif get(findobj(hIA,'Tag','Aux'),'Value') == 4; doDefineStimulus;
    end
    if get(findobj(hIA,'Tag','Aux'),'Value') == 3 && get(findobj(hIA,'Tag','dataType'),'Value') == 1 %Aux_combo w/scanimage
        set(findobj(hIA,'Tag','delay'),'Visible', 'off'); set(findobj(hIA,'Tag','delaylabel'),'Visible', 'off');
        set(findobj(hIA,'Tag','duration'),'Visible', 'on'); set(findobj(hIA,'Tag','durationlabel'),'Visible', 'on');
        set(findobj(hIA,'Tag','interval'),'Visible', 'off'); set(findobj(hIA,'Tag','intervallabel'),'Visible', 'off');
        set(findobj(hIA,'Tag','trials'),'Visible', 'off'); set(findobj(hIA,'Tag','trialslabel'),'Visible', 'off');
    elseif get(findobj(hIA,'Tag','Aux'),'Value') == 4 %Defined Stim
        set(findobj(hIA,'Tag','delay'),'Visible', 'on'); set(findobj(hIA,'Tag','delaylabel'),'Visible', 'on');
        set(findobj(hIA,'Tag','duration'),'Visible', 'on'); set(findobj(hIA,'Tag','durationlabel'),'Visible', 'on');
        set(findobj(hIA,'Tag','interval'),'Visible', 'on'); set(findobj(hIA,'Tag','intervallabel'),'Visible', 'on');
        set(findobj(hIA,'Tag','trials'),'Visible', 'on'); set(findobj(hIA,'Tag','trialslabel'),'Visible', 'on');
    else
        set(findobj(hIA,'Tag','delay'),'Visible', 'off'); set(findobj(hIA,'Tag','delaylabel'),'Visible', 'off');
        set(findobj(hIA,'Tag','duration'),'Visible', 'off'); set(findobj(hIA,'Tag','durationlabel'),'Visible', 'off');
        set(findobj(hIA,'Tag','interval'),'Visible', 'off'); set(findobj(hIA,'Tag','intervallabel'),'Visible', 'off');
        set(findobj(hIA,'Tag','trials'),'Visible', 'off'); set(findobj(hIA,'Tag','trialslabel'),'Visible', 'off');
    end
    CBplotFvsT;
    if ismember(get(findobj(hIA,'Tag','Aux'),'Value'),1:numel(get(findobj(hIA,'Tag','Aux'),'String'))-1) %last value is "no stimulus"
        set(findobj(hIA,'Tag','stim2frames'),'Enable','on');
    else
        set(findobj(hIA,'Tag','stim2frames'),'Enable','off');
    end
    hIA.UserData.IAdata = IAdata;
end
        
function doDefineStimulus %manually define a stimulus signal ***IAdata.def_stimulus***
    if ~isfield(IAdata,'currentframeRate'); return; end
    frames = size(IAdata.currentimage,3);
    delay = str2double(get(findobj(hIA,'Tag','delay'),'String')); % #frames delay
    duration = str2double(get(findobj(hIA,'Tag','duration'),'String')); % #frames duration 
    interval = str2double(get(findobj(hIA,'Tag','interval'),'String')); % #frames interval
    trials = str2double(get(findobj(hIA,'Tag','trials'),'String'));
    trials = min(trials,floor((frames/IAdata.currentframeRate-delay+interval)/(duration+interval)));
    set(findobj(hIA,'Tag','trials'),'String',trials);
    endT = frames/IAdata.currentframeRate;
    deltaT=1/150; %hardcoded: Stimulus sampling rate is set at 150Hz (lab standard)
    IAdata.def_stimulus = defineStimulus(0,endT,deltaT,delay,duration,interval,trials);
    set(findobj(hIA,'Tag','stim2frames'),'Enable','on');     
    hIA.UserData.IAdata = IAdata;
end

function CBcmap(~, ~) %change colormap
    if isempty(IAdata.file); return; end
    val = get(findobj(hIA,'Tag','cmaplist'), 'Value');
    hAx_ax1 = findobj(hIA,'Tag','ax1'); hAx_ax2 = findobj(hIA,'Tag','ax2');
    if ~isempty(hAx_ax1); axes(hAx_ax1); colormap(hAx_ax1,[cmapstrings{val} '(256)']); end
    if ~isempty(hAx_ax2); axes(hAx_ax2); colormap(hAx_ax2,[cmapstrings{val} '(256)']); end
end

function CBframeSliderFig1(~, ~)
    ind = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    ind = round(ind);
    set(findobj(hIA,'Tag','frame_slider')', 'Value', ind);
    set(findobj(hIA,'Tag','frame_text'),'String', sprintf('Frame # %d/%d (%0.3f Sec)',ind,size(IAdata.currentimage,3),(ind-1)/IAdata.currentframeRate));
    CBdrawFig1;
    if iscell(IAdata.currentimage)
        tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else
        tmpim = IAdata.currentimage;
    end
    tmp = sum(squeeze(sum(tmpim)));
    tmp = (tmp-min(tmp))/(max(tmp)-min(tmp));
    set(findobj(hIA,'Tag','mark'),'Xdata',(ind-1)/IAdata.currentframeRate,'Ydata',tmp(ind));
end

function CBplayFig1(~,~) %play like a movie
    if isempty(IAdata.file); return; end
    if iscell(IAdata.currentimage)
        tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else
        tmpim = IAdata.currentimage;
    end
    frames = size(tmpim,3);
    ind = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    total = sum(squeeze(sum(tmpim)));
    total = (total-min(total))/(max(total)-min(total));
    hAx_ax1 = findobj(hIA,'Tag','ax1'); hIm_ax1im = findobj(hIA,'Tag','ax1im');
    axes(hAx_ax1);
    while (get(findobj(hIA,'Tag','play_button'), 'Value'))
        ind = ind+1;
        if (ind>frames)
            ind = 1;
        end
        set(findobj(hIA,'Tag','frame_slider'), 'Value', ind);
        set(findobj(hIA,'Tag','frame_text'),'String', sprintf('Frame # %d/%d (%0.3f Sec)',ind,frames,(ind-1)/IAdata.currentframeRate));
        if get(findobj(hIA,'Tag','suppressbright'),'Value') || get(findobj(hIA,'Tag','fig1_lpf'), 'Value')
            CBdrawFig1;
        else
            tmpframe=tmpim(:,:,ind);
            set(hIm_ax1im,'CData',tmpframe);
            %set CLim values    
            if get(findobj(hIA,'Tag','stack_auto'),'Value')
                ax1lims = qprctile(tmpframe(:), [0.2 99.8]); %qprctile is a bit faster than prctile because it accepts integers as input
                set(findobj(hIA,'Tag','stack_blackpix'), 'String', num2str(ax1lims(1)));
                set(findobj(hIA,'Tag','stack_whitepix'), 'String', num2str(ax1lims(2)));
                set(hAx_ax1, 'Clim', ax1lims);
            end
        end
        val = get(findobj(hIA,'Tag','cmaplist'), 'Value'); colormap(hAx_ax1,[cmapstrings{val} '(256)']);
        drawnow;
        set(findobj(hIA,'Tag','mark'),'Xdata',(ind-1)/IAdata.currentframeRate,'Ydata',total(ind));
        if get(findobj(hIA,'Tag','speedcontrol'),'Value')
            speed = get(findobj(hIA,'Tag','speedslider'), 'Value');
            pause(1/speed);
        end
    end
    CBdrawFig1;
end

function CBsaveFig1Stack(~, ~)
    if ~isfield(IAdata,'currentimage') || isempty(IAdata.currentimage); return; end
    format = questdlg(sprintf(['>Save movie as .tif (Original Values)\n'...
        '>Or, save movie as .avi (Values scale to 0-255)\n']), ...
        'What file format do you want to use?','.tif','.avi','.tif');
    if isempty(format); return; end
    if iscell(IAdata.currentimage)
        tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
        dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename)+1; end
        tmpname = [IAdata.currentimagename(1:dot-1) '_ch' num2str(get(findobj(hIA,'Tag','channel_list'),'Value')) IAdata.currentimagename(dot:end)];
    else
        tmpim = IAdata.currentimage;
        tmpname = IAdata.currentimagename;
    end
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    tmpdir = IAdata.file(selected(1)).dir;
    if strcmp(format,'.tif')
        %save as .tif, applying filters and such
        [name,path] = uiputfile('*.tif','Select file name', fullfile(tmpdir, [tmpname(1:end-4) '.tif']));
        if ~name(1); return; end
        %apply filters to entire currentimage
        if get(findobj(hIA,'Tag','suppressbright'), 'Value')==1 %suppress bright pixels
            suppress = questdlg('Would you like to suppress bright pixels (this might be slow)','Yes','No');
            if strcmp(suppress,'Yes')
                pct = 100 - str2double(get(findobj(hIA,'Tag','fig1_bright'),'string'));
                tmpim = imfilter_suppressBrightPixels(tmpim,pct);
            end
        end
        if get(findobj(hIA,'Tag','fig1_lpf'), 'Value') %spatial filter
            gaussfilter = questdlg('Would you like to apply 2D gaussian filter (this might be slow)','Yes','No');
            if strcmp(gaussfilter,'Yes')
                sigma = str2double(get(findobj(hIA,'Tag','fig1_lpf_radius'), 'String'));
                tmpim = imfilter_spatialLPF(tmpim,sigma);
            end
        end
        %Apply Cmin/Cmax to threshold
        thresh = questdlg('Would you like to use [Cmin:Cmax] to Threshhold the image','Yes','No');
        if strcmp(thresh,'Yes')
            tmpmin = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
            tmpmax = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
            tmp1 = tmpim<tmpmin; tmpim(tmp1)=tmpmin;
            tmp2 = tmpim>tmpmax; tmpim(tmp2)=tmpmax;
        end
        tmpim=uint16(tmpim);
        fastsaveastiff(tmpim,fullfile(path, name));
    %     imwrite(tmpim(:,:,1), fullfile(path, name), 'tif');
    %     for k = 2:size(IAdata.currentimage,3)
    %         imwrite(tmpim(:,:,k), fullfile(path, name), 'tif', ...
    %             'writemode', 'append');
    %     end
        helpdlg('File Saved');
    else % .avi format
        [name,path] = uiputfile('*.tif','Select file name', fullfile(tmpdir, [tmpname(1:end-4) '.avi']));
        if ~name(1); return; end
        tmpname = fullfile(path,name);
        %apply filters to entire currentimage
        if get(findobj(hIA,'Tag','suppressbright'), 'Value')==1 %suppress bright pixels
            suppress = questdlg('Would you like to suppress bright pixels (this might be slow)','Yes','No');
            if strcmp(suppress,'Yes')
                pct = 100 - str2double(get(findobj(hIA,'Tag','fig1_bright'),'string')); %this should be user input!
                tmpim = imfilter_suppressBrightPixels(tmpim,pct);
            end
        end
        if get(findobj(hIA,'Tag','fig1_lpf'), 'Value') %spatial filter
            gaussfilter = questdlg('Would you like to apply 2D gaussian filter (this might be slow)','Yes','No');
            if strcmp(gaussfilter,'Yes')
                sigma = str2double(get(findobj(hIA,'Tag','fig1_lpf_radius'), 'String'));
                tmpim = imfilter_spatialLPF(tmpim,sigma);
            end
        end
        %Apply Cmin/Cmax to threshold
        thresh = questdlg('Would you like to use [Cmin:Cmax] to Threshhold the image','Yes','No');
        if strcmp(thresh,'Yes')
            tmpmin = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
            tmpmax = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
            tmp1 = tmpim<tmpmin; tmpim(tmp1)=tmpmin;
            tmp2 = tmpim>tmpmax; tmpim(tmp2)=tmpmax;
        end
        % write .avi
        %vidObj = VideoWriter(tmpname, 'Uncompressed AVI');
        vidObj = VideoWriter(tmpname, 'Indexed AVI');
        vidObj.FrameRate = str2double(inputdlg('Enter Frame/sec for movie (current value shown below):',...
                    'Get Frame Rate',1,{num2str(IAdata.currentframeRate)}));
        open(vidObj);
        hAx_ax1 = findobj(hIA,'Tag','ax1');
        cmap = colormap(hAx_ax1);
        F.colormap = cmap;
        tmpmin = double(min(tmpim(:))); tmpmax = double(max(tmpim(:)));
        tmpbar = waitbar(0,'writing .avi movie');
        for i = 1:size(IAdata.currentimage,3)
            waitbar(i/size(IAdata.currentimage,3),tmpbar);
            temp = double(tmpim(:,:,i));    
            temp = (temp-tmpmin)./(tmpmax-tmpmin);
            temp = uint8(temp.*255);
            F.cdata = temp;
            writeVideo(vidObj, F);
        end
        close(tmpbar);
        close(vidObj);
        helpdlg('File Saved');
    end
    %tcrtcrtcr:  Could as save as .dat/.mat or hdf5 format here!
end

function CBmovieMaker(~, ~)
    if ~isfield(IAdata,'currentimage') || isempty(IAdata.currentimage); return; end
    tmpdata.file.type = IAdata.type;
    if iscell(IAdata.currentimage)
        tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
        dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename)+1; end
        tmpname = [IAdata.currentimagename(1:dot-1) '_ch' num2str(get(findobj(hIA,'Tag','channel_list'),'Value')) IAdata.currentimagename(dot:end)];
    else
        tmpim = IAdata.currentimage;
        tmpname = IAdata.currentimagename;
    end
    tmpdata.file.name = tmpname;
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    tmpdata.file.dir = IAdata.file(selected(1)).dir;
    tmpdata.file.im = tmpim;
    tmpdata.file.frameRate = IAdata.currentframeRate;
    if isfield(IAdata,'currentAux1') && ~isempty(IAdata.currentAux1); tmpdata.file.aux1 = IAdata.currentAux1; end
    if isfield(IAdata,'currentAux2') && ~isempty(IAdata.currentAux2); tmpdata.file.aux2 = IAdata.currentAux2; end
    if isfield(IAdata,'currentAux3') && ~isempty(IAdata.currentAux3); tmpdata.file.aux3 = IAdata.currentAux3; end
    MovieMaker_MWLab(tmpdata);
end

function CBgetFileInfo(~,~) %calls external program to find image info from header and/or .txt files
    if isempty(IAdata.file); return; end
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    getFileInfo(IAdata.type,IAdata.file(selected(1)).dir,IAdata.file(selected(1)).name);
end

function CBfindStimulusFrames(~,~) %automatically detect frames before and during stimulus
    if get(findobj(hIA,'Tag','Aux'),'Value') == numel(get(findobj(hIA,'Tag','Aux'),'String')); return; end
    if ~max(get(findobj(hIA,'Tag','fig2_mode'),'Value') == [1 3 4 5 6]); return; end
    preStart=str2double(get(findobj(hIA,'Tag','preStimStart'),'String'));
    if preStart >= 0
        preStart = str2double(inputdlg('Pre-Stimulus start time should be a negative value (sec), enter:',...
            'Fix Pre-Stimulus time',1,{'-4.0'}));
        set(findobj(hIA,'Tag','preStimStart'),'String',num2str(preStart));
    end
    preEnd=str2double(get(findobj(hIA,'Tag','preStimEnd'),'String'));
    postStart=str2double(get(findobj(hIA,'Tag','postStimStart'),'String'));
    postEnd=str2double(get(findobj(hIA,'Tag','postStimEnd'),'String'));
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    imTimes=(0:size(tmpim,3)-1)./IAdata.currentframeRate; %time at start of each timeframe
    %Use whatever stimulus is shown in FvT plot
    if get(findobj(hIA,'Tag','Aux'),'Value') == 1
        [startframes,endframes] = findStimulusFrames(IAdata.currentAux1,imTimes,preStart,preEnd,postStart,postEnd);
    elseif get(findobj(hIA,'Tag','Aux'),'Value') == 2
        [startframes,endframes] = findStimulusFrames(IAdata.currentAux2,imTimes,preStart,preEnd,postStart,postEnd);
    elseif get(findobj(hIA,'Tag','Aux'),'Value') == 3
        [startframes,endframes] = findStimulusFrames(IAdata.currentAuxCombo,imTimes,preStart,preEnd,postStart,postEnd);
    elseif get(findobj(hIA,'Tag','Aux'),'Value') ==4
        [startframes,endframes] = findStimulusFrames(IAdata.def_stimulus,imTimes,preStart,preEnd,postStart,postEnd);
    end
    set(findobj(hIA,'Tag','startframes'), 'String', startframes);
    set(findobj(hIA,'Tag','endframes'), 'String', endframes);
    drawFig2;
end

function CBloadROIs(~, ~) %load ROIs file (or ROIs from scanbox realtime data)
    hAx_ax2 = findobj(hIA,'Tag','ax2'); hIm_ax2im = findobj(hIA,'Tag','ax2im');
    if isempty(hIm_ax2im); return; end %don't load unless there's an image
    if isfield(IAdata,'roi') && ~isempty(IAdata.roi); oldrois = IAdata.roi; end
    CBclearROIs;
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    newrois = loadROIs(IAdata.file(selected(1)).dir);
    if ~isempty(newrois)
        if isequal(size(newrois(1).mask),size(hIm_ax2im.CData))
            IAdata.roi = newrois;
        else
            uiwait(errordlg('New ROIs size does not match Image size'));
            if exist('oldrois','var'); IAdata.roi = oldrois; clear oldrois; end
        end
    elseif exist('oldrois','var')
        IAdata.roi = oldrois; clear oldrois;
    end
    set(findobj(hIA,'Tag','roi_listbox'),'Value', 1);
    set(findobj(hIA,'Tag','roi_listbox'),'Max', max(length(IAdata.roi),1));
    hIA.UserData.IAdata = IAdata;
    overlayContours(hAx_ax2);
end

function CBdrawROI(~, ~) %draw your own ROI, add to list
    hAx_ax2 = findobj(hIA,'Tag','ax2'); hIm_ax2im = findobj(hIA,'Tag','ax2im');
    if isempty(hIm_ax2im); return; end %don't draw unless there's an image
    cmap = colormap(hAx_ax2);
    tmpclim = get(hAx_ax2, 'Clim');
    if ~isfield(IAdata,'roi'); IAdata.roi = []; end
    bgimage = get(hIm_ax2im,'CData');
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    [IAdata.roi] = drawROI_refine(IAdata.roi,bgimage,tmpim,cmap,tmpclim);
    set(findobj(hIA,'Tag','roi_listbox'),'Value', 1);
    hIA.UserData.IAdata = IAdata;
    overlayContours(hAx_ax2);
end

function CBshiftROIsButton_fcn(~, ~) %move selected ROIs
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi); return; end
    colshift = inputdlg('Shift to the right (pixels)', 'Column Shift', 1, {'0.0'});
    if isempty(colshift); return; end
    colshift = str2double(colshift{1});
    rowshift = inputdlg('Shift down (pixels)', 'Row Shift', 1, {'0.0'});
    if isempty(rowshift); return; end
    rowshift = str2double(rowshift{1});
    selectedrois = get(findobj(hIA,'Tag','roi_listbox'), 'Value');
    for r = 1:length(selectedrois)
        IAdata.roi(selectedrois(r)).mask = circshift(IAdata.roi(selectedrois(r)).mask,[rowshift,colshift]);
    end
    hAx_ax2 = findobj(hIA,'Tag','ax2');
    hIA.UserData.IAdata = IAdata;
    overlayContours(hAx_ax2);
end

function CBclearROIs(~,~) %clear all ROIs
    if ~isfield(IAdata,'roi'); return; end
    set(findobj(hIA,'Tag','roi_listbox'),'String',''); set(findobj(hIA,'Tag','roi_listbox'),'Value',0);
    IAdata.roi = [];
    hAx_ax2 = findobj(hIA,'Tag','ax2');
    hIA.UserData.IAdata = IAdata;
    overlayContours(hAx_ax2);
end

function CBdeleteROIs(~, ~) %clear selected ROIs
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi); return; end
    rois = get(findobj(hIA,'Tag','roi_listbox'), 'Value');
    keepInds = setdiff(1:length(IAdata.roi), rois);
    IAdata.roi = IAdata.roi(keepInds);
    roistr = cell(numel(IAdata.roi),1);
    for n = 1:numel(IAdata.roi)
        cl = myColors(n).*255;
        roistr{n} = ['<HTML><FONT color=rgb(' ...
            num2str(cl(1)) ',' num2str(cl(2)) ',' num2str(cl(3)) ')>ROI #' num2str(n) '</Font></html>'];
    end
    set(findobj(hIA,'Tag','roi_listbox'), 'String', roistr);
    if isempty(IAdata.roi); set(findobj(hIA,'Tag','roi_listbox'),'Value',0); else; set(findobj(hIA,'Tag','roi_listbox'), 'Value', 1); end
    hAx_ax2 = findobj(hIA,'Tag','ax2');
    hIA.UserData.IAdata = IAdata;
    overlayContours(hAx_ax2);
end

function CBsaveROI_button_fcn(~,~) %save ROI masks
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi); return; end
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    saveROIs(IAdata.roi,IAdata.file(selected(1)).dir,IAdata.currentimagename);
end

function CBplotROIs(~, ~) %run TimeSeriesAnalysis_MWLab.m using currentimage
    if isempty(IAdata.file); return; end
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi)
        errordlg('No ROIs selected');
        return;
    end
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    if iscell(IAdata.currentimage)
        tmpdata.file(1).type = IAdata.type; tmpdata.file(2).type = IAdata.type;
        tmpdata.file(1).dir = IAdata.file(selected(1)).dir; tmpdata.file(2).dir = IAdata.file(selected(1)).dir;
        dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename)+1; end
        tmpdata.file(1).name = [IAdata.currentimagename(1:dot-1) '_ch1' IAdata.currentimagename(dot:end)];
        tmpdata.file(2).name = [IAdata.currentimagename(1:dot-1) '_ch2' IAdata.currentimagename(dot:end)];
        tmpdata.file(1).frameRate = IAdata.currentframeRate; tmpdata.file(2).frameRate = IAdata.currentframeRate;
        tmpdata.file(1).im = IAdata.currentimage{1}; tmpdata.file(2).im = IAdata.currentimage{2}; %only temporary!
        tmpdata.file(1).size = size(tmpdata.file(1).im(:,:,1)); tmpdata.file(2).size = size(tmpdata.file(2).im(:,:,1));
        tmpdata.file(1).frames = size(tmpdata.file(1).im,3); tmpdata.file(2).frames = size(tmpdata.file(2).im,3);
        if isfield(IAdata,'currentAux1'); tmpdata.file(1).aux1 = IAdata.currentAux1; tmpdata.file(2).aux1 = IAdata.currentAux1;end
        if isfield(IAdata,'currentAux2'); tmpdata.file(1).aux2 = IAdata.currentAux2; tmpdata.file(2).aux2 = IAdata.currentAux2; end
        if isfield(IAdata,'currentAux3'); tmpdata.file(1).aux3 = IAdata.currentAux3; tmpdata.file(2).aux3 = IAdata.currentAux3; end
        if isfield(IAdata,'currentAuxCombo'); tmpdata.file(1).aux_combo = IAdata.currentAuxCombo; ...
                tmpdata.file(2).aux_combo = IAdata.currentAuxCombo; end
        if isfield(IAdata,'currentEphys'); tmpdata.file(1).ephys = IAdata.currentEphys; ...
                tmpdata.file(2).ephys = IAdata.currentEphys; end
    else
        tmpdata.file(1).type = IAdata.type;
        tmpdata.file(1).dir = IAdata.file(selected(1)).dir;
        tmpdata.file(1).name = IAdata.currentimagename;
        tmpdata.file(1).frameRate = IAdata.currentframeRate;
        tmpdata.file(1).im = IAdata.currentimage;
        tmpdata.file(1).size = size(tmpdata.file(1).im(:,:,1));
        tmpdata.file(1).frames = size(tmpdata.file(1).im,3);
        if isfield(IAdata,'currentAux1'); tmpdata.file(1).aux1 = IAdata.currentAux1; end
        if isfield(IAdata,'currentAux2'); tmpdata.file(1).aux2 = IAdata.currentAux2; end
        if isfield(IAdata,'currentAux3'); tmpdata.file(1).aux3 = IAdata.currentAux3; end
        if isfield(IAdata,'currentAuxCombo'); tmpdata.file(1).aux_combo = IAdata.currentAuxCombo; end
        if isfield(IAdata,'currentEphys'); tmpdata.file(1).ephys = IAdata.currentEphys; end
    end
    if isfield(IAdata,'def_stimulus') && ~isempty(IAdata.def_stimulus)
        tmpdata.def_stimulus=IAdata.def_stimulus; end
    tmpdata.roi = IAdata.roi;
    %compute timeseries first... then open TimeSeriesAnalysis...
    tmpdata = computeTimeSeries(tmpdata,tmpdata.roi);
    tmpdata.file = rmfield(tmpdata.file,'im');
    TimeSeriesAnalysis_MWLab(tmpdata); clear tmpdata;
end

function CBsetFig2Clim(~,~) % "caxis" controls
    hAx_ax2 = findobj(hIA,'Tag','ax2'); hIm_ax2im = findobj(hIA,'Tag','ax2im');
    if isempty(get(findobj(hIA,'Tag','Im2Panel'),'Children'))
       return;
    end
    tmpim = get(hIm_ax2im, 'CData');
    set(findobj(hIA,'Tag','cmapmin'),'String',sprintf('Min = %.2f',min(min(tmpim))));
    set(findobj(hIA,'Tag','cmapmax'),'String',sprintf('Max = %.2f',max(max(tmpim))));
    if get(findobj(hIA,'Tag','auto'), 'Value')==1 %auto cmin/cmax
        set(findobj(hIA,'Tag','black_pix'), 'Enable', 'Off');
        set(findobj(hIA,'Tag','white_pix'), 'Enable', 'Off');
        tmpvals = tmpim(~isnan(tmpim));
        a = prctile((tmpvals(:)), [0.2 99.8]);
        cmin = a(1);
        cmax = a(2);
        if cmax == cmin; cmax = cmin+1; end %just in case the image is all zeros    
        set(findobj(hIA,'Tag','black_pix'), 'String', sprintf('%.2f',cmin));
        set(findobj(hIA,'Tag','white_pix'), 'String', sprintf('%.2f',cmax));
    else % manual cmin/cmax
        set(findobj(hIA,'Tag','black_pix'), 'Enable', 'On');
        set(findobj(hIA,'Tag','white_pix'), 'Enable', 'On');
        cmin = str2double(get(findobj(hIA,'Tag','black_pix'), 'String'));
        cmax = str2double(get(findobj(hIA,'Tag','white_pix'), 'String'));
    end
    set(hAx_ax2, 'Clim', [cmin cmax]);
    imAlpha=ones(size(tmpim));
    imAlpha(isnan(tmpim))=0;
    set(hIm_ax2im,'AlphaData',imAlpha); 
    axes(hAx_ax2);
    val = get(findobj(hIA,'Tag','cmaplist'), 'Value'); colormap(hAx_ax2,[cmapstrings{val} '(256)']); %in case of redwhiteblue map
end

function CBsaveFig2(~, ~)
    hAx_ax2 = findobj(hIA,'Tag','ax2');
    imType = questdlg(sprintf(['>Save data as .txt (Actual values are saved (double)\n'...
        '>Save image as .tif (Values are converted to integers (0-255))\n' ...
        '>Or, save image with ROI contours and labels (.tif or .eps)']),...
        'What type of image do you want to save?','.txt','.tif','image w/ROIs','.txt');
    if isempty(imType); return; end
    if strcmp(imType,'.txt')
        selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
        tmpoutname = [IAdata.file(selected(1)).dir 'tmp_' IAdata.currentimagename '.txt'];
        [outname,path] = uiputfile('*.txt','Select file name', tmpoutname);
        if ~outname(1)
            return;
        end
        outim = getimage(hAx_ax2);
        outim = double(outim);
        cmin = str2double(get(findobj(hIA,'Tag','black_pix'), 'String'));
        cmax = str2double(get(findobj(hIA,'Tag','white_pix'), 'String'));
        tmp1 = outim<cmin; outim(tmp1)=cmin;
        tmp2 = outim>cmax; outim(tmp2)=cmax;
        %rescaling for difference maps
        rescale = questdlg('Would you like to rescale this image such that [Cmin:Cmax] maps to [0:1]','Rescale','No');
        if strcmp(rescale,'Yes')
            outim = (outim-cmin)./(cmax-cmin);
        end
        save(fullfile(path,outname),'outim','-ascii','-double','-tabs');
    %     msgbox('File Saved');        
    elseif strcmp(imType,'.tif')   
        selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
        tmpoutname = [IAdata.file(selected(1)).dir IAdata.currentimagename '_tmp'];
        [outname,path] = uiputfile('*.tif','Select file name', tmpoutname);
        if ~outname(1); return; end
        cmin = str2double(get(findobj(hIA,'Tag','black_pix'), 'String'));
        cmax = str2double(get(findobj(hIA,'Tag','white_pix'), 'String'));
        outim = getimage(hAx_ax2);
        tmp1 = outim<cmin; outim(tmp1)=cmin;
        tmp2 = outim>cmax; outim(tmp2)=cmax;
        outim = uint8((outim-cmin)./(cmax-cmin).*255);
        cmap = colormap(hAx_ax2);
        imwrite(outim,cmap,fullfile(path,outname),'tif','Compression','none');
    else %Image w/ROIs - choose .tif or .eps
        tmpfig = figure('Visible','off');
        copyobj(hAx_ax2,tmpfig);
        tmpfig.Position = [0 0 flip(size(hAx_ax2.Children(end).CData))];%resize figure
        imType = questdlg(sprintf('>Save image w/ROIs as .tif\n>Or, save as .eps'),...
        'What format image do you want to save?','.tif','.eps','.tif');
        if isempty(imType); return; end
        selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
        tmpoutname = [IAdata.file(selected(1)).dir IAdata.currentimagename '_roisImage'];
        if strcmp(imType,'.tif')
            [outname,path] = uiputfile('*.tif','File name', tmpoutname);
            if ~outname(1); return; end
            tmp = getframe(tmpfig.Children);
            outim = frame2im(tmp);
            imwrite(outim,fullfile(path, outname), 'tif');
        else
            [outname,path] = uiputfile('*.eps','File name', tmpoutname);
            if ~outname(1); return; end
            print(tmpfig,fullfile(path, outname),'-depsc'); %might want to try '-painters','-dsvg'
        end
        delete(tmpfig);
    end
end

function CBdrawFig1(~,~)
    %this function filters & displays 1 frame of the selected image
    hAx_ax1 = findobj(hIA,'Tag','ax1'); hIm_ax1im = findobj('Tag','ax1im');
    if isempty(IAdata.file(1).name)
        if ~isempty(hAx_ax1); set(hIm_ax1im,'Cdata',zeros(5)); set(findobj(hIA,'Tag','name_text'),'String',''); end; return;
    end
    frame = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    if iscell(IAdata.currentimage)
        tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')}(:,:,frame);
        dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename)+1; end
        tmpname = [IAdata.currentimagename(1:dot-1) '_ch' num2str(get(findobj(hIA,'Tag','channel_list'),'Value')) IAdata.currentimagename(dot:end)];
    else
        tmpim = IAdata.currentimage(:,:,frame);
        tmpname =IAdata.currentimagename;
    end
    set(findobj(hIA,'Tag','name_text'),'String',tmpname);
    %suppress bright pixels (this frame only)
    if get(findobj(hIA,'Tag','suppressbright'), 'Value')==1
        pct = 100 - str2double(get(findobj(hIA,'Tag','fig1_bright'),'string'));
        tmpim = imfilter_suppressBrightPixels(tmpim,pct);
    end
    %spatial filter (this frame only)
    if get(findobj(hIA,'Tag','fig1_lpf'), 'Value')
        sigma = str2double(get(findobj(hIA,'Tag','fig1_lpf_radius'), 'String'));
        tmpim = imfilter_spatialLPF(tmpim,sigma);
    end
    % Display Image
    if isempty(get(findobj(hIA,'Tag','Im1Panel'),'Children'))
        hAx_ax1 = axes('Parent',findobj(hIA,'Tag','Im1Panel'));
        hIm_ax1im = imagesc(hAx_ax1,zeros(5),'Tag','ax1im'); %The image is a "child" of hAx_ax1, hIm_ax1im property 'Cdata' is the image displayed
        hAx_ax1.Tag ='ax1'; %note: high-level version of imagesc clears axes.tag, so put tag here.
        CBcmap;
    end
    axes(hAx_ax1);
    hold(hAx_ax1,'off');
    set(hIm_ax1im,'Cdata',tmpim);
    %set CLim values    
    if get(findobj(hIA,'Tag','stack_auto'),'Value')
        ax1lims = qprctile(tmpim(:), [0.2 99.8]);
        set(findobj(hIA,'Tag','stack_blackpix'), 'Enable', 'Off');
        set(findobj(hIA,'Tag','stack_whitepix'), 'Enable', 'Off');
    else
        ax1lims(1) = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
        ax1lims(2) = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
        set(findobj(hIA,'Tag','stack_blackpix'), 'Enable', 'On');
        set(findobj(hIA,'Tag','stack_whitepix'), 'Enable', 'On');       
    end
    if ax1lims(2) == ax1lims(1); ax1lims(2) = ax1lims(1)+1; end %just in case the image is uniform 
    set(findobj(hIA,'Tag','stack_blackpix'), 'String', sprintf('%.2f',ax1lims(1)));
    set(findobj(hIA,'Tag','stack_whitepix'), 'String', sprintf('%.2f',ax1lims(2)));
    set(hAx_ax1, 'Clim', ax1lims);
    axis(hAx_ax1,'off');
    axis(hAx_ax1,'image');
    set(hAx_ax1, 'Position', [0.0 0.0 1.0 1.0]);
    axes(hAx_ax1);
    val = get(findobj(hIA,'Tag','cmaplist'), 'Value'); colormap(hAx_ax1,[cmapstrings{val} '(256)']); %in case of redwhiteblue map
    if ~get(findobj(hIA,'Tag','play_button'), 'Value')
        drawFig2;
    end
end

function CBplotFvsT(~,~) % plot total flourescence vs time, and stimulus
    hAx_FvsT = findobj(hIA,'Tag','fPlotAxe'); %hAx_FvsT refers to the handle of the axes graphics object for the FvsT plot
    if isempty(IAdata.file(1).name) %files cleared
        if ~isempty(hAx_FvsT); delete(hAx_FvsT); end; return;
    end
    if isempty(hAx_FvsT) || ~isvalid(hAx_FvsT)
        hAx_FvsT = axes('Parent',findobj(hIA,'Tag','fPlotPanel'),'Tag','fPlotAxe','Position',[0.01 0.18 0.98 0.82]);
        set(findobj(hIA,'Tag','fPlotPanel'),'BackgroundColor',[1 1 1]);
    end
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    tmp = sum(squeeze(sum(tmpim)));
    tmp = (tmp-min(tmp))/(max(tmp)-min(tmp));
    imtimes=(0:size(tmpim,3)-1)./IAdata.currentframeRate;
    plot(hAx_FvsT,imtimes,tmp); hAx_FvsT.Tag = 'fPlotAxe'; %the plot function resets the tag to '', (unless hold on)
    %frame marker
    frame = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    line((frame-1)/IAdata.currentframeRate,tmp(frame),'Parent',hAx_FvsT,'Tag','mark');
    set(findobj(hIA,'Tag','mark'),'Marker','o')
    set(findobj(hIA,'Tag','mark'),'MarkerFaceColor','red')
    %aux/stimulus
    hold(hAx_FvsT, 'on');
    if isfield(IAdata,'currentAux1') && ~isempty(IAdata.currentAux1) && get(findobj(hIA,'Tag','Aux'),'Value') == 1
        plot(hAx_FvsT,IAdata.currentAux1.times,IAdata.currentAux1.signal,'r','LineWidth',1.5);
        %show the odor # for each odor on/off
        if isfield(IAdata,'currentAux3') && ~isempty(IAdata.currentAux3)
            i=2; jj=find(IAdata.currentAux3.times>2.1,1,'first'); %8x0.25sec intervals
            while i<length(IAdata.currentAux3.signal) %skip first frame in case signal is on at scan start
                if IAdata.currentAux3.signal(i)==1 && IAdata.currentAux3.signal(i-1)==0 %find odor onset
                    spikes = '';
                    for b = 1:8 %search for 8 x ~.25 second intervals, starting 0.1 sec after trigger spike
                        spike = 0;
                        for j = find(IAdata.currentAux3.times>(IAdata.currentAux3.times(i)+(b-1)*0.25 + 0.1),1)...
                                : find(IAdata.currentAux3.times>(IAdata.currentAux3.times(i)+ b*0.25 + 0.1),1)
                            if IAdata.currentAux3.signal(j)==1 && IAdata.currentAux3.signal(j-1)==0
                                spike = 1;
                            end
                        end
                        if spike
                            spikes = [spikes '1'];
                        else
                            spikes = [spikes '0'];
                        end
                    end
                    spikes = flip(spikes); %bit order is smallest to largest!
                    odor = bin2dec(spikes);
                    text(hAx_FvsT,IAdata.currentAux3.times(i),0.8,num2str(odor));
                    i=i+jj; %jump forward
                else
                    i=i+1;
                end
            end
        end
    end
    if isfield(IAdata,'currentAux2') && ~isempty(IAdata.currentAux2) && get(findobj(hIA,'Tag','Aux'),'Value') == 2
        plot(hAx_FvsT,IAdata.currentAux2.times,IAdata.currentAux2.signal,'g');
    end
    if isfield(IAdata,'currentAuxCombo') && ~isempty(IAdata.currentAuxCombo) && get(findobj(hIA,'Tag','Aux'),'Value') == 3
        plot(hAx_FvsT,IAdata.currentAuxCombo.times,IAdata.currentAuxCombo.signal,'y');
    end
    if isfield(IAdata,'def_stimulus') && ~isempty(IAdata.def_stimulus) && get(findobj(hIA,'Tag','Aux'),'Value') == 4
        plot(hAx_FvsT,IAdata.def_stimulus.times,IAdata.def_stimulus.signal,'b');
    end
    set(hAx_FvsT,'LineWidth',1.0,'FontSize',6,'YTickLabel',{},'YColor','none','Box','off','XLim',[0 imtimes(end)]);
    hold(hAx_FvsT,'off');
end

function CBchannel(~,~)
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    stackmin = min(tmpim(:)); stackmax = max(tmpim(:));
    set(findobj(hIA,'Tag','stack_min'), 'String', sprintf('Stack Min = %.0f',stackmin));
    set(findobj(hIA,'Tag','stack_max'), 'String', sprintf('Stack Max = %.0f',stackmax));
    set(findobj(hIA,'Tag','stack_blackpix'), 'String',stackmin);
    set(findobj(hIA,'Tag','stack_whitepix'), 'String',stackmax);   
    frames = size(tmpim,3);
    if frames>1
        set(findobj(hIA,'Tag','frame_slider'), 'Max', frames);
        set(findobj(hIA,'Tag','frame_slider'), 'SliderStep', [1./(frames-1) 1./(frames-1)]);
    else
        set(findobj(hIA,'Tag','frame_slider'), 'Max', 1.25);
        set(findobj(hIA,'Tag','frame_slider'), 'SliderStep', [1 1]); 
    end
    set(findobj(hIA,'Tag','frame_slider'), 'Value',1);
    set(findobj(hIA,'Tag','frame_text'), 'String', sprintf('Frame # 1/%d (%0.3f Sec)',frames,0.0));
    set(findobj(hIA,'Tag','frameRate_text'), 'String', sprintf('FrameRate: %0.3f (Frames/Sec)',IAdata.currentframeRate));
    set(findobj(hIA,'Tag','duration_text'), 'String', sprintf('Duration: %0.3f (Sec)',frames/IAdata.currentframeRate));
    if strcmp(get(findobj(hIA,'Tag','alignEnd'),'Enable'),'on'); set(findobj(hIA,'Tag','alignEnd'),'String',num2str(frames)); end
    CBselectStimulus;
    CBdrawFig1;
end
function drawFig2(~,~) %show processed image on right side
    % get image stack shown in left panel (unfiltered, selected files-averaged)
    if ~isfield(IAdata,'currentimage') || isempty(IAdata.currentimage); return; end
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    mode = get(findobj(hIA,'Tag','fig2_mode'), 'Value');
    startframe = str2num(get(findobj(hIA,'Tag','startframes'), 'String'));
    endframe = str2num(get(findobj(hIA,'Tag','endframes'), 'String'));
    if (startframe(end)>size(tmpim,3))
        startframe = 1; fprintf('Start Frames out of range, reset to 1\n');
        set(findobj(hIA,'Tag','startframes'), 'String', num2str(startframe));
    end
    if (endframe(end)>size(tmpim,3))
        endframe = size(tmpim,3);
        fprintf('End Frames out of range, reset to %d\n',endframe);
        set(findobj(hIA,'Tag','endframes'), 'String', num2str(endframe));
    end
    if max(mode==[5 6 8])
        set(findobj(hIA,'Tag','dividebyF'), 'Visible','on'); set(findobj(hIA,'Tag','Ftype'),'Visible','on');
        if get(findobj(hIA,'Tag','dividebyF'),'Value')
            set(findobj(hIA,'Tag','adjustFmask'),'Visible','on'); set(findobj(hIA,'Tag','Fmask_slider'),'Visible','on');
            set(findobj(hIA,'Tag','Fmask_edit'),'Visible','on');
        else
            set(findobj(hIA,'Tag','adjustFmask'),'Visible','off'); set(findobj(hIA,'Tag','Fmask_slider'),'Visible','off');
            set(findobj(hIA,'Tag','Fmask_edit'),'Visible','off');
        end
    else
        set(findobj(hIA,'Tag','dividebyF'), 'Value',0,'visible','off'); set(findobj(hIA,'Tag','Ftype'),'Visible','off');
        set(findobj(hIA,'Tag','adjustFmask'),'Visible','off'); set(findobj(hIA,'Tag','Fmask_slider'),'Visible','off');
        set(findobj(hIA,'Tag','Fmask_edit'),'Visible','off');
    end
    if get(findobj(hIA,'Tag','subtractBG'),'value') %background roi
        RoiNum = str2double(get(findobj(hIA,'Tag','BGROI'),'String'));
        if isempty(get(findobj(hIA,'Tag','roi_listbox'),'String')) || RoiNum>length(IAdata.roi)
            fprintf('Background ROI # %d not found\n',RoiNum);
            set(findobj(hIA,'Tag','subtractBG'),'Value',0);
            return;
        else
            BGroiIndex = IAdata.roi(RoiNum).mask>0.5;
            bg=zeros(size(tmpim,3),1);
            for i = 1:size(tmpim,3)
                tmp=tmpim(:,:,i);
                bg(i)=single(mean(tmp(BGroiIndex)));
            end
        end
    end
    Fig2Im = zeros(size(tmpim,1), size(tmpim,2));
    switch mode
        case 1 % None selected
        case 2 % 'Mean (Start:End frames)'
            if (length(startframe)>1);  startframe = 1;
                set(findobj(hIA,'Tag','startframes'), 'String', num2str(startframe)); end
            if (length(endframe)>1); if isfield(IAdata,'currentimage'); endframe = size(IAdata.currentimage,3); else; endframe=1; end
                set(findobj(hIA,'Tag','endframes'), 'String', num2str(endframe)); end
            Fig2Im = mean(tmpim(:,:, startframe:endframe), 3);
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                Fig2Im = Fig2Im-mean(bg(startframe:endframe));
            end
        case 3 % 'Mean (Start frames)'
            Fig2Im = mean(tmpim(:,:, startframe), 3);
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                Fig2Im = Fig2Im-mean(bg(startframe));
            end
        case 4 % 'Mean (End frames)'
            Fig2Im = mean(tmpim(:,:, endframe), 3);
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                Fig2Im = Fig2Im-mean(bg(endframe));
            end
        case 5 % DeltaF: mean(End Frame(s)) - mean(Start Frame(s))
            imA = mean(tmpim(:,:,startframe), 3);
            imB = mean(tmpim(:,:,endframe), 3);
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                imA = imA-mean(bg(startframe));
                imB = imB-mean(bg(endframe));
            end
            Fig2Im = imB-imA;
        case 6 % Difference: Current Frame (shown left) - mean(Start Frame(s))
            imA = mean(tmpim(:,:,startframe), 3);
            hIm_ax1im = findobj(hIA,'Tag','ax1im');
            imB = double(get(hIm_ax1im,'Cdata'));
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                imA = imA - mean(bg(startframe));
                currentframe = get(findobj(hIA,'Tag','frame_slider'), 'Value');
                imB = imB - bg(currentframe);
            end
            Fig2Im = imB - imA;
        case 7 %10th percentile (All frames)
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                tmpwait = waitbar(0,'computing 10th prctile image with background subtraction');
                for i = 1:size(tmpim,1)
                    waitbar(i/size(tmpim,1),tmpwait);
                    for j = 1:size(tmpim,2)
                        currentpixel = squeeze(single(tmpim(i,j,:)))-bg(:);
                        Fig2Im(i,j) = prctile(currentpixel, 10);
                    end
                end
                delete(tmpwait)
            else
                tmpwait = waitbar(0,'computing 10th prctile image');
                for i = 1:size(tmpim,1)
                    waitbar(i/size(tmpim,1),tmpwait);
                    Fig2Im(i,:) = prctile(tmpim(i,:,:), 10, 3);
                end
                delete(tmpwait)
            end
        case 8 % % DeltaF: mean(End Frame(s)) - 10th percentile(All frames)
            imB = mean(tmpim(:,:,endframe), 3);
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                imB = imB-mean(bg(endframe));
            end
            imA=zeros(size(Fig2Im));
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                tmpwait = waitbar(0,'computing 10th prctile image with background subtraction');
                for i = 1:size(tmpim,1)
                    waitbar(i/size(tmpim,1),tmpwait);
                    for j = 1:size(tmpim,2)
                        currentpixel = squeeze(single(tmpim(i,j,:)))-bg(:);
                        imA(i,j) = prctile(currentpixel, 10);
                    end
                end
                delete(tmpwait)
            else
                tmpwait = waitbar(0,'computing 10th prctile image');
                for i = 1:size(tmpim,1)
                    waitbar(i/size(tmpim,1),tmpwait);
                    imA(i,:) = prctile(tmpim(i,:,:), 10, 3);
                end
                delete(tmpwait)
            end
            Fig2Im = imB - imA;
        case 9 % max
            if (length(startframe)>1);  startframe = startframe(1);
                set(findobj(hIA,'Tag','startframes'), 'String', num2str(startframe)); end
            if (length(endframe)>1);  endframe = endframe(end);
                set(findobj(hIA,'Tag','endframes'), 'String', num2str(endframe)); end
            if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                Fig2Im = Fig2Im-max(bg(:)); %set image to lowest possible value
                for f = startframe:endframe
                    currentframe = single(tmpim(:,:,f))-bg(f);
                    Fig2Im = max(Fig2Im,currentframe); %update the max image
                end
            else
                Fig2Im = max(tmpim(:,:, startframe:endframe), [], 3);
            end
%         case 10 % Standard Deviation
%             if (length(startframe)>1);  startframe = startframe(1);
%                 set(findobj(hIA,'Tag','startframes'), 'String', num2str(startframe)); end
%             if (length(endframe)>1);  endframe = endframe(end);
%                 set(findobj(hIA,'Tag','endframes'), 'String', num2str(endframe)); end
%             if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
%                 stdwait = waitbar(0,'computing standard deviations with background subtraction');
%                 for i = 1:size(tmpim,1)
%                     waitbar(i/size(tmpim,1),stdwait);
%                     for j = 1:size(tmpim,2)
%                         currentpixel = squeeze(single(tmpim(i,j,startframe:endframe)))-bg(startframe:endframe);
%                         Fig2Im(i,j) = std(currentpixel);
%                     end
%                 end
%                 close(stdwait);
%             else
%                 stdwait = waitbar(0,'computing standard deviations');
%                 for i = 1:size(tmpim,1) %single precision & one row at a time helps with memory usage/speed
%                     waitbar(i/size(tmpim,1),stdwait);
%                     Fig2Im(i,:)=std(single(tmpim(i,:,startframe:endframe)),0,3);
%                 end
%                 close(stdwait);
%             end
%         case 11 % median
%             if (length(startframe)>1);  startframe = startframe(1);   
%                 set(findobj(hIA,'Tag','startframes'), 'String', num2str(startframe)); end
%             if (length(endframe)>1);  endframe = endframe(1);   
%                 set(findobj(hIA,'Tag','endframes'), 'String', num2str(endframe)); end
%             if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
%                 stdwait = waitbar(0,'computing median with background subtraction');
%                 for i = 1:size(tmpim,1)
%                     waitbar(i/size(tmpim,1),stdwait);
%                     for j = 1:size(tmpim,2)
%                         currentpixel = squeeze(single(tmpim(i,j,startframe:endframe)))-bg(startframe:endframe);
%                         Fig2Im(i,j) = median(currentpixel);
%                     end
%                 end
%                 close(stdwait);
%             else
%                 stdwait = waitbar(0,'computing median image');
%                 for i = 1:size(tmpim,1) %one row at a time helps with memory usage/speed
%                     waitbar(i/size(tmpim,1),stdwait);
%                     Fig2Im(i,:) = median(tmpim(i,:, startframe:endframe), 3);
%                 end
%                 close(stdwait)
%             end
    end
    % Divide by F and convert to percent
    if get(findobj(hIA,'Tag','dividebyF'), 'Value')
        fMode = get(findobj(hIA,'Tag','Ftype'),'Value');
        switch fMode
            case 1 % Mean (Start frames)
                if max(mode == [5 6]) %F=imA from above
                    F=imA;
                else
                    F = mean(tmpim(:,:,startframe), 3);
                    if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                        F = F-mean(bg(startframe));
                    end
                end
            case 2 % 10th percentile (all frames)
                if mode==8 %F=imA from above
                    F=imA;
                else
                    F=zeros(size(Fig2Im));
                    if get(findobj(hIA,'Tag','subtractBG'),'value') %subtract reference roi
                        tmpwait = waitbar(0,'computing 10th prctile image with background subtraction');
                        for i = 1:size(tmpim,1)
                            waitbar(i/size(tmpim,1),tmpwait);
                            for j = 1:size(tmpim,2)
                                currentpixel = squeeze(single(tmpim(i,j,:)))-bg(:);
                                F(i,j) = prctile(currentpixel, 10);
                            end
                        end
                        delete(tmpwait)
                    else
                        tmpwait = waitbar(0,'computing 10th prctile image');
                        for i = 1:size(tmpim,1)
                            waitbar(i/size(tmpim,1),tmpwait);
                            F(i,:) = prctile(tmpim(i,:,:), 10, 3);
                        end
                        delete(tmpwait)
                    end
                end
        end
        set(findobj(hIA,'Tag','Fmask_slider'),'Min', round(min(F(:))));
        set(findobj(hIA,'Tag','Fmask_slider'),'Max', round(mean(F(:)))); %get(findobj(hIA,'Tag','Fmask_slider'),'Max') = round(max(F(:)));
        if get(findobj(hIA,'Tag','Fmask_slider'),'Value')<round(min(F(:)))
            set(findobj(hIA,'Tag','Fmask_slider'),'Value',round(min(F(:))));
        elseif get(findobj(hIA,'Tag','Fmask_slider'),'Value')>round(mean(F(:)))
            set(findobj(hIA,'Tag','Fmask_slider'),'Value',round(mean(F(:))));
        end
        % Fig2Im = 100*Fig2Im./F; But avoiding divide by zero 
        Fig2Im(F~=0) = 100*Fig2Im(F~=0)./imA(F~=0); Fig2Im(F==0) = nan;
        Fmask = round(get(findobj(hIA,'Tag','Fmask_slider'),'Value'));
        set(findobj(hIA,'Tag','Fmask_edit'),'String',num2str(Fmask));
        Fig2Im(F<Fmask)=nan;
    end
    %spatial filter
    if get(findobj(hIA,'Tag','fig2_lpf'), 'Value')
        sigma = str2double(get(findobj(hIA,'Tag','fig2_lpf_radius'), 'String'));
        Fig2Im = imfilter_spatialLPF(Fig2Im,sigma);
    end
    % Draw the figure
    if isempty(get(findobj(hIA,'Tag','Im2Panel'),'Children'))
        hAx_ax2 = axes('Parent',findobj(hIA,'Tag','Im2Panel'));
        hIm_ax2im = imagesc(hAx_ax2,zeros(5),'Tag','ax2im'); %The image is a "child" of hAx_ax2, image property 'Cdata' is the image displayed
        hAx_ax2.Tag = 'ax2'; %high-level imagesc resets the axes, so Tag it here.
        CBcmap;
    else
        hAx_ax2 = findobj(hIA,'Tag','ax2'); hIm_ax2im = findobj(hIA,'Tag','ax2im');
    end
    set(hIm_ax2im,'Cdata',Fig2Im);
    CBsetFig2Clim;
    axis(hAx_ax2,'off');
    axis(hAx_ax2,'image');
    set(hAx_ax2, 'Position', [0.0 0.0 1.0 1.0]);
    % Overlay ROIs
    if isfield(IAdata,'roi') && ~isempty(IAdata.roi)
        overlayContours(hAx_ax2);
    end
end

function overlayContours(hAxis) %plot ROI contour lines
    axes(hAxis);
    hold on;
    h_roitext = findobj(hIA,'Tag','roitext');
    h_roiline = findobj(hIA,'Tag','roiline');
    %delete old contour lines
    if ~isempty(h_roitext)
        for r = 1:length(h_roitext); delete(h_roitext(r)); end
        clear h_roitext;
    end
    if ~isempty(h_roiline)
        for r = 1:length(h_roiline); delete(h_roiline(r)); end
        clear h_roitext;
    end
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi); return; end
    %check size match
    if iscell(IAdata.currentimage); tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
    else; tmpim = IAdata.currentimage; end
    if ~isequal(size(IAdata.roi(1).mask),size(tmpim(:,:,1)))
        uiwait(errordlg('Existing ROIs size did not match newly loaded images'));
        IAdata.roi = [];
    end
    %draw new contours, and update roi listbox
    roistr=cell(length(IAdata.roi));
    for r = 1:length(IAdata.roi)
        [ctemp,~] = contour(IAdata.roi(r).mask, 1, 'LineColor',myColors(r),'Tag','roiline');   
        text(mean(ctemp(1,:)),mean(ctemp(2,:)),num2str(r),'Color',myColors(r),'FontSize',14,'Tag','roitext');
        cl = myColors(r).*255;
        roistr{r} = ['<HTML><FONT color=rgb(' num2str(cl(1)) ',' num2str(cl(2))...
             ',' num2str(cl(3)) ')>' 'ROI # ' num2str(r) '</Font></html>'];
    end
    hold off;
    set(findobj(hIA,'Tag','roi_listbox'),'String',roistr);
end

function CBbatchTimeSeriesAnalysis(~, ~)
    % Compute Time Series with settings shown (image stack alignment) for
    % all selected files and open results in TimeSeriesAnalysis.m   
    if isempty(IAdata.file(1).name); return; end
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi)
        errordlg('No ROIs selected');
        return;
    end
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    if length(selected) == 1
        errordlg('Only 1 file selected, select more or use plotROIs button');
        return;
    end
    tmpdata.roi = IAdata.roi;
    nn = 0; %keep track of two-channel stuff
    if strcmp(IAdata.type,'neuroplex'); tmpdata.aux2bncmap = IAdata.aux2bncmap; end
    for n = 1:numel(selected)
        if strcmp(IAdata.type,'neuroplex')
            newdata = loadFile_MWLab(IAdata.type,IAdata.file(selected(n)).dir,IAdata.file(selected(n)).name,tmpdata.aux2bncmap);
        else
            newdata = loadFile_MWLab(IAdata.type,IAdata.file(selected(n)).dir,IAdata.file(selected(n)).name);
        end
        if iscell(newdata.im)
            nn = nn+2;
            tmpdata.file(nn-1).type = newdata.type; tmpdata.file(nn).type = newdata.type;
            tmpdata.file(nn-1).size = newdata.size; tmpdata.file(nn).size = newdata.size;
            tmpdata.file(nn-1).frames = newdata.frames; tmpdata.file(nn).frames = newdata.frames;
            tmpdata.file(nn-1).frameRate = newdata.frameRate; tmpdata.file(nn).frameRate = newdata.frameRate;
            tmpdata.file(nn-1).dir = newdata.dir; tmpdata.file(nn).dir = newdata.dir;
        else
            nn = nn+1;
            tmpdata.file(nn).type = newdata.type;
            tmpdata.file(nn).size = newdata.size;
            tmpdata.file(nn).frames = newdata.frames;
            tmpdata.file(nn).frameRate = newdata.frameRate;
            tmpdata.file(nn).dir = newdata.dir;
        end
        tmpname = newdata.name; tmpim = newdata.im;
        if get(findobj(hIA,'Tag','align_checkbox'),'value')
            % check to see if .align file exists first!
            dot = strfind(newdata.name,'.'); if isempty(dot); dot=length(newdata.name)+1; end
            alignfile = [fullfile(newdata.dir,newdata.name(1:dot)) 'align'];
            if exist(alignfile,'file')==2
                fprintf('Using existing .align file: %s.\n',alignfile);
                tmp = load(alignfile,'-mat');
                T = tmp.T; idx = tmp.idx;
                for f = 1:length(idx)
                    if iscell(tmpim)
                        tmpim{1}(:,:,idx(f)) = circshift(tmpim{1}(:,:,idx(f)),T(f,:));
                        tmpim{2}(:,:,idx(f)) = circshift(tmpim{2}(:,:,idx(f)),T(f,:));
                    else
                        tmpim(:,:,idx(f)) = circshift(tmpim(:,:,idx(f)),T(f,:));
                    end
                end
                tmpname=[tmpname(1:dot-1) '_aligned' tmpname(dot:end)];
            else
                fprintf('No .align file found; aligning image %s',tmpname);
                [tmpim,tmpname] = alignThisImage(tmpim,tmpname);     
            end
        end
        if iscell(tmpim)
            dot = strfind(tmpname,'.');
            tmpdata.file(nn-1).name = [tmpname(1:dot-1) '_ch1' tmpname(dot:end)];
            tmpdata.file(nn).name = [tmpname(1:dot-1) '_ch2' tmpname(dot:end)];
            if isfield(newdata,'aux1') && ~isempty(newdata.aux1); tmpdata.file(nn-1).aux1 = newdata.aux1; tmpdata.file(nn).aux1 = newdata.aux1;end
            if isfield(newdata,'aux2') && ~isempty(newdata.aux2); tmpdata.file(nn-1).aux2 = newdata.aux2; tmpdata.file(nn).aux2 = newdata.aux2;end
            if isfield(newdata,'aux2') && isempty(newdata.aux2); tmpdata.file(nn-1).aux2 = newdata.aux1; tmpdata.file(nn).aux2 = newdata.aux1;end
            if isfield(newdata,'aux3') && ~isempty(newdata.aux3); tmpdata.file(nn-1).aux3 = newdata.aux3; tmpdata.file(nn).aux3 = newdata.aux3;end
            if isfield(newdata,'ephys') && ~isempty(newdata.ephys); tmpdata.file(nn-1).ephys = newdata.ephys; tmpdata.file(nn).ephys = newdata.ephys; end
            clear newdata;
            tmpdata.file(nn-1).roi = []; tmpdata.file(nn).roi = [];
            tmptsdata.file = tmpdata.file(nn-1:nn);
            tmptsdata.file(1).im = tmpim{1}; tmptsdata.file(2).im = tmpim{2};
            tmptsdata = computeTimeSeries(tmptsdata,tmpdata.roi);
            tmptsdata.file = rmfield(tmptsdata.file,'im');
            tmpdata.file(nn-1:nn) = tmptsdata.file;
        else
            tmpdata.file(nn).name = tmpname;
            if isfield(newdata,'aux1') && ~isempty(newdata.aux1); tmpdata.file(nn).aux1 = newdata.aux1; end
            if isfield(newdata,'aux2') && ~isempty(newdata.aux2); tmpdata.file(nn).aux2 = newdata.aux2; end
            if isfield(newdata,'aux2') && isempty(newdata.aux2); tmpdata.file(nn).aux2 = newdata.aux1; end
            if isfield(newdata,'aux3') && ~isempty(newdata.aux3); tmpdata.file(nn).aux3 = newdata.aux3; end
            if isfield(newdata,'ephys') && ~isempty(newdata.ephys); tmpdata.file(nn).ephys = newdata.ephys; end
            clear newdata;
            tmpdata.file(nn).roi = [];
            tmptsdata.file = tmpdata.file(nn);
            tmptsdata.file.im = tmpim;
            tmptsdata = computeTimeSeries(tmptsdata,tmpdata.roi);
            tmptsdata.file = rmfield(tmptsdata.file,'im');
            tmpdata.file(nn) = tmptsdata.file;
        end
        clear tmpim tmpname;
    end
    if isfield(IAdata,'def_stimulus') && ~isempty(IAdata.def_stimulus)
        tmpdata.def_stimulus=IAdata.def_stimulus;
    end
    TimeSeriesAnalysis_MWLab(tmpdata); clear tmpdata;
end

function CBmapsAnalysis(~,~)
    if isempty(IAdata.file(1).name); return; end
    selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    tmpbar = waitbar(0,'Generating MapsData');
    mapsdata.basetimes(1)=str2double(get(findobj(hIA,'Tag','preStimStart'),'String'));
    mapsdata.basetimes(2)=str2double(get(findobj(hIA,'Tag','preStimEnd'),'String'));
    mapsdata.resptimes(1)=str2double(get(findobj(hIA,'Tag','postStimStart'),'String'));
    mapsdata.resptimes(2)=str2double(get(findobj(hIA,'Tag','postStimEnd'),'String'));
    %stimstr = {'Aux1(odor)', 'Aux2(sniff)', 'AuxCombo', 'Defined Stimulus'}; %must match makeMaps.m
    stimstr = getauxtypes; %must match makeMaps.m
    if get(findobj(hIA,'Tag','Aux'),'Value')==1; mapsdata.stim2use = stimstr{1};
    elseif get(findobj(hIA,'Tag','Aux'),'Value')==2; mapsdata.stim2use = stimstr{2};
    elseif get(findobj(hIA,'Tag','Aux'),'Value')==3; mapsdata.stim2use = stimstr{3};
    elseif get(findobj(hIA,'Tag','Aux'),'Value')==4; mapsdata.stim2use = stimstr{4};
    end
    %if only current file is selected, use it.
    if numel(selected) == 1 && strfind(IAdata.currentimagename,IAdata.file(selected(1)).name(1:end-4))
        tmpdata.type = IAdata.type;
        tmpdata.name = IAdata.currentimagename;
        tmpdata.dir = IAdata.file(selected(1)).dir;
        tmpdata.im = IAdata.currentimage;
        if iscell(tmpdata.im)
            tmpdata.size = [size(tmpdata.im{1},1) size(tmpdata.im{1},2)];
        else
            tmpdata.size = [size(tmpdata.im,1) size(tmpdata.im,2)];
        end
        tmpdata.frameRate = IAdata.currentframeRate;
        tmpdata.frames = size(IAdata.currentimage,3);
        tmpdata.aux1 = IAdata.currentAux1; tmpdata.aux2 = IAdata.currentAux2; tmpdata.aux3 = IAdata.currentAux3;
        if get(findobj(hIA,'Tag','Aux'),'Value')==3
            if strcmp(tmpdata.type,'scanimage') %scanimage (only gets "on" signal for odor - need to input duration)
                odorDuration = str2double(get(findobj(hIA,'Tag','duration'),'String'));
                tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2,odorDuration);
                mapsdata.odorDuration = odorDuration;
            else
                tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2);
            end
        elseif get(findobj(hIA,'Tag','Aux'),'Value')==4
            tmpdata.def_stimulus = IAdata.def_stimulus;
            mapsdata.def_stimulus = IAdata.def_stimulus;
        end
        if iscell(tmpdata.im)
            %channel 1
            dot = strfind(tmpdata.name,'.');
            mapsdata.file(1).type = tmpdata.type;
            mapsdata.file(1).name = [tmpdata.name(1:dot-1) '_ch1' tmpdata.name(dot:end)];
            mapsdata.file(1).dir = tmpdata.dir;
            mapsdata.file(1).size = tmpdata.size;
            mapsdata.file(1).frameRate = tmpdata.frameRate; mapsdata.file(1).frames = size(tmpdata.im{1},3);
            mapsdata.file(1).odors = []; mapsdata.file(1).odor = [];
            tmpdata1 = rmfield(tmpdata,'im'); tmpdata1.im = tmpdata.im{1};
            tmpMaps = makeMaps(tmpdata1, mapsdata.stim2use, mapsdata.basetimes, mapsdata.resptimes);
            mapsdata.file(1).odors = tmpMaps.file.odors; mapsdata.file(1).odor = tmpMaps.file.odor;
            %mapsdata.file(1).tenthprctileim = tmpMaps.file.tenthprctileim;
            %channel 2
            dot = strfind(tmpdata.name,'.');
            mapsdata.file(2).type = tmpdata.type;
            mapsdata.file(2).name = [tmpdata.name(1:dot-1) '_ch2' tmpdata.name(dot:end)];
            mapsdata.file(2).dir = tmpdata.dir;
            mapsdata.file(2).size = tmpdata.size;
            mapsdata.file(2).frameRate = tmpdata.frameRate; mapsdata.file(2).frames = size(tmpdata.im{2},3);
            mapsdata.file(2).odors = []; mapsdata.file(2).odor = [];
            tmpdata2 = rmfield(tmpdata,'im'); tmpdata2.im = tmpdata.im{2};
            tmpMaps = makeMaps(tmpdata2, mapsdata.stim2use, mapsdata.basetimes, mapsdata.resptimes);
            mapsdata.file(2).odors = tmpMaps.file.odors; mapsdata.file(2).odor = tmpMaps.file.odor;
            %mapsdata.file(2).tenthprctileim = tmpMaps.file.tenthprctileim;
            clear tmpdata tmpdata2;
        else
            mapsdata.file.type = tmpdata.type;
            mapsdata.file.name = tmpdata.name;
            mapsdata.file.dir = tmpdata.dir;
            mapsdata.file.size = tmpdata.size;
            mapsdata.file.frameRate = tmpdata.frameRate; mapsdata.file.frames = tmpdata.frames;
            mapsdata.file.odors = []; mapsdata.file.odor = [];
            tmpMaps = makeMaps(tmpdata, mapsdata.stim2use, mapsdata.basetimes, mapsdata.resptimes);
            mapsdata.file.odors = tmpMaps.file.odors; mapsdata.file.odor = tmpMaps.file.odor;
            %mapsdata.file.tenthprctileim = tmpMaps.file.tenthprctileim;
            clear tmpdata;
        end
    else
        nn = 0; %keep track of files and two-channel stuff
        if strcmp(IAdata.type,'neuroplex'); bncmap = IAdata.aux2bncmap; end
        for f = 1:numel(selected)
            waitbar(f/numel(selected),tmpbar);
            if strcmp(IAdata.type,'neuroplex')
                tmpdata = loadFile_MWLab(IAdata.type,IAdata.file(selected(f)).dir,IAdata.file(selected(f)).name,bncmap);
            else
                tmpdata = loadFile_MWLab(IAdata.type,IAdata.file(selected(f)).dir,IAdata.file(selected(f)).name);
            end
            %mapsdata images
            if get(findobj(hIA,'Tag','align_checkbox'),'value')
                % check to see if .align file exists first!
                dot = strfind(tmpdata.name,'.'); if isempty(dot); dot=length(tmpdata.name)+1; end
                alignfile = [fullfile(tmpdata.dir,tmpdata.name(1:dot)) 'align'];
                if exist(alignfile,'file')==2
                    fprintf('Using existing .align file: %s.\n',alignfile);
                    tmp = load(alignfile,'-mat');
                    m=tmp.m; T = tmp.T; idx = tmp.idx;
                    for i = 1:length(idx)
                        if iscell(tmpdata.im)
                            tmpdata.im{1}(:,:,idx(i)) = circshift(tmpdata.im{1}(:,:,idx(i)),T(i,:));
                            tmpdata.im{2}(:,:,idx(i)) = circshift(tmpdata.im{2}(:,:,idx(i)),T(i,:));
                        else
                            tmpdata.im(:,:,idx(i)) = circshift(tmpdata.im(:,:,idx(i)),T(i,:));
                        end
                    end
                    tmpdata.name=[tmpdata.name(1:dot-1) '_aligned' tmpdata.name(dot:end)];
                else
                    fprintf('No .align file found; aligning image %s',tmpdata.name);
                    [tmpdata.im,tmpdata.name] = alignThisImage(tmpdata.im,tmpdata.name);                
                end
            end
            if get(findobj(hIA,'Tag','Aux'),'Value')==3
                if strcmp(tmpdata.type,'scanimage') %scanimage (only gets "on" signal for odor - need to input duration)
                    odorDuration = str2double(get(findobj(hIA,'Tag','duration'),'String'));
                    tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2,odorDuration);
                    mapsdata.odorDuration = odorDuration;
                else
                    tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2);
                end
            elseif get(findobj(hIA,'Tag','Aux'),'Value')==4
                tmpdata.def_stimulus = IAdata.def_stimulus;
                 mapsdata.def_stimulus = tmpdata.def_stimulus;
            end
            if iscell(tmpdata.im)
                nn=nn+2;
                %channel 1
                dot = strfind(tmpdata.name,'.');
                mapsdata.file(nn-1).type = tmpdata.type;
                mapsdata.file(nn-1).name = [tmpdata.name(1:dot-1) '_ch1' tmpdata.name(dot:end)];
                mapsdata.file(nn-1).dir = tmpdata.dir;
                mapsdata.file(nn-1).size = tmpdata.size;
                mapsdata.file(nn-1).frameRate = tmpdata.frameRate; mapsdata.file(nn-1).frames = size(tmpdata.im{1},3);
                mapsdata.file(nn-1).odors = []; mapsdata.file(nn-1).odor = [];
                tmpdata1 = rmfield(tmpdata,'im'); tmpdata1.im = tmpdata.im{1};
                tmpMaps = makeMaps(tmpdata1, mapsdata.stim2use, mapsdata.basetimes, mapsdata.resptimes);
                mapsdata.file(nn-1).odors = tmpMaps.file.odors; mapsdata.file(nn-1).odor = tmpMaps.file.odor;
                %mapsdata.file(nn-1).tenthprctileim = tmpMaps.file.tenthprctileim;
                %channel 2
                mapsdata.file(nn).type = tmpdata.type;
                mapsdata.file(nn).name = [tmpdata.name(1:dot-1) '_ch2' tmpdata.name(dot:end)];
                mapsdata.file(nn).dir = tmpdata.dir;
                mapsdata.file(nn).size = tmpdata.size;
                mapsdata.file(nn).frameRate = tmpdata.frameRate; mapsdata.file(nn).frames = size(tmpdata.im{2},3);
                mapsdata.file(nn).odors = []; mapsdata.file(nn).odor = [];
                tmpdata2 = rmfield(tmpdata,'im'); tmpdata2.im = tmpdata.im{2};
                tmpMaps = makeMaps(tmpdata2, mapsdata.stim2use, mapsdata.basetimes, mapsdata.resptimes);
                mapsdata.file(nn).odors = tmpMaps.file.odors; mapsdata.file(nn).odor = tmpMaps.file.odor;
                %mapsdata.file(nn).tenthprctileim = tmpMaps.file.tenthprctileim;
                clear tmpdata tmpdata2;
            else
                nn=nn+1;
                mapsdata.file(nn).type = tmpdata.type;
                mapsdata.file(nn).name = tmpdata.name;
                mapsdata.file(nn).dir = tmpdata.dir;
                mapsdata.file(nn).size = tmpdata.size;
                mapsdata.file(nn).frameRate = tmpdata.frameRate; mapsdata.file(nn).frames = size(tmpdata.im,3);
                mapsdata.file(nn).odors = []; mapsdata.file(nn).odor = [];
                tmpMaps = makeMaps(tmpdata, mapsdata.stim2use, mapsdata.basetimes, mapsdata.resptimes);
                mapsdata.file(nn).odors = tmpMaps.file.odors; mapsdata.file(nn).odor = tmpMaps.file.odor;
                %mapsdata.file(nn).tenthprctileim = tmpMaps.file.tenthprctileim;
                clear tmpdata;
            end
        end
    end
    delete(tmpbar);
    if isfield(IAdata,'roi'); mapsdata.roi=IAdata.roi; end
    MapsAnalysis_MWLab(mapsdata);
end

function [tmpim,tmpname] = alignThisImage(tmpim,tmpname)
    startF = str2double(get(findobj(hIA,'Tag','alignStart'),'String'));
    endF = str2double(get(findobj(hIA,'Tag','alignEnd'),'String'));
    idx=startF:endF;
    if iscell(tmpim)
        [~,m,T] = alignImage_MWLab(tmpim{1},idx);
        for f = startF:endF
            tmpim{1}(:,:,f) = circshift(tmpim{1}(:,:,f),T(f-startF+1,:));
            tmpim{2}(:,:,f) = circshift(tmpim{2}(:,:,f),T(f-startF+1,:));
        end
    else
        [~,m,T] = alignImage_MWLab(tmpim,idx);
        for f = startF:endF
            tmpim(:,:,f) = circshift(tmpim(:,:,f),T(f-startF+1,:));
        end
    end
    dot = strfind(tmpname,'.');
    if get(findobj(hIA,'Tag','savealign_checkbox'),'value')
        %save results - if you do this, then the file will reload using saved alignments, so you can't undo it in the GUI
        name = [tmpname(1:dot) 'align'];
        selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
        save(fullfile(IAdata.file(selected(1)).dir,name),'m','T','idx');
    end
    tmpname=[tmpname(1:dot-1) '_aligned' tmpname(dot:end)];
    hIA.UserData.IAdata = IAdata;
end

function CBsaveDeltaF_AVI(~, ~) %save a difference map .avi movie (current frame - mean(start frames))
    if ~max((get(findobj(hIA,'Tag','fig2_mode'), 'Value') == [5 6]))
        errordlg('Set display mode to one of the "Difference" modes and choose start frames');
        return;
    end
    if ~get(findobj(hIA,'Tag','dividebyF'), 'Value')
        tmp = questdlg('Normalize by F not selected, do you want to continue?',...
            'Yes','No');
        if strcmp(tmp,'No')
            return;
        end
    end
    if iscell(IAdata.currentimage)
        tmpim = IAdata.currentimage{get(findobj(hIA,'Tag','channel_list'),'Value')};
        dot = strfind(IAdata.currentimagename,'.'); if isempty(dot);dot=length(IAdata.currentimagename)+1; end
        tmpname = [IAdata.currentimagename(1:dot-1) '_ch' num2str(get(findobj(hIA,'Tag','channel_list'),'Value')) IAdata.currentimagename(dot:end)];
    else
        tmpim = IAdata.currentimage;
        tmpname = IAdata.currentimagename;
    end
    tmpname = strcat(tmpname(1:end-4),'.deltaF.avi');
	selected = get(findobj(hIA,'Tag','name_listbox'),'Value');
    tmpname = fullfile(IAdata.file(selected(1)).dir,tmpname);
    tmpim = double(tmpim);
    % compute current frame - mean(start frame(s))
    startframe = str2num(get(findobj(hIA,'Tag','startframes'), 'String'));
    imA = mean(tmpim(:,:,startframe), 3);
    for i = 1:size(tmpim,3)
        tmpim(:,:,i) = tmpim(:,:,i) - imA;
    end
    % Check for normalization, filters
    % Normalize by F
    if (get(findobj(hIA,'Tag','dividebyF'), 'Value')==1)
        fMode = get(findobj(hIA,'Tag','Ftype'), 'Value');
        switch fMode
            case 1 %Mean (Start Frames)
                normim = imA;
            case 2 %Mean (All frames)
                normim = mean(tmpim,3);
            case 3 %Min (10th percentile)
                %tcr this will crash with many frames! see drawfig2 to fix
                normim = double(prctile(tmpim, 10, 3));
        end
        normim(normim==0)=1; %avoid divide by zero errors
        for i = 1:size(tmpim,3)
            tmpim(:,:,i) = 100*tmpim(:,:,i)./normim;
        end
    end
    %spatial filter
    if get(findobj(hIA,'Tag','fig2_lpf'), 'Value')
        sigma = str2double(get(findobj(hIA,'Tag','fig2_lpf_radius'), 'String'));
        tmpim = imfilter_spatialLPF(tmpim,sigma);
    end
    %Apply Cmin/Cmax to threshold
    thresh = questdlg('Would you like to use [Cmin:Cmax] to Threshhold the movie','Yes','No');
    if strcmp(thresh,'Yes')
        tmpmin = str2double(get(findobj(hIA,'Tag','black_pix'), 'String'));
        tmpmax = str2double(get(findobj(hIA,'Tag','white_pix'), 'String'));
        tmp1 = tmpim<tmpmin; tmpim(tmp1)=tmpmin;
        tmp2 = tmpim>tmpmax; tmpim(tmp2)=tmpmax;
    end
    % write .avi
    vidObj = VideoWriter(tmpname, 'Uncompressed AVI');
    vidObj.FrameRate = str2double(inputdlg('Enter Frame/sec for movie (current value shown below):',...
                'Get Frame Rate',1,{num2str(IAdata.currentframeRate)}));
    open(vidObj);
    hAx_ax2 = findobj(hIA,'Tag','ax2');
    cmap = colormap(hAx_ax2);
    F.colormap = cmap;
    tmpmin = min(tmpim(:)); tmpmax = max(tmpim(:));
    for i = 1:size(tmpim,3)
        temp = tmpim(:,:,i);    
        temp = (temp-tmpmin)./(tmpmax-tmpmin);
        temp = uint8(temp.*255);
        F.cdata = temp;
        writeVideo(vidObj, F);
    end
    close(vidObj);
    helpdlg('File Saved');
end

function CBsetFmask(src,~)
    if strcmp(src.Style,'slider')
        tmpval=round(src.Value);
        set(findobj(hIA,'Tag','Fmask_edit'),'String',num2str(src.Value));
    else
        tmpval = round(str2double(get(findobj(hIA,'Tag','Fmask_edit'),'String')));
        if tmpval<get(findobj(hIA,'Tag','Fmask_slider'),'Min'); tmpval=get(findobj(hIA,'Tag','Fmask_slider'),'Min'); end
        if tmpval>get(findobj(hIA,'Tag','Fmask_slider'),'Max'); tmpval=get(findobj(hIA,'Tag','Fmask_slider'),'Max'); end
        set(findobj(hIA,'Tag','Fmask_slider'),'Value',tmpval);
    end
    set(findobj(hIA,'Tag','Fmask_edit'),'String',num2str(tmpval));
    drawFig2;
end

end