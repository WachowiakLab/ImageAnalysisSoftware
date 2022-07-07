function hIA = NewImageAnalysis_MWLab(varargin)
% hIA = ImageAnalysis_MWLab(varargin)
% GUI for Flourescence Microscopy Image Analysis
% hIA is the GUI figure handle, data is stored as hIA.UserData.IAdata
% if varargin is empty, just opens the GUI
% else, varargin{1} must be mwfile struct (see loadFile_MWLab.m for more info)
%
% EXAMPLE:
% ImageAnalysis_MWLab(mwfile)

%% -------------------------------------------------------------------------
% Created/ Last Edited by:
% Thomas Rust: March, 2019 (Updated to include deltaF movie options and odortrials selection)
% -------------------------------------------------------------------------
% Notes:
%   -The current version is designed to load only 1 image stack (or average of selected images)
%    in order to reduce the memory load due to some large(>5GB) data files
%   -Global variables have been eliminated. Data is stored/updated as hIA.UserData.IAdata (hIA=gcf;)
%   -Select multiple files after clicking TimeSeries data or MapsData, or use batch script
%
% Suggestions for future work:
%   -update code to an object-oriented programming style
%   -improve where to send mouse focus after <enter> or <tab> key press in uicontrols
%   -add/move some features to the menubar (e.g. batch functions)
%   -add back in an auto ROI feature (Scanbox method, CellSort1.0 or other)
%   -create an hdf5 file type specific to our lab
%
%   -------------------------------------------------------------------------
%%
% Close previous
tmppath=which('NewImageAnalysis_MWLab');
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
figurename = [pathparts{end} '/' guiname];

prev = findobj('Name',figurename);
if ~isempty(prev); close(prev); end

typestr = getdatatypes;
cmapstrings = getcmaps;
auxstr = [getauxtypes; 'none selected'];
%load previous settings file
try
    load(fullfile(guipath,'newIAsettings.mat'),'-mat','IAsettings');
catch
end
if ~exist('IAsettings','var')
    getDefaultSettings;
end
function getDefaultSettings
    IAsettings.figpos = [0.1 0.05 0.8 0.85];
    IAsettings.divXpos = 0.29;
    IAsettings.pathstr = '.';
    IAsettings.datatypeval = 1;
    IAsettings.brightpct = 0.1;
    IAsettings.lpf_radius = 0.75;
    IAsettings.dispmodeval = 1;
    IAsettings.cmapval = 1;
    IAsettings.fstart = 0.0;
    IAsettings.fstop = 3.0;
    IAsettings.fmask = 50;
    IAsettings.overlaypct = 10.0;
    IAsettings.auxval = 1;
    IAsettings.delay = 3.0;
    IAsettings.duration = 3.0;
    IAsettings.interval = 10.0;
    IAsettings.trials = 1;
    IAsettings.avgtrialsval = 1;
    IAsettings.trial_prestimtime = 3.0;
    IAsettings.trial_poststimtime = 3.0;
    IAsettings.map_basetimes = [-3.0 0.0];
    IAsettings.map_resptimes = [0.0 3.0];
    IAsettings.map_fmask = 50;
end
% Read command line arguments
IAdata.file.type = '';
IAdata.file.dir = '';
IAdata.file.name = '';
if nargin; IAdata.file = varargin{1}; end
if nargin > 1
    errordlg(sprintf('Incorrect number of input arguments;\nType <help %s>  for more info!',guiname));
    return;
end
%%
% GUI figure setup
BGCol = [204 255 255]/255; %GUI Background Color
hIA = figure('NumberTitle','off','Name',figurename,'Units','Normalized','Position',IAsettings.figpos,...
    'Color',BGCol,'CloseRequestFcn',@CB_CloseFig);
hIA.UserData.IAdata = IAdata;
set(hIA, 'DefaultAxesLineWidth', 2, 'DefaultAxesFontSize', 12); %Used by axes objects with plots
hmenu = uimenu(hIA,'Text','GUI Settings');
uimenu(hmenu,'Text','Save Settings','Callback',@CBSaveSettings);
uimenu(hmenu,'Text','Load Settings','Callback',@CBLoadSettings);
uimenu(hmenu,'Text','Default Settings','Callback',@CBDefaultSettings);
%tcr -add restore original settings

%Divider Panel - left/right adjustable
uipanel(hIA,'Tag','divider','Units','Normalized','BackgroundColor',[0.5 0.5 0.5],...
    'Position',[IAsettings.divXpos 0 0.01 1],'ButtonDownFcn',@CBdivider);

%Controls Panel
fsize = 10;
hpControls = uipanel(hIA,'Tag','ControlsPanel','Units','Normalized','BackgroundColor',BGCol,...
    'Position',[0 0 IAsettings.divXpos 1]);
uicontrol(hpControls,'Style','pushbutton','Units','normalized','Position',[0.05 0.95 0.3 0.04],...
    'String', 'Load File', 'FontWeight', 'Bold', 'Callback', @CBloadFile);
uicontrol(hpControls,'Style','pushbutton','Units','normalized','Position',[0.4 0.95 0.3 0.04],...
    'String', 'File info','FontWeight','Bold', 'Callback',@CBgetFileInfo);
uicontrol(hpControls,'Tag','channel_list','Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [0.75 0.95 0.2 0.04], 'String', {'channel 1'; 'channel 2'}, 'Callback', ...
    @CBselectStimulus, 'Min', 1, 'Max', 2, 'Value', 1, 'Visible', 'off');
