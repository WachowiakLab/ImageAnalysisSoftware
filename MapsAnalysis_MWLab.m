function hMAP = MapsAnalysis_MWLab(varargin)
% MWLab program for analyzing baseline vs response "odor maps"
% MapsAnalysis_MWLab(varargin)
%   varargin{1} = MapsData; (e.g. saved mapsdata loaded to workspace)

% mwmap.concentrations  %concentration for each map image (#Trialsx1 cell, w/char elements, enter manually for now)
% % 
% % MapsData %struct used to store all basic maps data (stored in hMAP.UserData)
% %         MapsData.stim2use %which stimulus signal used to generate maps
% %         MapsData.odorDuration (optional, if stim2use = 'AuxCombo' - used for scanimage auxiliary signals which do not encode odor off) 
% %         MapsData.def_stimulus (if stim2use = 'Defined Stimulus')
% %             MapsData.stimulus.times, MapsData.stimulus.signal
% %             MapsData.stimulus.delay
% %             MapsData.stimulus.duration
% %             MapsData.stimulus.interval
% %             MapsData.stimulus.trials
% %         MapsData.basetimes %times relative to stimulus TTL signal used to generate baseline images
% %         MapsData.resptimes %times relative to stimulus TTL signal used to generate response images
% %         MapsData.file %note: channels become separate files
% %             MapsData.file().type %original data file
% %             MapsData.file().name %original data file
% %             MapsData.file().dir %original data file
% %             MapsData.file().odors() %odor #s
% %             MapsData.file().odor
% %             MapsData.file().tenthprctileim % useful for deltaf/f option
% %                 MapsData.file().odor().trials() %starts at 1 for each odor, only includes valid trials
% %                 MapsData.file().odor().trial
% %                 MapsData.file().odor().concentration (optional)
% %                     MapsData.file().odor().trial().baseim
% %                     MapsData.file().odor().trial().baseframes
% %                     MapsData.file().odor().trial().respim
% %                     MapsData.file().odor().trial().respframes
% %         MapsData.roi
% %             MapsData.roi().mask
% % figdata{} used to store figure images,titles,details (stored in hMAP.UserData)
% %         figdata{1}.im
% %         figdata{1}.title{}. %text field for use in figures and saved in Tiff Tag "ImageDescription"
% %         figdata{1}.details{}. %text field to be saved in Tiff Tag
% %             "ImageDescription" includes file/odor/trial info plus image filter settings

% Written 2018 by Thomas C. Rust, Wachowiak Lab, University of Utah

tmppath=which('MapsAnalysis_MWLab');
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
guiname = [pathparts{end} '/' guiname];

prev = findobj('Name', guiname);
if ~isempty(prev); close(prev); end

persistent oldpath; if isempty(oldpath); oldpath = ''; end
typestr = getdatatypes;
stimstr = getauxtypes;
imagetypestr = {'Mean Baseline';'Mean Response'; ...
    'DeltaF (Response-Baseline)'; '%DeltaFoverF [100*(Resp-Base)/Base]'};
%    '10th Percentile (All Frames)'; '%DeltaFoverF [100*(Resp-Base)/10thPctile]'};
cmapstrings = getcmaps;
defaultaxescolor = [.5 .5 .5];
figdata = {};

%load previous settings file
try
    load(fullfile(guipath,'MAsettings.mat'),'-mat','MAsettings');
catch
end
if ~exist('MAsettings','var')
    MAsettings.basetimes = [-3.0 0.0]; MAsettings.resptimes = [0.0 3.0];
    MAsettings.stim2use = stimstr{1};
    MAsettings.delaystr = '4'; MAsettings.durstr = '8'; MAsettings.intstr = '32'; MAsettings.trialstr = '8';
    MAsettings.imtypeval = 1;
    MAsettings.fmaskstr = '1'; MAsettings.bgsubtractval = 0; MAsettings.bgroistr = 1; 
    MAsettings.avgtrialval = 0; MAsettings.avgodorval = 0; MAsettings.avgfileval = 0;
    MAsettings.sortval = 0; MAsettings.odorlistval = 0; MAsettings.odorlistfilestr = ''; 
    MAsettings.overlayval = 0; MAsettings.cmapval = 1; MAsettings.clim1val = 1; 
    MAsettings.clim2val = 0; MAsettings.clim3val = 0; MAsettings.cminstr = '0'; 
    MAsettings.cmaxstr = '1'; MAsettings.loadfiltval = 0; MAsettings.filtfilestr = '';
    MAsettings.lpfval = 0; MAsettings.lpfstr = ''; MAsettings.hpfval = 0; MAsettings.hpfstr = '';
    MAsettings.cwfval = 0; MAsettings.cwfstr = ''; MAsettings.supval = 0; MAsettings.supstr = ''; 
    MAsettings.lowval = 0; MAsettings.lowstr = ''; MAsettings.mincutval = 0; MAsettings.mincutstr = '';
    MAsettings.maxcutval = 0; MAsettings.maxcutstr = ''; MAsettings.bilinval=0;    
end

if nargin
    MapsData = varargin{1};
%     hAux.Value = MapsData.stim2use;
else
    MapsData.file = []; MapsData.roi = [];
end

BGC = [255 204 255]/255; %background color
hMAP = figure('NumberTitle','off','Name', guiname, 'Units', 'Normalized', ...
    'Color', BGC, 'Position',  [0.01 0.05 0.25 0.85], 'DefaultAxesLineWidth', 3, ...
    'DefaultAxesFontSize', 12, 'DefaultAxesFontWeight', 'Bold','CloseRequestFcn',@CB_CloseFig);
hmenu = uimenu(hMAP,'Text','GUI Settings');
uimenu(hmenu,'Text','Save Settings','Callback',@CBSaveSettings);
uimenu(hmenu,'Text','Load Settings','Callback',@CBLoadSettings);
        
% general commands and info
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.01 .955 0.23 .04], 'String', 'Add File(s)','FontWeight','Bold', 'Callback', ...
    @CBaddFiles);
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.26 .955 0.23 .04], 'String', 'Clear File(s)','FontWeight','Bold', 'Callback', ...
    @CBclearFiles);
uicontrol(hMAP,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
    [.51 .955 0.23 .04], 'String', 'Load MapsData', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
    'Callback', @CBloadMapsData,'TooltipString','Load application data (Mapsdata) from <mydata>.mat file');
uicontrol(hMAP,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
    [.76 .955 0.23 .04], 'String', 'Save MapsData', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
    'Callback', @CBsaveMapsData,'TooltipString',sprintf(['Save application data (Mapsdata) in .mat file '...
    'so that it can be loaded again\n later (e.g. MapsAnalysis_MWLab(Mapsdata)'])); 
%ROI buttons
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.01 .755 0.18 .04], 'String', 'Load ROIs','FontWeight','Bold', 'Callback', ...
    @CBaddROIs);
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.2 .755 0.18 .04], 'String', 'Draw ROI(s)','FontWeight','Bold', 'Callback', ...
    @CBdrawROIs);
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.4 .755 0.18 .04], 'String', 'Shift ROI(s)','FontWeight','Bold', 'Callback', ...
    @CBshiftROIs);
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.6 .755 0.18 .04], 'String', 'Clear ROI(s)','FontWeight','Bold', 'Callback', ...
    @CBclearROIs);
uicontrol(hMAP,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.8 .755 0.18 .04], 'String', 'Save ROIs','FontWeight','Bold', 'Callback', ...
    @CBsaveROIs);

%Map Specifications
hMapSpecPanel = uipanel(hMAP,'Units','Normalized','Position', [0.01 0.8 0.98 0.15]);
uicontrol(hMapSpecPanel,'Style','text','String','MapsData Specifications:','FontSize',11,'FontWeight','Bold','Units','Normalized',...
    'Position',[0.0 0.82 .68 .15],'HorizontalAlignment','right');
uicontrol(hMapSpecPanel,'Style','pushbutton','String','Change','Units','normalized','Position',[0.72 0.82 .18 .15],...
    'Callback',@CBChangeSpecs);
uicontrol(hMapSpecPanel,'Style','text','String','Pre/Post Stimulus Times','Units','normalized',...
    'Position',[0.02 0.6 .36 0.15],'FontSize',10,'FontWeight','Bold',...
    'HorizontalAlignment','Center','Enable','off');
if isfield(MapsData,'basetimes'); basetimes = MapsData.basetimes; else; basetimes = MAsettings.basetimes; end
hBaseStart = uicontrol(hMapSpecPanel,'Style', 'edit', 'String', num2str(basetimes(1)),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.02 0.42 .07 0.15],'HorizontalAlignment','Right','Enable','off');
uicontrol(hMapSpecPanel,'Style', 'text', 'String', 'to','Units','normalized' ...
    ,'Position',[0.1 0.40 .05 0.15],'HorizontalAlignment','Left','Enable','off');
hBaseEnd = uicontrol(hMapSpecPanel,'Style', 'edit', 'String', num2str(basetimes(2)),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.13 0.42 .07 0.15],'HorizontalAlignment','Right','Enable','off');
uicontrol(hMapSpecPanel,'Style', 'text', 'String', '(secs) Pre-Stimulus','Units','normalized' ...
    ,'Position',[0.21 0.40 0.22 0.15],'HorizontalAlignment','Left','Enable','off');
if isfield(MapsData,'resptimes'); resptimes = MapsData.resptimes; else; resptimes = MAsettings.resptimes; end
hRespStart = uicontrol(hMapSpecPanel,'Style', 'edit', 'String', num2str(resptimes(1)),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.02 0.20 .07 0.15],'HorizontalAlignment','Right','Enable','off');
uicontrol(hMapSpecPanel,'Style', 'text', 'String', 'to','Units','normalized' ...
    ,'Position',[0.1 0.18 .05 0.15],'HorizontalAlignment','Left','Enable','off');
hRespEnd = uicontrol(hMapSpecPanel,'Style', 'edit', 'String', num2str(resptimes(2)),'Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.13 0.20 .07 0.15],'HorizontalAlignment','Right','Enable','off');
uicontrol(hMapSpecPanel,'Style', 'text', 'String', '(secs) Post-Stimulus','Units','normalized' ...
    ,'Position',[0.21 0.18 0.22 0.15],'HorizontalAlignment','Left','Enable','off');
if isfield(MapsData,'stim2use'); hauxvalue = find(strcmp(MapsData.stim2use,stimstr));
else; hauxvalue = find(strcmp(MAsettings.stim2use,stimstr));
end
hAux = uicontrol(hMapSpecPanel,'Tag','aux','Style','popupmenu','Units','normalized', 'Position', ...
    [0.53 0.6 .35 0.15], 'String', stimstr, 'FontSize',9,'FontWeight', 'Bold', 'Enable', 'off', 'Value', hauxvalue);
if hAux.Value == 3; othervisible = 'off'; durvisible = 'on'; %AuxCombo
elseif hAux.Value == 4; othervisible = 'on'; durvisible = 'on'; %Defined Stimulus
else; othervisible = 'off'; durvisible = 'off'; %Aux1, Aux2
end
if isfield(MapsData,'def_stimulus'); delaystr = num2str(MapsData.def_stimulus.delay); else; delaystr = MAsettings.delaystr; end
if isfield(MapsData,'def_stimulus'); durstr = num2str(MapsData.def_stimulus.duration);
elseif isfield(MapsData,'odorDuration'); durstr = num2str(MapsData.odorDuration);
else; durstr = MAsettings.durstr;
end
if isfield(MapsData,'def_stimulus'); intstr = num2str(MapsData.def_stimulus.interval); else; intstr = MAsettings.intstr; end
if isfield(MapsData,'def_stimulus'); trialstr = num2str(MapsData.def_stimulus.trials); else; trialstr = MAsettings.trialstr; end
hDelay = uicontrol(hMapSpecPanel,'Tag','delay','Style', 'edit', 'String', delaystr,'Units','normalized', ...
    'BackgroundColor',[1 1 1],'Position',[0.63 0.44 .05 0.1],'HorizontalAlignment','Right','Enable','off', ...
    'Visible', othervisible);
hDelayLabel = uicontrol(hMapSpecPanel,'Style', 'text', 'String', 'Initial Delay(sec)','Units','normalized', ...
    'Position',[0.69 0.44 .2 0.1],'HorizontalAlignment','Left','enable','off','Visible', othervisible);
hDuration = uicontrol(hMapSpecPanel,'Tag','duration','Style', 'edit', 'String', durstr,'Units','normalized', ...
    'BackgroundColor',[1 1 1],'Position',[0.63 0.31 .05 0.1],'HorizontalAlignment','Right','Enable','off', ...
    'Visible', durvisible);
hDurationLabel = uicontrol(hMapSpecPanel,'Style', 'text', 'String', 'Duration(sec)','Units','normalized', ...
    'Position',[0.69 0.31 .2 0.1],'HorizontalAlignment','Left','enable','off','Visible', durvisible);
hInterval = uicontrol(hMapSpecPanel,'Tag','interval','Style', 'edit', 'String', intstr,'Units','normalized', ...
    'BackgroundColor',[1 1 1],'Position',[0.63 0.18 .05 0.1],'HorizontalAlignment','Right','Enable','off', ...
    'Visible', othervisible);
hIntervalLabel = uicontrol(hMapSpecPanel,'Style', 'text', 'String', 'Interval(sec)','Units','normalized', ...
    'Position',[0.69 0.18 .2 0.1],'HorizontalAlignment','Left','enable','off', 'Visible', othervisible);
hTrials = uicontrol(hMapSpecPanel,'Tag','trials','Style', 'edit', 'String', trialstr,'Units','normalized', ...
   'BackgroundColor',[1 1 1],'Position',[0.63 0.05 .05 0.1],'HorizontalAlignment','Right','Enable','off', ...
   'Visible', othervisible);
hTrialsLabel = uicontrol(hMapSpecPanel,'Style', 'text', 'String', '# Trials','Units','normalized', ...
    'Position',[0.69 0.05 .2 0.1],'HorizontalAlignment','Left','enable','off','Visible', othervisible);

function CBChangeSpecs(~,~)
    hFig_ChangeSpecs = figure('NumberTitle','off','Toolbar','none','Name','Change MapsData Specifications',...
    'Units', 'Normalized', 'Position',[0.01 0.73 0.25 0.13],'WindowStyle','Modal');
    %Change Map Specifications
    uicontrol(hFig_ChangeSpecs,'Style','pushbutton','String','Cancel','Units','normalized','Position',[0.22 0.82 .28 .15],...
        'Callback',@CBdelete);
    uicontrol(hFig_ChangeSpecs,'Style','pushbutton','String','Apply Changes','Units','normalized','Position',[0.62 0.82 .28 .15],...
        'Callback',@CBapply);
    uicontrol(hFig_ChangeSpecs,'Style','text','String','Pre/Post Stimulus Times','Units','normalized',...
        'Position',[0.02 0.65 .36 0.15],'FontSize',10,'FontWeight','Bold', 'HorizontalAlignment','Center');
    baseStart = uicontrol(hFig_ChangeSpecs,'Style', 'edit', 'String', hBaseStart.String,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.02 0.47 .07 0.15],'HorizontalAlignment','Right');
    uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', 'to','Units','normalized' ...
        ,'Position',[0.1 0.45 .05 0.15],'HorizontalAlignment','Left');
    baseEnd = uicontrol(hFig_ChangeSpecs,'Style', 'edit', 'String', hBaseEnd.String,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.13 0.47 .07 0.15],'HorizontalAlignment','Right');
    uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', '(secs) Pre-Stimulus','Units','normalized' ...
        ,'Position',[0.21 0.45 0.22 0.15],'HorizontalAlignment','Left');
    respStart = uicontrol(hFig_ChangeSpecs,'Style', 'edit', 'String', hRespStart.String,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.02 0.25 .07 0.15],'HorizontalAlignment','Right');
    uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', 'to','Units','normalized' ...
        ,'Position',[0.1 0.23 .05 0.15],'HorizontalAlignment','Left');
    respEnd = uicontrol(hFig_ChangeSpecs,'Style', 'edit', 'String', hRespEnd.String,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.13 0.25 .07 0.15],'HorizontalAlignment','Right');
    uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', '(secs) Post-Stimulus','Units','normalized' ...
        ,'Position',[0.21 0.23 0.22 0.15],'HorizontalAlignment','Left');
    aux = uicontrol(hFig_ChangeSpecs,'Tag','aux','Style','popupmenu','Units','normalized',...
        'Position', [0.53 0.6 .35 0.15], 'String', stimstr, 'FontSize',9, ...
        'FontWeight', 'Bold', 'Value', hAux.Value, 'Callback',@CBchangestim);
    if aux.Value == 3; othervisible = 'off'; durvisible = 'on'; %AuxCombo
    elseif aux.Value == 4; othervisible = 'on'; durvisible = 'on'; %Defined Stimulus
    else; othervisible = 'off'; durvisible = 'off'; %Aux1, Aux2
    end
    if isfield(MapsData,'def_stimulus'); delaystr = num2str(MapsData.def_stimulus.delay); else; delaystr = MAsettings.delaystr; end
    if isfield(MapsData,'def_stimulus'); durstr = num2str(MapsData.def_stimulus.duration);
    elseif isfield(MapsData,'odorDuration'); durstr = num2str(MapsData.odorDuration);
    else; durstr = MAsettings.durstr;
    end
    if isfield(MapsData,'def_stimulus'); intstr = num2str(MapsData.def_stimulus.interval); else; intstr = MAsettings.intstr; end
    if isfield(MapsData,'def_stimulus'); trialstr = num2str(MapsData.def_stimulus.trials); else; trialstr = MAsettings.trialstr; end
    delay = uicontrol(hFig_ChangeSpecs,'Tag','delay','Style', 'edit', 'String', delaystr,'Units','normalized', ...
        'BackgroundColor',[1 1 1],'Position',[0.63 0.44 .05 0.1],'HorizontalAlignment','Right', ...
        'Visible', othervisible);
    delaylabel = uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', 'Initial Delay(sec)','Units','normalized', ...
        'Position',[0.69 0.44 .2 0.1],'HorizontalAlignment','Left','Visible', othervisible);
    duration = uicontrol(hFig_ChangeSpecs,'Tag','duration','Style', 'edit', 'String', durstr,'Units','normalized', ...
        'BackgroundColor',[1 1 1],'Position',[0.63 0.31 .05 0.1],'HorizontalAlignment','Right', ...
        'Visible', durvisible);
    durationlabel = uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', 'Duration(sec)','Units','normalized', ...
        'Position',[0.69 0.31 .2 0.1],'HorizontalAlignment','Left','Visible', durvisible);
    interval = uicontrol(hFig_ChangeSpecs,'Tag','interval','Style', 'edit', 'String', intstr,'Units','normalized', ...
        'BackgroundColor',[1 1 1],'Position',[0.63 0.18 .05 0.1],'HorizontalAlignment','Right', ...
        'Visible', othervisible);
    intervallabel = uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', 'Interval(sec)','Units','normalized', ...
        'Position',[0.69 0.18 .2 0.1],'HorizontalAlignment','Left', 'Visible', othervisible);
    trials = uicontrol(hFig_ChangeSpecs,'Tag','trials','Style', 'edit', 'String', trialstr,'Units','normalized', ...
       'BackgroundColor',[1 1 1],'Position',[0.63 0.05 .05 0.1],'HorizontalAlignment','Right', ...
       'Visible', othervisible);
    trialslabel = uicontrol(hFig_ChangeSpecs,'Style', 'text', 'String', '# Trials','Units','normalized', ...
        'Position',[0.69 0.05 .2 0.1],'HorizontalAlignment','Left', 'Visible', othervisible);

    function CBdelete(~,~); delete(hFig_ChangeSpecs); end
    function CBapply(~,~)
        hBaseStart.String = baseStart.String; hBaseEnd.String = baseEnd.String;
        if isfield(MapsData,'basetimes'); MapsData.basetimes = [str2double(baseStart.String) str2double(baseEnd.String)]; end
        hRespStart.String = respStart.String; hRespEnd.String = respEnd.String;
        if isfield(MapsData,'resptimes'); MapsData.resptimes = [str2double(respStart.String) str2double(respEnd.String)]; end
        hAux.Value = aux.Value; if isfield(MapsData,'stim2use'); MapsData.stim2use = stimstr{aux.Value}; end
        hDelay.String = delay.String; hDelay.Visible = delay.Visible; hDelayLabel.Visible = delaylabel.Visible;
        hDuration.String = duration.String; hDuration.Visible = duration.Visible; hDurationLabel.Visible = durationlabel.Visible; 
        hInterval.String = interval.String; hInterval.Visible = interval.Visible; hIntervalLabel.Visible = intervallabel.Visible;
        hTrials.String = trials.String; hTrials.Visible = trials.Visible; hTrialsLabel.Visible = trialslabel.Visible;
        delete(hFig_ChangeSpecs);
        hMAP.UserData.MapsData = MapsData;
        if isfield(MapsData,'file') && ~isempty(MapsData.file)
            %remove 2-channel data
            ch1 = [];
            for n = 1:length(MapsData.file)
                if isempty(strfind(MapsData.file(n).name,'_ch2')); ch1 = [ch1 n]; end
            end
            MapsData.file = MapsData.file(ch1);
            tmpbar = waitbar(0,'Loading Files & Making Maps');
            for n = 1:length(MapsData.file)
                waitbar(n/length(MapsData.file),tmpbar);
                skipch2 = []; %ch2 names are added during loop
                if n>1; skipch2 = strfind(MapsData.file(n).name,'_ch2'); end
                if isempty(skipch2)
                    dot = strfind(MapsData.file(n).name,'.'); %get raw data file name
                    orig = dot; %first character after end of original name
                    if strfind(MapsData.file(n).name,'_align')
                        orig = strfind(MapsData.file(n).name,'_align'); %added last
                    end
                    if strfind(MapsData.file(n).name,'_ch1')
                        orig = strfind(MapsData.file(n).name,'_ch1'); %added first
                    end
                    MapsData.file(n).name = [MapsData.file(n).name(1:orig-1) MapsData.file(n).name(dot:end)];
                    loadFileComputeMaps(n);
                end
            end
            close(tmpbar);
        end
        %tcrtcrtcr reset odortrialval=1...
        CBsortAndSelect;
    end
    function CBchangestim(src,~)
        if src.Value == 1 %Aux1
            othervisible = 'off'; durvisible = 'off';
        elseif src.Value == 2 %Aux2
            othervisible = 'off'; durvisible = 'off';
        elseif src.Value == 3 %AuxCombo
            othervisible = 'off'; durvisible = 'on';
        elseif src.Value == 4 %Defined Stimulus
            othervisible = 'on'; durvisible = 'on';
        end
        delay.Visible = othervisible; delaylabel.Visible = othervisible;
        duration.Visible = durvisible; durationlabel.Visible = durvisible;
        interval.Visible = othervisible; intervallabel.Visible = othervisible;
        trials.Visible = othervisible; trialslabel.Visible = othervisible;
    end