uicontrol(hpControls,'Style', 'text', 'String', 'File: ','FontSize',fsize,'Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.05 .91 .1 .02],'HorizontalAlignment','Left');
uicontrol(hpControls,'Tag','file_text','Style', 'text', 'String', IAdata.file.name,'Units','normalized', ...
    'BackgroundColor', [1 1 1],'Position',[0.12 .90 .58 .04],'HorizontalAlignment' ...
    ,'Left', 'FontSize', fsize);
if ismember(IAdata.file.type,typestr)
    IAsettings.datatypeval = find(strcmp(IAdata.file.type,typestr));
end
uicontrol(hpControls,'Tag','dataType','Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [0.72 .91 .23 .02], 'String', typestr, 'Max', 0, 'Min', 0,'Value', IAsettings.datatypeval);
 %alignment
uicontrol(hpControls,'Tag','align_checkbox','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.05 0.87 0.5 0.02], 'String', 'Align Time Frames:',...
    'FontSize',fsize,'Enable','on', 'Callback', @CBalign,...
    'TooltipString',sprintf(['Shift selected timeframes to align with last frame of image (see alignImage_MWLab.m)\n'...
    '2-channel data is currently aligned using the first channel, then results are applied to both']));
uicontrol(hpControls,'Tag','alignStart','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.42 0.865 0.12 0.03],'HorizontalAlignment','Right');
uicontrol(hpControls,'Style', 'text', 'String', 'to','Units','normalized', ...
    'BackgroundColor',BGCol,'Position',[0.56 0.87 0.05 0.02],'HorizontalAlignment','Left');
uicontrol(hpControls,'Tag','alignEnd','Style', 'edit', 'String', '1','Units','normalized', ...
    'BackgroundColor',[1 1 1],'Position',[0.61 0.865 0.12 0.03],'HorizontalAlignment','Right');
 %suppress bright pixels
uicontrol(hpControls,'Tag','suppressbright','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.05 0.83 0.5 0.02],'FontSize', fsize, ...
    'Callback', @CBupdateMovie, 'BackgroundColor', BGCol, 'String', 'Suppress bright pixels');
uicontrol(hpControls,'Tag','brightpct','Style', 'edit', 'String', IAsettings.brightpct,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.42 0.825 0.12 0.03],'HorizontalAlignment','Right', ...
    'Callback', @CBupdateMovie);
uicontrol(hpControls,'Style', 'text', 'String', '%(replace w/ local median)','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.56 0.83 0.4 0.02],'HorizontalAlignment','Left');
 %spatial filter
uicontrol(hpControls,'Tag','lpf','Style', 'checkbox', 'Value', 0,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.05 0.79 0.5 0.02],'FontSize',fsize, ...
    'Callback', @CBupdateMovie, 'BackgroundColor', BGCol, 'String', 'Gauss Spatial Filter @');
uicontrol(hpControls,'Tag','lpf_radius','Style', 'edit', 'String', IAsettings.lpf_radius,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.42 0.785 0.12 0.03],'HorizontalAlignment','Right', ...
    'Callback', @CBupdateMovie);
uicontrol(hpControls,'Style', 'text', 'String', 'pixels','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.56 0.79 0.35 0.02],'HorizontalAlignment','Left');
 % Display Mode
dispstr{1} = 'Mean Fluorescence Image';
dispstr{2} = 'Fluorescence Movie';
dispstr{3} = 'DeltaF Image';
dispstr{4} = 'DeltaF Movie';
dispstr{5} = '%DeltaF/FO Image';
dispstr{6} = '%DeltaF/FO Movie';
dispstr{7} = 'Overlay %DeltaF/FO Movie';
uicontrol(hpControls,'Style', 'text', 'String', 'Display: ','Units','Normalized',...
    'HorizontalAlignment','Right', 'BackgroundColor',BGCol,'Fontsize',fsize,...
    'Position',[0.02 0.73 0.2 0.03]);
uicontrol(hpControls,'Tag','dispmode','Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [0.22 0.745 0.32 0.02], 'String', dispstr,'Callback', @CBchangemode, ...
    'Value',IAsettings.dispmodeval, 'BackgroundColor', [1 1 1],'FontSize',fsize);
 % F0 window
ftimevis = 'off';
uicontrol(hpControls,'Tag','fowindow','style','text','string','F0 window (sec):','Units','Normalized',...
    'Position',[0.57 0.755 0.22 0.02],'BackgroundColor',BGCol,'HorizontalAlignment','left',...
    'Visible',ftimevis);
uicontrol(hpControls,'Tag','fstart','Style', 'edit', 'String', num2str(IAsettings.fstart),'Units','Normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.78 0.757 0.06 0.02],'HorizontalAlignment','Right',...
    'Visible',ftimevis,'Callback',@CBupdateMovie);
uicontrol(hpControls,'Tag','fto','Style','text','String','to','Units','Normalized','Position',[0.85 0.755 0.04 0.02],...
    'BackgroundColor',BGCol,'Visible',ftimevis);
uicontrol(hpControls,'Tag','fstop','Style', 'edit', 'String', num2str(IAsettings.fstop),'Units','Normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.89 0.757 0.06 0.02],'HorizontalAlignment','Right',...
    'Visible',ftimevis,'Callback',@CBupdateMovie);
 % F mask
fmaskvis = 'off';
uicontrol(hpControls,'Tag','fmasklabel','style','text','string','F mask:','Units','Normalized',...
    'Position',[0.57 0.726 0.1 0.02],'BackgroundColor',BGCol,'HorizontalAlignment','left',...
    'Visible',fmaskvis);
uicontrol(hpControls,'Tag','fmaskslider','style','slider','Units','Normalized','Position',[0.66 0.728 0.22 0.02],...
    'Visible',fmaskvis,'Value',IAsettings.fmask,'Max',IAsettings.fmask*2,'Callback',@CBsetFmask);
uicontrol(hpControls,'Tag','fmaskedit','Style', 'edit', 'String', num2str(IAsettings.fmask),'Units','Normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.89 0.728 0.06 0.02],'HorizontalAlignment','Right',...
    'Visible',fmaskvis,'Callback',@CBsetFmask);
% colormap
uicontrol(hpControls,'Style', 'text', 'String', 'Colormap: ','Units','normalized','HorizontalAlignment','Right', ...
    'BackgroundColor',BGCol,'Fontsize',fsize,'Position',[0.02 0.685 0.2 0.03]);
uicontrol(hpControls,'Tag','cmapval','Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [0.22 0.7 0.32 0.02], 'String', cmapstrings,'Callback', @CBcmap, ...
    'Value',IAsettings.cmapval, 'BackgroundColor', [1 1 1],'FontSize',fsize);
 % Cmin/Cmax Thresholding Options
uicontrol(hpControls,'Tag','stack_auto','Style', 'radiobutton',  'Units', 'normalized', 'Position', ...
    [0.05 0.635 0.3 0.05], 'String','<html><center>Auto Caxis<br>(0.02-99.8%)','FontWeight','Bold', ...
    'FontSize',fsize, 'BackgroundColor', BGCol, 'Value', 1, 'Callback', @CBdrawFrame);
uicontrol(hpControls,'Style', 'text', 'String', 'Cmin: ','Units','normalized','FontSize',fsize, ...
    'BackgroundColor',BGCol,'Position',[0.3 0.66 0.12 0.02],'HorizontalAlignment','Right');
uicontrol(hpControls,'Tag','stack_blackpix','Style', 'edit', 'String', '0','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.42 0.66 0.12 0.02],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFrame, 'Enable', 'Off');
uicontrol(hpControls,'Tag','stack_min','Style', 'text', 'String', '(0)','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.55 0.657 0.1 0.02],'HorizontalAlignment','Left');
uicontrol(hpControls,'Style', 'text', 'String', 'Cmax: ','Units','normalized','FontSize',fsize, ...
    'BackgroundColor',BGCol,'Position',[0.3 0.635 0.12 0.02],'HorizontalAlignment','Right');
uicontrol(hpControls,'Tag','stack_whitepix','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.42 0.635 0.12 0.02],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFrame, 'Enable', 'Off');
uicontrol(hpControls,'Tag','stack_max','Style', 'text', 'String', '(0)','Units','normalized' ...
    ,'BackgroundColor',BGCol,'Position',[0.55 0.633 0.1 0.02],'HorizontalAlignment','Left');
% Overlay
overlayvis = 'off';
hpOverlay = uipanel(hpControls,'Tag','overlaypanel','Units','Normalized','Position', [0.65 0.62 0.3 0.1],...
    'Visible',overlayvis);
uicontrol(hpOverlay,'style','text','string','Overlay %','Units','Normalized','Position',[0 0.75 .5 0.2],...
    'HorizontalAlignment','center');
uicontrol(hpOverlay,'Tag','overlaypct','Style', 'edit', 'String', num2str(IAsettings.overlaypct),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.54 0.74 .4 0.2],'HorizontalAlignment','Right','Callback',@CBoverlay);
uicontrol(hpOverlay,'Style','text','String','(or Value)','Units','normalized','Position',[0 0.55 .5 0.2]);
uicontrol(hpOverlay,'Tag','overlayval','Style', 'edit', 'String', '','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.54 0.54 .4 0.2],'HorizontalAlignment','Right','Callback',@CBoverlay);
uicontrol(hpOverlay,'Style', 'text', 'String', 'bgCmin:','Units','normalized','Position',[0 0.26 0.4 0.2],...
    'HorizontalAlignment','Right');
uicontrol(hpOverlay,'Tag','overlay_blackpix','Style', 'edit', 'String', '0','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.54 0.26 0.4 0.2],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFrame, 'Enable', 'Off');
uicontrol(hpOverlay,'Style', 'text', 'String', 'bgCmax:','Units','normalized','Position',[0 0.06 0.4 0.2],...
    'HorizontalAlignment','Right');
uicontrol(hpOverlay,'Tag','overlay_whitepix','Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.54 0.06 0.4 0.2],'HorizontalAlignment','Right', ...
    'Callback', @CBdrawFrame, 'Enable', 'Off');

annotation(hpControls,'Line',[0 1],[.61 .61]);
 % stimulus signal
 %Aux/Stimulus
auxpanel = uipanel(hpControls,'Tag','auxPanel','Units','Normalized','Position', [0.02 0.46 0.54 0.14]);
uicontrol(auxpanel, 'Style', 'text', 'String', 'Select Auxiliary Signal:','Units','Normalized',...
    'Position',[0.1 0.85 .8 0.13]);
uicontrol(auxpanel,'Tag','Aux','Style', 'popupmenu', 'Value', IAsettings.auxval, 'Units', 'normalized', ...
    'Position',[0.1 0.72 .8 0.12],'String',auxstr,'FontWeight','Bold',...
    'Callback',@CBselectStimulus);
uicontrol(auxpanel,'Tag','delay','Style', 'edit', 'String', IAsettings.delay,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.48 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off');
uicontrol(auxpanel,'Tag','delaylabel','Style', 'text', 'String', 'Initial Delay(sec)','Units','normalized' ...
    ,'Position',[0.41 0.48 0.7 0.12],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(auxpanel,'Tag','duration','Style', 'edit', 'String', IAsettings.duration,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.33 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off'); %tcrtcr: if used for scanbox - enable on and backgroundcolor green
uicontrol(auxpanel,'Tag','durationlabel','Style', 'text', 'String', 'Duration(sec)','Units','normalized' ...
    ,'Position',[0.41 0.33 0.7 0.12],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(auxpanel,'Tag','interval','Style', 'edit', 'String', IAsettings.interval,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.18 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off');
uicontrol(auxpanel,'Tag','intervallabel','Style', 'text', 'String', 'Interval(sec)','Units','normalized' ...
    ,'Position',[0.41 0.18 0.7 0.12],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(auxpanel,'Tag','trials','Style', 'edit', 'String', IAsettings.trials,'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.2 0.03 0.18 0.12],'HorizontalAlignment','Right', ...
    'Callback', @CBselectStimulus, 'Visible', 'off');
uicontrol(auxpanel,'Tag','trialslabel','Style', 'text', 'String', '# Trials','Units','normalized' ...
    ,'Position',[0.41 0.03 0.7 0.12],'HorizontalAlignment','Left', 'Visible', 'off');
uicontrol(hpControls,'Tag','avgtrials','Style','checkbox','String','Average Selected Odor Trials',...
    'FontSize',fsize,'Units','Normalized','Position',[0.05 0.43 0.54 0.025],'BackgroundColor',BGCol,...
    'Value',IAsettings.avgtrialsval,'Callback',@CBselectStimulus);
% trials settings panel
trialvis = 'off'; %show this when movie modes are selected
hp_trials = uipanel(hpControls,'Tag','trials_panel','Units','Normalized','Position',[0.02 0.36 0.54 0.065],'Visible',trialvis);
uicontrol(hp_trials,'Style','text','String','Pre-stimulus time (sec):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[0.05 0.5 0.65 0.4]);
uicontrol(hp_trials,'Tag','trial_prestimtime','Style', 'edit', 'String', num2str(IAsettings.trial_prestimtime),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.75 0.55 0.2 0.4],'HorizontalAlignment','Right','Callback',@CBselectStimulus);
uicontrol(hp_trials,'Style','text','String','Post-stimulus time (sec):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[0.05 0.05 0.65 0.4]);
uicontrol(hp_trials,'Tag','trial_poststimtime','Style', 'edit', 'String', num2str(IAsettings.trial_poststimtime),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.75 0.1 0.2 0.4],'HorizontalAlignment','Right','Callback',@CBselectStimulus);
% response maps settings panel
mapvis = 'off';%show this when df map modes are selected
hp_map = uipanel(hpControls,'Tag','maps_panel','Units','Normalized','Position',[0.02 0.36 0.54 0.065],'Visible',mapvis);
uicontrol(hp_map,'style','text','string','Base times (sec):','Units','Normalized',...
    'Position',[0.01 0.65 0.47 0.3],'HorizontalAlignment','right');
uicontrol(hp_map,'Tag','map_basestart','Style', 'edit', 'String', num2str(IAsettings.map_basetimes(1)),...
    'Units','Normalized','BackgroundColor',[1 1 1],'Position',[0.49 0.66 0.2 0.28],'HorizontalAlignment',...
    'Right','Callback',@CBselectStimulus);
uicontrol(hp_map,'Style','text','String','to','Units','Normalized','Position',[0.71 0.65 0.06 0.3]);
uicontrol(hp_map,'Tag','map_basestop','Style', 'edit', 'String', num2str(IAsettings.map_basetimes(2)),...
    'Units','Normalized','BackgroundColor',[1 1 1],'Position',[0.78 0.66 0.2 0.28],'HorizontalAlignment',...
    'Right','Callback',@CBselectStimulus);
uicontrol(hp_map,'style','text','string','Resp. times (sec):','Units','Normalized',...
    'Position',[0.01 0.33 0.47 0.3],'HorizontalAlignment','right');
uicontrol(hp_map,'Tag','map_respstart','Style', 'edit', 'String', num2str(IAsettings.map_resptimes(1)),...
    'Units','Normalized','BackgroundColor',[1 1 1],'Position',[0.49 0.34 0.2 0.28],'HorizontalAlignment',...
    'Right','Callback',@CBselectStimulus);
uicontrol(hp_map,'Style','text','String','to','Units','Normalized','Position',[0.71 0.33 0.06 0.3]);
uicontrol(hp_map,'Tag','map_respstop','Style', 'edit', 'String', num2str(IAsettings.map_resptimes(2)),...
    'Units','Normalized','BackgroundColor',[1 1 1],'Position',[0.78 0.34 0.2 0.28],'HorizontalAlignment',...
    'Right','Callback',@CBselectStimulus);
uicontrol(hp_map,'style','text','string','F mask:','Units','Normalized',...
    'Position',[0.01 0.02 0.23 0.28],'HorizontalAlignment','Right');
uicontrol(hp_map,'Tag','map_fmaskslider','style','slider','Units','Normalized','Position',[0.26 0.04 0.51 0.28],...
    'Value',IAsettings.map_fmask,'Max',IAsettings.map_fmask*2,'Callback',@CBsetMapFmask);
uicontrol(hp_map,'Tag','map_fmaskedit','Style', 'edit', 'String', num2str(IAsettings.map_fmask),...
    'Units','Normalized','BackgroundColor',[1 1 1],'Position',[0.78 0.04 0.2 0.28],...
    'HorizontalAlignment','Right','Callback',@CBsetMapFmask);
uicontrol(hpControls,'Tag','odortrialslist','style','listbox','Units','normalized',...
    'Position',[0.58 0.36 0.4 0.24],'Callback',@CBupdateMovie);

annotation(hpControls,'Line',[0 1],[.35 .35]);
 % ROIs
%ROIs Listbox & Tools
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0.29 0.25 0.04],...
    'String', 'Load ROIs','FontWeight','Bold', 'Callback', @CBloadROIs);
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.30 0.29 0.25 0.04],...
    'String', 'Draw ROI', 'FontWeight', 'Bold', 'Callback', @CBdrawROI);
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0.25 0.25 0.04],...
    'String', 'Delete ROI(s)','FontWeight','Bold', 'Callback', @CBdeleteROIs);
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.30 0.25 0.25 0.04],...
    'String', 'Shift ROI(s)', 'Fontweight', 'Bold', 'Callback', @CBshiftROIsButton_fcn);
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0.21 0.25 0.04],...
    'String', 'Save All ROIs','FontWeight','Bold', 'Callback', @CBsaveROI_button_fcn);
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.30 0.21 0.25 0.04],...
    'String', 'Clear All ROIs','FontWeight','Bold', 'Callback', @CBclearROIs);
uicontrol(hpControls,'Tag','bgsubtract','Style','checkbox','String','Subtract Background ROI #',...
    'FontSize',fsize,'Units','Normalized','Position',[0.05 0.17 0.45 0.02],'BackgroundColor',BGCol,...
    'Callback',@CBupdateMovie);
uicontrol(hpControls,'Tag','bgroi','Style', 'edit', 'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.49 0.17 0.06 0.025],'HorizontalAlignment','Right',...
    'Callback',@CBupdateMovie);
uicontrol(hpControls,'Tag','roisoverlay','Style','checkbox','String','Show ROI(s) Overlay',...
    'FontSize',fsize,'Units','Normalized','Position',[0.05 0.14 0.45 0.02],'BackgroundColor',BGCol,...
    'Callback',@CBoverlayROIs);
uicontrol(hpControls,'Tag','roisplot','Style','checkbox','String','Show ROI(s) Time Series',...
    'FontSize',fsize,'Units','Normalized','Position',[0.05 0.11 0.5 0.02],'BackgroundColor',BGCol,...
    'Callback',@CBchangemode);
uicontrol(hpControls,'Tag','roi_listbox','Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [0.58 0.1 0.4 0.24], 'Value', 1, 'BackgroundColor', [1 1 1], 'Max', 100,...
    'Min', 0, 'FontSize',10,'Callback',@CBoverlayROIs);

annotation(hpControls,'Line',[0 1],[.09 .09]);
 % MapsAnalysis
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.03 0.02 0.3 0.05],...
    'String','<html><center>Maps Analysis', 'FontWeight','Bold','Callback', @CBmapsAnalysis, ...
    'TooltipString',sprintf(['Creates Maps Data using current auxiliary signal, baseline, '...
    'and response time windows and runs MapsAnalysis_MWLab.\n']));
% TimeSeriesAnalysis
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.35 0.02 0.3 0.05], ... %.585
    'String','Time Series Analysis', 'FontWeight','Bold','Callback', @CBTimeSeriesAnalysis, ...
    'TooltipString',sprintf('Creates TimeSeriesAnalysis_MWLab data. Image filters are not applied.'));
uicontrol(hpControls,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.67 0.02 0.3 0.05], ...
    'String','Save Image/Movie', 'FontWeight','Bold','Callback', @CBsaveImageMovie);

% Movie Panel - always show image; show movie controls when needed; show time series plot when needed.
hpMovie = uipanel(hIA,'Tag','MoviePanel','Units','Normalized','BackgroundColor',[0 0 0],...
    'Position', [IAsettings.divXpos+.01 0 0.99-IAsettings.divXpos(1) 1]);
axes(hpMovie,'Tag','fPlotAx','Position',[0.01 0.82 .98 0.18],'Color',[0 0 0]); xticks([]);yticks([]);
axes(hpMovie,'Tag','MovieAx','Position',[0.0 0.1 1 0.7],'Color',[0 0 0]); xticks([]);yticks([]);
%Play movie controls
hpPlay = uipanel(hpMovie,'Tag','PlayPanel','Units','Normalized','BackgroundColor',[0 0 0],...
    'Position',[0 0 1 .1]);
uicontrol(hpPlay,'Tag','play_button','Style', 'togglebutton',  'Units', 'normalized', 'Position', ...
    [0.02 0.2 .1 0.6], 'String', 'Play','FontWeight','Bold', 'FontSize',14,'Callback', ...
    @CBplayMovie, 'Min', 0, 'Max', 1, 'Value', 0);
uicontrol(hpPlay,'Tag','speedcontrol','Style', 'checkbox', 'String', 'Speed Control','Units','normalized' ...
    ,'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 0],'Position',[0.14 0.6 .14 0.3],'HorizontalAlignment', ...
    'Left', 'FontSize', 11, 'FontWeight', 'normal');
uicontrol(hpPlay,'Tag','speedslider','Style','slider','min',1,'max',100,'value',50,'sliderstep',[1/99 1/99],...
    'Units','normalized','Position',[0.14 0.2 .14 0.3]);
uicontrol(hpPlay,'Tag','frame_slider','Style', 'Slider', 'Units', 'normalized', 'Position', ...
    [0.3 0.55 .68 0.3], 'Min', 1, 'Max', 1.4, 'Value', 1, 'SliderStep', [1 1], ...
    'Callback', @CBframeSlider, 'BackgroundColor', [1 1 1]);
uicontrol(hpPlay,'Tag','frame_text','Style', 'text', 'String', 'Frame #:','Units','normalized' ...
    ,'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 0],'Position',[0.30 0.1 .23 .3],'HorizontalAlignment','Left','FontSize',fsize);
uicontrol(hpPlay,'Tag','frameRate_text','Style', 'text', 'String', 'FrameRate:','Units','normalized' ...
    ,'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 0],'Position',[0.53 0.1 .23 .3],'HorizontalAlignment','Left','FontSize',fsize);
uicontrol(hpPlay,'Tag','duration_text','Style', 'text', 'String', 'Duration:','Units','normalized' ...
    ,'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 0],'Position',[0.76 0.1 .23 .3],'HorizontalAlignment','Left','FontSize',fsize);

% Update GUI if data is loaded
CBchangemode;

%% Nested Callback functions
function CB_CloseFig(~,~)
    %save settings file
    getSettings;
    save(fullfile(guipath,'newIAsettings.mat'),'IAsettings');
    delete(hIA);
end
function CBSaveSettings(~, ~)
    getSettings;
    [setfile,setpath] = uiputfile(fullfile(guipath,'myIAsettings.mat'));
    save(fullfile(setpath,setfile),'IAsettings');
end
function getSettings
    IAsettings.figpos = hIA.Position;
    divpos = get(findobj(hIA,'Tag','divider'),'Position');
    IAsettings.divXpos = divpos(1);
    IAsettings.pathstr = hIA.UserData.IAdata.file.dir;
    IAsettings.datatypeval = get(findobj(hIA,'Tag','dataType'),'Value');
    IAsettings.brightpct = str2double(get(findobj(hIA,'Tag','brightpct'),'string'));
    IAsettings.lpf_radius = str2double(get(findobj(hIA,'Tag','lpf_radius'),'String'));
    IAsettings.dispmodeval =  get(findobj(hIA,'Tag','dispmode'), 'Value');
    IAsettings.cmapval =  get(findobj(hIA,'Tag','cmapval'), 'Value');
    IAsettings.fstart = str2double(get(findobj(hIA,'Tag','fstart'),'String'));
    IAsettings.fstop = str2double(get(findobj(hIA,'Tag','fstop'),'String'));
    IAsettings.fmask = str2double(get(findobj(hIA,'Tag','fmaskedit'),'String'));
    IAsettings.overlaypct = str2double(get(findobj(hIA,'Tag','overlaypct'),'String'));
    IAsettings.auxval = get(findobj(hIA,'Tag','Aux'),'Value');
    IAsettings.delay = str2double(get(findobj(hIA,'Tag','delay'),'String'));
    IAsettings.duration = str2double(get(findobj(hIA,'Tag','duration'),'String'));
    IAsettings.interval = str2double(get(findobj(hIA,'Tag','interval'),'String'));
    IAsettings.trials = str2double(get(findobj(hIA,'Tag','trials'),'String'));
    IAsettings.avgtrialsval = get(findobj(hIA,'Tag','avgtrials'),'Value');
    IAsettings.trial_prestimtime = str2double(get(findobj(hIA,'Tag','trial_prestimtime'),'String'));
    IAsettings.trial_poststimtime =str2double(get(findobj(hIA,'Tag','trial_poststimtime'),'String')); 
    IAsettings.map_basetimes(1) = str2double(get(findobj(hIA,'Tag','map_basestart'),'String'));
    IAsettings.map_basetimes(2) = str2double(get(findobj(hIA,'Tag','map_basestop'),'String'));
    IAsettings.map_resptimes(1) = str2double(get(findobj(hIA,'Tag','map_respstart'),'String'));
    IAsettings.map_resptimes(2) = str2double(get(findobj(hIA,'Tag','map_respstop'),'String'));
    IAsettings.map_fmask = str2double(get(findobj(hIA,'Tag','map_fmaskedit'),'String'));
end
function setSettings
    hIA.Position = IAsettings.figpos;
    divpos = get(findobj(hIA,'Tag','divider'),'Position'); divpos(1) = IAsettings.divXpos;
    set(findobj(hIA,'Tag','divider'),'Position',divpos);
    set(findobj(hIA,'Tag','dataType'),'Value',IAsettings.datatypeval);
    set(findobj(hIA,'Tag','brightpct'),'string',num2str(IAsettings.brightpct));
    set(findobj(hIA,'Tag','lpf_radius'),'String',num2str(IAsettings.lpf_radius));
    set(findobj(hIA,'Tag','dispmode'), 'Value',IAsettings.dispmodeval);
    set(findobj(hIA,'Tag','cmapval'), 'Value',IAsettings.cmapval);
    set(findobj(hIA,'Tag','fstart'),'String',num2str(IAsettings.fstart));
    set(findobj(hIA,'Tag','fstop'),'String',num2str(IAsettings.fstop));
    set(findobj(hIA,'Tag','fmaskedit'),'String',num2str(IAsettings.fmask));
    set(findobj(hIA,'Tag','overlaypct'),'String',num2str(IAsettings.overlaypct));
    set(findobj(hIA,'Tag','Aux'),'Value',IAsettings.auxval);
    set(findobj(hIA,'Tag','delay'),'String',num2str(IAsettings.delay));
    set(findobj(hIA,'Tag','duration'),'String',num2str(IAsettings.duration));
    set(findobj(hIA,'Tag','interval'),'String',num2str(IAsettings.interval));
    set(findobj(hIA,'Tag','trials'),'String',num2str(IAsettings.trials));
    set(findobj(hIA,'Tag','avgtrials'),'Value',IAsettings.avgtrialsval);
    set(findobj(hIA,'Tag','trial_prestimtime'),'String',num2str(IAsettings.trial_prestimtime));
    set(findobj(hIA,'Tag','trial_poststimtime'),'String',num2str(IAsettings.trial_poststimtime)); 
    set(findobj(hIA,'Tag','map_basestart'),'String',num2str(IAsettings.map_basetimes(1)));
    set(findobj(hIA,'Tag','map_basestop'),'String',num2str(IAsettings.map_basetimes(2)));
    set(findobj(hIA,'Tag','map_respstart'),'String',num2str(IAsettings.map_resptimes(1)));
    set(findobj(hIA,'Tag','map_respstop'),'String',num2str(IAsettings.map_resptimes(2)));
    set(findobj(hIA,'Tag','map_fmaskedit'),'String',num2str(IAsettings.map_fmask));
    set(findobj(hIA,'Tag','map_fmaskslider'),'Value',IAsettings.map_fmask);
    CBselectStimulus;
end
function CBLoadSettings(~, ~)
    [setfile,setpath] = uigetfile(fullfile(guipath,'*.mat'));
    try
        load(fullfile(setpath,setfile),'-mat','IAsettings');
        if isempty(hIA.UserData.IAdata.file) || isempty(hIA.UserData.IAdata.file(1).dir)
            set(findobj(hIA,'Tag','dataType'),'Value',IAsettings.datatypeval);
        end
        val = IAsettings.cmapval; set(findobj(hIA,'Tag','cmapval'), 'Value',val); CBcmap;
        set(findobj(hIA,'Tag','fig_bright'),'String',num2str(IAsettings.brightpct));
        setSettings;
    catch
    end
end
function CBDefaultSettings(~,~)
    getDefaultSettings;
    setSettings;
end
function CBdivider(~,~)
    set(hIA,'WindowButtonMotionFcn',@paneldrag,'WindowButtonUpFcn',@paneldrop);
end
function paneldrag(~,~)
    divpos = get(findobj(hIA,'Tag','divider'),'Position');
    pt = get(hIA,{'CurrentPoint','Position'});
    try
        set(findobj(hIA,'Tag','divider'),'Position',[pt{1}(1) 0 0.01 1]);
        set(hpControls,'Position',[0 0 divpos(1) 1]);
        set(hpMovie,'Position',[divpos(1)+.01 0 0.99-divpos(1) 1]);
    catch
    end
    IAsettings.divXpos = pt{1}(1);
end
function paneldrop(~,~)
    divpos = get(findobj(hIA,'Tag','divider'),'Position');
    IAsettings.divXpos = divpos(1);
    set(hIA, 'WindowButtonMotionFcn', [], 'WindowButtonUpFcn', [])
end
function CBloadFile(~, ~) %load image(s), average if > 1
    hIA.UserData.IAdata.file.type = ''; hIA.UserData.IAdata.file.dir = ''; hIA.UserData.IAdata.file.name = '';
    hIA.UserData.IAdata.file.type = typestr{get(findobj(hIA,'Tag','dataType'),'Value')};
    try
        hIA.UserData.IAdata.file = loadFile_MWLab(hIA.UserData.IAdata.file.type,IAsettings.pathstr);
        if iscell(hIA.UserData.IAdata.file.im) %image is a cell if 2-channels are present!
            set(findobj(hIA,'Tag','channel_list'),'Visible','on');
            set(findobj(hIA,'Tag','channel_list'),'Value',1);
        else; set(findobj(hIA,'Tag','channel_list'),'Visible','off');
        end
        if ~isfield(hIA.UserData.IAdata.file,'aux1') || isempty(hIA.UserData.IAdata.file.aux1)
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [1,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
        end
        if ~isfield(hIA.UserData.IAdata.file,'aux2') && ~isempty(hIA.UserData.IAdata.file.aux2)
            if max(get(findobj(hIA,'Tag','Aux'),'Value') == [2,3])
                set(findobj(hIA,'Tag','Aux'),'Value', numel(get(findobj(hIA,'Tag','Aux'),'String')));
            end
        end
        IAsettings.pathstr = hIA.UserData.IAdata.file.dir;
        set(findobj(hIA,'Tag','alignStart'),'String','1');
        set(findobj(hIA,'Tag','alignEnd'),'String',num2str(size(hIA.UserData.IAdata.file.im,3)));
        if get(findobj(hpControls,'Tag','align_checkbox'),'Value'); CBalign; end
        set(findobj(hpControls,'Tag','file_text'),'String',hIA.UserData.IAdata.file.name);
        %auto-turn on avg trials for "large" datasets
        if hIA.UserData.IAdata.file.frames>500; set(findobj(hpControls,'Tag','avgtrials'),'Value',1); end
        if isfield(hIA.UserData.IAdata,'roi') && ~isempty(hIA.UserData.IAdata.roi)
            if ~isequal(size(hIA.UserData.IAdata.roi(1).mask),hIA.UserData.IAdata.file.size)
               CBclearROIs;
            end
        end
    catch
        return
    end
    CBselectStimulus;
end
function CBgetFileInfo(~,~) %calls external program to find image info from header and/or .txt files
    if isempty(hIA.UserData.IAdata.file); return; end
    getFileInfo(hIA.UserData.IAdata.file.type,hIA.UserData.IAdata.file.dir,hIA.UserData.IAdata.file.name);
end
function CBalign(~,~)
    if ~isfield(hIA.UserData.IAdata,'file') || isempty(hIA.UserData.IAdata.file.im)
        set(findobj(hIA,'Tag','align_checkbox'),'Value',0);
        return;
    end
    if get(findobj(hIA,'Tag','align_checkbox'),'value')
        startF = str2double(get(findobj(hIA,'Tag','alignStart'),'String'));
        endF = str2double(get(findobj(hIA,'Tag','alignEnd'),'String'));
        %compute alignment and save .align file... or use existing file
        hIA.UserData.IAdata.file = alignImage_MWLab(hIA.UserData.IAdata.file,startF:endF);
    else
        hIA.UserData.IAdata.file = loadFile_MWLab(hIA.UserData.IAdata.file.type,...
            hIA.UserData.IAdata.file.dir,hIA.UserData.IAdata.file.name);
        set(findobj(hIA,'Tag','align_checkbox'),'Value',0);
    end
    CBselectStimulus;
end
function CBchangemode(~,~)
    %set(findobj(hIA,'Tag','stack_auto'),'Value',1);
    if ~isfield(hIA.UserData.IAdata,'roi') || isempty(hIA.UserData.IAdata.roi)
        set(findobj(hpControls,'Tag','roisoverlay'),'Value',0);
        set(findobj(hpControls,'Tag','roisplot'),'Value',0);
    end
    %set visibility and adjust size of Image Axes for Movie Panel
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    if max(modeval == [2 4 6 7]) 
        if get(findobj(hpControls,'Tag','roisplot'),'Value') %show movie controls, show tsplot
            set(findobj(hpMovie,'Tag','fPlotAx'),'Visible','On');
            set(findobj(hpMovie,'Tag','MovieAx'),'Position',[0.0 0.1 1 0.7]);
            set(findobj(hpMovie,'Tag','PlayPanel'),'Visible','On');
        else %show movie controls, no tsplot
            cla(findobj(hIA,'Tag','fPlotAx'));
            set(findobj(hpMovie,'Tag','fPlotAx'),'Visible','Off');
            set(findobj(hpMovie,'Tag','MovieAx'),'Position',[0.0 0.1 1 0.9]);
            set(findobj(hpMovie,'Tag','PlayPanel'),'Visible','On');
        end
    else %no movie controls, no tsplot
        set(findobj(hpControls,'Tag','roisplot'),'Value',0);
        cla(findobj(hIA,'Tag','fPlotAx'));
        set(findobj(hpMovie,'Tag','fPlotAx'),'Visible','Off');
        set(findobj(hpMovie,'Tag','MovieAx'),'Position',[0.0 0.0 1 1]);
        set(findobj(hpMovie,'Tag','PlayPanel'),'Visible','Off');
    end
    CBselectStimulus;
end
function CBsetFmask(~,~) %applies to df movies
    if ~isfield(hIA.UserData.IAdata,'current') || isempty(hIA.UserData.IAdata.current); return; end
    hfmaskslider = findobj(hpControls,'Tag','fmaskslider');
    hfmaskedit = findobj(hpControls,'Tag','fmaskedit');
    clicked = hIA.CurrentObject;
    if strcmp(clicked.Tag,'fmaskslider')
        tmpval = round(clicked.Value);
    else %edit box value
        tmpval = round(str2double(clicked.String));
        if tmpval<hfmaskslider.Min; tmpval=hfmaskslider.Min; end
        if tmpval>hfmaskslider.Max; tmpval=hfmaskslider.Max; end
        hfmaskslider.Value = tmpval;
    end
    hfmaskedit.String = num2str(tmpval);
    CBupdateMovie;
end
function CBsetMapFmask(~,~) %applies to df map images
    if ~isfield(hIA.UserData.IAdata,'current') || isempty(hIA.UserData.IAdata.current); return; end
    hmapfmaskslider = findobj(hpControls,'Tag','map_fmaskslider');
    hmapfmaskedit = findobj(hpControls,'Tag','map_fmaskedit');
    clicked = hIA.CurrentObject;
    if strcmp(clicked.Tag,'map_fmaskslider')
        tmpval = round(clicked.Value);
        if tmpval<hmapfmaskslider.Min; tmpval=hmapfmaskslider.Min; end
        if tmpval>hmapfmaskslider.Max; tmpval=hmapfmaskslider.Max; end
    else %edit box value
        tmpval = round(str2double(clicked.String));
        if tmpval<hmapfmaskslider.Min; tmpval=hmapfmaskslider.Min; end
        if tmpval>hmapfmaskslider.Max; tmpval=hmapfmaskslider.Max; end
       
    end
     hmapfmaskslider.Value = tmpval;
     hmapfmaskedit.String = num2str(tmpval);
    CBupdateMovie;
end
function CBcmap(~, ~) %change colormap
    if isempty(hIA.UserData.IAdata.file); return; end
    val = get(findobj(hpControls,'Tag','cmapval'), 'Value');
    hAx_Movie = findobj(hpMovie,'Tag','MovieAx'); %hAx_ax2 = findobj(hIA,'Tag','ax2');
    if ~isempty(hAx_Movie); axes(hAx_Movie); colormap(hAx_Movie,[cmapstrings{val} '(256)']); end
end
function CBframeSlider(~, ~)
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    if modeval == 1; return; end
    ind = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    ind = round(ind);
    set(findobj(hIA,'Tag','frame_slider')', 'Value', ind);
    set(findobj(hIA,'Tag','frame_text'),'String', sprintf('Frame # %d/%d (%0.3f Sec)',...
        ind,size(hIA.UserData.IAdata.current,3),(ind-1)/hIA.UserData.IAdata.file.frameRate));
    CBdrawFrame;
    tmptime = [(ind-1)/hIA.UserData.IAdata.file.frameRate (ind-1)/hIA.UserData.IAdata.file.frameRate];
    set(findobj(hIA,'Tag','mark'),'Xdata',tmptime);%,'Ydata',tmp(ind));
end
function CBselectStimulus(~,~)
    %check that stimulus is present
    if ~isfield(hIA.UserData.IAdata,'file') || ~isfield(hIA.UserData.IAdata.file,'name') || ...
            isempty(hIA.UserData.IAdata.file.name); return; end
    if ~isfield(hIA.UserData.IAdata.file,'aux1') || isempty(hIA.UserData.IAdata.file.aux1) || ...
            max(hIA.UserData.IAdata.file.aux1.signal)==0
        if max(get(findobj(hIA,'Tag','Aux'),'Value') == [1,3])
            set(findobj(hIA,'Tag','Aux'),'Value', numel(auxstr));
        end
    end
    if ~isfield(hIA.UserData.IAdata.file,'aux2') || isempty(hIA.UserData.IAdata.file.aux2) || ...
            max(hIA.UserData.IAdata.file.aux2.signal)==0
        if max(get(findobj(hIA,'Tag','Aux'),'Value') == [2,3])
            set(findobj(hIA,'Tag','Aux'),'Value', numel(auxstr));
        end
    end
    if get(findobj(hIA,'Tag','Aux'),'Value')== numel(auxstr) && ...
            max(get(findobj(hpControls,'Tag','dispmode'),'Value') == [3 5])
        set(findobj(hpControls,'Tag','dispmode'),'Value',1);
        %tcrtcrtcr might allow df w/out odortrial
        disp('Select a valid stimulus signal before making maps!');
    end
    if get(findobj(hIA,'Tag','Aux'),'Value') == 3
        odorDuration = str2double(get(findobj(hIA,'Tag','duration'),'String'));
        if isnan(odorDuration) %empty string
            hIA.UserData.IAdata.file.aux_combo = doAuxCombo(hIA.UserData.IAdata.file.aux1,...
                hIA.UserData.IAdata.file.aux2);
        else
            hIA.UserData.IAdata.file.aux_combo = doAuxCombo(hIA.UserData.IAdata.file.aux1,...
                hIA.UserData.IAdata.file.aux2,odorDuration);            
        end
    elseif get(findobj(hIA,'Tag','Aux'),'Value') == 4; hIA.UserData.IAdata.file.def_stimulus = doDefineStimulus;
    end
    %set visibilities
    if get(findobj(hIA,'Tag','Aux'),'Value') == 3 %&& get(findobj(hIA,'Tag','dataType'),'Value') == 1 %Aux_combo w/scanimage
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
    %get odortrials (timeframes/maps) and update odortrialslist
    bavgtrials = get(findobj(hpControls,'Tag','avgtrials'),'Value');
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    auxval = get(findobj(hIA,'Tag','Aux'),'Value');
    if ismember(auxval, [1 2 3 4]) && max(modeval == [1 2 4 6 7]) && bavgtrials
        set(findobj(hpControls,'Tag','trials_panel'),'Visible','on');
        set(findobj(hpControls,'Tag','maps_panel'),'Visible','off');
        % get odortrial timeframes and update odortrialslist
        auxtype = auxstr{auxval};
        trial_prestimtime = str2double(get(findobj(hIA,'Tag','trial_prestimtime'),'String'));
        trial_poststimtime = str2double(get(findobj(hIA,'Tag','trial_poststimtime'),'String'));
        hIA.UserData.IAdata.allOdorTrials = getAllOdorTrials(auxtype,trial_prestimtime,trial_poststimtime,hIA.UserData.IAdata.file);
        cnt=0; trialstr = {};
        odors = hIA.UserData.IAdata.allOdorTrials.odors;
        for o = 1:length(odors)
            trials = hIA.UserData.IAdata.allOdorTrials.odor(o).trials;
            for t = trials
                cnt=cnt+1;
                trialstr{cnt} = ['Odor' num2str(odors(o)) 'Trial' num2str(t)];
            end
        end
        if isempty(trialstr)
            set(findobj(hpControls,'Tag','avgtrials'),'Value',0);%,'Enable','off');
            set(findobj(hpControls,'Tag','odortrialslist'),'String','','Max',1);
        else
            set(findobj(hpControls,'Tag','odortrialslist'),'Value',1);
            set(findobj(hpControls,'Tag','odortrialslist'),'String',trialstr,'Max',length(trialstr));
        end
    elseif ismember(auxval, [1 2 3 4]) && max(modeval == [3 5]) && bavgtrials
        if isfield(hIA.UserData.IAdata,'maps'); hIA.UserData.IAdata = rmfield(hIA.UserData.IAdata,'maps'); end
        set(findobj(hpControls,'Tag','trials_panel'),'Visible','off');
        set(findobj(hpControls,'Tag','maps_panel'),'Visible','on');
        % make maps and update odortrialslist
        if iscell(hIA.UserData.IAdata.file.im)
            channel = get(findobj(hIA,'Tag','channel_list'),'Value');
            tmpdata = hIA.UserData.IAdata.file;
            tmpdata = rmfield(tmpdata,'im');tmpdata.im = hIA.UserData.IAdata.file.im{channel};
        else
            tmpdata = hIA.UserData.IAdata.file;
        end
        auxtype = auxstr{auxval};
        baseTimes(1) = str2double(get(findobj(hpControls,'Tag','map_basestart'),'String'));
        baseTimes(2) = str2double(get(findobj(hpControls,'Tag','map_basestop'),'String'));
        respTimes(1) = str2double(get(findobj(hpControls,'Tag','map_respstart'),'String'));
        respTimes(2) = str2double(get(findobj(hpControls,'Tag','map_respstop'),'String'));
        mapsdata = makeMaps(tmpdata,auxtype,baseTimes,respTimes);
        clear tmpdata;
        cnt=0; trialstr = {};
        if ~isempty(mapsdata)
            odors = mapsdata.file.odors;
            for o = 1:length(mapsdata.file.odor)
                for t = 1:length(mapsdata.file.odor(o).trial)
                    cnt=cnt+1;
                    trialstr{cnt} = ['Odor' num2str(odors(o)) 'Trial' num2str(t)];
                end
            end
            hIA.UserData.IAdata.maps = mapsdata;
        else
            disp('error making maps... figure this out... try different settings'); %change display setting?
        end
        if isempty(trialstr)
            set(findobj(hpControls,'Tag','avgtrials'),'Value',0);%,'Enable','off');
            set(findobj(hpControls,'Tag','odortrialslist'),'String','','Max',1);
        else
            set(findobj(hpControls,'Tag','odortrialslist'),'Value',1);
            set(findobj(hpControls,'Tag','odortrialslist'),'String',trialstr,'Max',length(trialstr));
        end
    else
        set(findobj(hpControls,'Tag','trials_panel'),'Visible','off');
        set(findobj(hpControls,'Tag','maps_panel'),'Visible','off');
        set(findobj(hpControls,'Tag','avgtrials'),'Value',0);
        set(findobj(hpControls,'Tag','odortrialslist'),'String','','Value',0,'Max',1);
        if max(modeval == [3 5])
            waitfor(errordlg('Click on <Average Selected Odor Trials> to display maps.'));
            set(findobj(hpControls,'Tag','dispmode'),'Value',1); 
        end
    end
    CBupdateMovie;
end
function def_stimulus = doDefineStimulus %manually define a stimulus signal
    if ~isfield(hIA.UserData.IAdata.file,'frameRate'); return; end
    frames = size(hIA.UserData.IAdata.file.im,3);
    delay = str2double(get(findobj(hIA,'Tag','delay'),'String')); % #frames delay
    duration = str2double(get(findobj(hIA,'Tag','duration'),'String')); % #frames duration 
    interval = str2double(get(findobj(hIA,'Tag','interval'),'String')); % #frames interval
    trials = str2double(get(findobj(hIA,'Tag','trials'),'String'));
    trials = min(trials,floor((frames/hIA.UserData.IAdata.file.frameRate-delay+interval)/(duration+interval)));
    set(findobj(hIA,'Tag','trials'),'String',trials);
    endT = frames/hIA.UserData.IAdata.file.frameRate;
    deltaT=1/150; %hardcoded: Stimulus sampling rate is set at 150Hz (lab standard)
    def_stimulus = defineStimulus(0,endT,deltaT,delay,duration,interval,trials);
end
function CBupdateMovie(~,~)
    IAdata = hIA.UserData.IAdata;
    if ~isfield(IAdata.file,'im') || isempty(IAdata.file.im); return; end
    if ~isfield(IAdata,'file') || ~isfield(IAdata.file,'im') || isempty(IAdata.file.im); return; end
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi)
        set(findobj(hpControls,'Tag','bgsubtract'),'value',0)
    end
    if iscell(IAdata.file.im); channel = get(findobj(hIA,'Tag','channel_list'),'Value'); end
    if get(findobj(hpControls,'Tag','bgsubtract'),'value') %background roi
        RoiNum = str2double(get(findobj(hpControls,'Tag','bgroi'),'String'));
        if isnan(RoiNum) || RoiNum>length(IAdata.roi)
            fprintf('Background ROI # %d not found\n',RoiNum);
            set(findobj(hpControls,'Tag','bgsubtract'),'Value',0);
        else
            BGroiIndex = IAdata.roi(RoiNum).mask>0.5;
        end
    end
    %what to display...
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    if max(modeval == [1 2 4 6 7])
        %average selectedOdorTrials
        if get(findobj(hpControls,'Tag','avgtrials'),'Value')
            selected = get(findobj(hpControls,'Tag','odortrialslist'),'Value');
            cnt = 0;
            tmpbar = waitbar(0,'Averaging Trials');
            for o = 1:length(IAdata.allOdorTrials.odor)
                for t = 1:length(IAdata.allOdorTrials.odor(o).trial)
                    cnt = cnt+1;
                    if max(cnt==selected)
                        waitbar(cnt/length(selected),tmpbar);
                        tmpind = IAdata.allOdorTrials.odor(o).trial(t).imindex;
                        if iscell(IAdata.file.im)
                            tmptrial = single(IAdata.file.im{channel}(:,:,tmpind));
                        else
                            tmptrial = single(IAdata.file.im(:,:,tmpind));
                        end
                        %perform background roi subtraction (before averaging trials)
                        if get(findobj(hpControls,'Tag','bgsubtract'),'value') %background roi
                            bg=zeros(length(tmpind),1);
                            for i = 1:size(tmptrial,3)
                                tmp=tmptrial(:,:,i);
                                bg(i)=single(mean(tmp(BGroiIndex)));
                                clear tmp;
                                tmptrial(:,:,i) = tmptrial(:,:,i) - bg(i);
                            end
                            clear bg;
                        end
                        if cnt == selected(1)
                            tmpstack = tmptrial;
                        else
                            tmpstack = tmpstack + tmptrial;
                        end
                        clear tmptrial;
                    end
                end
            end
            tmpstack = tmpstack./length(selected);
            delete(tmpbar);
            if modeval==1
                tmpstack = single(mean(tmpstack,3)); %mean fluorescence of avgtrials
            end
        else %full length movie
            %perform background roi subtraction (before averaging trials)
            if get(findobj(hpControls,'Tag','bgsubtract'),'value') %compute background subtraction values
                bg=zeros(IAdata.file.frames,1);
                for i = 1:length(bg)
                    if iscell(IAdata.file.im); tmp = IAdata.file.im{channel}(:,:,i);
                    else; tmp = IAdata.file.im(:,:,i);
                    end
                    bg(i)=single(mean(tmp(BGroiIndex)));
                end
            end
            if max(modeval == [ 2 4 6 7])
                if iscell(IAdata.file.im)
                    if modeval==2
                        tmpstack = IAdata.file.im{channel};
                    else
                        tmpstack = single(IAdata.file.im{channel});
                    end
                else
                    if modeval==2
                        tmpstack = IAdata.file.im;
                    else
                        tmpstack = single(IAdata.file.im);
                    end
                end
                %perform background roi subtraction (before averaging trials)
                if get(findobj(hpControls,'Tag','bgsubtract'),'value') %background roi
                    if isa(tmpstack,'uint16'); tmpstack = single(tmpstack); end
                    for i = 1:size(tmpstack,3)
                        tmpstack(:,:,i) = tmpstack(:,:,i) - bg(i);
                    end
                end
            else %modeval == 1 %mean fluorescence - calculate line by row to limit memory usage
                tmpstack = single(zeros(IAdata.file.size));
                for r = 1:IAdata.file.size(1)
                    if iscell(IAdata.file.im)
                        tmprow = squeeze(IAdata.file.im{channel}(r,:,:));
                    else
                        tmprow = squeeze(IAdata.file.im(r,:,:));
                    end
                    if get(findobj(hpControls,'Tag','bgsubtract'),'value')
                        tmprow = single(tmprow) - repmat(bg',size(tmprow,1),1);
                    end
                    tmpstack(r,:) = single(mean(tmprow,2));
                end
            end
        end
    else %max(modeval == [3 5])df maps
        if iscell(IAdata.file.im)
            tmpstack = zeros(size(IAdata.file.im{1},1),size(IAdata.file.im{1},2));
        else
            tmpstack = zeros(size(IAdata.file.im,1),size(IAdata.file.im,2));
        end
        fmask = round(str2double(get(findobj(hIA,'Tag','map_fmaskedit'),'String')));
        selected = get(findobj(hpControls,'Tag','odortrialslist'),'Value');
        cnt = 0; fmaskmin = inf; fmaskmax = -inf;
        tmpbar = waitbar(0,'Averaging Maps');
        for o = 1:length(IAdata.maps.file.odor)
            for t = 1:length(IAdata.maps.file.odor(o).trial)
                cnt=cnt+1;
                if ismember(cnt,selected)
                    waitbar(cnt/length(selected),tmpbar);
                    if get(findobj(hpControls,'Tag','bgsubtract'),'value')
                        respim = IAdata.maps.file.odor(o).trial(t).respim - ...
                            mean(IAdata.maps.file.odor(o).trial(t).respim(BGroiIndex));
                        baseim = IAdata.maps.file.odor(o).trial(t).baseim - ...
                            mean(IAdata.maps.file.odor(o).trial(t).baseim(BGroiIndex));
                    else
                        respim = IAdata.maps.file.odor(o).trial(t).respim;
                        baseim = IAdata.maps.file.odor(o).trial(t).baseim;
                    end
                    fmaskmin = min(fmaskmin,floor(min(baseim(:))));
                    fmaskmax = max(fmaskmax,round(mean(baseim(:))));
                    if modeval == 3 %df maps
                        tmpmap = respim-baseim;
                        tmpmap(baseim<fmask) = nan;
                    else %df/f maps
                        tmpmap = 100.*(respim-baseim)./baseim;
                        tmpmap(baseim<fmask) = nan;
                    end
                    tmpstack = tmpstack + tmpmap;
                end
            end
        end
        tmpstack = tmpstack./length(selected);
        delete(tmpbar);
        %reset fmask values
        set(findobj(hIA,'tag','map_fmaskslider'),'Min',fmaskmin,'Max',fmaskmax);
        if get(findobj(hIA,'tag','map_fmaskslider'),'Value')<fmaskmin
            set(findobj(hIA,'tag','map_fmaskslider'),'Value',fmaskmin);
            set(findobj(hIA,'tag','map_fmaskedit'),'String',num2str(fmaskmin));
        end
        if get(findobj(hIA,'tag','map_fmaskslider'),'Value')>fmaskmax
            set(findobj(hIA,'tag','map_fmaskslider'),'Value',fmaskmax);
            set(findobj(hIA,'tag','map_fmaskedit'),'String',num2str(fmaskmax));
        end
    end
    %suppress bright pixels (this frame only)
    if get(findobj(hIA,'Tag','suppressbright'), 'Value')
        pct = 100 - str2double(get(findobj(hIA,'Tag','brightpct'),'string'));
        tmpstack = imfilter_suppressBrightPixels(tmpstack,pct);
    end
    %spatial filter (this frame only)
    if get(findobj(hIA,'Tag','lpf'), 'Value')
        tmpbar = waitbar(0/size(tmpstack,3),'Gauss Spatial Filter');
        sigma = str2double(get(findobj(hIA,'Tag','lpf_radius'), 'String'));
        for f = 1:size(tmpstack,3)
            if max(f==0:100:size(tmpstack,3)); waitbar(f/size(tmpstack,3),tmpbar);end
            tmpstack(:,:,f) = imfilter_spatialLPF(tmpstack(:,:,f),sigma);
        end
        delete(tmpbar);
    end
    if isfield(IAdata,'currentbg'); IAdata.currentbg = rmfield(IAdata,'currentbg'); end
    switch modeval
        case 1 %mean fluorescence image
            ftimevis = 'off'; fmaskvis = 'off'; overlayvis = 'off';
%             IAdata.current = single(mean(tmpstack,3));
            IAdata.current = tmpstack;
        case 2 %fluorescence movie
            ftimevis = 'off'; fmaskvis = 'off'; overlayvis = 'off';
            IAdata.current = tmpstack;
        case {3,5} %deltaf map
            ftimevis = 'off'; fmaskvis = 'off'; overlayvis = 'off';
            IAdata.current = single(tmpstack);
        case {4,6,7} %deltaf movie and deltafoverf cases
            IAdata.current = single(zeros(size(tmpstack)));
            ftimevis = 'on'; fmaskvis = 'off'; overlayvis = 'off';
            fstart = str2double(get(findobj(hpControls,'Tag','fstart'),'String'));
            fstop = str2double(get(findobj(hpControls,'Tag','fstop'),'String'));
            imtimes = (0:size(tmpstack,3)-1)./IAdata.file.frameRate;
            ind1 = find(imtimes<=fstart,1,'first'); ind2 = find(imtimes<=fstop,1,'last');
            baseim = single(mean(tmpstack(:,:,ind1:ind2),3));
            if modeval == 4
                IAdata.current = tmpstack-baseim;
            elseif max(modeval == [6 7]) %deltaf over f cases
                tmpF = tmpstack(~isnan(tmpstack(:)));
                %check fmask and set slider min/max/value
                set(findobj(hIA,'Tag','fmaskslider'),'Min', round(min(tmpF)));
                set(findobj(hIA,'Tag','fmaskslider'),'Max', round(mean(tmpF)));
                set(findobj(hIA,'Tag','fmaskslider'),'Value',round(str2double(get(findobj(hIA,'Tag','fmaskedit'),'String'))));
                if get(findobj(hIA,'Tag','fmaskslider'),'Value')<round(min(tmpF))
                    set(findobj(hIA,'Tag','fmaskslider'),'Value',round(min(tmpF)));
                    set(findobj(hIA,'Tag','fmaskedit'),'String',num2str(round(min(tmpF))));
                elseif get(findobj(hIA,'Tag','fmaskslider'),'Value')>round(mean(tmpF))
                    set(findobj(hIA,'Tag','fmaskslider'),'Value',round(mean(tmpF)));
                    set(findobj(hIA,'Tag','fmaskedit'),'String',num2str(round(mean(tmpF))));
                end
                ftimevis = 'on'; fmaskvis = 'on'; overlayvis = 'off';
                Fmask = round(str2double(get(findobj(hIA,'Tag','fmaskedit'),'String')));
                set(findobj(hIA,'Tag','fmaskedit'),'String',num2str(Fmask));
                set(findobj(hIA,'Tag','dfmap_fmaskedit'),'String',num2str(Fmask));
                for i = 1:size(tmpstack,3)
                    tmpim = tmpstack(:,:,i);
                    tmpim(baseim~=0) = 100*(tmpim(baseim~=0)-baseim(baseim~=0))./baseim(baseim~=0);
                    tmpim(baseim==0) = nan;
                    tmpim(tmpstack(:,:,i)<Fmask)=nan;
                    IAdata.current(:,:,i)=single(tmpim);
                end
                if modeval == 7 %overlay
                    ftimevis = 'on'; fmaskvis = 'on'; overlayvis = 'on';
                    IAdata.currentbg = single(tmpstack);
                end
            end
    end
	set(findobj(hpControls,'Tag','fowindow'),'Visible',ftimevis);
	set(findobj(hpControls,'Tag','fstart'),'Visible',ftimevis);
	set(findobj(hpControls,'Tag','fto'),'Visible',ftimevis);
	set(findobj(hpControls,'Tag','fstop'),'Visible',ftimevis);
	set(findobj(hpControls,'Tag','fmasklabel'),'Visible',fmaskvis);
	set(findobj(hpControls,'Tag','fmaskslider'),'Visible',fmaskvis);
	set(findobj(hpControls,'Tag','fmaskedit'),'Visible',fmaskvis);
	set(findobj(hpControls,'Tag','overlaypanel'),'Visible',overlayvis);
    %put image info in gui
    stackmin = min(IAdata.current(:)); stackmax = max(IAdata.current(:));
    set(findobj(hIA,'Tag','stack_min'), 'String', sprintf('(%.0f)',stackmin));
    set(findobj(hIA,'Tag','stack_max'), 'String', sprintf('(%.0f)',stackmax));
    frames = size(IAdata.current,3);
    if frames>1
        set(findobj(hIA,'Tag','frame_slider'), 'Max', frames);
        set(findobj(hIA,'Tag','frame_slider'), 'SliderStep', [1./(frames-1) 10./(frames-1)]);
    else
        set(findobj(hIA,'Tag','frame_slider'), 'Max', 1.25);
        set(findobj(hIA,'Tag','frame_slider'), 'SliderStep', [1 1]); 
    end
    set(findobj(hIA,'Tag','frame_slider'), 'Value',1);
    set(findobj(hIA,'Tag','frame_text'), 'String', sprintf('Frame # 1/%d (%0.3f Sec)',frames,0.0));
    set(findobj(hIA,'Tag','frameRate_text'), 'String', sprintf('FrameRate: %0.3f (Hz)',IAdata.file.frameRate));
    set(findobj(hIA,'Tag','duration_text'), 'String', sprintf('Duration: %0.3f (Sec)',frames/IAdata.file.frameRate));
    hIA.UserData.IAdata = IAdata;
    CBplotFvsT;
    if modeval == 7; CBoverlay; else; CBdrawFrame; end
end
function CBplayMovie(~,~) %play like a movie
    if isempty(hIA.UserData.IAdata.file); return; end
    tmpim = hIA.UserData.IAdata.current;
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    if modeval == 7
        tmpbgim = hIA.UserData.IAdata.currentbg;
        hIm_bgmovie = findobj(hIA,'Tag','bgmovie');
    end
    frames = size(tmpim,3);
    ind = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    hAx_Movie = findobj(hIA,'Tag','MovieAx'); hIm_movie = findobj(hIA,'Tag','movie');
    axes(hAx_Movie);
    cmapval = get(findobj(hIA,'Tag','cmapval'), 'Value');
    while (get(findobj(hIA,'Tag','play_button'), 'Value'))
        ind = ind+1;
        if (ind>frames)
            ind = 1;
        end
        set(findobj(hIA,'Tag','frame_slider'), 'Value', ind);
        set(findobj(hIA,'Tag','frame_text'),'String', sprintf('Frame # %d/%d (%0.3f Sec)',ind,...
            frames,(ind-1)/hIA.UserData.IAdata.file.frameRate));
        if modeval == 7 %update background
            tmpbgframe = tmpbgim(:,:,ind);
            set(hIm_bgmovie,'CData',tmpbgframe);
        end
        tmpframe=tmpim(:,:,ind);
        set(hIm_movie,'CData',tmpframe);
        %set CLim values    
        if get(findobj(hIA,'Tag','stack_auto'),'Value')
            axClims = qprctile(tmpframe(~isnan(tmpframe)), [0.2 99.8]); %qprctile is faster than prctile (uses integers)
            set(findobj(hIA,'Tag','stack_blackpix'), 'String', num2str(axClims(1)));
            set(findobj(hIA,'Tag','stack_whitepix'), 'String', num2str(axClims(2)));
        else
            axClims(1) = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
            axClims(2) = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
        end
        set(hAx_Movie, 'Clim', axClims);
        colormap(hAx_Movie,[cmapstrings{cmapval} '(256)']); %this is slow if colorbar is showing!
        %alphamap overlay cutoff
        hIm_movie.AlphaData =  ~isnan(tmpframe);
        if modeval == 7
            hIm_movie.AlphaData(tmpframe<hIA.UserData.IAdata.overlayval) = 0;
        end
        drawnow;
        tmptime = [(ind-1)/hIA.UserData.IAdata.file.frameRate (ind-1)/hIA.UserData.IAdata.file.frameRate];
        set(findobj(hIA,'Tag','mark'),'Xdata',tmptime);%,'Ydata',total(ind));
        if get(findobj(hIA,'Tag','speedcontrol'),'Value')
            speed = get(findobj(hIA,'Tag','speedslider'), 'Value');
            pause(1/speed);
        end
    end
    CBdrawFrame;
end
function CBdrawFrame(~,~)
    %this function displays 1 frame of the movie/image
    hAx_movie = findobj(hpMovie,'Tag','MovieAx'); hIm_Movie = findobj(hpMovie,'Tag','movie');
    if isempty(hIA.UserData.IAdata.file.name) || isempty(hIA.UserData.IAdata.current)
        if ~isempty(hIm_Movie); set(hIm_Movie,'Cdata',zeros(5)); set(findobj(hIA,'Tag','name_text'),'String',''); end; return;
    end
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    if max(modeval == [1 3 5])
        frame = 1;
    else
        frame = get(findobj(hIA,'Tag','frame_slider'), 'Value');
    end
    if modeval == 7 %Display Background Image for overlay deltaf/f movie
        hAx_bgmovie = findobj(hpMovie,'Tag','BGMovieAx'); hIm_BGMovie = findobj(hpMovie,'Tag','bgmovie');
        if isempty(hAx_bgmovie)
            hAx_bgmovie = axes(hpMovie,'Tag','BGMovieAx','Position',hpMovie.Position,'Color',[0 0 0]); xticks([]);yticks([]);
            uistack(hAx_bgmovie,'bottom');
        end
        if isempty(hAx_bgmovie.Children)
            hIm_BGMovie = imagesc(hAx_bgmovie,zeros(5),'Tag','bgmovie');
            hAx_bgmovie.Tag ='BGMovieAx'; %note: high-level version of imagesc clears axes.tag, so put tag here.
            axes(hAx_bgmovie); colormap(hAx_bgmovie,'gray(256)');
        end
        tmpbgim = hIA.UserData.IAdata.currentbg(:,:,frame);
        set(hIm_BGMovie,'Cdata',tmpbgim);
        %set bg CLim values
        bgaxClims = qprctile(tmpbgim(~isnan(tmpbgim)), [0.2 99.8]);
        set(findobj(hIA,'Tag','overlay_blackpix'), 'Enable', 'Off');
        set(findobj(hIA,'Tag','overlay_whitepix'), 'Enable', 'Off');
        if bgaxClims(2) == bgaxClims(1); bgaxClims(2) = bgaxClims(1)+1; end %just in case the image is uniform 
        set(findobj(hIA,'Tag','overlay_blackpix'), 'String', sprintf('%.2f',bgaxClims(1)));
        set(findobj(hIA,'Tag','overlay_whitepix'), 'String', sprintf('%.2f',bgaxClims(2)));
        set(hAx_bgmovie, 'Clim', bgaxClims);
        axis(hAx_bgmovie,'off');
        axis(hAx_bgmovie,'image');
        set(hAx_bgmovie, 'Position', hAx_movie.Position);
        axes(hAx_bgmovie);
        colormap(hAx_bgmovie,'gray(256)'); %in case of redwhiteblue map
    else
        hAx_bgmovie = findobj(hpMovie,'Tag','BGMovieAx');
        if ~isempty(hAx_bgmovie); delete(hAx_bgmovie); end
    end
    % Display Movie Image
    tmpim = hIA.UserData.IAdata.current(:,:,frame);
    if isempty(hAx_movie.Children)
        hIm_Movie = imagesc(hAx_movie,zeros(5),'Tag','movie');
        hAx_movie.Tag ='MovieAx'; %note: high-level version of imagesc clears axes.tag, so put tag here.
        CBcmap;
    end
%     axes(hAx_movie);
    hold(hAx_movie,'off'); tmppos = hAx_movie.Position;
    set(hIm_Movie,'Cdata',tmpim);
    %set CLim values    
    if get(findobj(hIA,'Tag','stack_auto'),'Value')
        axClims = qprctile(tmpim(~isnan(tmpim)), [0.2 99.8]);
        set(findobj(hIA,'Tag','stack_blackpix'), 'Enable', 'Off');
        set(findobj(hIA,'Tag','stack_whitepix'), 'Enable', 'Off');
    else
        axClims(1) = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
        axClims(2) = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
        set(findobj(hIA,'Tag','stack_blackpix'), 'Enable', 'On');
        set(findobj(hIA,'Tag','stack_whitepix'), 'Enable', 'On');
    end
    if axClims(2) == axClims(1); axClims(2) = axClims(1)+1; end %just in case the image is uniform 
    set(findobj(hIA,'Tag','stack_blackpix'), 'String', sprintf('%.2f',axClims(1)));
    set(findobj(hIA,'Tag','stack_whitepix'), 'String', sprintf('%.2f',axClims(2)));
    set(hAx_movie, 'Clim', axClims);
    axis(hAx_movie,'off');
    axis(hAx_movie,'image');
    set(hAx_movie, 'Position', tmppos);
    axes(hAx_movie);
    val = get(findobj(hIA,'Tag','cmapval'), 'Value');
    colormap(hAx_movie,[cmapstrings{val} '(256)']); %in case of redwhiteblue map
    %alphamap overlay cutoff
    hIm_Movie.AlphaData = ones(size(tmpim));
    hIm_Movie.AlphaData(isnan(tmpim)) = 0;
    if modeval == 7
        hIm_Movie.AlphaData(tmpim<hIA.UserData.IAdata.overlayval) = 0;
    end
    %frame#, time, and marker
    if max(modeval == [2 4 6 7])
        set(findobj(hIA,'Tag','frame_text'),'String', sprintf('Frame # %d/%d (%0.3f Sec)',frame,...
            size(hIA.UserData.IAdata.current,3),(frame-1)/hIA.UserData.IAdata.file.frameRate));
        tmptime = [(frame-1)/IAdata.file.frameRate (frame-1)/IAdata.file.frameRate];
        set(findobj(hIA,'Tag','mark'),'XData',tmptime);
    end
end
function CBloadROIs(~, ~) %load ROIs file (or ROIs from scanbox realtime data)
    hAx_movie = findobj(hpMovie,'Tag','MovieAx'); hIm_Movie = findobj(hpMovie,'Tag','movie');
    if isempty(hIm_Movie); return; end %don't load unless there's an image
    if isfield(hIA.UserData.IAdata,'roi') && ~isempty(hIA.UserData.IAdata.roi); oldrois = hIA.UserData.IAdata.roi; end
    CBclearROIs;
    newrois = loadROIs(hIA.UserData.IAdata.file.dir);
    if ~isempty(newrois)
        if isequal(size(newrois(1).mask),size(hIm_Movie.CData))
            hIA.UserData.IAdata.roi = newrois;
        else
            uiwait(errordlg('New ROIs size does not match Image size'));
            if exist('oldrois','var'); hIA.UserData.IAdata.roi = oldrois; clear oldrois; end
        end
    elseif exist('oldrois','var')
        hIA.UserData.IAdata.roi = oldrois; clear oldrois;
    end
    set(findobj(hIA,'Tag','roi_listbox'),'Value', 1);
    set(findobj(hIA,'Tag','roi_listbox'),'Max', max(length(hIA.UserData.IAdata.roi),1));
    overlayContours(hAx_movie);
end
function CBdrawROI(~, ~) %draw your own ROI, add to list
    hAx_movie = findobj(hpMovie,'Tag','MovieAx'); hIm_Movie = findobj(hpMovie,'Tag','movie');
    if isempty(hIm_Movie); return; end %don't draw unless there's an image
    cmap = colormap(hAx_movie);
    tmpclim = get(hAx_movie, 'Clim');
    if ~isfield(hIA.UserData.IAdata,'roi'); hIA.UserData.IAdata.roi = []; end
    bgimage = get(hIm_Movie,'CData');
    tmpim = hIA.UserData.IAdata.current;
    [hIA.UserData.IAdata.roi] = drawROI_refine(hIA.UserData.IAdata.roi,bgimage,tmpim,cmap,tmpclim);
    set(findobj(hIA,'Tag','roi_listbox'),'Value', 1);
    overlayContours(hAx_movie);
end
function CBshiftROIsButton_fcn(~, ~) %move selected ROIs
    if ~isfield(hIA.UserData.IAdata,'roi') || isempty(hIA.UserData.IAdata.roi); return; end
    colshift = inputdlg('Shift to the right (pixels)', 'Column Shift', 1, {'0.0'});
    if isempty(colshift); return; end
    colshift = str2double(colshift{1});
    rowshift = inputdlg('Shift down (pixels)', 'Row Shift', 1, {'0.0'});
    if isempty(rowshift); return; end
    rowshift = str2double(rowshift{1});
    selectedrois = get(findobj(hIA,'Tag','roi_listbox'), 'Value');
    for r = 1:length(selectedrois)
        hIA.UserData.IAdata.roi(selectedrois(r)).mask = circshift(hIA.UserData.IAdata.roi(selectedrois(r)).mask,[rowshift,colshift]);
    end
    hAx_movie = findobj(hpMovie,'Tag','MovieAx');
    overlayContours(hAx_movie);
end
function CBclearROIs(~,~) %clear all ROIs
    if ~isfield(hIA.UserData.IAdata,'roi'); return; end
    set(findobj(hIA,'Tag','roi_listbox'),'String',''); set(findobj(hIA,'Tag','roi_listbox'),'Value',0);
    hIA.UserData.IAdata.roi = [];
    hAx_movie = findobj(hpMovie,'Tag','MovieAx');
    overlayContours(hAx_movie);
end
function CBdeleteROIs(~, ~) %clear selected ROIs
    if ~isfield(hIA.UserData.IAdata,'roi') || isempty(hIA.UserData.IAdata.roi); return; end
    rois = get(findobj(hIA,'Tag','roi_listbox'), 'Value');
    keepInds = setdiff(1:length(hIA.UserData.IAdata.roi), rois);
    hIA.UserData.IAdata.roi = hIA.UserData.IAdata.roi(keepInds);
    roistr = cell(numel(hIA.UserData.IAdata.roi),1);
    for n = 1:numel(hIA.UserData.IAdata.roi)
        cl = myColors(n).*255;
        roistr{n} = ['<HTML><FONT color=rgb(' ...
            num2str(cl(1)) ',' num2str(cl(2)) ',' num2str(cl(3)) ')>ROI #' num2str(n) '</Font></html>'];
    end
    set(findobj(hIA,'Tag','roi_listbox'), 'String', roistr);
    if isempty(hIA.UserData.IAdata.roi)
        set(findobj(hIA,'Tag','roi_listbox'),'Value',0);
    else; set(findobj(hIA,'Tag','roi_listbox'), 'Value', 1);
    end
    hAx_movie = findobj(hpMovie,'Tag','MovieAx');
    overlayContours(hAx_movie);
end
function CBsaveROI_button_fcn(~,~) %save ROI masks
    if ~isfield(hIA.UserData.IAdata,'roi') || isempty(hIA.UserData.IAdata.roi); return; end
    saveROIs(hIA.UserData.IAdata.roi,hIA.UserData.IAdata.file.dir,hIA.UserData.IAdata.file.name);
end
function CBplotFvsT(~,~) % plot total flourescence vs time, and stimulus
    IAdata = hIA.UserData.IAdata;
    if isempty(IAdata.current) || ~isfield(IAdata,'roi') || isempty(IAdata.roi); return; end
    if isfield(IAdata.roi,'time'); IAdata.roi = rmfield(IAdata.roi,'time'); end
    if isfield(IAdata.roi,'series'); IAdata.roi = rmfield(IAdata.roi,'series'); end
    hAx_FvsT = findobj(hIA,'Tag','fPlotAx');
    if get(findobj(hpControls,'Tag','roisplot'),'Value')
        tmpstack = IAdata.current;
        imtimes=(0:size(tmpstack,3)-1)./IAdata.file.frameRate;
        selected = get(findobj(hpControls,'Tag','roi_listbox'),'Value');
        for r = 1:length(selected)
            rr = selected(r);
            roiIndex{r} = find(IAdata.roi(rr).mask>0.5);
            IAdata.roi(rr).time = []; IAdata.roi(rr).series = [];
        end
        for i = 1:size(tmpstack,3)
            tmpframeim = tmpstack(:,:,i);
            for r = 1:length(selected)
                rr = selected(r);
                IAdata.roi(rr).time(1,i) = (i-1)/IAdata.file.frameRate;
                tmpvals = tmpframeim(roiIndex{r});
                IAdata.roi(rr).series(1,i) = mean(tmpvals(~isnan(tmpvals))); %compute mean value in ROI
            end
        end
        cla(hAx_FvsT); hold(hAx_FvsT,'on');
        tmpmin = inf; tmpmax = -inf;
        for r = 1:length(selected)
            rr = selected(r);
            tmp = IAdata.roi(rr).series;
            line(hAx_FvsT,IAdata.roi(rr).time,tmp,'Color',myColors(rr)); %hAx_FvsT.Tag = 'fPlotAx';
            tmpmin = min(tmpmin,min(tmp)); tmpmax = max(tmpmax,max(tmp));
        end        
        %frame marker
        frame = get(findobj(hIA,'Tag','frame_slider'), 'Value');
        tmptime = [(frame-1)/IAdata.file.frameRate (frame-1)/IAdata.file.frameRate];
        line(tmptime,[tmpmin tmpmax],'Parent',hAx_FvsT,'Tag','mark','Color',[0.5 0.5 0.5],'LineWidth',1.5);
        %aux/stimulus
        hold(hAx_FvsT, 'on');
        if isfield(IAdata.file,'aux1') && ~isempty(IAdata.file.aux1) && get(findobj(hIA,'Tag','Aux'),'Value') == 1
            if get(findobj(hpControls,'Tag','avgtrials'),'Value')
                trial_prestimtime = str2double(get(findobj(hpControls,'Tag','trial_prestimtime'),'String'));
                duration = (size(tmpstack,3)-1)./IAdata.file.frameRate;
                newaux1 = shiftAux(IAdata.file.aux1,trial_prestimtime,duration);
                plot(hAx_FvsT,newaux1.times,newaux1.signal*tmpmax,'r','LineWidth',1.5);
                %tcrtcr - this plots aux signal zero to max, not min to max (helps to see suppression)
            else
                plot(hAx_FvsT,IAdata.file.aux1.times,IAdata.file.aux1.signal*tmpmax,'r','LineWidth',1.5);
                %show the odor # for each odor on/off
                if isfield(IAdata.file,'aux3') && ~isempty(IAdata.file.aux3)
                    i=2; jj=find(IAdata.file.aux3.times>2.1,1,'first'); %8x0.25sec intervals
                    while i<length(IAdata.file.aux3.signal) %skip first frame in case signal is on at scan start
                        if IAdata.file.aux3.signal(i)==1 && IAdata.file.aux3.signal(i-1)==0 %find odor onset
                            spikes = '';
                            for b = 1:8 %search for 8 x ~.25 second intervals, starting 0.1 sec after trigger spike
                                spike = 0;
                                for j = find(IAdata.file.aux3.times>(IAdata.file.aux3.times(i)+(b-1)*0.25 + 0.1),1)...
                                        : find(IAdata.file.aux3.times>(IAdata.file.aux3.times(i)+ b*0.25 + 0.1),1)
                                    if IAdata.file.aux3.signal(j)==1 && IAdata.file.aux3.signal(j-1)==0
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
                            text(hAx_FvsT,IAdata.file.aux3.times(i),0.8*tmpmax,num2str(odor),'Color',[1 1 1]);
                            i=i+jj; %jump forward
                        else
                            i=i+1;
                        end
                    end
                end
            end
        end
        if isfield(IAdata.file,'aux2') && ~isempty(IAdata.file.aux2) && get(findobj(hIA,'Tag','Aux'),'Value') == 2
            if get(findobj(hpControls,'Tag','avgtrials'),'Value')
                trial_prestimtime = str2double(get(findobj(hpControls,'Tag','trial_prestimtime'),'String'));
                duration = (size(tmpstack,3)-1)./IAdata.file.frameRate;
                newaux2 = shiftAux(IAdata.file.aux2,trial_prestimtime,duration);
                plot(hAx_FvsT,newaux2.times,newaux2.signal*tmpmax,'r','LineWidth',1.5);
            else
                plot(hAx_FvsT,IAdata.file.aux2.times,IAdata.file.aux2.signal*tmpmax,'g');
            end
        end
        if isfield(IAdata.file,'aux_combo') && ~isempty(IAdata.file.aux_combo) && get(findobj(hIA,'Tag','Aux'),'Value') == 3
            if get(findobj(hpControls,'Tag','avgtrials'),'Value')
                trial_prestimtime = str2double(get(findobj(hpControls,'Tag','trial_prestimtime'),'String'));
                duration = (size(tmpstack,3)-1)./IAdata.file.frameRate;
                newauxcombo = shiftAux(IAdata.file.aux_combo,trial_prestimtime,duration);
                plot(hAx_FvsT,newauxcombo.times,newauxcombo.signal*tmpmax,'r','LineWidth',1.5);
            else
                plot(hAx_FvsT,IAdata.file.aux_combo.times,IAdata.file.aux_combo.signal*tmpmax,'y');
            end
        end
        if isfield(IAdata.file,'def_stimulus') && ~isempty(IAdata.file.def_stimulus) && get(findobj(hIA,'Tag','Aux'),'Value') == 4
            if get(findobj(hpControls,'Tag','avgtrials'),'Value')
                trial_prestimtime = str2double(get(findobj(hpControls,'Tag','trial_prestimtime'),'String'));
                duration = (size(tmpstack,3)-1)./IAdata.file.frameRate;
                newauxdef = shiftAux(IAdata.file.def_stimulus,trial_prestimtime,duration);
                plot(hAx_FvsT,newauxdef.times,newauxdef.signal*tmpmax,'r','LineWidth',1.5);
            else
                plot(hAx_FvsT,IAdata.file.def_stimulus.times,IAdata.file.def_stimulus.signal*tmpmax,'b');
            end
        end
        set(hAx_FvsT,'LineWidth',1.0,'FontSize',6,'YTickLabel',{},'YColor','none','Box','off','XLim',...
            [0 imtimes(end)],'YLim',[tmpmin tmpmax],'Color',[0 0 0],'XColor',[1 1 1]);
        hAx_FvsT.XTick = 0:1:floor(IAdata.roi(selected(1)).time(end));
        hold(hAx_FvsT,'off'); hAx_FvsT.Visible = 'on';
    else %no TSplot
        cla(hAx_FvsT); hAx_FvsT.Visible = 'off';
    end
    hIA.UserData.IAdata = IAdata;
end
function newaux = shiftAux(aux,trial_prestimtime,duration)
    checkpreframes = find(aux.times >= trial_prestimtime,1,'first');
    On = find(aux.signal>0,1,'first');
    if On < checkpreframes
        i=checkpreframes;
        while i<length(aux.signal)
            if aux.signal(i)>0 && aux.signal(i-1)==0
                On=i; break;
            end
            i=i+1;
        end
    end
    tOn = aux.times(On);
    stimstart = find(aux.times >= tOn-trial_prestimtime,1,'first');
    stimend = find(aux.times > tOn+-trial_prestimtime+duration,1,'first')-1;
    newaux.times = aux.times(stimstart:stimend)-aux.times(stimstart);
    newaux.signal = aux.signal(stimstart:stimend);
end
function CBoverlay(~,~)
    if ~isfield(hIA.UserData.IAdata,'current') || isempty(hIA.UserData.IAdata.current); return; end
    clicked = hIA.CurrentObject;
    if strcmp(clicked.Tag,'overlayval')
        hIA.UserData.IAdata.overlayval = str2double(clicked.String);
        tmpvals = hIA.UserData.IAdata.current(~isnan(hIA.UserData.IAdata.current(:)));
        tmp = sort(tmpvals);
        overlaypct = 100-100*(find(tmp>=hIA.UserData.IAdata.overlayval,1,'first')/length(tmp));
        set(findobj(hpControls,'Tag','overlaypct'),'String',sprintf('%.1f',overlaypct));
    else %strcmp(clicked.Tag,'overlaypct')
        overlaypct = str2double(get(findobj(hpControls,'Tag','overlaypct'),'String'));
        if overlaypct >= 0
            tmpvals = hIA.UserData.IAdata.current(~isnan(hIA.UserData.IAdata.current(:)));
            overlayval = qprctile(tmpvals,100-overlaypct);
        else
            tmpvals = hIA.UserData.IAdata.current(~isnan(hIA.UserData.IAdata.current(:)));
            overlayval = qprctile(tmpvals,-overlaypct);
        end
        overlayval = round(overlayval,3);
        hIA.UserData.IAdata.overlayval = overlayval;
        set(findobj(hpControls,'Tag','overlayval'),'String',sprintf('%.1f',overlayval));
    end
    CBdrawFrame;
end
function CBoverlayROIs(~,~)
    hAx_movie = findobj(hpMovie,'Tag','MovieAx');
    overlayContours(hAx_movie);
end
function overlayContours(hAxis) %plot ROI contour lines
    axes(hAxis);
    hold(hAxis,'on');
    h_roitext = findobj(hIA,'Tag','roitext');
    h_roiline = findobj(hIA,'Tag','roiline');
    %delete old contour lines
    if ~isempty(h_roitext)
        for r = 1:length(h_roitext); delete(h_roitext(r)); end
        clear h_roitext;
    end
    if ~isempty(h_roiline)
        for r = 1:length(h_roiline); delete(h_roiline(r)); end
        clear h_roiline;
    end
    if ~isfield(hIA.UserData.IAdata,'roi') || isempty(hIA.UserData.IAdata.roi)
        set(findobj(hpControls,'Tag','roisoverlay'),'Value',0);
        set(findobj(hpControls,'Tag','roisplot'),'Value',0);
        return;
    end
    roistr=cell(length(hIA.UserData.IAdata.roi),1);
    selected = get(findobj(hpControls,'Tag','roi_listbox'),'Value');
    for r = 1:length(hIA.UserData.IAdata.roi)
        if ismember(r,selected)
            if get(findobj(hpControls,'Tag','roisoverlay'),'Value')
                [ctemp,~] = contour(hIA.UserData.IAdata.roi(r).mask, 1, 'LineColor',myColors(r),'LineWidth',1.5,'Tag','roiline');   
                text(mean(ctemp(1,:)),mean(ctemp(2,:)),num2str(r),'Color',myColors(r),'FontSize',14,'Tag','roitext');
            end
            cl = myColors(r).*255;
            roistr{r} = ['<HTML><FONT color=rgb(' num2str(cl(1)) ',' num2str(cl(2))...
                 ',' num2str(cl(3)) ')>' 'ROI # ' num2str(r) '</Font></html>'];
        else
            roistr{r} = ['ROI # ' num2str(r)];
        end
    end
    hold off;
    set(findobj(hIA,'Tag','roi_listbox'),'String',roistr);
    CBplotFvsT;
end
function CBmapsAnalysis(~,~)
    if ~isfield(hIA.UserData.IAdata.file,'name') || isempty(hIA.UserData.IAdata.file.name); return; end
    IAdata = hIA.UserData.IAdata;
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    if max(modeval == [3 5])
        mapsdata = IAdata.maps;
    else
        set(findobj(hpControls,'Tag','dispmode'),'Value',3);
        set(findobj(hpControls,'Tag','avgtrials'),'Value',1);
        CBchangemode;
        tmpbar = waitbar(0,'Generating MapsData');
        auxval = get(findobj(hIA,'Tag','Aux'),'Value');
        mapsdata.stim2use = auxstr{auxval};
        mapsdata.basetimes(1) = str2double(get(findobj(hpControls,'Tag','map_basestart'),'String'));
        mapsdata.basetimes(2) = str2double(get(findobj(hpControls,'Tag','map_basestop'),'String'));
        mapsdata.resptimes(1) = str2double(get(findobj(hpControls,'Tag','map_respstart'),'String'));
        mapsdata.resptimes(2) = str2double(get(findobj(hpControls,'Tag','map_respstop'),'String'));
        %if only current file is selected, use it.
        tmpdata.type = IAdata.file.type;
        tmpdata.name = IAdata.file.name;
        tmpdata.dir = IAdata.file.dir;
        %deal with channels!
        tmpdata.im = IAdata.file.im;
        tmpdata.size = [size(IAdata.file.im,1) size(IAdata.file.im,2)];
        tmpdata.frameRate = IAdata.file.frameRate;
        tmpdata.frames = size(IAdata.file.im,3);
        tmpdata.aux1 = IAdata.file.aux1; tmpdata.aux2 = IAdata.file.aux2; tmpdata.aux3 = IAdata.file.aux3;
        if get(findobj(hIA,'Tag','Aux'),'Value')==3
            odorDuration = str2double(get(findobj(hIA,'Tag','duration'),'String'));
            if isnan(odorDuration) %empty string
                tmpdata.aux_combo = doAuxCombo(IAdata.file.aux1,IAdata.file.aux2);
            else
                tmpdata.aux_combo = doAuxCombo(IAdata.file.aux1,IAdata.file.aux2,odorDuration);            
            end
            mapsdata.aux_combo = tmpdata.aux_combo;
        elseif get(findobj(hIA,'Tag','Aux'),'Value')==4
            tmpdata.def_stimulus = IAdata.file.def_stimulus;
            mapsdata.def_stimulus = IAdata.file.def_stimulus;
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
        end
        delete(tmpbar);
    end
    if isfield(IAdata,'roi'); mapsdata.roi=IAdata.roi; end
    MapsAnalysis_MWLab(mapsdata);
end

function CBTimeSeriesAnalysis(~, ~) %run TimeSeriesAnalysis_MWLab.m using current
    if isempty(hIA.UserData.IAdata.file) || ~isfield(hIA.UserData.IAdata.file,'name') || ...
            isempty(hIA.UserData.IAdata.file.name); return; end
    IAdata = hIA.UserData.IAdata;
    if ~isfield(IAdata,'roi') || isempty(IAdata.roi)
        errordlg('No ROIs selected');
        return;
    end
    if iscell(IAdata.file.im)
        tmpdata.file(1).type = IAdata.file.type; tmpdata.file(2).type = IAdata.file.type;
        tmpdata.file(1).dir = IAdata.file.dir; tmpdata.file(2).dir = IAdata.file.dir;
        dot = strfind(IAdata.file.name,'.'); if isempty(dot);dot=length(IAdata.file.name)+1; end
        tmpdata.file(1).name = [IAdata.file.name(1:dot-1) '_ch1' IAdata.file.name(dot:end)];
        tmpdata.file(2).name = [IAdata.file.name(1:dot-1) '_ch2' IAdata.file.name(dot:end)];
        tmpdata.file(1).frameRate = IAdata.file.frameRate; tmpdata.file(2).frameRate = IAdata.file.frameRate;
        tmpdata.file(1).im = IAdata.file.im{1}; tmpdata.file(2).im = IAdata.file.im{2}; %only temporary!
        tmpdata.file(1).size = size(tmpdata.file(1).im(:,:,1)); tmpdata.file(2).size = size(tmpdata.file(2).im(:,:,1));
        tmpdata.file(1).frames = size(tmpdata.file(1).im,3); tmpdata.file(2).frames = size(tmpdata.file(2).im,3);
        if isfield(IAdata.file,'aux1'); tmpdata.file(1).aux1 = IAdata.file.aux1; tmpdata.file(2).aux1 = IAdata.file.aux1;end
        if isfield(IAdata.file,'aux2'); tmpdata.file(1).aux2 = IAdata.file.aux2; tmpdata.file(2).aux2 = IAdata.file.aux2; end
        if isfield(IAdata.file,'aux3'); tmpdata.file(1).aux3 = IAdata.file.aux3; tmpdata.file(2).aux3 = IAdata.file.aux3; end
        if isfield(IAdata.file,'aux_combo'); tmpdata.file(1).aux_combo = IAdata.file.aux_combo; ...
                tmpdata.file(2).aux_combo = IAdata.file.aux_combo; end
        if isfield(IAdata.file,'ephys'); tmpdata.file(1).ephys = IAdata.file.ephys; ...
                tmpdata.file(2).ephys = IAdata.file.ephys; end
    else
        tmpdata.file.type = IAdata.file.type;
        tmpdata.file.dir = IAdata.file.dir;
        tmpdata.file.name = IAdata.file.name;
        tmpdata.file.frameRate = IAdata.file.frameRate;
        tmpdata.file.im = IAdata.file.im;
        tmpdata.file.size = size(tmpdata.file.im(:,:,1));
        tmpdata.file.frames = size(tmpdata.file.im,3);
        if isfield(IAdata.file,'aux1'); tmpdata.file.aux1 = IAdata.file.aux1; end
        if isfield(IAdata.file,'aux2'); tmpdata.file.aux2 = IAdata.file.aux2; end
        if isfield(IAdata.file,'aux3'); tmpdata.file.aux3 = IAdata.file.aux3; end
        if isfield(IAdata.file,'aux_combo'); tmpdata.file.aux_combo = IAdata.file.aux_combo; end
        if isfield(IAdata.file,'ephys'); tmpdata.file.ephys = IAdata.file.ephys; end
    end
    if isfield(IAdata.file,'def_stimulus') && ~isempty(IAdata.file.def_stimulus)
        tmpdata.def_stimulus=IAdata.file.def_stimulus; end
    tmpdata.roi = IAdata.roi;
    %compute timeseries first... then open TimeSeriesAnalysis...
    tmpdata = computeTimeSeries(tmpdata,tmpdata.roi);
    tmpdata.file = rmfield(tmpdata.file,'im');
    TimeSeriesAnalysis_MWLab(tmpdata); clear tmpdata;
end

function CBsaveImageMovie(~, ~)
    if ~isfield(hIA.UserData.IAdata,'current') || isempty(hIA.UserData.IAdata.current); return; end
    modeval = get(findobj(hpControls,'Tag','dispmode'),'Value');
    bsavemovie = 0; %binary: save movie(1) or image(0)
    if max(modeval == [2 4 6 7])
        savemovie = questdlg('Do you want to save a Movie or just this Frame?',...
            'Save Movie?','Movie','Image','Movie');
        if isempty(savemovie); return; end
        if strcmp(savemovie,'Movie'); bsavemovie = 1; end
    end
    if bsavemovie
% %         tcrtcrtcr still working on this!
        if modeval == 7
            movieType = 'illustrated .avi'; % df/f overlay
        else
            movieType = questdlg(sprintf(['>Save current movie as .tif (image data only, %s precision)\n'...
                '  >Or, save current movie as .avi (image data only, values scale to 0-255)\n'...
                '    >Or, save movie as illustrated .avi (include ROIs, TSplot, etc.'],...
                class(hIA.UserData.IAdata.current)), 'What kind of movie do you want to save?',...
                '.tif','.avi','illustrated .avi','illustrated .avi');
            if isempty(movieType); return; end
        end
        %set up File/Video Object/etc - msgdlg
        tmpim = hIA.UserData.IAdata.current;
        hAx_Movie = findobj(hIA,'Tag','MovieAx'); hIm_movie = findobj(hIA,'Tag','movie');
        if modeval == 7
            tmpbgim = hIA.UserData.IAdata.currentbg;
            hIm_bgmovie = findobj(hIA,'Tag','bgmovie');
        end
        tmpname = hIA.UserData.IAdata.file.name;
        tmpdir = hIA.UserData.IAdata.file.dir;
        if strcmp(movieType,'.tif')
            [name,path] = uiputfile('*.tif','Select file name', fullfile(tmpdir, [tmpname(1:end-4) '_tmp.tif']));
            tifmovie = Tiff(fullfile(path,name),'w');
            tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
            tagstruct.ImageLength = size(tmpim,1);
            tagstruct.ImageWidth = size(tmpim,2);
            tagstruct.SamplesPerPixel = 1;
            tagstruct.RowsPerStrip = size(tmpim,1);
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.Compression = Tiff.Compression.None;
            if isa(hIA.UserData.IAdata.current,'uint16')
                tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
                tagstruct.BitsPerSample = 16;
            else
                tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
                tagstruct.BitsPerSample = 32;
            end
        elseif strcmp(movieType,'.avi') % .avi format
            [name,path] = uiputfile('*.avi','Select file name', fullfile(tmpdir, [tmpname(1:end-4) '_tmp.avi']));
            vidObj = VideoWriter(fullfile(path,name), 'Indexed AVI');
            vidObj.FrameRate = str2double(inputdlg('Enter Frame/sec for movie (current value shown below):',...
                'Get Frame Rate',1,{num2str(hIA.UserData.IAdata.file.frameRate)}));
            open(vidObj);
        else %illustrated .avi
            [name,path] = uiputfile('*.avi','Select file name', fullfile(tmpdir, [tmpname(1:end-4) '_tmp.avi']));
            vidObj = VideoWriter(fullfile(path,name), 'Uncompressed AVI');
            vidObj.FrameRate = str2double(inputdlg('Enter Frame/sec for movie (current value shown below):',...
                'Get Frame Rate',1,{num2str(hIA.UserData.IAdata.file.frameRate)}));
            open(vidObj);
            hpMovie.Units = 'Pixels'; movierect = hpMovie.Position; hpMovie.Units = 'Normalized';
        end
        if ~name(1); return; end
        %play movie/save
        frames = size(tmpim,3);
        tmpbar = waitbar(0/frames,'Saving Movie as it plays...','Units','Normalized',...
            'Position',[hIA.Position(1)+.5*hIA.Position(3) hIA.Position(2)-.1 .25 .05]);
        axes(hAx_Movie);
        cmapval = get(findobj(hIA,'Tag','cmapval'), 'Value');
        for ind = 1:frames
            waitbar(ind/frames,tmpbar);
            set(findobj(hIA,'Tag','frame_slider'), 'Value', ind);
            set(findobj(hIA,'Tag','frame_text'),'String', sprintf('Frame # %d/%d (%0.3f Sec)',ind,...
                frames,(ind-1)/hIA.UserData.IAdata.file.frameRate));
            if modeval == 7 %update background
                tmpbgframe = tmpbgim(:,:,ind);
                set(hIm_bgmovie,'CData',tmpbgframe);
            end
            tmpframe=tmpim(:,:,ind);
            set(hIm_movie,'CData',tmpframe);
            %set CLim values
            if get(findobj(hIA,'Tag','stack_auto'),'Value')
                axClims = qprctile(tmpframe(~isnan(tmpframe)), [0.2 99.8]); %qprctile is faster than prctile (uses integers)
                set(findobj(hIA,'Tag','stack_blackpix'), 'String', num2str(axClims(1)));
                set(findobj(hIA,'Tag','stack_whitepix'), 'String', num2str(axClims(2)));
            else
                axClims(1) = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
                axClims(2) = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
            end
            set(hAx_Movie, 'Clim', axClims);
            cmap = colormap(hAx_Movie,[cmapstrings{cmapval} '(256)']); %this is slow if colorbar is showing!
            %alphamap overlay cutoff
            hIm_movie.AlphaData =  ~isnan(tmpframe);
            if modeval == 7
                hIm_movie.AlphaData(tmpframe<hIA.UserData.IAdata.overlayval) = 0;
            end
            drawnow;
            tmptime = [(ind-1)/hIA.UserData.IAdata.file.frameRate (ind-1)/hIA.UserData.IAdata.file.frameRate];
            set(findobj(hIA,'Tag','mark'),'Xdata',tmptime);
            %save the movie here
            tmpframe(tmpframe<axClims(1)) = axClims(1);
            tmpframe(tmpframe>axClims(2)) = axClims(2);
            if strcmp(movieType,'.tif')
                tifmovie.setTag(tagstruct);
                tifmovie.write(tmpframe);
                if ind ~= frames; tifmovie.writeDirectory(); end
            elseif strcmp(movieType,'.avi')
                F.colormap = cmap;
                F.cdata = uint8(255*(tmpframe-axClims(1))./(axClims(2)-axClims(1)));
                writeVideo(vidObj, F);
            else %illustrated avi
                if ind==1;  disp(movierect); end
                F = getframe(hIA,movierect);
                %F.colormap = hIA.Colormap;
                writeVideo(vidObj, F);
            end
        end
        %close and end
        if strcmp(movieType,'.tif'); close(tifmovie); else; close(vidObj); end
        close(tmpbar);
        disp('Movie Saved');
        %reset at frame #1
        set(findobj(hIA,'Tag','frame_slider'), 'Value',1);
        CBdrawFrame;
    else %save image
        hAx_Movie = findobj(hpMovie,'Tag','MovieAx');
        if modeval == 7
            imType = 'illustration'; % df/f overlay
        else
            imType = questdlg(sprintf(['>Save image data as .tif (Actual values are saved - %s precision)\n' ...
                '>Save image data as .txt (Actual values are saved - double precision)\n'...
                '>Or, save image as illustration (w/TimeSeries, ROIs, annotations, etc.)'],...
                class(hIA.UserData.IAdata.current)), 'What kind of image do you want to save?',...
                '.tif','.txt','illustration','illustration');
            if isempty(imType); return; end
        end
        if strcmp(imType,'.tif')
            tmpoutname = [hIA.UserData.IAdata.file.dir hIA.UserData.IAdata.file.name '_tmp'];
            [outname,path] = uiputfile('*.tif','Select file name', tmpoutname);
            if ~outname(1); return; end
            outim = getimage(hAx_Movie);
            %cmap = colormap(hmovieax);
            tfid = Tiff(fullfile(path,outname),'w');
            tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
            tagstruct.ImageLength = size(outim,1);
            tagstruct.ImageWidth = size(outim,2);
            tagstruct.SamplesPerPixel = 1;
            tagstruct.RowsPerStrip = size(outim,1);
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.Compression = Tiff.Compression.None;
            if isa(outim,'uint16')
                tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
                tagstruct.BitsPerSample = 16;
            else
                tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
                tagstruct.BitsPerSample = 32;
            end
            tfid.setTag(tagstruct);
            tfid.write(outim);
            close(tfid);
            disp('.tif image saved');
        elseif strcmp(imType,'.txt')
            tmpoutname = [hIA.UserData.IAdata.file.dir hIA.UserData.IAdata.file.name '_tmp.txt'];
            [outname,path] = uiputfile('*.txt','Select file name', tmpoutname);
            if ~outname(1)
                return;
            end
            outim = getimage(hAx_Movie);
            outim = double(outim);
            %rescaling option: cmin/cmax to 0/1 
            rescale = questdlg('Would you like to rescale this image such that [Cmin:Cmax] maps to [0:1]','Rescale','No');
            if strcmp(rescale,'Yes')
                cmin = str2double(get(findobj(hIA,'Tag','stack_blackpix'), 'String'));
                cmax = str2double(get(findobj(hIA,'Tag','stack_whitepix'), 'String'));
                valididx = find(~isnan(outim));
                tmp1 = outim(valididx)<cmin; outim(valididx(tmp1))=cmin;
                tmp2 = outim(valididx)>cmax; outim(valididx(tmp2))=cmax;disp(outim(53,100));
                outim = (outim-cmin)./(cmax-cmin); disp((cmax-cmin)); disp(outim(53,100));
            end
            save(fullfile(path,outname),'outim','-ascii','-double','-tabs');
            disp('.txt image saved');
        else %Image illustration
            tmpfig = figure('Visible','off','Units','Normalized','InvertHardcopy','off'); %hardcopy off: just keeps background black
            xadjust = hpMovie.Position(1)*hIA.Position(3);
            tmpfig.Position = [hIA.Position(1)+xadjust hIA.Position(2) hIA.Position(3)-xadjust hIA.Position(4)];
            copyobj(hpMovie,tmpfig); tmpfig.Children(1).Position = [ 0 0 1 1];
            imType = questdlg(sprintf(['>Save as .pdf (recommended)\n  >Or, save as .tif\n    '...
                '>Or, save as .eps']),'What format image do you want to save?','.pdf','.tif','.eps','.pdf');
            if isempty(imType); return; end
            tmpoutname = [IAdata.file.dir IAdata.file.name '_tmp'];
            if strcmp(imType,'.pdf')
                [outname,path] = uiputfile('*.pdf','File name', tmpoutname);
                if ~outname(1); return; end
                saveas(tmpfig,fullfile(path, outname),'pdf');
            elseif strcmp(imType,'.tif')
                [outname,path] = uiputfile('*.tif','File name', tmpoutname);
                if ~outname(1); return; end
                print(tmpfig,fullfile(path, outname), '-dtiffn');
            else %.eps
                [outname,path] = uiputfile('*.eps','File name', tmpoutname);
                if ~outname(1); return; end
                print(tmpfig,fullfile(path, outname),'-depsc'); %might want to try '-painters','-dsvg'
            end
            delete(tmpfig);
            disp('illustration image saved');
        end
    end
end

end