end

%Create tabs for each new figure
% TabGroup/Figure #1 Tab - controls for each plot
hTabgroup = uitabgroup(hMAP,'Units','Normalized','Position',[0 0 1 .75],'SelectionChangedFcn',@CBchangetabs);
uitab(hTabgroup,'Title','Figure #1','Tag','1','ForegroundColor','green','BackgroundColor',BGC);
tabsetup(hTabgroup.SelectedTab);
uitab(hTabgroup,'Title','Add Figure');

function CBchangetabs(~,~)
    ntabs = numel(hTabgroup.Children);
    for tabs = 1:ntabs %turn all tab names black
        hTabgroup.Children(tabs).ForegroundColor = 'black';
    end
    if strcmp(hTabgroup.SelectedTab.Title,'Add Figure')
        hTabgroup.SelectedTab.Title = sprintf('Figure #%d',ntabs);
        hTabgroup.SelectedTab.Tag = num2str(ntabs);
        hTabgroup.SelectedTab.BackgroundColor = BGC;
        hTabgroup.SelectedTab.ForegroundColor = 'green';
        tabsetup(hTabgroup.SelectedTab);
        uitab(hTabgroup,'Title','Add Figure');
    else
        hTabgroup.SelectedTab.ForegroundColor = 'green';
        tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',hTabgroup.SelectedTab.Tag));
        if isempty(tmpfig)
            tabsetup(hTabgroup.SelectedTab);
        else
            figure(tmpfig);
        end
        figure(hMAP);
    end
    CBsortAndSelect;
end

function tabsetup(tab)
    if str2double(tab.Tag)>1
        prevtab = findobj('Tag',num2str(str2double(tab.Tag)-1));
        fileval = get(findobj(prevtab,'Tag','FILE_listbox'),'Value');
        otval = get(findobj(prevtab,'Tag','OdorTrial_listbox'),'Value');
        roival = get(findobj(prevtab,'Tag','ROIs_listbox'),'Value');
        imtypeval = get(findobj(prevtab,'Tag','imagetype'),'Value');
        fmaskstr = get(findobj(prevtab,'Tag','fmaskedit'),'String');
        bgsubtractval = get(findobj(prevtab,'Tag','bgsubtract'),'Value');
        bgroistr = get(findobj(prevtab,'Tag','bgroi'),'String');
        avgtrialval = get(findobj(prevtab,'Tag','avgtrials'),'Value');
        avgodorval = get(findobj(prevtab,'Tag','avgodors'),'Value');
        avgfileval = get(findobj(prevtab,'Tag','avgfiles'),'Value');
        sortval = get(findobj(prevtab,'Tag','sortbyodor'),'Value');
        odorlistval = get(findobj(prevtab,'Tag','odorlist'),'Value');
        odorlistfilestr = get(findobj(prevtab,'Tag','odorlistfile'),'String');
        overlayval = get(findobj(prevtab,'Tag','overlay'),'Value');
        cmapval = get(findobj(prevtab,'Tag','cmap_popupmenu'),'Value');
        clim1val = get(findobj(prevtab,'Tag','clim1'),'Value');
        clim2val = get(findobj(prevtab,'Tag','clim2'),'Value');
        clim3val = get(findobj(prevtab,'Tag','clim3'),'Value');
        cminstr = get(findobj(prevtab,'Tag','Cmin'),'String');
        cmaxstr = get(findobj(prevtab,'Tag','Cmax'),'String');
        loadfiltval = get(findobj(prevtab,'Tag','loadfilter'),'Value'); filtfilestr = get(findobj(prevtab,'Tag','filtfile'),'String');
        lpfval = get(findobj(prevtab,'Tag','lpfilter'),'Value'); lpfstr = get(findobj(prevtab,'Tag','lpfilterparm'),'String');
        hpfval = get(findobj(prevtab,'Tag','hpfilter'),'Value'); hpfstr = get(findobj(prevtab,'Tag','hpfilterparm'),'String');
        cwfval = get(findobj(prevtab,'Tag','cwfilter'),'Value'); cwfstr = get(findobj(prevtab,'Tag','cweight'),'String');
        supval = get(findobj(prevtab,'Tag','suppresshighpix'),'Value'); supstr = get(findobj(prevtab,'Tag','highpix'),'String');
        lowval = get(findobj(prevtab,'Tag','lowthresh'),'Value'); lowstr = get(findobj(prevtab,'Tag','thresh'),'String');
        mincutval = get(findobj(prevtab,'Tag','mincutoff'),'Value'); mincutstr = get(findobj(prevtab,'Tag','mincut'),'String');
        maxcutval = get(findobj(prevtab,'Tag','maxcutoff'),'Value'); maxcutstr = get(findobj(prevtab,'Tag','maxcut'),'String');
        bilinval = get(findobj(prevtab,'Tag','bilinear'),'Value');        
    else
        fileval = 1; otval = 1; roival = 1;
        imtypeval = MAsettings.imtypeval; fmaskstr = MAsettings.fmaskstr; bgsubtractval = MAsettings.bgsubtractval;
        bgroistr = MAsettings.bgroistr; avgtrialval = MAsettings.avgtrialval; avgodorval = MAsettings.avgodorval; 
        avgfileval = MAsettings.avgfileval; sortval = MAsettings.sortval; odorlistval = MAsettings.odorlistval;
        odorlistfilestr = MAsettings.odorlistfilestr; overlayval = MAsettings.overlayval; cmapval = MAsettings.cmapval;
        clim1val = MAsettings.clim1val; clim2val = MAsettings.clim2val; clim3val = MAsettings.clim3val; 
        cminstr = MAsettings.cminstr; cmaxstr = MAsettings.cmaxstr; loadfiltval = MAsettings.loadfiltval;
        filtfilestr = MAsettings.filtfilestr; lpfval = MAsettings.lpfval; lpfstr = MAsettings.lpfstr;
        hpfval = MAsettings.hpfval; hpfstr = MAsettings.hpfstr; cwfval = MAsettings.cwfval; cwfstr = MAsettings.cwfstr;
        supval = MAsettings.supval; supstr = MAsettings.supstr; lowval = MAsettings.lowval; lowstr = MAsettings.lowstr;
        mincutval = MAsettings.mincutval; mincutstr = MAsettings.mincutstr; maxcutval = MAsettings.maxcutval;
        maxcutstr = MAsettings.maxcutstr; bilinval = MAsettings.bilinval;         
    end
    % Files/ROIs
    uicontrol(tab,'Style', 'text',  'Units', 'normalized', 'Position', [.01 .96 0.4 .03],...
        'BackgroundColor',BGC, 'String', 'Select File(s)','FontWeight','Bold');
    filenamestr=cell(length(MapsData.file));
    if ~isempty(MapsData.file)
        for i = 1:length(MapsData.file); filenamestr{i}=MapsData.file(i).name; end
    else; filenamestr{1} = '';
    end
    uicontrol(tab,'Style', 'listbox','Tag','FILE_listbox','Units', 'normalized', 'Position', ...
        [0.01 0.53 0.4 0.43], 'String', filenamestr, 'Value', fileval, 'BackgroundColor', [1 1 1], ...
        'Max', 100, 'Min', 0, 'Callback', @CBdrawnow, 'KeyPressFcn', @CBDeleteFile);
    function CBdrawnow(src,~) %returns control to source object
        CBsortAndSelect; figure(hMAP); hMAP.CurrentObject = src;
    end
    uicontrol(tab,'Style', 'text',  'Units', 'normalized', 'Position', [.42 .96 0.3 .03],...
        'BackgroundColor',BGC,'String', 'Odor(s),Trial(s)','FontWeight','Bold');
    uicontrol(tab,'Style', 'listbox','Tag','OdorTrial_listbox','Units', 'normalized', 'Position', ...
        [0.42 0.53 0.3 0.43], 'String', '', 'Value', otval, 'BackgroundColor', [1 1 1], ...
        'Max', 10000, 'Min', 0, 'Callback', @CBdrawnow, 'ButtonDownFcn',@CBodorSelect, 'KeyPressFcn', @CBDeleteOdorTrial);
    uicontrol(tab,'Style', 'text',  'Units', 'normalized', 'Position', [.73 .96 0.25 .03],...
        'BackgroundColor',BGC,'String', 'Select ROI(s)','FontWeight','Bold');
    uicontrol(tab,'Style', 'listbox','Tag','ROIs_listbox','Units', 'normalized', 'Position', ...
        [0.73 0.53 0.25 0.43], 'String', '', 'Value', roival, 'BackgroundColor', [1 1 1], ...
        'Max', 10000, 'Min', 0, 'Callback', @CBdrawnow);
    % Image Type
    uicontrol(tab,'Style', 'popupmenu', 'Tag', 'imagetype', 'FontSize', 9, 'FontWeight', 'bold', ...
        'String', imagetypestr, 'Value', imtypeval, 'Units', 'normalized', 'Position', ...
        [0.04 0.48 0.38 0.03], 'Callback', @CBsortAndSelect);
    uicontrol(tab,'Tag','fmasklabel','Style','text','Units','normalized','Position',[0.04 0.44 0.1 0.03], ...
        'String', 'F mask:','HorizontalAlignment','left','BackgroundColor',BGC);
    uicontrol(tab,'Tag','fmaskslider','Style','Slider','Units','Normalized','Position',[0.13 0.44 0.23 0.03],...
        'Callback',@CBsetFmask);
    uicontrol(tab,'Tag','fmaskedit', 'Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.37 0.44 0.06 0.03], 'String', fmaskstr, 'Callback',@CBsetFmask);
    % Background subtraction
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.41 0.33 0.03], 'Value', bgsubtractval, ...
        'String', 'Subtract Background ROI #:', 'BackgroundColor', BGC, 'Tag', 'bgsubtract', 'Callback', @CBsortAndSelect, ...
        'ToolTipString','BACKGROUND SUBTRACTION IS ONLY APPLIED TO BASELINE AND RESPONSE IMAGES (NOT 10th Percentile)');
    uicontrol(tab, 'Tag', 'bgroi', 'Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.37 0.41 0.06 0.03], 'String', bgroistr, 'Callback',@CBsortAndSelect);
    % Average Files/Odors/Trials
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.38 0.33 0.03], 'Value', avgtrialval, ...
        'String', 'Average Trials', 'BackgroundColor',BGC,'Tag','avgtrials','Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.35 0.33 0.03], 'Value', avgodorval, ...
        'String', 'Average Odors', 'BackgroundColor',BGC,'Tag','avgodors','Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.32 0.3 0.03], 'Value', avgfileval, ...
        'String', 'Average Files', 'BackgroundColor',BGC,'Tag','avgfiles','Callback',@CBsortAndSelect);
    %Sort by Odor#
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.29 0.3 0.03],...
        'String', 'Sort Images by Odor#', 'BackgroundColor',BGC, 'Value', sortval, ...
        'Tag', 'sortbyodor', 'Callback', @CBsortAndSelect);
    %Lookup odor name from list
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.26 0.15 0.03],...
        'String', 'Odor List', 'BackgroundColor',BGC, 'Value', odorlistval, 'Tag','odorlist','Callback',@CBsortAndSelect);
    uicontrol(tab,'Tag','odorlistfile','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.19 0.26 0.24 0.03], 'String', odorlistfilestr, 'Callback',@CBsortAndSelect);
    %Overlay ROIs
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.23 0.3 0.03],...
        'String', 'Overlay ROIs', 'BackgroundColor' ,BGC, 'Value', overlayval, 'Tag','overlay','Callback',@CBsortAndSelect);
    %List of Colormaps
    uicontrol(tab,'Style', 'text', 'String', 'Colormaps: ','Units','normalized', 'BackgroundColor',BGC,...
        'FontWeight','bold','HorizontalAlignment','left','Position',[0.04 0.19 0.3 0.03]);
    uicontrol(tab,'Style', 'popupmenu', 'Tag','cmap_popupmenu','Units', 'normalized', 'Position', ...
        [0.04 0.17 0.3 0.03], 'String', cmapstrings,'FontSize', 9, 'Callback', @CBsortAndSelect, ...
        'Value', cmapval, 'BackgroundColor', [1 1 1]);
    uicontrol(tab,'Style', 'text', 'String', 'Colormap Limits: ','Units','normalized', 'BackgroundColor',BGC,...
        'FontWeight','bold','HorizontalAlignment','left','Position',[0.04 0.13 0.3 0.03]);
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.11 0.33 0.03], ...
        'Value', clim1val, 'String', 'Auto (min-max)','BackgroundColor',BGC,'Tag','clim1','Callback',@CBmapLimits);
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.08 0.33 0.03], ...
        'Value', clim2val, 'String', 'Auto (0.2-99.8%)', 'BackgroundColor',BGC,'Tag','clim2','Callback',@CBmapLimits);
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.04 0.05 0.33 0.03],...
        'Value', clim3val, 'String', 'Manual', 'BackgroundColor',BGC,'Tag','clim3','Callback',@CBmapLimits);
    uicontrol(tab,'Style', 'text', 'String', 'Cmin: ','Units','normalized' ...
        ,'BackgroundColor',BGC,'Position',[0.04 0.015 0.065 0.02],'HorizontalAlignment','Right');
    uicontrol(tab,'Style', 'edit', 'String', cminstr,'Units','normalized', 'Callback', @CBsortAndSelect, ...
        'BackgroundColor',[1 1 1],'Position',[0.1 0.015 0.08 0.03],'HorizontalAlignment','Right', ...
        'Tag', 'Cmin', 'Enable', 'Off');
    uicontrol(tab,'Style', 'text', 'String', 'Cmax: ','Units','normalized' ...
        ,'BackgroundColor',BGC,'Position',[0.195 0.015 0.07 0.02],'HorizontalAlignment','Right');
    uicontrol(tab,'Style', 'edit', 'String', cmaxstr,'Units','normalized', 'Callback', @CBsortAndSelect, ...
        'BackgroundColor',[1 1 1],'Position',[0.26 0.015 0.08 0.03],'HorizontalAlignment','Right', ...
        'Tag', 'Cmax', 'Enable', 'Off');
    %Image Processing / Filters
    uicontrol(tab,'Style', 'text', 'String', 'Image Processing (Sequential): ','Units','normalized', 'BackgroundColor',BGC,...
        'FontWeight','bold','HorizontalAlignment','left','Position',[0.47 0.48 0.5 0.03]);
    uicontrol(tab,'Style','checkbox','string','Load Filter Kernel File','units','normalized', 'Tag', 'loadfilter',...
        'BackgroundColor',BGC, 'position',[0.47 0.45 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', loadfiltval);
    uicontrol(tab,'Tag','filtfile','Style', 'edit', 'Units', 'normalized', 'Position', [0.75 0.45 0.22 0.03], ...
        'String', filtfilestr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);  
    uicontrol(tab,'Style','checkbox','string','Low Pass Gaussian @','units','normalized', 'Tag', 'lpfilter',...
        'BackgroundColor',BGC, 'position',[0.47 0.42 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', lpfval);
    uicontrol(tab,'Tag','lpfilterparm','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.42 0.08 0.03], 'String', lpfstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'text','String', [char(963) ' Pixels'], 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.415 0.15 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','High Pass Gaussian @','units','normalized', 'Tag', 'hpfilter',...
        'BackgroundColor',BGC, 'position',[0.47 0.39 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', hpfval);
    uicontrol(tab,'Tag','hpfilterparm','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.39 0.08 0.03], 'String', hpfstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'text', 'String', [char(963) ' Pixels'], 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.385 0.15 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','3x3 Center Weighted','units','normalized', 'Tag', 'cwfilter', ...
        'BackgroundColor',BGC, 'position',[0.47 0.36 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', cwfval, ...
        'TooltipString','Center Weighted Smoothing Kernel [1,1,1;1,weight,1;1,1,1]; enter center weight');
    uicontrol(tab,'Tag','cweight','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.36 0.08 0.03], 'String', cwfstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'text', 'String', 'Weight' , 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.355 0.1 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','Suppress High Pixels','units','normalized', 'Tag', 'suppresshighpix', ...
        'BackgroundColor',BGC, 'position',[0.47 0.33 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', supval, ...
        'TooltipString',sprintf(['Sort pixel values (excluding a 5 pixel border),'...
        'then limit the max value in the image\n to be the mean of the high pixels selected. (enter # of high pixels']));
    uicontrol(tab,'Tag','highpix','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.33 0.08 0.03], 'String', supstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'text', 'String', '# Pixels', 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.325 0.1 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','Low Threshold (0-1.0)','units','normalized', 'Tag', 'lowthresh', ...
        'BackgroundColor',BGC, 'position',[0.47 0.30 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', lowval, ...
        'TooltipString','Limit the minumum value to a specified fraction of the total range (enter value 0-1)');
    uicontrol(tab,'Tag','thresh','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.30 0.08 0.03], 'String', lowstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'text', 'String', 'Fraction' , 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.295 0.1 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','Minimum Cut-off','units','normalized', 'Tag', 'mincutoff',...
        'BackgroundColor',BGC, 'position',[0.47 0.27 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', mincutval);
    uicontrol(tab,'Tag','mincut','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.27 0.08 0.03], 'String', mincutstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect, ...
        'TooltipString','Limit the minumum to a specified value');
    uicontrol(tab,'Style', 'text', 'String', 'Value' , 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.265 0.1 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','Maximum Cut-off ','units','normalized', 'Tag', 'maxcutoff', ...
        'BackgroundColor',BGC, 'position',[0.47 0.24 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', maxcutval, ...
        'TooltipString','Limit the maximum to a specified value');
    uicontrol(tab,'Tag','maxcut','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.75 0.24 0.08 0.03], 'String', maxcutstr, 'Fontweight', 'Bold', 'Callback',@CBsortAndSelect);
    uicontrol(tab,'Style', 'text', 'String', 'Value' , 'Units', 'Normalized' ,'BackgroundColor',BGC, ...
        'Position', [0.84 0.235 0.1 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Style','checkbox','string','Bilinear Interpolation','units','normalized', 'Tag', 'bilinear',...
        'BackgroundColor',BGC, 'position',[0.47 0.21 0.3 0.03],'Callback',@CBsortAndSelect, 'Value', bilinval);    
    %Analysis Methods
    uicontrol(tab,'Style', 'text', 'String', 'Analysis Methods: ','Units','normalized', 'BackgroundColor',BGC,...
        'FontWeight','bold','HorizontalAlignment','left','Position',[0.47 0.17 0.5 0.03]);
    %Save Maps as Tif
    uicontrol(tab,'Style', 'pushbutton',  'Units', 'normalized', 'Position', [0.47 0.13 0.24 .04],...
        'String', 'Save Maps as Tiff','FontWeight','Bold', 'Callback', @CBsaveImage);
    %Montage
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.47 0.09 0.24 0.04],...
        'String', 'Montage', 'Fontweight', 'Bold', 'Value', 0, 'Tag','montage','Callback',@CB_montage);
    %Correlation Image
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.47 0.05 0.24 0.04],...
    'String', 'XCorr Image', 'Fontweight', 'Bold', 'Value', 0, 'Callback',@CB_CorrImage);
    %Max/Min Projection Image
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.47 0.01 0.24 0.04],...
    'String', 'Max/Min Projection', 'Fontweight', 'Bold', 'Value', 0, 'Callback',@CB_ProjectImage);
    %ROIs
    %RoiVsMap# Plot/Image
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.72 0.13 0.24 0.04],...
        'String', 'ROI vs Map # Plot', 'Fontweight', 'Bold', 'Value', 0, 'Tag','plotrois','Callback',@CB_plotROIvalues);
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.72 0.09 0.24 0.04],...
        'String', 'ROI vs Map # Image', 'Fontweight', 'Bold', 'Value', 0, 'Callback',@CB_ROIvsMapImage);
% %     uicontrol(tab,'Tag','saveplotdata', 'Style', 'pushbutton',  'Units', 'normalized', 'Position', [0.75 0.37 0.23 .04],...
% %         'String', 'Save Plot Data','FontWeight','Bold', 'Callback', @CBsavePlotData,'Enable','off');    %RoiVsRoi#
    %RoiVsROI# Plot/Image
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.72 0.05 0.24 0.04],...
        'String', 'ROI vs ROI # Plot', 'Fontweight', 'Bold', 'Value', 0, 'Tag','plotrois','Callback',@CB_plotROIvsROInum);
% %     %Save MattStack - This is some junk for Isaac/Matt
% %     uicontrol(tab,'Style', 'pushbutton',  'Units', 'normalized', 'Position', [0.72 0.01 0.23 .04],...
% %         'String', 'Save MattStack','FontWeight','Bold', 'Callback', @CBsaveMattStack);
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.72 0.01 0.24 0.04],...
        'String', 'OdorRespFile', 'Fontweight', 'Bold', 'Value', 0, 'Tag','tcr','Callback',@CB_ORfile);
    %setup new figure for image
    figshift = 0.02*(str2double(tab.Tag)-1);
    pos=hMAP.Position;
    figure('NumberTitle','off','Name',sprintf('Figure #%s',tab.Tag),'Tag',guiname,...
        'Units','normalized','Position',[(pos(1)+pos(3))+figshift+0.001 ...
        pos(2)+0.5*pos(4)-figshift 0.35 0.5*pos(4)],'WindowButtonDownFcn',@CBfigClick,'CloseRequestFcn',@CBcloseTab);
    imagesc(zeros(512,796)); set(gca,'Tag','mapax','DataAspectRatio',[1 1 1],'DataAspectRatioMode','manual','Position',[.05 .15 .9 .75]);
    val = cmapval;
    colormap(gca,[cmapstrings{val} '(256)']);
    axis image off;
end

if isfield(MapsData,'file') && ~isempty(MapsData.file)
    if isfield(MapsData.file(1),'odor') && ~isempty(MapsData.file(1).odor(1))
        CBsortAndSelect;
    end
end
hMAP.UserData.MapsData = MapsData;
%%
%Nested Callback Functions
function CB_CloseFig(~,~)
    %save settings from current tab
    updateSettings;
    save(fullfile(guipath,'MAsettings.mat'),'MAsettings');
    clear MAsettings;
    delete(hMAP);     
    delete(findobj('Tag',guiname));
end
function CBSaveSettings(~, ~)
    updateSettings;
    [setfile,setpath] = uiputfile(fullfile(guipath,'myMAsettings.mat'));
    save(fullfile(setpath,setfile),'MAsettings');
end
function updateSettings
    tab = findobj(hTabgroup,'Tag','1'); %tcrtcrtcr tab = hTabgroup.SelectedTab;
    MAsettings.basetimes = [str2double(hBaseStart.String) str2double(hBaseEnd.String)];
    MAsettings.resptimes = [str2double(hRespStart.String) str2double(hRespEnd.String)];
    MAsettings.stim2use = stimstr{hAux.Value};
    MAsettings.delaystr = hDelay.String; MAsettings.durstr = hDuration.String;
    MAsettings.intstr = hInterval.String; MAsettings.trialstr = hTrials.String;
    MAsettings.imtypeval = get(findobj(tab,'Tag','imagetype'),'Value');
    MAsettings.fmaskstr = get(findobj(tab,'Tag','fmaskedit'),'String');
    MAsettings.bgsubtractval = get(findobj(tab,'Tag','bgsubtract'),'Value');
    MAsettings.bgroistr = get(findobj(tab,'Tag','bgroi'),'String');
    MAsettings.avgtrialval = get(findobj(tab,'Tag','avgtrials'),'Value');
    MAsettings.avgodorval = get(findobj(tab,'Tag','avgodors'),'Value');
    MAsettings.avgfileval = get(findobj(tab,'Tag','avgfiles'),'Value');
    MAsettings.sortval = get(findobj(tab,'Tag','sortbyodor'),'Value');
    MAsettings.odorlistval = get(findobj(tab,'Tag','odorlist'),'Value');
    MAsettings.odorlistfilestr = get(findobj(tab,'Tag','odorlistfile'),'String');
    MAsettings.overlayval = get(findobj(tab,'Tag','overlay'),'Value');
    MAsettings.cmapval = get(findobj(tab,'Tag','cmap_popupmenu'),'Value');
    MAsettings.clim1val = get(findobj(tab,'Tag','clim1'),'Value');
    MAsettings.clim2val = get(findobj(tab,'Tag','clim2'),'Value');
    MAsettings.clim3val = get(findobj(tab,'Tag','clim3'),'Value');
    MAsettings.cminstr = get(findobj(tab,'Tag','Cmin'),'String');
    MAsettings.cmaxstr = get(findobj(tab,'Tag','Cmax'),'String');
    MAsettings.loadfiltval = get(findobj(tab,'Tag','loadfilter'),'Value');
    MAsettings.filtfilestr = get(findobj(tab,'Tag','filtfile'),'String');
    MAsettings.lpfval = get(findobj(tab,'Tag','lpfilter'),'Value');
    MAsettings.lpfstr = get(findobj(tab,'Tag','lpfilterparm'),'String');
    MAsettings.hpfval = get(findobj(tab,'Tag','hpfilter'),'Value');
    MAsettings.hpfstr = get(findobj(tab,'Tag','hpfilterparm'),'String');
    MAsettings.cwfval = get(findobj(tab,'Tag','cwfilter'),'Value');
    MAsettings.cwfstr = get(findobj(tab,'Tag','cweight'),'String');
    MAsettings.supval = get(findobj(tab,'Tag','suppresshighpix'),'Value');
    MAsettings.supstr = get(findobj(tab,'Tag','highpix'),'String');
    MAsettings.lowval = get(findobj(tab,'Tag','lowthresh'),'Value');
    MAsettings.lowstr = get(findobj(tab,'Tag','thresh'),'String');
    MAsettings.mincutval = get(findobj(tab,'Tag','mincutoff'),'Value'); 
    MAsettings.mincutstr = get(findobj(tab,'Tag','mincut'),'String');
    MAsettings.maxcutval = get(findobj(tab,'Tag','maxcutoff'),'Value');
    MAsettings.maxcutstr = get(findobj(tab,'Tag','maxcut'),'String');
    MAsettings.bilinval = get(findobj(tab,'Tag','bilinear'),'Value');
end
function CBLoadSettings(~, ~)
    [setfile,setpath] = uigetfile(fullfile(guipath,'*.mat'));
    try
        load(fullfile(setpath,setfile),'-mat','MAsettings');
        tab = findobj(hTabgroup,'Tag','1'); %tcrtcrtcr tab = hTabgroup.SelectedTab;
        if ~isfield(MapsData,'file') || isempty(MapsData.file)
            %only apply these settings if there are no maps loaded
            hBaseStart.String = num2str(MAsettings.basetimes(1));
            hBaseEnd.String = num2str(MAsettings.basetimes(2));
            if isfield(MapsData,'basetimes'); MapsData.basetimes = [str2double(baseStart.String) str2double(baseEnd.String)]; end
            hRespStart.String = num2str(MAsettings.resptimes(1));
            hRespEnd.String = num2str(MAsettings.resptimes(2));
            if isfield(MapsData,'resptimes'); MapsData.resptimes = [str2double(respStart.String) str2double(respEnd.String)]; end
            hAux.Value = find(strcmp(MAsettings.stim2use,stimstr));
            if isfield(MapsData,'stim2use'); MapsData.stim2use = stimstr{hAux.Value}; end
            hDelay.String = MAsettings.delaystr; hDuration.String = MAsettings.durstr;
            hInterval.String = MAsettings.intstr; hTrials.String = MAsettings.trialstr;
            if hAux.Value == 4; othervisible = 'on'; durvisible = 'on';
            else; othervisible = 'off'; durvisible = 'off';
            end
            hDelay.Visible = othervisible; hDuration.Visible = durvisible;
            hInterval.Visible = othervisible; hTrials.Visible = othervisible;
        end
        %if above change recompute maps!
        set(findobj(tab,'Tag','imagetype'),'Value',MAsettings.imtypeval);
        set(findobj(tab,'Tag','fmaskedit'),'String',MAsettings.fmaskstr);
        set(findobj(tab,'Tag','bgsubtract'),'Value',MAsettings.bgsubtractval);
        set(findobj(tab,'Tag','bgroi'),'String',MAsettings.bgroistr);
        set(findobj(tab,'Tag','avgtrials'),'Value',MAsettings.avgtrialval);
        set(findobj(tab,'Tag','avgodors'),'Value',MAsettings.avgodorval);
        set(findobj(tab,'Tag','avgfiles'),'Value',MAsettings.avgfileval);
        set(findobj(tab,'Tag','sortbyodor'),'Value',MAsettings.sortval);
        set(findobj(tab,'Tag','odorlist'),'Value',MAsettings.odorlistval);
        set(findobj(tab,'Tag','odorlistfile'),'String',MAsettings.odorlistfilestr);
        set(findobj(tab,'Tag','overlay'),'Value',MAsettings.overlayval);
        set(findobj(tab,'Tag','cmap_popupmenu'),'Value',MAsettings.cmapval);
        set(findobj(tab,'Tag','clim1'),'Value',MAsettings.clim1val);
        set(findobj(tab,'Tag','clim2'),'Value',MAsettings.clim2val);
        set(findobj(tab,'Tag','clim3'),'Value',MAsettings.clim3val);
        set(findobj(tab,'Tag','Cmin'),'String',MAsettings.cminstr);
        set(findobj(tab,'Tag','Cmax'),'String',MAsettings.cmaxstr);
        set(findobj(tab,'Tag','loadfilter'),'Value',MAsettings.loadfiltval);
        set(findobj(tab,'Tag','filtfile'),'String',MAsettings.filtfilestr);
        set(findobj(tab,'Tag','lpfilter'),'Value',MAsettings.lpfval);
        set(findobj(tab,'Tag','lpfilterparm'),'String',MAsettings.lpfstr);
        set(findobj(tab,'Tag','hpfilter'),'Value',MAsettings.hpfval);
        set(findobj(tab,'Tag','hpfilterparm'),'String',MAsettings.hpfstr);
        set(findobj(tab,'Tag','cwfilter'),'Value',MAsettings.cwfval);
        set(findobj(tab,'Tag','cweight'),'String',MAsettings.cwfstr);
        set(findobj(tab,'Tag','suppresshighpix'),'Value',MAsettings.supval);
        set(findobj(tab,'Tag','highpix'),'String',MAsettings.supstr);
        set(findobj(tab,'Tag','lowthresh'),'Value',MAsettings.lowval);
        set(findobj(tab,'Tag','thresh'),'String',MAsettings.lowstr);
        set(findobj(tab,'Tag','mincutoff'),'Value',MAsettings.mincutval); 
        set(findobj(tab,'Tag','mincut'),'String',MAsettings.mincutstr);
        set(findobj(tab,'Tag','maxcutoff'),'Value',MAsettings.maxcutval);
        set(findobj(tab,'Tag','maxcut'),'String',MAsettings.maxcutstr);
        set(findobj(tab,'Tag','bilinear'),'Value',MAsettings.bilinval);
        CBsortAndSelect;
    catch
    end
end
function CBfigClick(~,~)
    plotfig = gcf;
    idx = strfind(plotfig.Name,'#');
    hTabgroup.SelectedTab = findobj(hTabgroup,'Tag',plotfig.Name(idx+1:end)); CBchangetabs;
end
function CBsliderClick(obj,~)
    figure(obj.Parent);
    CBfigClick;
    CBsortAndSelect;
end
function CBcloseTab(plotfig,~)
    idx = strfind(plotfig.Name,'#');
    plotnum = str2double(plotfig.Name(idx+1:end));
    delete(plotfig);
    if numel(hTabgroup.Children)>2 %not the last tab...
        delete(hTabgroup.Children(plotnum));
        hTabgroup.SelectedTab = hTabgroup.Children(1); CBchangetabs;
        for i = 1:numel(hTabgroup.Children)
            if ~strcmp(hTabgroup.Children(i).Tag,num2str(i)) && ~strcmp(hTabgroup.Children(i).Title,'Add Figure')
                tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',hTabgroup.Children(i).Tag));
                hTabgroup.Children(i).Tag = num2str(i);
                hTabgroup.Children(i).Title = sprintf('Figure #%d',i);
                tmpfig.Name = sprintf('Figure #%s',num2str(i));           
            end 
        end
    else %last tab
        CB_CloseFig;
    end
end
function CBodorSelect(obj,~)
    tmplist = cell(numel(obj.String),1);
    for i = 1:numel(obj.String)
        ind1 = strfind(obj.String{i},'Odor');
        ind2 = strfind(obj.String{i},'Trial');
        tmplist{i} = obj.String{i}(ind1:ind2-1);
    end
    ind = obj.Value;
    match = [];
    for i = 1:length(ind)
        ind1 = strfind(obj.String{ind(i)},'Odor');
        ind2 = strfind(obj.String{ind(i)},'Trial');
        tmpmatch = find(cellfun(@(X)strcmp(obj.String{ind(i)}(ind1:ind2-1),X),tmplist));
        match = union(match,tmpmatch);
    end
    obj.Value = match;
    CBsortAndSelect;
end
function CBaddFiles(~,~) %add image file(s) to list
    % get data type if unknown
    if isempty(MapsData.file) || ~isfield(MapsData.file(1),'type') || isempty(MapsData.file(1).type)
        [typeval,ok]= listdlg('SelectionMode','single','PromptString','Select Data Type','SelectionMode','single','ListString',...
            typestr);
        if ok == 0
            return;
        end
        MapsData.file(1).type = typestr{typeval};
    end
    %get pathname & filenames
    if isfield(MapsData.file(1),'dir') && ~isempty(MapsData.file(1).dir); pathname = MapsData.file(1).dir;
    elseif exist('oldpath','var'); pathname = oldpath; else; pathname = '';
    end
    switch MapsData.file(1).type
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
            ext = {'*.da;*.tsm','Neuroplex Files'};
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', pathname, 'MultiSelect', 'On');
            MapsData.aux2bncmap = assignNeuroplexBNC;
        case 'tif' %Standard .tif
            ext = '.tif';
            [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'On');
    end
    if ~ok; return; end
    % add to any existing files, and check image file sizes match
    if isfield(MapsData.file,'name') && ~isempty(MapsData.file(end).name)
        cnt = length(MapsData.file);
        imsize = MapsData.file(1).size;
    else
        cnt = 0;
        if ischar(filename)
            [imsize(1),imsize(2)] = getImageSize(MapsData.file(1).type,fullfile(pathname,filename));
        else
            [imsize(1),imsize(2)] = getImageSize(MapsData.file(1).type,fullfile(pathname,filename{1}));
        end
    end
    if ischar(filename) %only adding 1 file
        if cnt>0
            [tmpsize(1),tmpsize(2)] = getImageSize(MapsData.file(1).type,fullfile(pathname,filename));
            if ~isequal(imsize,tmpsize)
                errordlg('File sizes do not match');
                return;
            end
        end
        numChannels = getNumChannels(MapsData.file(1).type,fullfile(pathname,filename));
        if numChannels == 1
            MapsData.file(cnt+1).name = filename;
            MapsData.file(cnt+1).dir = pathname;
            MapsData.file(cnt+1).type = MapsData.file(1).type; %tcrtcr currently limit all files to same type
            MapsData.file(cnt+1).size = imsize;
            %MapsData.file(cnt+1).numChannels = 1;
        else %two channels
            MapsData.file(cnt+1).name = filename; MapsData.file(cnt+2).name = filename;
            MapsData.file(cnt+1).dir = pathname; MapsData.file(cnt+2).dir = pathname;
            MapsData.file(cnt+1).type = MapsData.file(1).type; %tcrtcr currently limit all files to same type
            MapsData.file(cnt+2).type = MapsData.file(1).type;
            MapsData.file(cnt+1).size = imsize; MapsData.file(cnt+2).size = imsize;
            %MapsData.file(cnt+1).numChannels = 2; MapsData.file(cnt+2).numChannels = 2;
        end
    else %add more than 1 file
        %check all file sizes
        if cnt>0; m1=1; else; m1=2; end
        for i = m1:length(filename) %check image size matches
            [tmpsize(1),tmpsize(2)] = getImageSize(MapsData.file(1).type,fullfile(pathname,filename{i}));
            if ~isequal(imsize,tmpsize)
                errordlg('File sizes do not match');
                return;
            end
        end
        new = 0;
        for i = 1:length(filename) %add the images
            numChannels = getNumChannels(MapsData.file(1).type,fullfile(pathname,filename{1}));
            if numChannels == 1
                new = new+1;
                MapsData.file(cnt+new).name = filename{i};
                MapsData.file(cnt+new).dir = pathname;
                MapsData.file(cnt+new).type = MapsData.file(1).type; %tcrtcr currently limit all files to same type
                MapsData.file(cnt+new).size = imsize;
                %MapsData.file(cnt+new).numChannels = 1;
            else
                new = new+2;
                MapsData.file(cnt+new-1).name = filename{i}; MapsData.file(cnt+new).name = filename{i};
                MapsData.file(cnt+new-1).dir = pathname; MapsData.file(cnt+new).dir = pathname;
                MapsData.file(cnt+new-1).type = MapsData.file(1).type; %tcrtcr currently limit all files to same type
                MapsData.file(cnt+new).type = MapsData.file(1).type;
                MapsData.file(cnt+new-1).size = imsize; MapsData.file(cnt+new).size = imsize;
                %MapsData.file(cnt+new-1).numChannels = 2; MapsData.file(cnt+new).numChannels = 2;
            end
        end
    end
    if ~isempty(MapsData.file(end).dir); oldpath = MapsData.file(end).dir; end
    %in case ROIs were loaded, check roi size matches image size
    if isfield(MapsData,'roi') && ~isempty(MapsData.roi)
        if ~isequal(imsize,size(MapsData.roi(1).mask))
            MapsData.roi = []; % Existing ROIs size does not match loaded images; delete ROIs.
        end
    end
    %compute maps
    if isfield(MapsData,'file') && ~isempty(MapsData.file(1).name)
        tmpbar = waitbar(0,'Loading Files & Making Maps');
        for n = cnt+1:length(MapsData.file)
            waitbar(n/length(MapsData.file),tmpbar);
            skipch2 = [];
            if n>1; skipch2 = strfind(MapsData.file(n).name,'_ch2'); end
            if isempty(skipch2)
                loadFileComputeMaps(n);
            end
        end
        close(tmpbar);
    end
    hMAP.UserData.MapsData = MapsData;
    CBsortAndSelect;
end
function CBDeleteFile(~,keydata)
    if strcmp(keydata.Key,'delete'); CBclearFiles; end
end
function CBclearFiles(~,~) %clear selected files and related timeseries
    selectedfiles = get(findobj(hMAP,'Tag','FILE_listbox'),'Value');
    keep = setdiff(1:length(MapsData.file),selectedfiles);
    MapsData.file = MapsData.file(keep);
    set(findobj(hMAP,'Tag','FILE_listbox'),'Value',1);
    hMAP.UserData.MapsData = MapsData;
    CBsortAndSelect;
end
function CBDeleteOdorTrial(~,keydata)
    if ~strcmp(keydata.Key,'delete') || ~isfield(MapsData,'file') || isempty(MapsData.file); return; end
    check = questdlg('Are you sure you want to delete the selected OdorTrials?','Ask before deleting','Yes','No','Yes');
    if strcmp(check,'No'); return; end
    tab = hTabgroup.SelectedTab;
    files = get(findobj(tab,'Tag','FILE_listbox'),'Value');
    odortrials = get(findobj(tab,'Tag','OdorTrial_listbox'),'Value');
    cnt = 0; filesremoved = [];
    for f = 1:length(files)
        numodors = length(MapsData.file(files(f)).odor);
        odorsremoved = [];
        for o = 1:numodors
            nTrials = length(MapsData.file(files(f)).odor(o).trial);
            trialsremoved = [];
            for t = 1:nTrials
                cnt = cnt+1;
                if max(cnt==odortrials)
                    trialsremoved = [trialsremoved o];
                end
            end
            MapsData.file(files(f)).odor(o).trial = MapsData.file(files(f)).odor(o).trial(setdiff(1:nTrials,trialsremoved));
            MapsData.file(files(f)).odor(o).trials =  MapsData.file(files(f)).odor(o).trials(setdiff(1:nTrials,trialsremoved));
            if isempty(MapsData.file(files(f)).odor(o).trial); odorsremoved = [odorsremoved o]; end
        end
        MapsData.file(files(f)).odor = MapsData.file(files(f)).odor(setdiff(1:numodors,odorsremoved));
        MapsData.file(files(f)).odors = MapsData.file(files(f)).odors(setdiff(1:numodors,odorsremoved));
        if isempty(MapsData.file(files(f)).odor); filesremoved = [filesremoved files(f)]; end
    end
    MapsData.file = MapsData.file(setdiff(1:length(MapsData.file),filesremoved));
    hMAP.UserData.MapsData = MapsData;
    CBsortAndSelect;
end
function CBloadMapsData(~,~)
    [tmpfile, tmppath, ok] = uigetfile('*.mat', 'Open MapsData file');
    if ~ok; return; end
    MapsData = [];
    load(fullfile(tmppath,tmpfile),'MapsData');
    if strcmp(MapsData.stim2use,'AuxCombo'); MapsData.stim2use = stimstr{3}; end %this updates aux names for older saved MapsData
    if strcmp(MapsData.stim2use,'Manually Defined Stimulus'); MapsData.stim2use = stimstr{4}; end
    %set mapsdata specifications
    hBaseStart.String = MapsData.basetimes(1); hBaseEnd.String = MapsData.basetimes(2);
    hRespStart.String = MapsData.resptimes(1); hRespEnd.String = MapsData.resptimes(2);
    hAux.Value = find(strcmp(MapsData.stim2use,stimstr));
    if hAux.Value == 3 && isfield(MapsData,'odorDuration')
        hDuration.String = num2str(MapsData.odorDuration); hDuration.Visible = 'on';
    elseif hAux.Value == 4 && isfield(MapsData,'def_stimulus')
        hDelay.String = num2str(MapsData.def_stimulus.delay); hDuration.String = num2str(MapsData.def_stimulus.duration);
        hInterval.String = num2str(MapsData.def_stimulus.interval); hTrials.String = num2str(MapsData.def_stimulus.trials);
    else
        hDelay.Visible = 'off'; hDuration.Visible = 'off';
        hDuration.Visible = 'off'; hTrials.Visible = 'off';
    end
    hMAP.UserData.MapsData = MapsData;
    tab = hTabgroup.SelectedTab; set(findobj(tab,'Tag','FILE_listbox'),'Value',1);
    CBsortAndSelect;
end
function CBsaveMapsData(~,~)
    tab = hTabgroup.SelectedTab;
    selected = get(findobj(tab,'Tag','FILE_listbox'),'Value');
    [tmpfile, tmppath, ok] = uiputfile(fullfile(MapsData.file(selected(1)).dir,'MapsData.mat'), 'Save MapsData file');
    if ~ok; return; end
    m = matfile(fullfile(tmppath,tmpfile),'Writable',true);
    m.MapsData = MapsData;
    %save(fullfile(tmppath,tmpfile),'MapsData','-mat'); %This does not work as expected!!
    disp('MapsData Saved');
end

function CBaddROIs(~,~) %load/add ROIs and compute timeseries
    if isempty(MapsData.file); return; end
    tab = hTabgroup.SelectedTab;
    selectedfiles = get(findobj(tab,'Tag','FILE_listbox'),'Value');
    newrois = loadROIs(MapsData.file(selectedfiles(1)).dir);
    if ~isempty(newrois)
        if isfield(MapsData,'file') && ~isempty(MapsData.file(1).name)
            imsize = MapsData.file(1).size;
            if ~isequal(imsize,size(newrois(1).mask))
                errordlg('New ROIs size does not match image size'); uiwait;
                clear newrois; return;
            end
        elseif isfield(MapsData,'roi') && ~isempty(MapsData.roi)
            if ~isequal(size(MapsData.roi(1).mask),size(newrois(1).mask))
                errordlg('New ROIs size does not match old ROI size'); uiwait;
                clear newrois; return;
            end
        end
        % add to list of rois
        if isfield(MapsData,'roi') && ~isempty(MapsData.roi)
            cnt = length(MapsData.roi);
        else; cnt = 0;
        end
        for rr = 1:length(newrois)
            MapsData.roi(cnt+rr).mask = newrois(rr).mask;
        end
        hMAP.UserData.MapsData = MapsData;
        CBsortAndSelect;
    end
    clear newrois;
end

function CBdrawROIs(~, ~) %draw your own ROI, add to list
    if isempty(MapsData.file); return; end
    tab = hTabgroup.SelectedTab;
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag)); figure(tmpfig);
    mapax = findobj(tmpfig,'Tag','mapax');
    if isempty(mapax); return; end
    if numel(mapax)>1; mapax=mapax(end); end
    cmap = colormap(mapax);
    tmpclim = get(mapax, 'Clim');
    if ~isfield(MapsData,'roi'); MapsData.roi = []; end
    bgimage = get(mapax.Children(end),'CData');
    [MapsData.roi] = drawROI_refine(MapsData.roi,bgimage,bgimage,cmap,tmpclim);
    hMAP.UserData.MapsData = MapsData;
    CBsortAndSelect;
end
function CBshiftROIs(~, ~) %move selected ROIs
    if isempty(hMAP.UserData.MapsData.file) || ~isfield(hMAP.UserData.MapsData,'roi') ...
            || isempty(hMAP.UserData.MapsData.roi)
        return; 
    end
    colshift = inputdlg('Shift to the right (pixels)', 'Column Shift', 1, {'0.0'});
    if isempty(colshift); return; end
    colshift = str2double(colshift{1});
    rowshift = inputdlg('Shift down (pixels)', 'Row Shift', 1, {'0.0'});
    if isempty(rowshift); return; end
    rowshift = str2double(rowshift{1});
    tab = hTabgroup.SelectedTab;
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    for r = 1:length(rois)
        MapsData.roi(rois(r)).mask = circshift(MapsData.roi(rois(r)).mask,[rowshift,colshift]);
    end
    hMAP.UserData.MapsData = MapsData;
    CBsortAndSelect;
end
function CBclearROIs(~,~) %clear all ROIs
    if ~isfield(MapsData,'roi') || isempty(MapsData.roi); return; end
    tab = hTabgroup.SelectedTab;
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    keepInds = setdiff(1:length(MapsData.roi), rois);
    MapsData.roi = MapsData.roi(keepInds);
    hMAP.UserData.MapsData = MapsData;
    CBsortAndSelect;
end

function CBsaveROIs(~,~) %save ROI masks
    if ~isfield(MapsData,'roi') || isempty(MapsData.roi); return; end
    tab = hTabgroup.SelectedTab;
    selected = get(findobj(tab,'Tag','FILE_listbox'),'Value');
    saveROIs(MapsData.roi,MapsData.file(selected(1)).dir,MapsData.file(selected(1)).name);
end

function CBsortAndSelect(~,~)
    tab = hTabgroup.SelectedTab;
    filenamestr = {''};
    if isfield(MapsData,'file') && ~isempty(MapsData.file)    
        for f = 1:length(MapsData.file); filenamestr{f}=MapsData.file(f).name; end
        set(findobj(tab,'Tag','FILE_listbox'),'String',filenamestr);
        val = get(findobj(tab,'Tag','FILE_listbox'),'Value');
        odortrialstr = {''}; cnt = 0; odornum = [];
        for f = val
            for o = 1:length(MapsData.file(f).odor)
                for t = 1:length(MapsData.file(f).odor(o).trial)
                    cnt = cnt+1;
                    odortrialstr{cnt} = ['File' num2str(f) 'Odor' num2str(MapsData.file(f).odors(o)) 'Trial' num2str(MapsData.file(f).odor(o).trials(t))];
                    odornum(cnt) = MapsData.file(f).odors(o);
                end
            end
        end
        set(findobj(tab,'Tag','OdorTrial_listbox'),'String',odortrialstr);
        if max(get(findobj(tab,'Tag','OdorTrial_listbox'),'Value')>length(odortrialstr)); set(findobj(tab,'Tag','OdorTrial_listbox'),'Value',1); end
    else
        clear filenamestr; filenamestr{1} = ''; set(findobj(tab,'Tag','FILE_listbox'),'String',filenamestr,'Value',1);
        clear odortrialstr; odortrialstr{1} = ''; set(findobj(tab,'Tag','OdorTrial_listbox'),'String',odortrialstr,'Value',1);
    end
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    if ~isempty(rois) && isfield(MapsData,'roi') && ~isempty(MapsData.roi)
        if max(rois)>numel(MapsData.roi); rois = 1; set(findobj(tab,'Tag','ROIs_listbox'),'Value',1); end
        roistr = cell(numel(MapsData.roi),1);
        cnt=0;
        for n = 1:numel(MapsData.roi)
            if max(n==rois)
                cnt=cnt+1;
                cl = myColors(cnt).*255;
                roistr{n} = ['<HTML><FONT color=rgb(' ...
                    num2str(cl(1)) ',' num2str(cl(2)) ',' num2str(cl(3)) ')>ROI #' num2str(n) '</Font></html>'];
            else
                roistr{n} = ['ROI #' num2str(n)];
            end
        end
    else
        roistr='';
        set(findobj(tab,'Tag','overlay'),'Value',0); set(findobj(tab,'Tag','bgsubtract'),'Value',0);
    end
    set(findobj(tab,'Tag','ROIs_listbox'),'String',roistr);
    CBmakeFig;
end

function loadFileComputeMaps(n) %load image file and compute maps (one file at a time)
    tmpname = MapsData.file(n).name; %tmpdata = [];
    if ~isfield(MapsData,'stim2use') || isempty(MapsData.stim2use)
        MapsData.stim2use = stimstr{hAux.Value};
        MapsData.basetimes = [str2double(hBaseStart.String) str2double(hBaseEnd.String)];
        MapsData.resptimes = [str2double(hRespStart.String) str2double(hRespEnd.String)];
    end
    if strcmp(MapsData.file(n).type,'neuroplex')
        tmpdata = loadFile_MWLab(MapsData.file(n).type,MapsData.file(n).dir,tmpname,MapsData.aux2bncmap);
    else
        tmpdata = loadFile_MWLab(MapsData.file(n).type,MapsData.file(n).dir,tmpname);
    end
    %automatically align file if tmpname.align is present
    dot = strfind(tmpdata.name,'.');
    alignfile = fullfile(tmpdata.dir,[tmpdata.name(1:dot) 'align']);
    if exist(alignfile,'file')==2
        tmpbar = waitbar(0,'Aligning File');
        tmp = load(alignfile,'-mat');
        T = tmp.T; idx = tmp.idx;
        if iscell(tmpdata.im)
            for i = 1:length(idx)
                tmpdata.im{1}(:,:,idx(i)) = circshift(tmpdata.im{1}(:,:,idx(i)),T(i,:));
                tmpdata.im{2}(:,:,idx(i)) = circshift(tmpdata.im{2}(:,:,idx(i)),T(i,:));
            end
        else
            for i = 1:length(idx)
                tmpdata.im(:,:,idx(i)) = circshift(tmpdata.im(:,:,idx(i)),T(i,:));
            end
        end
        tmpname = [tmpname(1:dot-1) '_align' tmpname(dot:end)];
        close(tmpbar);
    end
    %get auxcombo stimulus if needed
    if strcmp(MapsData.stim2use,stimstr{3}) %aux_combo
        if strcmp(tmpdata.type,'scanimage') %scanimage (only gets "on" signal for odor - need to input duration)
            hDuration.Visible = 'on'; %only show duration if it is being used
            odorDuration = str2double(hDuration.String);
            tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2,odorDuration);            
        else
            hDuration.Visible = 'off';
            tmpdata.aux_combo = doAuxCombo(tmpdata.aux1,tmpdata.aux2);
        end
    end
    %get defined stimulus if needed
    if strcmp(MapsData.stim2use,stimstr{4}) %definestim
        if isfield(tmpdata,'aux1'); Max = tmpdata.aux1.times(end);
        else; Max = tmpdata.frames./tmpdata.frameRate;
        end
        delay = str2double(hDelay.String); % #frames delay
        duration = str2double(hDuration.String);
        interval = str2double(hInterval.String);
        trials = str2double(hTrials.String);
        trials = min(trials,round((Max-delay+interval)/(duration+interval)));
        hTrials.String = num2str(trials);
        deltaT=1/150; %Stimulus sampling rate is arbitrarily set at 150Hz
        tmpdata.def_stimulus = defineStimulus(0,Max,deltaT,delay,duration,interval,trials);
    end
    %make maps
    if iscell(tmpdata.im)
        %channel 1
        dot = strfind(tmpdata.name,'.');
        MapsData.file(n).name = [tmpname(1:dot-1) '_ch1' tmpname(dot:end)];
        MapsData.file(n).frameRate = tmpdata.frameRate; MapsData.file(n).frames = size(tmpdata.im{1},3);
        MapsData.file(n).odors = []; MapsData.file(n).odor = [];
        tmpdata1 = rmfield(tmpdata,'im'); tmpdata1.im = tmpdata.im{1};
        tmpMaps = makeMaps(tmpdata1, MapsData.stim2use, MapsData.basetimes, MapsData.resptimes);
        MapsData.file(n).odors = tmpMaps.file.odors; MapsData.file(n).odor = tmpMaps.file.odor;
        %channel 2
        MapsData.file(n+1).name = [tmpname(1:dot-1) '_ch2' tmpname(dot:end)];
        MapsData.file(n+1).frameRate = tmpdata.frameRate; MapsData.file(n+1).frames = size(tmpdata.im{2},3);
        MapsData.file(n+1).odors = []; MapsData.file(n+1).odor = [];
        tmpdata2 = rmfield(tmpdata,'im'); tmpdata2.im = tmpdata.im{2};
        tmpMaps = makeMaps(tmpdata2, MapsData.stim2use, MapsData.basetimes, MapsData.resptimes);
        MapsData.file(n+1).odors = tmpMaps.file.odors; MapsData.file(n+1).odor = tmpMaps.file.odor;
    else
        MapsData.file(n).name = tmpname;
        MapsData.file(n).frameRate = tmpdata.frameRate; MapsData.file(n).frames = size(tmpdata.im,3);
        MapsData.file(n).odors = []; MapsData.file(n).odor = [];
        tmpMaps = makeMaps(tmpdata, MapsData.stim2use, MapsData.basetimes, MapsData.resptimes);
        MapsData.file(n).odors = tmpMaps.file.odors; MapsData.file(n).odor = tmpMaps.file.odor;
    end
    hMAP.UserData.MapsData = MapsData;
    clear tmpdata tmpMapsData;
end

function CBmakeFig(~,~)
    if isempty(MapsData.file); return; end
    %get selected maps for figure
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag)); figure(tmpfig);
    files = get(findobj(tab,'Tag','FILE_listbox'),'Value');
    odortrials = get(findobj(tab,'Tag','OdorTrial_listbox'),'Value');
    imagetype = get(findobj(tab,'Tag','imagetype'),'Value');
    figdata{tabnum} = [];
    figdata{tabnum}.ImageDescription = [sprintf('MWLab Maps Image Description:') ...
        sprintf('\nimagetype: %s;',imagetypestr{imagetype}) ...
        sprintf('\nstim2use: %s;',MapsData.stim2use) ...
        sprintf('\nbasetimes: [%f %f];',MapsData.basetimes(1),MapsData.basetimes(2)) ...
        sprintf('\nresptimes: [%f %f];',MapsData.resptimes(1),MapsData.resptimes(2))];
    %set Fmask limits, and whether visible
    if max(imagetype==[4 6]) %tcr option 6 dF/10thpctile is removed for now
        set(findobj(tab,'tag','fmasklabel'),'Visible','on');
        set(findobj(tab,'tag','fmaskslider'),'Visible','on');
        set(findobj(tab,'tag','fmaskedit'),'Visible','on');
        fmask = str2double(get(findobj(tab,'tag','fmaskedit'),'String'));
        fmaskmin = inf; fmaskmax = -inf;
    else
        set(findobj(tab,'tag','fmasklabel'),'Visible','off');
        set(findobj(tab,'tag','fmaskslider'),'Visible','off');
        set(findobj(tab,'tag','fmaskedit'),'Visible','off');
    end
    %collect selected images used in figdata{tabnum}
    
    cnt = 0; ff = 0;
    for f = 1:length(files)
        oo = 0;
        for o = 1:length(MapsData.file(files(f)).odor)
            tt = 0;
            for t = 1:length(MapsData.file(files(f)).odor(o).trial)
                cnt = cnt+1;
                if max(cnt==odortrials)
                    tt = tt+1;
                    if ~isfield(figdata{tabnum},'file') || ~strcmp(MapsData.file(files(f)).name,figdata{tabnum}.file(ff).name)
                        ff=ff+1;
                        figdata{tabnum}.file(ff) = MapsData.file(files(f));
                        figdata{tabnum}.file(ff).odor = [];
                        figdata{tabnum}.file(ff).odors = [];
                    end
                    if isempty(figdata{tabnum}.file(ff).odors) || ~max(MapsData.file(files(f)).odors(o) == figdata{tabnum}.file(ff).odors)
                        oo=oo+1;
                        figdata{tabnum}.file(ff).odors = [figdata{tabnum}.file(ff).odors MapsData.file(files(f)).odors(o)];
                        figdata{tabnum}.file(ff).odor(oo).trials = [];
                    end
                    figdata{tabnum}.file(ff).odor(oo).trials = [figdata{tabnum}.file(ff).odor(oo).trials t];
                    
                    switch imagetype
                        case 1 %mean baseline
                            if get(findobj(tab,'Tag','bgsubtract'),'Value')
                                RoiNum = str2double(get(findobj(tab,'Tag','bgroi'),'String'));
                                BGroiIndex = MapsData.roi(RoiNum).mask>0.5;
                                figdata{tabnum}.file(ff).odor(oo).trial(tt).im = MapsData.file(files(f)).odor(o).trial(t).baseim ...
                                    - mean(MapsData.file(files(f)).odor(o).trial(t).baseim(BGroiIndex));
                            else
                                figdata{tabnum}.file(ff).odor(oo).trial(tt).im = MapsData.file(files(f)).odor(o).trial(t).baseim;
                            end
                        case 2 %mean response
                            if get(findobj(tab,'Tag','bgsubtract'),'Value')
                                RoiNum = str2double(get(findobj(tab,'Tag','bgroi'),'String'));
                                BGroiIndex = MapsData.roi(RoiNum).mask>0.5;
                                figdata{tabnum}.file(ff).odor(oo).trial(tt).im = MapsData.file(files(f)).odor(o).trial(t).respim ...
                                    - mean(MapsData.file(files(f)).odor(o).trial(t).respim(BGroiIndex));
                            else
                                figdata{tabnum}.file(ff).odor(oo).trial(tt).im = MapsData.file(files(f)).odor(o).trial(t).respim;
                            end
                        case 3 %deltaF (respone-baseline)
                            if get(findobj(tab,'Tag','bgsubtract'),'Value')
                                RoiNum = str2double(get(findobj(tab,'Tag','bgroi'),'String'));
                                BGroiIndex = MapsData.roi(RoiNum).mask>0.5;
                                baseim = MapsData.file(files(f)).odor(o).trial(t).baseim ...
                                    - mean(MapsData.file(files(f)).odor(o).trial(t).baseim(BGroiIndex));
                                respim = MapsData.file(files(f)).odor(o).trial(t).respim ...
                                    - mean(MapsData.file(files(f)).odor(o).trial(t).respim(BGroiIndex));
                            else
                                baseim = MapsData.file(files(f)).odor(o).trial(t).baseim;
                                respim = MapsData.file(files(f)).odor(o).trial(t).respim;
                            end
                            figdata{tabnum}.file(ff).odor(oo).trial(tt).im =  respim - baseim;
                            %RefImage for CB_ORdata
                            if tt==1
                                figdata{tabnum}.baseim_ORdata = baseim;
                            else
                                figdata{tabnum}.baseim_ORdata(:,:,end+1) = baseim;
                            end
                        case 4 %pct deltaF/F [100*(resp-base)/base]
                            if get(findobj(tab,'Tag','bgsubtract'),'Value')
                                RoiNum = str2double(get(findobj(tab,'Tag','bgroi'),'String'));
                                BGroiIndex = MapsData.roi(RoiNum).mask>0.5;
                                baseim = MapsData.file(files(f)).odor(o).trial(t).baseim ...
                                    - mean(MapsData.file(files(f)).odor(o).trial(t).baseim(BGroiIndex));
                                respim = MapsData.file(files(f)).odor(o).trial(t).respim ...
                                    - mean(MapsData.file(files(f)).odor(o).trial(t).respim(BGroiIndex));
                            else
                                baseim = MapsData.file(files(f)).odor(o).trial(t).baseim;
                                respim = MapsData.file(files(f)).odor(o).trial(t).respim;
                            end
                            figdata{tabnum}.file(ff).odor(oo).trial(tt).im = 100.*(respim - baseim)./baseim;
                            %apply Fmask - note that this is applied before
                            %averaging, so all nans become nan in the final
                            %result tcrtcrtcr
                            figdata{tabnum}.file(ff).odor(oo).trial(tt).im(baseim<fmask) = nan;
                            fmaskmin = min(fmaskmin,round(min(baseim(:))));
                            fmaskmax = max(fmaskmax,round(mean(baseim(:))));
                            %RefImage for CB_ORdata
                            if tt==1
                                figdata{tabnum}.baseim_ORdata = baseim;
                            else
                                figdata{tabnum}.baseim_ORdata(:,:,end+1) = baseim;
                            end
                            %10th percentile images take a looong time to compute so this is removed
% %                         case 5 %10th percentile (All Frames)
% %                             if get(findobj(tab,'Tag','bgsubtract'),'Value')
% %                                 set(findobj(tab,'Tag','bgsubtract'),'Value',0);
% %                             end
% %                             figdata{tabnum}.file(ff).odor(oo).trial(tt).im = MapsData.file(files(f)).tenthprctileim;
% %                         case 6 %pct deltaF/F [100*(resp-base)/10th pctile]
% %                             if get(findobj(tab,'Tag','bgsubtract'),'Value')
% %                                 set(findobj(tab,'Tag','bgsubtract'),'Value',0);
% %                             end
% % %                             if get(findobj(tab,'Tag','bgsubtract'),'Value')
% % %                                 RoiNum = str2double(get(findobj(tab,'Tag','bgroi'),'String'));
% % %                                 BGroiIndex = MapsData.roi(RoiNum).mask>0.5;
% % %                                 baseim = MapsData.file(files(f)).odor(o).trial(t).baseim ...
% % %                                     - mean(MapsData.file(files(f)).odor(o).trial(t).baseim(BGroiIndex));
% % %                                 respim = MapsData.file(files(f)).odor(o).trial(t).respim ...
% % %                                     - mean(MapsData.file(files(f)).odor(o).trial(t).respim(BGroiIndex));
% % %                             else
% %                                 baseim = MapsData.file(files(f)).odor(o).trial(t).baseim;
% %                                 respim = MapsData.file(files(f)).odor(o).trial(t).respim;
% % %                             end
% %                             figdata{tabnum}.file(ff).odor(oo).trial(tt).im = 100.*(respim - baseim)./MapsData.file(files(f)).tenthprctileim;
% %                             %apply Fmask
% %                             figdata{tabnum}.file(ff).odor(oo).trial(tt).im(MapsData.file(files(f)).tenthprctileim<fmask) = nan;
% %                             fmaskmin = min(fmaskmin,round(min(MapsData.file(files(f)).tenthprctileim(:))));
% %                             fmaskmax = max(fmaskmax,round(mean(MapsData.file(files(f)).tenthprctileim(:))));
                    end
                end
            end
        end
    end
    if max(imagetype==[4 6]) %tcr option 6 dF/10thpctile is removed for now
        set(findobj(tab,'tag','fmaskslider'),'Min',fmaskmin);
        if get(findobj(tab,'tag','fmaskslider'),'Value')<fmaskmin
            set(findobj(tab,'tag','fmaskslider'),'Value',fmaskmin); set(findobj(tab,'tag','fmaskedit'),'String',num2str(fmaskmin));
        end
        set(findobj(tab,'tag','fmaskslider'),'Max',fmaskmax);    
        if get(findobj(tab,'tag','fmaskslider'),'Value')>fmaskmax
            set(findobj(tab,'tag','fmaskslider'),'Value',fmaskmax); set(findobj(tab,'tag','fmaskedit'),'String',num2str(fmaskmax));
        end
    end
    %this is the tricky part of the code! we have all kinds of options for
    %averaging files/odors/trials. Also, we keep track of exactly which
    %files/odors/trials are selected (using figdata.details) so this can be
    %included in tif.ImageDescription when saving a tif file later on.
    %Also, note that averaged trials are not weighted according to the #frames
    
    %Do all the File/Odor/Trial Averaging and get Map(s), Title(s), and Detail(s)
    if get(findobj(tab,'Tag','odorlist'),'Value')
        if isempty(get(findobj(tab,'Tag','odorlistfile'),'String'))
            [odorlistfile, odorlistpath]=uigetfile('*.txt', 'Choose Odor List',MapsData.file(1).dir);
            if odorlistfile == 0; disp('Error: Odor List File Not Found'); return; end
            odorlistfile = fullfile(odorlistpath,odorlistfile);
            set(findobj(tab,'Tag','odorlistfile'),'String',odorlistfile);
        else
            odorlistfile = get(findobj(tab,'Tag','odorlistfile'),'String');
        end
        listfid = fopen(odorlistfile);
        odorlist = textscan(listfid,'%f %s %s','Delimiter','\t');
        fclose(listfid);
    end
    figdata{tabnum}.im = single([]); figdata{tabnum}.title = []; odornum = [];
    if get(findobj(tab,'Tag','avgfiles'),'Value')
        if get(findobj(tab,'Tag','avgodors'),'Value')
            if get(findobj(tab,'Tag','avgtrials'),'Value')
                cnt=1; %gather all the maps (and details)
                avgfile.avgodor.avgtrial.im = []; fileodortrialstr = [];
                for f = 1:length(figdata{tabnum}.file)
                    fileodortrialstr = [fileodortrialstr figdata{tabnum}.file(f).name];
                    if isfield(figdata{tabnum}.file(f),'odor')
                        for o = 1:length(figdata{tabnum}.file(f).odor)
                            if get(findobj(tab,'Tag','odorlist'),'Value')
                                idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                                fileodortrialstr = [fileodortrialstr '/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trials('];
                            else; fileodortrialstr = [fileodortrialstr '/Odor' num2str(figdata{tabnum}.file(f).odors(o)) '/Trials('];
                            end                            
                            for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                                fileodortrialstr = [fileodortrialstr num2str(figdata{tabnum}.file(f).odor(o).trials(t)) ','];
                                if isempty(avgfile.avgodor.avgtrial.im)
                                    avgfile.avgodor.avgtrial.im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                else; avgfile.avgodor.avgtrial.im(:,:,end+1) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                end
                            end
                            fileodortrialstr = [fileodortrialstr(1:end-1) ')'];
                        end
                        fileodortrialstr = [fileodortrialstr '/'];
                    end
                end
                figdata{tabnum}.im = mean(avgfile.avgodor.avgtrial.im,3);
                figdata{tabnum}.title{1} = 'AvgFiles/AvgOdors/AvgTrials';
                figdata{tabnum}.details{1} = fileodortrialstr;
            else %avg files/odors, not trials
                %gather all the maps for each trial#
                avgfile.avgodor.trial = []; fileodortrialstr = [];
                for f = 1:length(figdata{tabnum}.file)
                    for o = 1:length(figdata{tabnum}.file(f).odor)
                        for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                            nTrial = figdata{tabnum}.file(f).odor(o).trials(t);
                            if length(avgfile.avgodor.trial)<nTrial || isempty(avgfile.avgodor.trial(nTrial))
                                if get(findobj(tab,'Tag','odorlist'),'Value')
                                    idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                                    fileodortrialstr{nTrial} = [figdata{tabnum}.file(f).name '/' ...
                                        cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(nTrial) '/'];
                                else; fileodortrialstr{nTrial} = [figdata{tabnum}.file(f).name ...
                                        '/Odor' num2str(figdata{tabnum}.file(f).odors(o)) '/Trial' num2str(nTrial) '/'];
                                end
                                avgfile.avgodor.trial(nTrial).im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            else 
                                if get(findobj(tab,'Tag','odorlist'),'Value')
                                    idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                                    fileodortrialstr{nTrial} = [fileodortrialstr{nTrial} figdata{tabnum}.file(f).name ...
                                        '/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(nTrial) '/'];
                                else; fileodortrialstr{nTrial} = [fileodortrialstr{nTrial} figdata{tabnum}.file(f).name ...
                                        '/Odor' num2str(figdata{tabnum}.file(f).odors(o)) '/Trial' num2str(nTrial) '/'];
                                end
                                if isempty(avgfile.avgodor.trial(nTrial).im)
                                    avgfile.avgodor.trial(nTrial).im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                else
                                    avgfile.avgodor.trial(nTrial).im(:,:,end+1) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                end
                            end
                        end
                    end
                end
                %sort through what you found and toss out empty trial#s
                cnt = 0; ntrial = 0;
                for t = 1:length(avgfile.avgodor.trial)
                    if ~isempty(avgfile.avgodor.trial(t).im)
                        cnt = cnt+1; ntrial = ntrial+1;
                        figdata{tabnum}.avgfile.avgodor.trials(ntrial) = t;
                        figdata{tabnum}.im(:,:,cnt) = mean(avgfile.avgodor.trial(t).im,3);
                        figdata{tabnum}.title{cnt} = ['AvgFiles/AvgOdors' ...
                            '/Trial' num2str(t)];
                        figdata{tabnum}.details{cnt} = fileodortrialstr{t}(1:end-1);
                    end
                end                
            end
        else %avg files, not odors
            if get(findobj(tab,'Tag','avgtrials'),'Value') %avg files/trials, not odors
                %gather all the trials for each odor using odorNum+1 for index, since different files may have different odors selected)
                avgfile.odor = []; fileodortrialstr = {[]};
                for f = 1:length(figdata{tabnum}.file)
                    if isfield(figdata{tabnum}.file(f),'odor')
                        for o = 1:length(figdata{tabnum}.file(f).odor)
                            %use odorNum+1 for odorIdx, because we can have odorNum=0, so shift index by +1
                            odorNum = figdata{tabnum}.file(f).odors(o); odorIdx = odorNum+1;
                            if length(avgfile.odor)<odorIdx || isempty(avgfile.odor(odorIdx).avgtrial)
                                avgfile.odor(odorIdx).avgtrial.im = []; fileodortrialstr{odorIdx} = [];
                            end
                            for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                                if isempty(avgfile.odor(odorIdx).avgtrial.im)
                                    if get(findobj(tab,'Tag','odorlist'),'Value')
                                        idx = find(odorlist{1} == odorNum);
                                        fileodortrialstr{odorIdx} = [fileodortrialstr{odorIdx} figdata{tabnum}.file(f).name '/' ...
                                            cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                    else; fileodortrialstr{odorIdx} = [fileodortrialstr{odorIdx} figdata{tabnum}.file(f).name ...
                                            '/Odor' num2str(odorNum) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                    end
                                    avgfile.odor(odorIdx).avgtrial.im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                else
                                    if get(findobj(tab,'Tag','odorlist'),'Value')
                                        idx = find(odorlist{1} == odorNum);
                                        fileodortrialstr{odorIdx} = [fileodortrialstr{odorIdx} figdata{tabnum}.file(f).name '/' ...
                                            cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                    else; fileodortrialstr{odorIdx} = [fileodortrialstr{odorIdx} figdata{tabnum}.file(f).name ...
                                            '/Odor' num2str(odorNum) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                    end
                                    if isempty(avgfile.odor(odorIdx).avgtrial.im)
                                        avgfile.odor(odorIdx).avgtrial.im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                    else
                                        avgfile.odor(odorIdx).avgtrial.im(:,:,end+1) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                    end
                                end
                            end
                        end
                    end
                end
                %sort through what you found and toss out empty odor#s
                cnt = 0; %cnt keeps track of the new odors and #maps
                for odorIdx = 1:length(avgfile.odor)
                    if ~isempty(avgfile.odor(odorIdx).avgtrial)
                        cnt = cnt+1;
                        odornum(cnt) = odorIdx-1; %recall odorIdx is odorNum+1
                        if get(findobj(tab,'Tag','odorlist'),'Value')
                            idx = find(odorlist{1} == odorIdx-1);
                            odorstr = ['/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx))];
                        else; odorstr = ['/Odor' num2str(odorIdx-1)];
                        end
                        figdata{tabnum}.title{cnt} = ['AvgFiles' odorstr '/AvgTrials'];
                        figdata{tabnum}.details{cnt} = fileodortrialstr{odorIdx}(1:end-1);
                        figdata{tabnum}.im(:,:,cnt) = mean(avgfile.odor(odorIdx).avgtrial.im,3);
                    end
                end              
            else %avg files, not odors/trials
                %gather all the maps for each odor/trial
                avgfile.odor = []; fileodortrialstr = {[]};
                for f = 1:length(figdata{tabnum}.file)
                    for o = 1:length(figdata{tabnum}.file(f).odor)
                        odorNum = figdata{tabnum}.file(f).odors(o); odorIdx = odorNum+1;
                        if length(avgfile.odor)<odorIdx; avgfile.odor(odorIdx).trial = []; fileodortrialstr{odorIdx,1} = []; end
                        for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                            nTrial = figdata{tabnum}.file(f).odor(o).trials(t);
                            if length(avgfile.odor(odorIdx).trial)<nTrial %|| isempty(avgfile.odor(odorIdx).trial)
                                fileodortrialstr{odorIdx,nTrial} = [];
                                if get(findobj(tab,'Tag','odorlist'),'Value')
                                    idx = find(odorlist{1} == odorNum);
                                    fileodortrialstr{odorIdx,nTrial} = [fileodortrialstr{odorIdx,nTrial} figdata{tabnum}.file(f).name '/' ...
                                        cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                else; fileodortrialstr{odorIdx,nTrial} = [fileodortrialstr{odorIdx,nTrial} figdata{tabnum}.file(f).name ...
                                        '/Odor' num2str(odorNum) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                end
                                avgfile.odor(odorIdx).trial(nTrial).im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            else
                                if isempty(avgfile.odor(odorIdx).trial(nTrial).im)
                                    avgfile.odor(odorIdx).trial(nTrial).im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                else
                                    avgfile.odor(odorIdx).trial(nTrial).im(:,:,end+1) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                end
                                if get(findobj(tab,'Tag','odorlist'),'Value')
                                    idx = find(odorlist{1} == odorNum);
                                    fileodortrialstr{odorIdx,nTrial} = [fileodortrialstr{odorIdx,nTrial} figdata{tabnum}.file(f).name '/' ...
                                        cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                else; fileodortrialstr{odorIdx,nTrial} = [fileodortrialstr{odorIdx,nTrial} figdata{tabnum}.file(f).name ...
                                        '/Odor' num2str(odorNum) '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t)) '/'];
                                end
                            end
                        end
                    end
                end
                %sort through what you found and toss out empty odor#s/trial#s
                cnt = 0; newodorIdx = 0; ntrial = zeros(length(avgfile.odor),1);
                for odorIdx = 1:length(avgfile.odor)
                    ntrial(odorIdx) = 0; odorNum=odorIdx-1; %recall that odorIdx=odorNum+1
                    for t = 1:length(avgfile.odor(odorIdx).trial)
                        if ~isempty(avgfile.odor(odorIdx).trial(t).im)
                            cnt = cnt+1; ntrial(odorIdx) = ntrial(odorIdx)+1; odornum(cnt) = odorNum;
                            if ntrial(odorIdx) == 1; newodorIdx = newodorIdx+1; figdata{tabnum}.avgfile.odors(newodorIdx) = odorNum; end
                            if get(findobj(tab,'Tag','odorlist'),'Value')
                                idx = find(odorlist{1} == odorNum);
                                odorstr = ['/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx))];
                            else; odorstr = ['/Odor' num2str(odorNum)];
                            end
                            figdata{tabnum}.title{cnt} = ['AvgFiles' odorstr '/Trial' num2str(t)];
                            figdata{tabnum}.details{cnt} = fileodortrialstr{odorIdx,t}(1:end-1);
                            figdata{tabnum}.im(:,:,cnt) = mean(avgfile.odor(odorIdx).trial(t).im,3);
                        end
                    end
                end
            end
        end
    else %no file avg
        if get(findobj(tab,'Tag','avgodors'),'Value')
            if get(findobj(tab,'Tag','avgtrials'),'Value') %avg odors/trials, no files
                cnt = 0; %gather maps for each file
                for f = 1:length(figdata{tabnum}.file)
                    cnt=cnt+1; avgodor.avgtrial.im = []; odortrialstr = [];
                    for o = 1:length(figdata{tabnum}.file(f).odor)
                        if get(findobj(tab,'Tag','odorlist'),'Value')
                            idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                            odortrialstr = [odortrialstr '/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trials('];
                        else; odortrialstr = [odortrialstr '/Odor' num2str(figdata{tabnum}.file(f).odors(o)) '/Trials('];
                        end
                        for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                            odortrialstr = [odortrialstr num2str(figdata{tabnum}.file(f).odor(o).trials(t)) ','];
                            if isempty(avgodor.avgtrial.im)
                                avgodor.avgtrial.im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            else
                                avgodor.avgtrial.im(:,:,end+1) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            end
                        end
                        odortrialstr = [odortrialstr(1:end-1) ')'];
                    end
                    figdata{tabnum}.im(:,:,cnt) = mean(avgodor.avgtrial.im,3);
                    figdata{tabnum}.title{cnt} = [figdata{tabnum}.file(f).name '/AvgOdors/AvgTrials'];
                    figdata{tabnum}.details{cnt} = [figdata{tabnum}.file(f).name odortrialstr];
                end
            else %avg odors, no files/trials
                cnt = 0;
                for f = 1:length(figdata{tabnum}.file)
                    %gather maps for each trial#
                    avgodor.trial = []; odortrialstr = [];
                    for o = 1:length(figdata{tabnum}.file(f).odor)
                        for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                            nTrial = figdata{tabnum}.file(f).odor(o).trials(t);
                            if length(avgodor.trial)<nTrial || isempty(avgodor.trial(nTrial))
                                if get(findobj(tab,'Tag','odorlist'),'Value')
                                    idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                                    odortrialstr{nTrial} = ['/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(nTrial)];
                                else; odortrialstr{nTrial} = ['/Odor' num2str(figdata{tabnum}.file(f).odors(o)) '/Trial' num2str(nTrial)];
                                end
                                avgodor.trial(nTrial).im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            else
                                if get(findobj(tab,'Tag','odorlist'),'Value')
                                    idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                                    odortrialstr{nTrial} = [odortrialstr{nTrial} '/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx)) '/Trial' num2str(nTrial)];
                                else; odortrialstr{nTrial} = [odortrialstr{nTrial} '/Odor' num2str(figdata{tabnum}.file(f).odors(o)) '/Trial' num2str(nTrial)];
                                end
                                if isempty(avgodor.trial(nTrial).im)
                                    avgodor.trial(nTrial).im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                else
                                    avgodor.trial(nTrial).im(:,:,end+1) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                                end
                            end
                        end
                    end
                    %sort through what you found and toss out empty trial#s
                    for t = 1:length(avgodor.trial)
                        if ~isempty(avgodor.trial(t).im)
                            cnt = cnt+1;
                            figdata{tabnum}.im(:,:,cnt) = mean(avgodor.trial(t).im,3);
                            figdata{tabnum}.title{cnt} = [figdata{tabnum}.file(f).name '/AvgOdors' ...
                                '/Trial' num2str(t)];
                            figdata{tabnum}.details{cnt} = [figdata{tabnum}.file(f).name odortrialstr{t}];
                        end
                    end
                end
            end
        else %no file/odor avg
            if get(findobj(tab,'Tag','avgtrials'),'Value') %avg trials, no files/odors
                cnt = 0;
                for f = 1:length(figdata{tabnum}.file)
                    for o = 1:length(figdata{tabnum}.file(f).odor)
                        %gather maps
                        cnt=cnt+1; avgtrial.im = []; odortrialstr = [];
                        odornum(cnt) = figdata{tabnum}.file(f).odors(o);
                        for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                            odortrialstr = [odortrialstr num2str(t) ','];
                            if isempty(avgtrial.im)
                                avgtrial.im = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            else; avgtrial.im(:,:,end+1) =  figdata{tabnum}.file(f).odor(o).trial(t).im;
                            end
                        end
                        figdata{tabnum}.im(:,:,cnt) = mean(avgtrial.im,3);
                        if get(findobj(tab,'Tag','odorlist'),'Value')
                            idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                            odorstr = ['/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx))];
                        else; odorstr = ['/Odor' num2str(figdata{tabnum}.file(f).odors(o))];
                        end                        
                        figdata{tabnum}.title{cnt} = [figdata{tabnum}.file(f).name odorstr '/AvgTrials'];
                        figdata{tabnum}.details{cnt} = [figdata{tabnum}.file(f).name odorstr '/Trials(' odortrialstr(1:end-1) ')'];
                    end
                end
            else %no file/odor/trial avg
                cnt = 0;
                for f = 1:length(figdata{tabnum}.file)
                    for o = 1:length(figdata{tabnum}.file(f).odor)
                        for t = 1:length(figdata{tabnum}.file(f).odor(o).trial)
                            cnt = cnt+1;
                            figdata{tabnum}.im(:,:,cnt) = figdata{tabnum}.file(f).odor(o).trial(t).im;
                            odornum(cnt) = figdata{tabnum}.file(f).odors(o);
                            if get(findobj(tab,'Tag','odorlist'),'Value')
                                idx = find(odorlist{1} == figdata{tabnum}.file(f).odors(o));
                                odorstr = ['/' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx))];
                            else; odorstr = ['/Odor' num2str(figdata{tabnum}.file(f).odors(o))];
                            end
                            figdata{tabnum}.title{cnt} = [figdata{tabnum}.file(f).name odorstr ...
                                '/Trial' num2str(figdata{tabnum}.file(f).odor(o).trials(t))];
                            figdata{tabnum}.details{cnt} = figdata{tabnum}.title{cnt};
                        end
                    end
                end
            end
        end
    end
    %sort by odors
    if get(findobj(tab,'Tag','sortbyodor'),'Value')
        if get(findobj(tab,'Tag','avgodors'),'Value')
            disp('Cannot sort by odor when averaging odors');
            set(findobj(tab,'Tag','sortbyodor'),'Value',0)
        else
            [~,ind] = sort(odornum);
            figdata{tabnum}.im = figdata{tabnum}.im(:,:,ind);
            figdata{tabnum}.title = figdata{tabnum}.title(ind);
            figdata{tabnum}.details = figdata{tabnum}.details(ind);
        end
    end
    doImageProcessing;
    %display map
    mapax = findobj(tmpfig,'Tag','mapax');
    if size(figdata{tabnum}.im,3)>1
        if ~isequal(cnt,size(figdata{tabnum}.im,3)); disp('Error -tcr'); end
        slider = findobj(tmpfig,'style','slider');
        if isempty(slider)
            slider = uicontrol(tmpfig,'style','slider','Tag','slider','units','normalized','Position',[.05 .05 mapax.Position(3)-.05 .05],...
                'Max',cnt,'Min',1,'Value',1,'SliderStep',[1/(cnt-1) 1],'Callback',@CBsliderClick);
        else
            slider.Value = round(slider.Value);
            if slider.Value>cnt; slider.Value = 1; end
            slider.Max = cnt; slider.SliderStep = [1/(cnt-1) 1];
        end
        %frame # indicator
        txt = findall(tmpfig,'type','annotation');
        txt = findall(txt,'type','textbox');
        assignin('base','txt',txt');
        if isempty(txt)
            annotation(tmpfig, 'textbox', [mapax.Position(3) .05 .05 .05],'LineStyle','none',...
                'String', sprintf('%d/%d',slider.Value,cnt));
        else
            txt(end).String = sprintf('%d/%d',slider.Value,cnt);
        end
    else
        delete(findobj(tmpfig,'style','slider'));
        delete(findall(tmpfig,'type','annotation'));
    end
    tmpax = mapax;
    if size(figdata{tabnum}.im,3)>1
        tmpim = figdata{tabnum}.im(:,:,slider.Value);
        titlestr = figdata{tabnum}.title(slider.Value);
    else
        tmpim = figdata{tabnum}.im(:,:,1);
        titlestr = figdata{tabnum}.title(1);
    end
    imagesc(tmpax,tmpim); set(tmpax,'Tag','mapax','DataAspectRatio', [1 1 1],'DataAspectRatioMode','manual',...
        'YTick',[],'YColor',[1 1 1],'XTick',[],'XColor',[1 1 1]);
    tmpax.Children.AlphaData = ~isnan(tmpim); tmpax.Color = defaultaxescolor; % or use tmpax.Parent.Color;
    title(tmpax,titlestr,'interpreter','none');
    %colormap
    if get(findobj(tab,'Tag','clim1'), 'Value') %min-max
        tmp1 = min(tmpim(:)); tmp2 = max(tmpim(:));
        caxis(tmpax,[tmp1 tmp2]);
        set(findobj(tab,'Tag','Cmin'),'String',sprintf('%0.2f',tmp1)); set(findobj(tab,'Tag','Cmax'),'String',sprintf('%0.2f',tmp2));
    elseif get(findobj(tab,'Tag','clim2'), 'Value') %0.2-99.8 prctile
        tmp = prctile(tmpim(:),[.2 99.8]);
        caxis(tmpax,[tmp(1) tmp(2)]);
        set(findobj(tab,'Tag','Cmin'),'String',sprintf('%0.2f',tmp(1))); set(findobj(tab,'Tag','Cmax'),'String',sprintf('%0.2f',tmp(2)));
    elseif get(findobj(tab,'Tag','clim3'), 'Value') %manual
        tmp1 = str2num(get(findobj(tab,'Tag','Cmin'), 'String'));
        tmp2 = str2num(get(findobj(tab,'Tag','Cmax'), 'String'));
        caxis(tmpax,[tmp1 tmp2]);
    end
    val = get(findobj(tab,'Tag','cmap_popupmenu'), 'Value');
    colormap(tmpax,[cmapstrings{val} '(256)']);
    %overlay rois
    oldrois = findobj(tmpax,'type','Contour');
    for r = 1:length(oldrois); delete(oldrois(r)); end
    oldtext = findobj(tmpax,'type','Text');
    for t = 1:length(oldtext); delete(oldtext(t)); end
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    if ~isfield(MapsData,'roi') || isempty(MapsData.roi) || ~get(findobj(tab,'Tag','overlay'),'Value')
        set(findobj(tab,'Tag','overlay'),'Value',0);
    else
        hold(tmpax,'on');
        for r = 1:length(rois)
            if get(findobj(tab,'Tag','bilinear'),'Value')
                [ctemp,~] = contour(tmpax,interp2(single(MapsData.roi(rois(r)).mask)), 1, 'LineColor',myColors(r));
            else
                [ctemp,~] = contour(tmpax,MapsData.roi(rois(r)).mask, 1, 'LineColor',myColors(r));
            end
            text(tmpax,mean(ctemp(1,:)),mean(ctemp(2,:)),num2str(rois(r)),'Color',myColors(r),'FontSize',14);
        end
        hold(tmpax,'off');
    end
    roiax = findobj(tmpfig,'Tag','roiax');
    if ~isempty(roiax)
        roiax.Units = 'Pixels'; width = roiax.Position(3)+spacing; delete(roiax);
        tmpfig.Units = 'pixels'; figpos = tmpfig.Position;
        for c = 1:length(tmpfig.Children)
            tmpfig.Children(c).Units = 'pixels'; %'normalized';
        end
        txt = findall(tmpfig,'type','annotation'); if ~isempty(txt); txt.Children.Units = 'pixels'; end
        tmpfig.Position = [figpos(1) figpos(2) figpos(3)-width figpos(4)];
        for c = 1:length(tmpfig.Children)
            tmpfig.Children(c).Units = 'normalized';
        end
        if ~isempty(txt); txt.Children.Units = 'normalized'; end
        tmpfig.Units = 'normalized';
% %         set(findobj(tab,'Tag','saveplotdata'),'Enable','off')
    end
    hMAP.UserData.figdata = figdata;
end
function doImageProcessing()
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpim = figdata{tabnum}.im;
    figdata{tabnum}.im = [];
    if get(findobj(tab,'Tag','loadfilter'),'Value')
        if isempty(get(findobj(tab,'Tag','filtfile'),'String'))
            [kernfile, kernpath]=uigetfile('*.txt', 'Choose filter kernel');
            if kernfile == 0; disp('Error: Filter Kernel File Not Found'); return; end
            kernfile = fullfile(kernpath,kernfile);
            set(findobj(tab,'Tag','filtfile'),'String',kernfile);
        else
            kernfile = get(findobj(tab,'Tag','filtfile'),'String');
        end
        lp_kernel = load(kernfile); %load kernel
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nLoaded Filter Kernel: %s;',kernfile)];
    end
    if get(findobj(tab,'Tag','lpfilter'),'Value')
        if isempty(get(findobj(tab,'Tag','lpfilterparm'),'String'))
            lp_sigma = str2double(inputdlg('Enter LP Filter Sigma Value (pixels):','Enter Sigma'));
            if isempty(lp_sigma); disp('Error: LP Filter Sigma Value Not Found'); return; end
            set(findobj(tab,'Tag','lpfilterparm'),'String',num2str(lp_sigma));
        else
            lp_sigma = str2double(get(findobj(tab,'Tag','lpfilterparm'),'String'));
        end 
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nLow Pass Gaussian (sigma = %s pixels);',num2str(lp_sigma))];
    end
    if get(findobj(tab,'Tag','hpfilter'),'Value')
        if isempty(get(findobj(tab,'Tag','hpfilterparm'),'String'))
            hp_sigma = str2double(inputdlg('Enter HP Filter Sigma Value (pixels):','Enter Sigma'));
            if isempty(hp_sigma); disp('Error: HP Filter Sigma Value Not Found'); return; end
            set(findobj(tab,'Tag','hpfilterparm'),'String',num2str(hp_sigma));
        else
            hp_sigma = str2double(get(findobj(tab,'Tag','hpfilterparm'),'String'));
        end
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nHigh Pass Gaussian (sigma = %s pixels);',num2str(hp_sigma))];
    end
    if get(findobj(tab,'Tag','cwfilter'),'Value')
        if isempty(get(findobj(tab,'Tag','cweight'),'String'))
            cweight = str2double(inputdlg('Enter Center Weight Filter Value:','Enter Weight'));
            if isempty(cweight); disp('Error: Center Weight Filter Value Not Found'); return; end
            set(findobj(tab,'Tag','cweight'),'String',num2str(cweight));
        else
            cweight = str2double(get(findobj(tab,'Tag','cweight'),'String'));
        end
        cwkernel = [1,1,1;1,cweight,1;1,1,1]/(8+cweight); %this is center-weighted smoothing kernel
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\n3x3 Center Weighted Filter (weight = %s);',num2str(cweight))];
    end
    if get(findobj(tab,'Tag','suppresshighpix'),'Value')
        if isempty(get(findobj(tab,'Tag','highpix'),'String'))
            highpix = str2double(inputdlg('Enter Number of High Pixels:','Enter High Pixels'));
            if isempty(highpix); disp('Error: High Pixels Value Not Found'); return; end
            set(findobj(tab,'Tag','highpix'),'String',num2str(highpix));
        else
            highpix = str2double(get(findobj(tab,'Tag','highpix'),'String'));
        end
        if highpix <1 || highpix > numel(tmpim(:,:,1))
            highpix = ''; set(findobj(tab,'Tag','highpix'),'String',highpix);
        end
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nSuppress High Pixels (%s pixels);',num2str(highpix))];
    end
    if get(findobj(tab,'Tag','lowthresh'),'Value')
        if isempty(get(findobj(tab,'Tag','thresh'),'String'))
            thresh = str2double(inputdlg('Enter Low Threshold (fractional value):','Enter Low Thresh'));
            if isempty(thresh); disp('Error: Low Threshold Value Not Found'); return; end
            set(findobj(tab,'Tag','thresh'),'String',num2str(thresh));
        else
            thresh = str2double(get(findobj(tab,'Tag','thresh'),'String'));
        end
        if thresh <0 || thresh > 1
            thresh = ''; set(findobj(tab,'Tag','thresh'),'String',thresh);
        end
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nLow Threshold: (%s);',num2str(thresh))];
    end
    if get(findobj(tab,'Tag','mincutoff'),'Value')
        if isempty(get(findobj(tab,'Tag','mincut'),'String'))
            mincut = str2double(inputdlg('Enter Minimum Cutoff Value):','Enter Cutoff'));
            if isempty(mincut); disp('Error: Minimum Cutoff Value Not Found'); return; end
            set(findobj(tab,'Tag','mincut'),'String',num2str(mincut));
        else
            mincut = str2double(get(findobj(tab,'Tag','mincut'),'String'));
        end
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nMin Cut-off: (%s);',num2str(mincut))];
    end
    if get(findobj(tab,'Tag','maxcutoff'),'Value')
        if isempty(get(findobj(tab,'Tag','maxcut'),'String'))
            maxcut = str2double(inputdlg('Enter Maximum Cutoff Value):','Enter Cutoff'));
            if isempty(maxcut); disp('Error: Maximum Cutoff Value Not Found'); return; end
            set(findobj(tab,'Tag','maxcut'),'String',num2str(maxcut));
        else
            maxcut = str2double(get(findobj(tab,'Tag','maxcut'),'String'));
        end
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nMax Cut-off: (%s);',num2str(maxcut))];
    end
    if get(findobj(tab,'Tag','bilinear'),'Value')
        figdata{tabnum}.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nBilinear Interpolation;')];
    end
        
    for t = 1:size(tmpim,3)
        if get(findobj(tab,'Tag','loadfilter'),'Value')
            tmpim(:,:,t) = imfilter(tmpim(:,:,t), lp_kernel, 'replicate'); 
        end
        if get(findobj(tab,'Tag','lpfilter'),'Value')
            tmpim(:,:,t) = imgaussfilt(tmpim(:,:,t),lp_sigma);
        end
        if get(findobj(tab,'Tag','hpfilter'),'Value')
            tmpim(:,:,t) = tmpim(:,:,t) - imgaussfilt(tmpim(:,:,t),hp_sigma);
        end
        if get(findobj(tab,'Tag','cwfilter'),'Value')
            tmpim(:,:,t) = imfilter(tmpim(:,:,t), cwkernel, 'replicate');  %filter with appropriate kernel
        end
        if get(findobj(tab,'Tag','suppresshighpix'),'Value')
            %replaces top #highpix pixels with their mean(excluding image border)
            tmp = tmpim(:,:,t);
            tmp_sort = tmp(5:end-5,5:end-5);
            tmp_sort = sort(tmp_sort(:));
            tmp_max = mean(tmp_sort((end-highpix+1:end)));
            tmp(tmp > tmp_max) = tmp_max;
            tmpim(:,:,t) = tmp;
        end
        if get(findobj(tab,'Tag','lowthresh'),'Value')
            tmp = tmpim(:,:,t);
            tmp_min = thresh*(max(tmp(:))-min(tmp(:))) + min(tmp(:));
            tmp(tmp<tmp_min) = tmp_min;  %Sets values below threshold to be equal to min value
            tmpim(:,:,t) = tmp;
        end
        if get(findobj(tab,'Tag','mincutoff'),'Value')
            tmp = tmpim(:,:,t);
            tmp(tmp<mincut) = mincut;
            tmpim(:,:,t) = tmp;
        end
        if get(findobj(tab,'Tag','maxcutoff'),'Value')
            tmp = tmpim(:,:,t);
            tmp(tmp>maxcut) = maxcut;
            tmpim(:,:,t) = tmp;
        end
        if get(findobj(tab,'Tag','bilinear'),'Value') %This changes the image size! Bilinear interpolation DO LAST!!!
            bitmpim(:,:,t) = interp2(tmpim(:,:,t)); %also resize rois!
        end
    end
    if get(findobj(tab,'Tag','bilinear'),'Value')
        figdata{tabnum}.im = bitmpim;
    else
        figdata{tabnum}.im = tmpim;
    end
end
function CBmapLimits(~,~)
    tab = hTabgroup.SelectedTab;
    clicked = hMAP.CurrentObject;
    if clicked.Value
        if strcmp(clicked.Tag,'clim1')
            set(findobj(tab,'Tag','clim2'),'Value',0);
            set(findobj(tab,'Tag','clim3'),'Value',0);
            set(findobj(tab,'Tag','Cmin'),'Enable','off'); set(findobj(tab,'Tag','Cmax'),'Enable','off');
        elseif strcmp(clicked.Tag,'clim2')
            set(findobj(tab,'Tag','clim1'),'Value',0);
            set(findobj(tab,'Tag','clim3'),'Value',0);
            set(findobj(tab,'Tag','Cmin'),'Enable','off'); set(findobj(tab,'Tag','Cmax'),'Enable','off');
        elseif strcmp(clicked.Tag,'clim3')
            set(findobj(tab,'Tag','clim1'),'Value',0);
            set(findobj(tab,'Tag','clim2'),'Value',0);
            set(findobj(tab,'Tag','Cmin'),'Enable','on'); set(findobj(tab,'Tag','Cmax'),'Enable','on');
        end
    else
        clicked.Value = 1;
    end
    CBsortAndSelect;
end
function CBsetFmask(src,~)
    tab = hTabgroup.SelectedTab;
    if strcmp(src.Style,'slider')
        tmpval=round(src.Value);
        set(findobj(tab,'tag','fmaskedit'),'String',num2str(tmpval));
    else
        tmpval = round(str2double(get(findobj(tab,'tag','fmaskedit'),'String')));
        if tmpval<get(findobj(tab,'tag','fmaskslider'),'Min')
            tmpval=get(findobj(tab,'tag','fmaskslider'),'Min');
        end
        if tmpval>get(findobj(tab,'tag','fmaskslider'),'Max')
            tmpval=get(findobj(tab,'tag','fmaskslider'),'Max');
        end
        set(findobj(tab,'tag','fmaskslider'),'Value',tmpval);
    end
    set(findobj(tab,'tag','fmaskedit'),'String',num2str(tmpval));
    CBsortAndSelect;
end
function CBsaveImage(~,~)
    if isempty(MapsData.file); return; end
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag)); figure(tmpfig);
    mapax = findobj(tmpfig,'Tag','mapax');
    tmpoutname = [MapsData.file(1).dir 'myMaps.tif'];
    [outname,path] = uiputfile('*.tif','Select file name', tmpoutname);
    if ~outname; return; end
    tiffout = Tiff(fullfile(path,outname), 'w');%r+?
    %set Tags
    [height, width, depth] = size(figdata{tabnum}.im);
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.ImageLength = height;
    tagstruct.ImageWidth = width;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.RowsPerStrip = height;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
    tagstruct.BitsPerSample = 32;
    for d = 1:depth
        tagstruct.ImageDescription = [figdata{tabnum}.ImageDescription ...
            sprintf('\nTitle: %s;',figdata{tabnum}.title{d}) ...
            sprintf('\nDetails: %s;',figdata{tabnum}.details{d})];
        tiffout.setTag(tagstruct);
        tiffout.write(figdata{tabnum}.im(:, :, d));
        if d ~= depth; tiffout.writeDirectory(); end
    end
    tiffout.close();
    disp('Image Stack Saved as Tif (single precision 32-bit)');  
end

% % function CBsaveMattStack(~,~)
% %     if isempty(MapsData.file); return; end
% %     tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
% %     if get(findobj(tab,'Tag','odorlist'),'Value'); set(findobj(tab,'Tag','odorlist'),'Value',0); CBsortAndSelect; end
% %     tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag)); figure(tmpfig);
% %     mapax = findobj(tmpfig,'Tag','mapax');
% %     tmpoutname = [MapsData.file(1).dir 'MattStack.mat'];
% %     [outname,outpath] = uiputfile('*.tif','Select file name', tmpoutname);
% %     if ~outname; return; end
% %     tmpname = fullfile(outpath,outname);
% %     for n = 1:size(figdata{tabnum}.im,3)
% %         mattstack(:,:,n) = figdata{tabnum}.im(:,:,n);
% %         tmp1 = strfind(figdata{tabnum}.title{n},'Odor') + 4;
% %         tmp2 = strfind(figdata{tabnum}.title{n},'/') - 1; tmp2 = tmp2(2);
% %         odor = str2num(figdata{tabnum}.title{n}(tmp1:tmp2));
% %         mattstack(1,1,n) = odor/100;
% %     end
% %     save(tmpname,'mattstack');
% %     disp('MattStack File Saved');
% % end

function CB_montage(~,~)
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    frames = size(figdata{tabnum}.im,3);
    if frames < 2; return; end
    %ask #columns/rows here?
    bresize = questdlg('Would you like to customize the rows/columns?','Customize Montage','Yes','No','No');
    if strcmp(bresize,'Yes')
        [nCols,nRows] = getMontageSize(frames);
        montfig = figure('NumberTitle','off','Name',sprintf('Figure #%s Montage',tab.Tag),...
            'Units','Normalized','Position',[0.1 .2 .8 .7]);
    else
        tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
        tmpfig.Units = 'pixels'; pos = tmpfig.Position; tmpfig.Units = 'normalized';
        screens = get(0,'MonitorPositions'); width = screens(1,3);% maxwidth = sum(screens(:,3))-pos(1);
        nRows = floor((frames-1)/12)+1; if frames<=12; nCols=frames; else; nCols = 12; end
        montfig = figure('NumberTitle','off','Name',sprintf('Figure #%s Montage',tab.Tag),...
            'Position',[0 (pos(2)+pos(4))-nRows*1.2*width/nCols width nRows*1.2*(width/nCols)]);
    end
    for m = 1:frames
        if strcmp(bresize,'Yes')
            row = floor((m-1)/nCols)+1; col = m-nCols*(row-1);
            tmpax = axes(montfig,'tag','montax','Units','Normalized','Position',[(col-1)/nCols 1-row/nRows 1/nCols 1/(nRows+1)]);
        else
            row = floor((m-1)/12)+1; col = m-12*(row-1);
            tmpax = axes(montfig,'tag','montax','Position',[(col-1)/nCols 1-row/nRows 1/nCols 1/nRows]);
        end
        tmpim = figdata{tabnum}.im(:,:,m);
        titlestr = figdata{tabnum}.title(m);
        imagesc(tmpax,tmpim,'AlphaData',~isnan(tmpim)); set(tmpax,'Tag','mapax','DataAspectRatio', [1 1 1],'DataAspectRatioMode','manual',...
            'YTick',[],'YColor',[1 1 1],'XTick',[],'XColor',[1 1 1],'Color',defaultaxescolor);
        t = title(tmpax,titlestr,'interpreter','none');
        t.FontSize = 6;
        %colormap
        if get(findobj(tab,'Tag','clim1'), 'Value') %min-max
            tmp1 = min(tmpim(:)); tmp2 = max(tmpim(:));
            caxis(tmpax,[tmp1 tmp2]);
            set(findobj(tab,'Tag','Cmin'),'String',sprintf('%0.2f',tmp1)); set(findobj(tab,'Tag','Cmax'),'String',sprintf('%0.2f',tmp2));
        elseif get(findobj(tab,'Tag','clim2'), 'Value') %0.2-99.8 prctile
            tmp = prctile(tmpim(:),[.2 99.8]);
            caxis(tmpax,[tmp(1) tmp(2)]);
            set(findobj(tab,'Tag','Cmin'),'String',sprintf('%0.2f',tmp(1))); set(findobj(tab,'Tag','Cmax'),'String',sprintf('%0.2f',tmp(2)));
        elseif get(findobj(tab,'Tag','clim3'), 'Value') %manual
            tmp1 = str2num(get(findobj(tab,'Tag','Cmin'), 'String'));
            tmp2 = str2num(get(findobj(tab,'Tag','Cmax'), 'String'));
            caxis(tmpax,[tmp1 tmp2]);
        end
        val = get(findobj(tab,'Tag','cmap_popupmenu'), 'Value');
        colormap(tmpax,[cmapstrings{val} '(256)']);
    end
end
function [nCols,nRows] = getMontageSize(frames)
    h_sizefig = figure('NumberTitle','off','Name','Enter Montage Size','MenuBar','none','ToolBar','none',...
        'Units','Normalized','Position',[.4 .4 .2 .1]);%,'WindowStyle','Modal');
    uicontrol(h_sizefig,'Style','text','String',['Total # of Frames: ' num2str(frames)],...
        'FontSize',9, 'Units','Normalized','Position',[.2 .7 .6 .2]);
    nCols = round(frames/3); nRows = ceil(frames/nCols);
    uicontrol(h_sizefig,'Style','text','String','# of Columns: ','FontSize',9, ...
        'Units','Normalized','Position',[.3 .4 .3 .2]);
    hCol = uicontrol(h_sizefig,'Tag','col','Style','edit','String', num2str(nCols), ...
        'FontSize',9, 'Units','Normalized','Position',[.6 .4 .15 .2],'Callback', @CBresize);
    uicontrol(h_sizefig,'Style','text','String','# of Rows: ','FontSize',9, ...
        'Units','Normalized','Position',[.3 .1 .3 .2]);
    hRow = uicontrol(h_sizefig,'Tag','row','Style','edit','String',num2str(nRows),...
        'FontSize',9, 'Units','Normalized','Position',[.6 .1 .15 .2],'Callback', @CBresize);
    uicontrol(h_sizefig,'Style','pushbutton', 'String', 'OK', 'FontSize',9, ...
        'Units','Normalized','Position',[.8 .3 .15 .2], 'Callback', @(src, event) delete(h_sizefig));
    function CBresize(hobj,~)
        if strcmp(hobj.Tag,'col')
            nCols = round(str2double(hobj.String));
            nRows = ceil(frames/nCols);
        else %row
            nRows = round(str2double(hobj.String));
            nCols = ceil(frames/nRows);
        end
        hCol.String = num2str(nCols);
        hRow.String = num2str(nRows);
    end
    waitfor(h_sizefig);
end

function CB_plotROIvalues(~,~)
    if ~isfield(MapsData,'roi') || isempty(MapsData.roi); disp('ROIs not found.'); return; end
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    oldfig = findobj('type','figure','Name',sprintf('Figure #%s ROI Values',tab.Tag));
    if ~isempty(oldfig); delete(oldfig); end
    figure('NumberTitle','off','Name',sprintf('Figure #%s ROI Values',tab.Tag),'Units','normalized', ...
        'Position',[tmpfig.Position(1)+tmpfig.Position(3) tmpfig.Position(2) tmpfig.Position(3) tmpfig.Position(4)]);    
    frames = size(figdata{tabnum}.im,3);
    roivsmapdata = [];
    for r = 1:length(rois)
        roivsmapdata(r).XData = 1:frames;
        roivsmapdata(r).YData = zeros(1,frames);
        roivsmapdata(r).YDataLabel = sprintf('ROI #%d',rois(r));        
        for t = 1:frames
            tmp = figdata{tabnum}.im(:,:,t);
            if get(findobj(tab,'Tag','bilinear'),'Value')
                tmpdata = mean(tmp(interp2(MapsData.roi(rois(r)).mask)>0));
            else
                tmpdata = mean(tmp(MapsData.roi(rois(r)).mask>0));
            end
            roivsmapdata(r).YData(t) = mean(tmpdata(:));
            roivsmapdata(r).XDataLabels{t} = figdata{tabnum}.title{t};
        end
        plot(roivsmapdata(r).YData,'Marker','o','Color',myColors(r),'LineWidth',2,'DisplayName',sprintf('ROI #%d',rois(r)));
        hold on;
    end
    roiax = gca;
    roiax.XLim = [0.5 frames+.5]; roiax.XTick = 1:frames;
    ylabel(roiax,'ROI Values'); xlabel(roiax,'Map #');
    title('ROI Values Plotted Versus Map #');
%     roiax.XAxis.TickLabels = roivsmapdata(1).XDataLabels; roiax.XAxis.TickLabelRotation = -40;
%     roiax.XAxis.TickLabelInterpreter = 'none';
    assignin('base','roivsmapdata',roivsmapdata);
end
function CB_ROIvsMapImage(~,~)
    if isempty(MapsData.roi); return; end
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    oldfig = findobj('type','figure','Name',sprintf('Figure #%s ROI Values Image',tab.Tag));
    if ~isempty(oldfig); delete(oldfig); end
    figure('NumberTitle','off','Name',sprintf('Figure #%s ROI Values Image',tab.Tag),'Units','normalized', ...
        'Position',[tmpfig.Position(1)+tmpfig.Position(3) tmpfig.Position(2) tmpfig.Position(3) tmpfig.Position(4)]);  
    roivsmapim = [];
    for r = 1:length(rois)
        for t = 1:size(figdata{tabnum}.im,3)
            tmp = figdata{tabnum}.im(:,:,t);
            if get(findobj(tab,'Tag','bilinear'),'Value')
                tmpdata = mean(tmp(interp2(MapsData.roi(rois(r)).mask)>0));
            else
                tmpdata = mean(tmp(MapsData.roi(rois(r)).mask>0));
            end
            roivsmapim(r,t) = mean(tmpdata(:));
        end
    end
    
    imagesc(roivsmapim); ylabel('ROI#'); xlabel('Map#');
    title('ROI Vs Map# Image')
    assignin('base','roivsmapim',roivsmapim);
end

function CB_plotROIvsROInum(~,~)
    if ~isfield(MapsData,'roi') || isempty(MapsData.roi); disp('ROIs not found.'); return; end
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
    rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
    oldfig = findobj('type','figure','Name',sprintf('Figure #%s ROI Vs ROI#',tab.Tag));
    if ~isempty(oldfig); delete(oldfig); end
    figure('NumberTitle','off','Name',sprintf('Figure #%s ROI Vs ROI#',tab.Tag),'Units','normalized', ...
        'Position',[tmpfig.Position(1)+tmpfig.Position(3) tmpfig.Position(2) tmpfig.Position(3) tmpfig.Position(4)]);    
    frames = size(figdata{tabnum}.im,3);
%     for n = 1:9; linecolors(n,1:3)=ninelinecolors(n); end
%     set(0,'defaultaxescolororder',linecolors);
    set(0,'defaultaxeslinestyleorder',{'-','--',':'});
    roisvsroidata = [];
    roivsroidata(1:frames) = struct('XData',1:length(rois),'YData',zeros(1,length(rois)), ...
        'YDataLabel',[],'XDataLabels',[]);
    for t = 1:frames
        roivsroidata(t).YDataLabel = figdata{tabnum}.title{t};     
        tmp = figdata{tabnum}.im(:,:,t);
        for r = 1:length(rois)
            if get(findobj(tab,'Tag','bilinear'),'Value')
                tmpdata = mean(tmp(interp2(MapsData.roi(rois(r)).mask)>0));
            else
                tmpdata = mean(tmp(MapsData.roi(rois(r)).mask>0));
            end
            roivsroidata(t).YData(r) = mean(tmpdata(:));
            roivsroidata(t).XDataLabels{r} = sprintf('ROI #%d',rois(r));
        end
%         plot(roidata,'Marker','o','Color',ninelinecolors(t),'LineWidth',2,'DisplayName',sprintf('Map #%d',t));
        plot(roivsroidata(t).YData,'Marker','o','LineWidth',2,'DisplayName',sprintf('Map #%d',t));
        hold on;
    end
    roiax = gca;
    roiax.XLim = [0.5 length(rois)+.5]; roiax.XTick = 1:length(rois);
    ylabel(roiax,'ROI Values'); xlabel(roiax,'ROI #');
    title('ROI Values Plotted Versus ROI #');
%     set(0,'defaultaxescolororder','remove');
    set(0,'defaultaxeslinestyleorder','remove');
    assignin('base','roivsroidata',roivsroidata);
end
% % function CB_imageROIvsROInum(~,~)
% %     if isempty(MapsData.roi); return; end
% %     tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
% %     tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
% %     rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value');
% %     oldfig = findobj('type','figure','Name',sprintf('Figure #%s ROI Values Image',tab.Tag));
% %     if ~isempty(oldfig); delete(oldfig); end
% %     figure('NumberTitle','off','Name',sprintf('Figure #%s ROI Values Image',tab.Tag),'Units','normalized', ...
% %         'Position',[tmpfig.Position(1)+tmpfig.Position(3) tmpfig.Position(2) tmpfig.Position(3) tmpfig.Position(4)]);  
% %     roivaluesim = [];
% %     for r = 1:length(rois)
% %         for t = 1:size(figdata{tabnum}.im,3)
% %             tmp = figdata{tabnum}.im(:,:,t);
% %             if get(findobj(tab,'Tag','bilinear'),'Value')
% %                 tmpdata = mean(tmp(interp2(MapsData.roi(rois(r)).mask)>0));
% %             else
% %                 tmpdata = mean(tmp(MapsData.roi(rois(r)).mask>0));
% %             end
% %             roivaluesim(r,t) = mean(tmpdata(:));
% %         end
% %     end
% %     imagesc(roivaluesim); ylabel('ROI#'); xlabel('Image#');
% %     title('ROI Values Image')
% % end

function CB_CorrImage(~,~)
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    frames = size(figdata{tabnum}.im,3); if frames<2; disp('Requires >1 image'); return; end
    %Could add questionbox to ask if correlate whole map or draw/select a region
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
    oldfig = findobj('type','figure','Name',sprintf('Figure #%s Correlations Image',tab.Tag));
    if ~isempty(oldfig); delete(oldfig); end
    figure('NumberTitle','off','Name',sprintf('Figure #%s Correlations Image',tab.Tag), 'Units','normalized', ...
        'Position',[tmpfig.Position(1)+tmpfig.Position(3) tmpfig.Position(2) tmpfig.Position(3) tmpfig.Position(4)]);  
    for t = 1:frames
        tmp1 = figdata{tabnum}.im(:,:,t);
        for tt = 1:size(figdata{tabnum}.im,3)
            tmp2 = figdata{tabnum}.im(:,:,tt);
            corrMap(t,tt) = corr(tmp1(:),tmp2(:));
        end
    end
    imagesc(corrMap); ylabel('Image#'); xlabel('Image#');
    title('Correlations Image');
%     assignin('base','xcorrdata',corrMap);
end
function CB_ProjectImage(~,~)
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
    oldfig = findobj('type','figure','Name',sprintf('Figure #%s Min/Max Projections',tab.Tag));
    if ~isempty(oldfig); delete(oldfig); end
    newfig=figure('NumberTitle','off','Name',sprintf('Figure #%s Min/Max Projections',tab.Tag), 'Units','normalized', ...
        'Position',[tmpfig.Position(1)+tmpfig.Position(3) tmpfig.Position(2) 2*tmpfig.Position(3) tmpfig.Position(4)]);
    val = get(findobj(tab,'Tag','cmap_popupmenu'), 'Value');
    maxax=axes(newfig,'Position',[0.05 0.05 .4 .9]); imagesc(max(figdata{tabnum}.im,[],3)); axis image off; title('Max Intensity Projection');
    colormap(maxax,[cmapstrings{val} '(256)']);
    minax=axes(newfig,'Position',[0.55 0.05 .4 .9]); imagesc(min(figdata{tabnum}.im,[],3)); axis image off; title('Min Intensity Projection');
    colormap(minax,[cmapstrings{val} '(256)']);
end

% % function CBsavePlotData(~,~)
% %     if isempty(MapsData.file); return; end
% %     tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
% %     tmpfig = findobj('type','figure','Name',sprintf('Figure #%s',tab.Tag));
% %     roiax=findobj(tmpfig,'Tag','roiax');
% %     
% %     %decide how to output values: save cell, or writetable, or whatnot
% % %     if isempty(roiax); set(findobj(tmpfig,'Tag','saveplotdata'),'Enable','off'); return; end
% % %     lines = findobj(roiax,'type','line');
% % %     lines = flip(lines);
% % %     for l = 1:numel(lines)
% % %         myplotdata{l}.XData = lines(l).XData;
% % %         myplotdata{l}.YData = lines(l).YData;
% % %         %myplotdata{l}.Label = lines(l).DisplayName;
% % %     end
% % %     save(fullfile(path, fn), 'myplotdata');
% % end

function CB_ORfile(~,~)
    if isempty(MapsData.roi); disp('No ROIs present'); return; end
    tab = hTabgroup.SelectedTab; tabnum = str2double(tab.Tag);
    if ~max(get(findobj(tab,'Tag','imagetype'),'Value') == [3 4]); disp('Switch to %DeltaFoverF mode first!'); return; end
%     rois = get(findobj(tab,'Tag','ROIs_listbox'),'Value'); %just use all rois for now
    %%registrationGUI
    regdata.file.name = 'temporarymap';
    regdata.file.dir = './';
    regdata.file.im = mean(figdata{tabnum}.baseim_ORdata,3);
    %should probably ask - do you want to register maps?
    doreg = questdlg('Would you like to register the Maps?','Global Registration','Yes','No','Yes');
    if strcmp(doreg,'Yes')
        [registration] = RegistrationGUI_MWLab(regdata);
        ROIpositions = centroids_RegGUI(MapsData.roi,registration);
    else
        registration = [];
        ROIpositions = centroids_pixels(MapsData.roi);
    end
    roivsodordata = [];
    for r = 1:length(MapsData.roi)
        for t = 1:size(figdata{tabnum}.im,3)
            tmp = figdata{tabnum}.im(:,:,t);
            if get(findobj(tab,'Tag','bilinear'),'Value') %rois image size must match maps
                tmpdata = mean(tmp(interp2(MapsData.roi(r).mask)>0));
            else
                tmpdata = mean(tmp(MapsData.roi(r).mask>0));
            end
            roivsodordata(r,t) = mean(tmpdata(:));
        end
    end
    for o = 1:size(figdata{tabnum}.im,3)
        tmpind = strfind(figdata{tabnum}.title{o},'/');
        odorlist{o} = figdata{tabnum}.title{o}(tmpind(1)+1:tmpind(2)-1);
%         odorlist{o} = sprintf('odor %d',o);
        maps{o} = figdata{tabnum}.im(:,:,o);
        metadata{o} = [figdata{tabnum}.ImageDescription ...
            sprintf('\nTitle: %s;',figdata{tabnum}.title{o}) ...
            sprintf('\nDetails: %s;',figdata{tabnum}.details{o})];
    end
    ORdata.RefImage = regdata.file.im;
    ORdata.RespMatrix = roivsodordata;
    ORdata.OdorList = odorlist;
    ORdata.ROIPos = ROIpositions;
    ORdata.Maps = maps;
    ORdata.Reg = registration;
    ORdata.MetaData = metadata;
    tmpoutname = fullfile(MapsData.file(1).dir,'tmp.mwlab_ORdata');
    [outname,outpath] = uiputfile('*.mwlab_ORdata','Select file name', tmpoutname);
    if ~outname; return; end
    save(fullfile(outpath,outname),'ORdata','-mat');

%     disp(ORdata.Reg); assignin('base','TCR_ORdata',ORdata);
%     ROIvsOdorGUI(ORdata);
%     app.bgimage = varargin{1};
%     app.bgreg = varargin{2};
%     app.ORdata = varargin{3};
%     app.odorlist = varargin{4};
%     app.ROIPos = varargin{5};
%     app.maps = varargin{6};
    %     imagesc(roivsodordata); ylabel('ROI#'); xlabel('Map#');
%     title('ROI Vs Map# Image')
%     assignin('base','roivsmapim',roivsodordata);
end

end