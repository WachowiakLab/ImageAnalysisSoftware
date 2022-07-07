function hTS = TimeSeriesAnalysis_MWLab(varargin)
%hTS = TimeSeriesAnalysis_MWLab(varargin)
% This program is for viewing and analyzing timeseries data
% hTS is the GUI figure handle, TSdata and plotdata are stored in hTS.UserData
% varargin is for loading TSdata(struct), which must include:
%   TSdata.file.type
%   TSdata.file.name - filenames (cellstr)
%   TSdata.roi - ROIs, array w/roi(#).mask for each roi

tmppath=which('TimeSeriesAnalysis_MWLab');
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
guiname = [pathparts{end} '/' guiname];

prev = findobj('Tag',guiname);
if ~isempty(prev); close(prev); end

persistent oldpath; if isempty(oldpath); oldpath = ''; end
typestr = getdatatypes; %{'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};
auxstr = ['-Select Auxiliary Signal' getauxtypes']; %{'Aux1(odor)'; 'Aux2(sniff)'; 'AuxCombo(sniff w/odor)'; 'Define Stimulus Manually'}

bDefaultSelectAllOdorTrials = 1;

%load previous settings file
try
    load(fullfile(guipath,'TSsettings.mat'),'-mat','TSsettings');
catch
end
if ~exist('TSsettings','var') || isempty(TSsettings.byfileval)
    TSsettings.byfileval = 1; TSsettings.byroival = 0; TSsettings.byodorval = 0;
    TSsettings.bytrialval = 0; TSsettings.stimselectval = 1;
    TSsettings.delaystr = '4'; TSsettings.durstr = '4';
    TSsettings.intstr = '16'; TSsettings.trialstr = '24';
    TSsettings.hidestimval = 0;
    TSsettings.prestr = '4.0'; TSsettings.poststr = '8.0';
    TSsettings.supval = 0; TSsettings.avgtrialval = 0; TSsettings.avgfileval = 0;
    TSsettings.avgroival = 0; TSsettings.avgodorval = 0; TSsettings.bgroival = 0; TSsettings.bgroistr = '1';
    TSsettings.hpfval = 0; TSsettings.hpfstr = '0.01'; TSsettings.lpfval = 0; TSsettings.lpfstr = '0.5';
    TSsettings.confval=0; TSsettings.dfval = 0; TSsettings.dffval = 0; 
    TSsettings.fstartstr = '0'; TSsettings.fstopstr = '4'; TSsettings.showchangeval = 0;
    TSsettings.basestartstr = '0'; TSsettings.basedurstr = '4'; TSsettings.respstartstr = '0';
    TSsettings.respdurstr = '4'; TSsettings.ylimval = 0; TSsettings.yminstr = '0';
    TSsettings.ymaxstr = '1'; TSsettings.tlimval = 0; TSsettings.tminstr = '0'; TSsettings.tmaxstr = '1';
end

if nargin > 0
    TSdata = varargin{1};
    bloadnow = 1;
else
    TSdata.file = []; TSdata.roi = [];
    bloadnow = 0;
end

BGC = [255 255 204]/255; %background color
hTS = figure('NumberTitle','off','Name',guiname,'Tag',guiname,'Units', 'Normalized', ...
    'Position',  [0.01 0.05 0.22 0.85],'DefaultAxesLineWidth', 3, 'DefaultAxesFontSize', 12, ...
    'DefaultAxesFontWeight', 'Bold','CloseRequestFcn',@CB_CloseFig);
hmenu = uimenu(hTS,'Text','GUI Settings');
uimenu(hmenu,'Text','Save Settings','Callback',@CBSaveSettings);
uimenu(hmenu,'Text','Load Settings','Callback',@CBLoadSettings);
hTS.UserData.TSdata = TSdata; %update this every time it is changed!

% TabGroup/Plot #1 Tab - controls for each plot
htabgroup = uitabgroup(hTS,'Units','Normalized','Position',[0 .09 1 .91],'SelectionChangedFcn',@CBchangetabs);
uitab(htabgroup,'Title','Plot #1','Tag','1','ForegroundColor','green','BackgroundColor',BGC);
tabsetup(htabgroup.SelectedTab);
uitab(htabgroup,'Title','Add Plot');
% general commands
uicontrol(hTS,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.02 .045 0.3 .04], 'String', 'Add File(s)','FontWeight','Bold', 'Callback', ...
    @CBaddFiles);
uicontrol(hTS,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.02 .005 0.3 .04], 'String', 'Clear File(s)','FontWeight','Bold', 'Callback', ...
    @CBclearFiles);
uicontrol(hTS,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.35 .045 0.3 .04], 'String', 'Add ROI(s)','FontWeight','Bold', 'Callback', ...
    @CBaddROIs);
uicontrol(hTS,'Style', 'pushbutton',  'Units', 'normalized', 'Position', ...
    [.35 .005 0.3 .04], 'String', 'Clear ROI(s)','FontWeight','Bold', 'Callback', ...
    @CBclearROIs);
uicontrol(hTS,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
    [.68 .045 0.3 .04], 'String', 'Load App Data', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
    'Callback', @CBloadTSData,'TooltipString','Load application data (TSdata) from <mydata>.mat file');
uicontrol(hTS,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
    [.68 .005 0.3 .04], 'String', 'Save App Data', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
    'Callback', @CBsaveTSData,'TooltipString',sprintf(['Save application data (TSdata) in .mat file '...
    'so that it can be loaded again\n later (e.g. TimeSeriesAnalysis_MWLab(TSdata)']));

function CBchangetabs(~,~)
    ntabs = numel(htabgroup.Children);
    for tabs = 1:ntabs %turn all tab names black
        htabgroup.Children(tabs).ForegroundColor = 'black';
    end
    if strcmp(htabgroup.SelectedTab.Title,'Add Plot')
        htabgroup.SelectedTab.Title = sprintf('Plot #%d',ntabs);
        htabgroup.SelectedTab.Tag = num2str(ntabs);
        htabgroup.SelectedTab.BackgroundColor = BGC;
        htabgroup.SelectedTab.ForegroundColor = 'green';
        tabsetup(htabgroup.SelectedTab);
        uitab(htabgroup,'Title','Add Plot');
        CBSelectAndSortColors;
    else
        htabgroup.SelectedTab.ForegroundColor = 'green';
        tmpfig = findobj('type','figure','Name',sprintf('Plot #%s',htabgroup.SelectedTab.Tag));
        if isempty(tmpfig)
            tabsetup(htabgroup.SelectedTab); %tcr maybe have a separate figsetup fxn... or drawfig...
        else
            figure(tmpfig);
        end
        figure(hTS);
    end
end

function tabsetup(tab)
    %get previous tab info to copy to new tab - as requested
    if str2double(tab.Tag)>1
        prevtab = findobj(htabgroup,'Tag',num2str(str2double(tab.Tag)-1));
        fileval = get(findobj(prevtab,'Tag','FILE_listbox'),'Value');
        roival = get(findobj(prevtab,'Tag','ROI_listbox'),'Value');
        odortrialval = get(findobj(prevtab,'Tag','OdorTrial_listbox'),'Value');
        byfileval = get(findobj(prevtab,'Tag','byfile'),'Value');
        byroival = get(findobj(prevtab,'Tag','byroi'),'Value');
        byodorval = get(findobj(prevtab,'Tag','byodor'),'Value');
        bytrialval = get(findobj(prevtab,'Tag','bytrial'),'Value');
        stimselectval = get(findobj(prevtab,'Tag','stimselect'),'Value');
        delaystr = get(findobj(prevtab,'Tag','delay'),'String');
        durstr = get(findobj(prevtab,'Tag','duration'),'String');
        intstr = get(findobj(prevtab,'Tag','interval'),'String');
        trialstr = get(findobj(prevtab,'Tag','trials'),'String');
        hidestimval = get(findobj(prevtab,'Tag','hidestim'),'Value');
        prestr = get(findobj(prevtab,'Tag','prestim'),'String');
        poststr = get(findobj(prevtab,'Tag','poststim'),'String');
        supval = get(findobj(prevtab,'Tag','superimpose'),'Value');
        avgtrialval = get(findobj(prevtab,'Tag','avgtrials'),'Value');
        avgfileval = get(findobj(prevtab,'Tag','avgfiles'),'Value');
        avgroival = get(findobj(prevtab,'Tag','avgrois'),'Value');
        avgodorval = get(findobj(prevtab,'Tag','avgodors'),'Value');
        bgroival = get(findobj(prevtab,'Tag','subtractbgroi'),'Value');
        bgroistr = get(findobj(prevtab,'Tag','bgroi'),'String');
        hpfval = get(findobj(prevtab,'Tag','hpfilter'),'Value');
        hpfstr = get(findobj(prevtab,'Tag','hpfilterparm'),'String');
        lpfval = get(findobj(prevtab,'Tag','lpfilter'),'Value');
        lpfstr = get(findobj(prevtab,'Tag','lpfilterparm'),'String');
        confval = get(findobj(prevtab,'Tag','confint'),'Value');
        dfval = get(findobj(prevtab,'Tag','deltaf'),'Value');
        dffval = get(findobj(prevtab,'Tag','deltafoverf'),'Value');
        fstartstr = get(findobj(prevtab,'Tag','fstart'),'String');
        fstopstr = get(findobj(prevtab,'Tag','fstop'),'String');
        showchangeval = get(findobj(prevtab,'Tag','showchange'),'Value');
        basestartstr = get(findobj(prevtab,'Tag','basestart'),'String');
        basedurstr = get(findobj(prevtab,'Tag','basedur'),'String');
        respstartstr = get(findobj(prevtab,'Tag','respstart'),'String');
        respdurstr = get(findobj(prevtab,'Tag','respdur'),'String');
        ylimval = get(findobj(prevtab,'Tag','Ylims'),'Value');
        yminstr = get(findobj(prevtab,'Tag','Ymin'),'String');
        ymaxstr = get(findobj(prevtab,'Tag','Ymax'),'String');
        tlimval = get(findobj(prevtab,'Tag','Tlims'),'Value');
        tminstr = get(findobj(prevtab,'Tag','Tmin'),'String');
        tmaxstr = get(findobj(prevtab,'Tag','Tmax'),'String');
    else
        fileval = 1; roival = 1; odortrialval = 1;
        byfileval = TSsettings.byfileval; byroival = TSsettings.byroival;
        byodorval = TSsettings.byodorval; bytrialval = TSsettings.bytrialval;
        stimselectval = TSsettings.stimselectval;
        delaystr = TSsettings.delaystr; durstr = TSsettings.durstr;
        intstr = TSsettings.intstr; trialstr = TSsettings.trialstr;
        hidestimval = TSsettings.hidestimval;
        prestr = TSsettings.prestr; poststr=TSsettings.poststr;
        supval = TSsettings.supval; avgtrialval = TSsettings.avgtrialval;
        avgfileval = TSsettings.avgfileval; avgroival = TSsettings.avgroival;
        avgodorval = TSsettings.avgodorval;
        bgroival = TSsettings.bgroival; bgroistr = TSsettings.bgroistr;
        hpfval = TSsettings.hpfval; hpfstr = TSsettings.hpfstr;
        lpfval = TSsettings.lpfval; lpfstr = TSsettings.lpfstr;
        confval=TSsettings.confval; dfval = TSsettings.dfval;
        dffval = TSsettings.dffval; fstartstr = TSsettings.fstartstr;
        fstopstr = TSsettings.fstopstr; showchangeval = TSsettings.showchangeval;
        basestartstr = TSsettings.basestartstr; basedurstr = TSsettings.basedurstr;
        respstartstr = TSsettings.respstartstr; respdurstr = TSsettings.respdurstr;
        ylimval = TSsettings.ylimval; yminstr = TSsettings.yminstr; ymaxstr = TSsettings.ymaxstr;
        tlimval = TSsettings.tlimval; tminstr = TSsettings.tminstr; tmaxstr = TSsettings.tminstr;
    end
    
    % Files/ROIs
    uicontrol(tab,'Style', 'text',  'Units', 'normalized', 'Position', [.02 .95 0.24 .04],...
        'BackgroundColor',BGC, 'String', 'Select File(s)','FontWeight','Bold');
    filenamestr=cell(length(TSdata.file));
    if ~isempty(TSdata.file)
        for f = 1:length(TSdata.file); filenamestr{f}=TSdata.file(f).name; end
    else; filenamestr{1} = '';
    end
    uicontrol(tab,'Style', 'listbox','Tag','FILE_listbox','Units', 'normalized', 'Position', ...
        [0.01 0.605 0.48 0.36], 'String', filenamestr, 'Value', fileval, 'BackgroundColor', [1 1 1], ...
        'Max', 100, 'Min', 0, 'Callback', @CBSelectAndSortColors);
%     if ~isempty(prevtab); set(get(findobj(tab,'Tag','FILE_listbox'),'Value', get(findobj(prevtab,'Tag','FILE_listbox'),'Value'))); end
    uicontrol(tab,'Style', 'text',  'Units', 'normalized', 'Position', [.485 .94 0.24 .05],...
        'BackgroundColor',BGC,'String', 'Select ROI(s)','FontWeight','Bold');
    uicontrol(tab,'Style', 'listbox','Tag','ROI_listbox','Units', 'normalized', 'Position', ...
        [0.51 0.605 0.24 0.36], 'String', '', 'Value', roival, 'BackgroundColor', [1 1 1], ...
        'Max', 100, 'Min', 0, 'Callback', @CBSelectAndSortColors);
    uicontrol(tab,'Style', 'text',  'Units', 'normalized', 'Position', [.75 .94 0.25 .05],...
        'BackgroundColor',BGC,'String', 'Odor(s),Trial(s)','FontWeight','Bold');
    uicontrol(tab,'Style', 'listbox','Tag','OdorTrial_listbox','Units', 'normalized', 'Position', ...
        [0.76 0.605 0.24 0.36], 'String', '', 'Value', odortrialval, 'BackgroundColor', [1 1 1], ...
        'Max', 10000, 'Min', 0, 'Callback', @CBSelectAndSortColors);
    if isfield(TSdata,'roi')
        roistr = cell(numel(TSdata.roi),1);
        for i = 1:numel(TSdata.roi)
            tmpcl = myColors(i).*255;
            roistr{i} = ['<HTML><FONT color=rgb(' num2str(tmpcl(1)) ',' num2str(tmpcl(2)) ',' ...
                num2str(tmpcl(3)) ')>' ['ROI # ' num2str(i)] '</Font></html>'];
        end
        set(findobj(tab,'Tag','ROI_listbox'), 'String', roistr);
    else
        set(findobj(tab,'Tag','ROI_listbox'), 'String','');
    end
    % Group plot line colors by ROI or by File (default set to group by ROI, value = 1)
    bg=uibuttongroup(tab,'Tag','sortColors','Position',[0.0 0.565 1 0.04],'SelectionChangedFcn',@CBSelectAndSortColors);
    uicontrol(bg,'Style', 'radiobutton', 'Units', 'normalized', 'Position', ...
        [0.01 0.01 0.4 0.98], 'String', 'Sort Colors by File', 'Fontweight', 'Bold', ...
        'Min', 0, 'Max', 1, 'Value', byfileval, 'Tag','byfile');
    uicontrol(bg,'Style', 'radiobutton', 'Units', 'normalized', 'Position', ...
        [0.4 0.01 0.2 0.98], 'String', 'by ROI', 'Fontweight', 'Bold', ...
        'Min', 0, 'Max', 1, 'Value', byroival, 'Tag','byroi');
    uicontrol(bg,'Style', 'radiobutton', 'Units', 'normalized', 'Position', ...
        [0.6 0.01 0.2 0.98], 'String', 'by Odor', 'Fontweight', 'Bold', ...
        'Min', 0, 'Max', 1, 'Value', byodorval, 'Tag','byodor');
    uicontrol(bg,'Style', 'radiobutton', 'Units', 'normalized', 'Position', ...
        [0.8 0.01 0.2 0.98], 'String', 'by Trial', 'Fontweight', 'Bold', ...
        'Min', 0, 'Max', 1, 'Value', bytrialval, 'Tag','bytrial');    %bg.SelectedObject = bg.Children(2); %default to sort by ROI
    set(bg.Children,'Enable','off');
    if numel(TSdata.file) == 1
        set(findobj(tab,'Tag','sortColors_button'),'Enable','off');
    end
    %Aux/Defined Stimulus
    stimpanel = uipanel(tab,'Units','Normalized','Position', [0.0 0.35 1.0 0.22]);
%     stimstr = {'-Select Auxiliary Signal-';'Aux1(odor)';'Aux2(sniff)';'AuxCombo';'Manually Defined Stimulus'};
    uicontrol(stimpanel,'Tag','stimselect','Style','popupmenu','Units','normalized','Position',...
        [0.05 0.85 0.55 0.12],'String',auxstr, 'Value',stimselectval, 'Callback', @CBSelectStimulus);
    uicontrol(stimpanel,'Tag','delay','Style', 'edit', 'String', delaystr,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.05 0.75 .08 0.1],'HorizontalAlignment','Right', ...
        'Callback', @CBdefineStimulus, 'Visible', 'off');
    uicontrol(stimpanel,'Tag','delaystr', 'Style', 'text', 'String', 'Initial Delay(sec)','Units','normalized' ...
        ,'Position',[0.15 0.74 .35 0.1],'HorizontalAlignment','Left', 'Visible', 'off');
    uicontrol(stimpanel,'Tag','duration','Style', 'edit', 'String', durstr,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.05 0.65 .08 0.1],'HorizontalAlignment','Right', ...
        'Callback', @CBdefineStimulus, 'Visible', 'off');
    uicontrol(stimpanel,'Tag','durationstr','Style', 'text', 'String', 'Duration(sec)','Units','normalized' ...
        ,'Position',[0.15 0.64 .35 0.1],'HorizontalAlignment','Left', 'Visible', 'off');
    uicontrol(stimpanel,'Tag','interval','Style', 'edit', 'String', intstr,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.05 0.55 .08 0.1],'HorizontalAlignment','Right', ...
        'Callback', @CBdefineStimulus, 'Visible', 'off');
    uicontrol(stimpanel,'Tag','intervalstr','Style', 'text', 'String', 'Interval(sec)','Units','normalized' ...
        ,'Position',[0.15 0.54 .35 0.1],'HorizontalAlignment','Left', 'Visible', 'off');
    uicontrol(stimpanel,'Tag','trials','Style', 'edit', 'String', trialstr,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.05 0.45 .08 0.1],'HorizontalAlignment','Right', ...
        'Callback', @CBdefineStimulus, 'Visible', 'off');
    uicontrol(stimpanel,'Tag','trialsstr','Style', 'text', 'String', '# Trials','Units','normalized' ...
        ,'Position',[0.15 0.44 .35 0.1],'HorizontalAlignment','Left', 'Visible', 'off');
    uicontrol(stimpanel,'Tag','hidestim','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.65 0.85 .35 0.12], 'String', 'Hide stimuli', 'Fontweight', 'Bold', 'Value', hidestimval, ...
        'Fontsize',10,'Callback', @CBSelectAndSortColors,'Enable','off')
    ephysstr = {'-ephys signals-','odor','sniff','puff'};
    uicontrol(stimpanel,'Tag','ephys','Style','listbox','Units','normalized','Position', ...
        [0.65 0.45 .35 .4],'String',ephysstr,'Max',8,'Visible','off');
    uicontrol(stimpanel,'style','text','Units','normalized','Position',[0.05 0.33 .9 0.1],...
        'String','-------------------------------------------------------------------------','HorizontalAlignment','center');
    % Show/Average Trials
    uicontrol(stimpanel,'Style', 'text', 'String', 'Pre-Stimulus','Units','normalized' ...
        ,'Position',[0.04 0.20 .18 0.1],'HorizontalAlignment','Left'); 
    uicontrol(stimpanel,'Tag','prestim','Style', 'edit', 'String', prestr,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.22 0.21 .11 0.1],'HorizontalAlignment','Right', ...
        'Callback', @CBSelectAndSortColors);
    uicontrol(stimpanel,'Style', 'text', 'String', '(sec)','Units','normalized' ...
        ,'Position',[0.34 0.20 .4 0.1],'HorizontalAlignment','Left');    
    uicontrol(stimpanel,'Style', 'text', 'String', 'Post-Stimulus','Units','normalized' ...
        ,'Position',[0.50 0.20 .2 0.1],'HorizontalAlignment','Left'); 
    uicontrol(stimpanel,'Tag','poststim','Style', 'edit', 'String', poststr,'Units','normalized' ...
        ,'BackgroundColor',[1 1 1],'Position',[0.71 0.21 .11 0.1],'HorizontalAlignment','Right', ...
        'Callback', @CBSelectAndSortColors);
    uicontrol(stimpanel,'Style', 'text', 'String', '(sec)','Units','normalized' ...
        ,'Position',[0.83 0.2 .4 0.1],'HorizontalAlignment','Left');
    uicontrol(stimpanel,'Tag','superimpose','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.05 0.05 .4 0.1], 'String', 'Superimpose Trials', 'Fontweight', 'Bold', 'Value', supval, ...
        'FontSize',10,'Callback', @CBSupOrAvgTrials,'Enable','off');
    uicontrol(stimpanel,'Tag','avgtrials','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.5 0.05 .5 0.1], 'String', 'Average Trials (by Odor)', 'Fontweight', 'Bold', 'Value', avgtrialval, ...
        'FontSize',10,'Callback', @CBSupOrAvgTrials,'Enable','off');
    % Average Files/ROIs/Odors
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.02 0.32 0.3 0.03], ...
        'String', 'Average Files', 'Fontweight', 'Bold', 'BackgroundColor', BGC, 'Value', avgfileval, ...
        'Enable','off','Tag','avgfiles','Callback',@CBSelectAndSortColors);
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.35 0.32 0.3 0.03], ...
        'String', 'Average ROIs', 'Fontweight', 'Bold', 'BackgroundColor', BGC, 'Value', avgroival, ...
        'Enable','off','Tag','avgrois','Callback',@CBSelectAndSortColors,...
        'TooltipString',sprintf(['"Average ROIs" is done using a weighted average of time series data\n'...
        'with weights based on the number of pixels in each ROI mask\n']));
    %average rois ***note: to average/combine roimasks, do weighted average based on mask sizes
    uicontrol(tab,'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.67 0.32 0.33 0.03], ...
        'String', 'Average Odors', 'Fontweight', 'Bold', 'BackgroundColor', BGC, 'Value', avgodorval, ...
        'Enable','off','Tag','avgodors','Callback',@CBSelectAndSortColors);
    %subtract background roi
    uicontrol(tab,'Tag','subtractbgroi','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.02 0.285 0.42 0.03], 'String', 'Subtract Background ROI #:', 'Value', bgroival, ...
        'BackgroundColor',BGC,'Callback', @CBSelectAndSortColors);
    uicontrol(tab,'Tag','bgroi','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.43 0.29 0.08 0.025], 'String', bgroistr, 'Fontweight', 'Bold', 'Callback', ...
        @CBSelectAndSortColors);
    % Filter Buttons
    uicontrol(tab,'Tag','hpfilter','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.02 0.255 0.25 0.03], 'String', 'High Pass Filter', 'Value', hpfval, ...
        'BackgroundColor',BGC,'Callback', @CBSelectAndSortColors);
    uicontrol(tab,'Tag','hpfilterparm','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.27 0.26 0.10 0.025], 'String', hpfstr, 'Fontweight', 'Bold', 'Callback', ...
        @CBSelectAndSortColors);
    uicontrol(tab,'Style', 'text', 'String', 'Hz' , 'Units', 'Normalized' ...
        ,'BackgroundColor',BGC,'Position',   [0.38 0.25 0.05 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Tag','lpfilter','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.02 0.23 0.25 0.03], 'String', 'Low Pass Filter', 'Value', lpfval, ...
        'BackgroundColor',BGC,'Callback', @CBSelectAndSortColors);
    uicontrol(tab,'Tag','lpfilterparm','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.27 0.235 0.10 0.025], 'String', lpfstr, 'Fontweight', 'Bold', 'Callback', ...
        @CBSelectAndSortColors);
    uicontrol(tab,'Style', 'text', 'String', 'Hz' , 'Units', 'Normalized' ...
        ,'BackgroundColor',BGC,'Position',   [0.38 0.225 0.25 0.03],'HorizontalAlignment','Left');
    uicontrol(tab,'Tag','confint','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.02 0.205 0.54 0.03], 'String', 'Show 95% Confidence Intervals', 'Value', confval, ...
        'BackgroundColor',BGC,'Callback', @CBSelectAndSortColors);
    % %     % Deconvolve
% %     uicontrol(tab,'Tag','deconv','Style', 'checkbox', 'Value', 0,'Units','normalized', ...
% %         'Position',[0.02 0.175 0.24 0.03],'HorizontalAlignment','Left', 'BackgroundColor',BGC,...
% %         'String', 'Deconvolution:', 'Callback', @CBSelectAndSortColors);
% %     uicontrol(tab,'Style', 'text', 'String', 'Rise (sec)' , 'Units', 'Normalized' ...
% %         ,'Position',[0.26 0.177 0.16 0.02],'BackgroundColor',BGC,'HorizontalAlignment','Right');
% %     uicontrol(tab,'Tag','tauRise','Style', 'edit', 'Units', 'normalized', 'Position', ...
% %         [0.43 0.175 0.1 0.025], 'String', '0.2', 'Fontweight', 'Bold', 'Callback', @CBSelectAndSortColors);
% %     uicontrol(tab,'Style', 'text', 'String', 'Decay(sec)' , 'Units', 'Normalized' ...
% %         ,'Position',[0.25 0.152 0.17 0.02],'BackgroundColor',BGC,'HorizontalAlignment','Right');
% %     uicontrol(tab,'Tag','tauDecay','Style', 'edit', 'Units', 'normalized', 'Position', ...
% %         [0.43 0.15 0.1 0.025], 'String', '0.5', 'Fontweight', 'Bold','Callback', @CBSelectAndSortColors);

    % Delta F
    deltafgroup = uibuttongroup(tab,'Tag','deltafgroup','Position',[0.53 0.21 0.47 0.11]);
    uicontrol(deltafgroup,'Tag','deltaf','Style', 'checkbox', 'Value', dfval,'Units','normalized' ...
        ,'Position',[0.1 .75 1 .25],'HorizontalAlignment','Left', ...
        'String', '<html><b>Delta F</b> (F-F<sub>0</sub>)</html>', 'FontSize', 10, 'Callback', @CBdeltaF);
    uicontrol(deltafgroup,'Tag','deltafoverf','Style', 'checkbox', 'Value', dffval,'Units','normalized' ...
        ,'Position',[0.1 .5 1 .25],'HorizontalAlignment','Left', ...
        'String', '<html><b>Percent Delta F/F<sub>0</sub></b></html>','FontSize', 10, 'Callback', @CBdeltaF);
    uicontrol(deltafgroup,'Style','text','Units','normalized','Position',...
        [0 .3 1 .2],'String','F0 time window (sec):','FontSize', 9);
    uicontrol(deltafgroup,'Tag','fstart','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.1 0.05 .3 .25], 'String', fstartstr, 'Fontweight', 'Bold', 'Callback', ...
        @CBSelectAndSortColors);
    uicontrol(deltafgroup,'Style', 'text', 'String', 'to' , 'Units', 'Normalized' ...
        ,'Position',[0.45 0.051 .1 .2],'FontSize', 9);
    uicontrol(deltafgroup,'Tag','fstop','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.58 0.05 .3 .25], 'String', fstopstr, 'Fontweight', 'Bold', 'Callback', ...
        @CBSelectAndSortColors);
    % Show Mean Change vs Baseline
    uicontrol(tab, 'Tag', 'showchange','Style', 'checkbox', 'Units', 'normalized', 'Position', ...
        [0.02 0.18 0.9 0.03], 'String', 'Show Mean Change vs Baseline - edit start/duration (sec) -or- use slider',...
        'Value', showchangeval, 'BackgroundColor',BGC, 'Callback', @CBSelectAndSortColors);
    uicontrol(tab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01 0.147 0.15 0.025],...
        'BackgroundColor',BGC,'String','Baseline:','HorizontalAlignment','right');
    uicontrol(tab, 'Tag', 'basestart', 'Style', 'edit', 'Units', 'normalized', 'Position',...
        [0.16 0.15 0.09 0.025],'String',basestartstr, 'Callback', @CBEditBaseline);
    uicontrol(tab, 'Tag', 'baseslider', 'Style', 'Slider', 'Units', 'normalized', 'Position', ...
        [0.25 0.15 0.5 0.025],'Max',1000, 'Callback', @CBAdjustSlider);
    uicontrol(tab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.76 0.147 0.14 0.025],...
        'BackgroundColor',BGC,'String','Duration:');
    uicontrol(tab, 'Tag', 'basedur', 'Style', 'edit', 'Units', 'normalized', 'Position',...
        [0.89 0.15 0.09 0.025],'String',basedurstr,'Callback', @CBSelectAndSortColors);
    uicontrol(tab, 'Style', 'text', 'HorizontalAlignment', 'right', 'Units', 'normalized', 'Position', [0.01 0.112 0.15 0.025],...
        'BackgroundColor',BGC,'String','Response:');
    uicontrol(tab, 'Tag', 'respstart', 'Style', 'edit', 'Units', 'normalized', 'Position',...
        [0.16 0.115 0.09 0.025],'String',respstartstr,'Callback', @CBEditBaseline);
    uicontrol(tab, 'Tag', 'changeslider', 'Style', 'Slider', 'Units', 'normalized', 'Position', ...
        [0.25 0.115 0.5 0.025],'Max',1000, 'Callback', @CBAdjustSlider);
    uicontrol(tab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.76 0.112 0.14 0.025],...
        'BackgroundColor',BGC,'String','Duration:');
    uicontrol(tab, 'Tag', 'respdur', 'Style', 'edit', 'Units', 'normalized', 'Position',...
        [0.89 0.115 0.09 0.025],'String',respdurstr,'Callback', @CBSelectAndSortColors);
    % Y-axis (Fluorescence) range controls (INITIAL VALUE of 'String' = '')
    uicontrol(tab,'Tag','Ylims','Style', 'checkbox', 'String', 'Y-Axis Limits:' , 'Units', 'Normalized', ...
        'BackgroundColor',BGC,'ForegroundColor',[0 0 1],'Position',[0.05 0.07 0.35 0.04],'Value',ylimval, ...
        'HorizontalAlignment','Left','FontSize', 10,'FontWeight','Bold','Callback',@CBplotLimits);
    uicontrol(tab,'Style', 'text', 'String', 'Min:' , 'Units', 'Normalized', ...
        'BackgroundColor',BGC,'Position',[0.04 0.04 0.13 0.03],'HorizontalAlignment','Left',...
        'FontSize', 8);
    uicontrol(tab,'Tag','Ymin','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.12 0.05 0.12 0.025], 'String', yminstr, 'Fontweight', 'Bold', 'Enable','off',...
        'Callback', @CBSelectAndSortColors);
    uicontrol(tab,'Style', 'text', 'String', 'Max:' , 'Units', 'Normalized' ...
        ,'BackgroundColor',BGC,'Position',[0.26 0.04 0.13 0.03],'HorizontalAlignment','Left'...
        ,'FontSize', 8);
    uicontrol(tab,'Tag','Ymax','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.35 0.05 0.12 0.025], 'String', ymaxstr, 'Fontweight', 'Bold', 'Enable','off',...
        'Callback', @CBSelectAndSortColors);
    %X-axis (Time) range controls
    uicontrol(tab,'Tag','Tlims','Style', 'checkbox', 'String', 'X-Axis Limits:' , 'Units', 'Normalized' ...
        ,'BackgroundColor',BGC,'ForegroundColor',[0 0 1],'Position',[0.55 0.07 0.35 0.04],'Value',tlimval, ...
        'HorizontalAlignment','Left','FontSize', 10,'FontWeight','Bold','Callback',@CBplotLimits);
    uicontrol(tab,'Style', 'text', 'String', 'Min:' , 'Units', 'Normalized' ...
        ,'BackgroundColor',BGC,'Position',[0.54 0.04 0.13 0.03],'HorizontalAlignment','Left'...
        ,'FontSize', 8);
    uicontrol(tab,'Tag','Tmin','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.62 0.05 0.12 0.025], 'String', tminstr, 'Fontweight', 'Bold', 'Enable','off',...
        'Callback', @CBSelectAndSortColors);
    uicontrol(tab,'Style', 'text', 'String', 'Max:' , 'Units', 'Normalized' ...
        ,'BackgroundColor',BGC,'Position',[0.76 0.04 0.13 0.03],'HorizontalAlignment','Left'...
        ,'FontSize', 8);
    uicontrol(tab,'Tag','Tmax','Style', 'edit', 'Units', 'normalized', 'Position', ...
        [0.85 0.05 0.12 0.025], 'String', tmaxstr, 'Fontweight', 'Bold', 'Enable','off',...
        'Callback', @CBSelectAndSortColors);
    
    % Save Plot/Data
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position',[.05 .005 0.27 .04],...
        'String', 'Save Plot Figure', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
        'Callback', @CBsaveFigure, 'TooltipString', 'Save plot as matlab .fig file, to open: openfig(''myfile.fig'')');
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
        [.365 .005 0.27 .04], 'String', 'Save Plot Data', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
        'Callback', @CBsaveFigData, 'TooltipString', ['Save data from lines shown on plot '...
        'as .mat or .txt file (not including stimulus)']);
    uicontrol(tab,'Style', 'pushbutton', 'Units', 'normalized', 'Position', ...
        [.68 .005 0.27 .04], 'String', 'Behavior Analysis', 'Fontweight', 'Bold', 'Min', 0, 'Max', 1, ...
        'Callback', @CBBehave, 'TooltipString', ['Create trialsdata struct from TSdata and run '...
        'BehaviorAnalysis_MWLab']);
    
    %figure for plot
    figshift = 0.02*(str2double(tab.Tag)-1);
    pos=hTS.Position;
    figure('NumberTitle','off','Name',sprintf('Plot #%s',tab.Tag),'Tag',guiname,...
        'Units','normalized','Position',[(pos(1)+pos(3))+figshift+0.001 ...
        pos(2)+0.5*pos(4)-figshift 0.50 0.5*pos(4)],'CloseRequestFcn',@CBclosePlot);
    axes('Tag','tsax');
end

% % % % 
% % % % % Plot ROIs on same time-axis or "align" end-to-end (this is turned off, does not work!!!)
% % % % % hTS.stackButton = uicontrol('Style', 'togglebutton', 'Units', 'normalized', 'Position', ...
% % % % %     [.01 .01 0.08 .05], 'String', 'Stacked', 'Fontweight', 'Bold', ...
% % % % %     'Min', 0, 'Max', 1, 'Value', 0, 'Callback', @CBstackButton_fcn,'Enable','off','Visible','off');
% % % % % function CBstackButton_fcn(~, ~)
% % % % %     groupstr = {'Stacked'; 'Aligned'};
% % % % %     val = get(hTS.stackButton, 'Value');
% % % % %     set(hTS.stackButton, 'String', groupstr{1+val});
% % % % %     do_time_series_plot;
% % % % % end
% % % % 

if isfield(TSdata,'file') && ~isempty(TSdata.file) && isfield(TSdata,'roi') && ~isempty(TSdata.roi)
    if isfield(TSdata.file(1).roi(1),'series') && ~isempty(TSdata.file(1).roi(1).series)
        bloadnow = 0;
        CBSelectStimulus;
    else
        CBaddFiles;
    end
end

%%
%Nested Callback Functions
function CB_CloseFig(~,~)
    updateSettings;
    save(fullfile(guipath,'TSsettings.mat'),'TSsettings');
    delete(findobj('Tag',guiname));
    delete(hTS);
end

function CBSaveSettings(~, ~)
    updateSettings;
    [setfile,setpath] = uiputfile(fullfile(guipath,'myTSsettings.mat'));
    save(fullfile(setpath,setfile),'TSsettings');
end

function updateSettings
    %save settings from current tab
    tab = htabgroup.SelectedTab;
    TSsettings.byfileval = get(findobj(tab,'Tag','byfile'),'Value');
    TSsettings.byroival = get(findobj(tab,'Tag','byroi'),'Value');
    TSsettings.byodorval = get(findobj(tab,'Tag','byodor'),'Value');
    TSsettings.bytrialval = get(findobj(tab,'Tag','bytrial'),'Value');
    TSsettings.stimselectval = get(findobj(tab,'Tag','stimselect'),'Value');
    TSsettings.delaystr = get(findobj(tab,'Tag','delay'),'String');
    TSsettings.durstr = get(findobj(tab,'Tag','duration'),'String');
    TSsettings.intstr = get(findobj(tab,'Tag','interval'),'String');
    TSsettings.trialstr = get(findobj(tab,'Tag','trials'),'String');
    TSsettings.hidestimval = get(findobj(tab,'Tag','hidestim'),'Value');
    TSsettings.prestr = get(findobj(tab,'Tag','prestim'),'String');
    TSsettings.poststr = get(findobj(tab,'Tag','poststim'),'String');
    TSsettings.supval = get(findobj(tab,'Tag','superimpose'),'Value');
    TSsettings.avgtrialval = get(findobj(tab,'Tag','avgtrials'),'Value');
    TSsettings.avgfileval = get(findobj(tab,'Tag','avgfiles'),'Value');
    TSsettings.avgroival = get(findobj(tab,'Tag','avgrois'),'Value');
    TSsettings.avgodorval = get(findobj(tab,'Tag','avgodors'),'Value');
    TSsettings.bgroival = get(findobj(tab,'Tag','subtractbgroi'),'Value');
    TSsettings.bgroistr = get(findobj(tab,'Tag','bgroi'),'String');
    TSsettings.hpfval = get(findobj(tab,'Tag','hpfilter'),'Value');
    TSsettings.hpfstr = get(findobj(tab,'Tag','hpfilterparm'),'String');
    TSsettings.lpfval = get(findobj(tab,'Tag','lpfilter'),'Value');
    TSsettings.lpfstr = get(findobj(tab,'Tag','lpfilterparm'),'String');
    TSsettings.confval = get(findobj(tab,'Tag','confint'),'Value');
    TSsettings.dfval = get(findobj(tab,'Tag','deltaf'),'Value');
    TSsettings.dffval = get(findobj(tab,'Tag','deltafoverf'),'Value');
    TSsettings.fstartstr = get(findobj(tab,'Tag','fstart'),'String');
    TSsettings.fstopstr = get(findobj(tab,'Tag','fstop'),'String');
    TSsettings.showchangeval = get(findobj(tab,'Tag','showchange'),'Value');
    TSsettings.basestartstr = get(findobj(tab,'Tag','basestart'),'String');
    TSsettings.basedurstr = get(findobj(tab,'Tag','basedur'),'String');
    TSsettings.respstartstr = get(findobj(tab,'Tag','respstart'),'String');
    TSsettings.respdurstr = get(findobj(tab,'Tag','respdur'),'String');
    TSsettings.ylimval = get(findobj(tab,'Tag','Ylims'),'Value');
    TSsettings.yminstr = get(findobj(tab,'Tag','Ymin'),'String');
    TSsettings.ymaxstr = get(findobj(tab,'Tag','Ymax'),'String');
    TSsettings.tlimval = get(findobj(tab,'Tag','Tlims'),'Value');
    TSsettings.tminstr = get(findobj(tab,'Tag','Tmin'),'String');
    TSsettings.tmaxstr = get(findobj(tab,'Tag','Tmax'),'String');
end

function CBLoadSettings(~, ~)
    [setfile,setpath] = uigetfile(fullfile(guipath,'*.mat'));
    try
        load(fullfile(setpath,setfile),'-mat','TSsettings');
        tab = htabgroup.SelectedTab; %only apply settings to current tab
        set(findobj(tab,'Tag','byfile'),'Value',TSsettings.byfileval);
        set(findobj(tab,'Tag','byroi'),'Value',TSsettings.byroival);
        set(findobj(tab,'Tag','byodor'),'Value',TSsettings.byodorval);
        set(findobj(tab,'Tag','bytrial'),'Value',TSsettings.bytrialval);
        set(findobj(tab,'Tag','stimselect'),'Value',TSsettings.stimselectval);
        set(findobj(tab,'Tag','delay'),'String',TSsettings.delaystr);
        set(findobj(tab,'Tag','duration'),'String',TSsettings.durstr);
        set(findobj(tab,'Tag','interval'),'String',TSsettings.intstr);
        set(findobj(tab,'Tag','trials'),'String',TSsettings.trialstr);
        set(findobj(tab,'Tag','hidestim'),'Value',TSsettings.hidestimval);
        set(findobj(tab,'Tag','prestim'),'String',TSsettings.prestr);
        set(findobj(tab,'Tag','poststim'),'String',TSsettings.poststr);
        set(findobj(tab,'Tag','superimpose'),'Value',TSsettings.supval);
        set(findobj(tab,'Tag','avgtrials'),'Value',TSsettings.avgtrialval);
        set(findobj(tab,'Tag','avgfiles'),'Value',TSsettings.avgfileval);
        set(findobj(tab,'Tag','avgrois'),'Value',TSsettings.avgroival);
        set(findobj(tab,'Tag','avgodors'),'Value',TSsettings.avgodorval);
        set(findobj(tab,'Tag','subtractbgroi'),'Value',TSsettings.bgroival);
        set(findobj(tab,'Tag','bgroi'),'String',TSsettings.bgroistr);
        set(findobj(tab,'Tag','hpfilter'),'Value',TSsettings.hpfval);
        set(findobj(tab,'Tag','hpfilterparm'),'String',TSsettings.hpfstr);
        set(findobj(tab,'Tag','lpfilter'),'Value',TSsettings.lpfval);
        set(findobj(tab,'Tag','lpfilterparm'),'String',TSsettings.lpfstr);
        set(findobj(tab,'Tag','confint'),'Value',TSsettings.confval);
        set(findobj(tab,'Tag','deltaf'),'Value',TSsettings.dfval);
        set(findobj(tab,'Tag','deltafoverf'),'Value',TSsettings.dffval);
        set(findobj(tab,'Tag','fstart'),'String',TSsettings.fstartstr);
        set(findobj(tab,'Tag','fstop'),'String',TSsettings.fstopstr);
        set(findobj(tab,'Tag','showchange'),'Value',TSsettings.showchangeval);
        set(findobj(tab,'Tag','basestart'),'String',TSsettings.basestartstr);
        set(findobj(tab,'Tag','basedur'),'String',TSsettings.basedurstr);
        set(findobj(tab,'Tag','respstart'),'String',TSsettings.respstartstr);
        set(findobj(tab,'Tag','respdur'),'String',TSsettings.respdurstr);
        set(findobj(tab,'Tag','Ylims'),'Value',TSsettings.ylimval);
        set(findobj(tab,'Tag','Ymin'),'String',TSsettings.yminstr);
        set(findobj(tab,'Tag','Ymax'),'String',TSsettings.ymaxstr);
        set(findobj(tab,'Tag','Tlims'),'Value',TSsettings.tlimval);
        set(findobj(tab,'Tag','Tmin'),'String',TSsettings.tminstr);
        set(findobj(tab,'Tag','Tmax'),'String',TSsettings.tmaxstr);
        CBSelectStimulus;
    catch
    end
end

function CBclosePlot(plotfig,~)
    idx = strfind(plotfig.Name,'#');
    plotnum = str2double(plotfig.Name(idx+1:end));
    if numel(htabgroup.Children) > 2 %not the last plot
        delete(plotfig);    
        delete(htabgroup.Children(plotnum));
        for i = 1:numel(htabgroup.Children)
            if ~strcmp(htabgroup.Children(i).Tag,num2str(i)) && ~strcmp(htabgroup.Children(i).Title,'Add Plot')
                tmpfig = findobj('type','figure','Name',sprintf('Plot #%s',htabgroup.Children(i).Tag));
                htabgroup.Children(i).Tag = num2str(i);
                htabgroup.Children(i).Title = sprintf('Plot #%d',i);
                tmpfig.Name = sprintf('Plot #%s',num2str(i));           
            end 
        end
    else %last plot
        CB_CloseFig; return;
    end
end

function CBaddFiles(~,~) %add image file(s) to list (and/or load scanbox realtime data)
    if bloadnow %path & filenames provided on function call
        bloadnow = 0; cnt=0;
        [imsize(1),imsize(2)] = getImageSize(TSdata.file(1).type,fullfile(TSdata.file(1).dir,TSdata.file(1).name));
        TSdata.file(1).size = imsize;
        if length(TSdata.file) > 1
            for mm = 2:length(TSdata.file) %check image XY size matches
                [tmpsize(1),tmpsize(2)] = getImageSize(TSdata.file(1).type,fullfile(TSdata.file(mm).dir,TSdata.file(mm).name));
                if ~isequal(imsize,tmpsize)
                    errordlg('File sizes do not match');
                    TSdata.file = []; TSdata.roi = [];
                    CBSelectStimulus;
                    return;
                end
                TSdata.file(mm).size = imsize;
            end
        end
    else %add files button press
        % get data type if unknown
        if isempty(TSdata.file) || ~isfield(TSdata.file(1),'type') || isempty(TSdata.file(1).type)
            [typeval,ok]= listdlg('SelectionMode','single','PromptString','Select Data Type','SelectionMode','single','ListString',...
                typestr);
            if ok == 0
                return;
            end
            TSdata.file(1).type = typestr{typeval};
        end
        %get pathname & filenames
        if isfield(TSdata.file(1),'dir') && ~isempty(TSdata.file(1).dir); pathname = TSdata.file(1).dir; elseif exist('oldpath','var'); pathname = oldpath; else pathname = ''; end
        switch TSdata.file(1).type
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
                TSdata.aux2bncmap = assignNeuroplexBNC;
            case 'tif' %Standard .tif
                ext = '.tif';
                [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'On');
        end
        if ~ok; return; end
        % add to any existing files, and check image file sizes match
        if isfield(TSdata.file,'name') && ~isempty(TSdata.file(end).name)
            cnt = length(TSdata.file);
            imsize = TSdata.file(1).size;
        else
            cnt = 0;
            if ischar(filename)
                [imsize(1),imsize(2)] = getImageSize(TSdata.file(1).type,fullfile(pathname,filename));
            else
                [imsize(1),imsize(2)] = getImageSize(TSdata.file(1).type,fullfile(pathname,filename{1}));
            end
        end
        if ischar(filename) %only adding 1 file
            if cnt>0
                [tmpsize(1),tmpsize(2)] = getImageSize(TSdata.file(1).type,fullfile(pathname,filename));
                if ~isequal(imsize,tmpsize)
                    errordlg('File sizes do not match');
                    return;
                end
            end
            numChannels = getNumChannels(TSdata.file(1).type,fullfile(pathname,filename));
            if numChannels == 1
                TSdata.file(cnt+1).name = filename;
                TSdata.file(cnt+1).dir = pathname;
                TSdata.file(cnt+1).type = TSdata.file(1).type; %tcrtcr currently limit all files to same type
                TSdata.file(cnt+1).size = imsize;
                TSdata.file(cnt+1).numChannels = 1;
            else %two channels
                TSdata.file(cnt+1).name = filename; TSdata.file(cnt+2).name = filename;
                TSdata.file(cnt+1).dir = pathname; TSdata.file(cnt+2).dir = pathname;
                TSdata.file(cnt+1).type = TSdata.file(1).type; %tcrtcr currently limit all files to same type
                TSdata.file(cnt+2).type = TSdata.file(1).type;
                TSdata.file(cnt+1).size = imsize; TSdata.file(cnt+2).size = imsize;
                TSdata.file(cnt+1).numChannels = 2; TSdata.file(cnt+2).numChannels = 2;
            end
        else %add more than 1 file
            %check all file sizes
            if cnt>0; m1=1; else; m1=2; end
            for mm = m1:length(filename) %check image size matches
                [tmpsize(1),tmpsize(2)] = getImageSize(TSdata.file(1).type,fullfile(pathname,filename{mm}));
                if ~isequal(imsize,tmpsize)
                    errordlg('File sizes do not match');
                    return;
                end
            end
            new = 0;
            for mm = 1:length(filename) %add the images
                numChannels = getNumChannels(TSdata.file(1).type,fullfile(pathname,filename{1}));
                if numChannels == 1
                    new = new+1;
                    TSdata.file(cnt+new).name = filename{mm};
                    TSdata.file(cnt+new).dir = pathname;
                    TSdata.file(cnt+new).type = TSdata.file(1).type; %tcrtcr currently limit all files to same type
                    TSdata.file(cnt+new).size = imsize;
                    TSdata.file(cnt+new).numChannels = 1;
                else
                    new = new+2;
                    TSdata.file(cnt+new-1).name = filename{mm}; TSdata.file(cnt+new).name = filename{mm};
                    TSdata.file(cnt+new-1).dir = pathname; TSdata.file(cnt+new).dir = pathname;
                    TSdata.file(cnt+new-1).type = TSdata.file(1).type; %tcrtcr currently limit all files to same type
                    TSdata.file(cnt+new).type = TSdata.file(1).type;
                    TSdata.file(cnt+new-1).size = imsize; TSdata.file(cnt+new).size = imsize;
                    TSdata.file(cnt+new-1).numChannels = 2; TSdata.file(cnt+new).numChannels = 2;
                end
            end
        end
    end
    if ~isempty(TSdata.file(end).dir); oldpath = TSdata.file(end).dir; end
    %in case ROIs were loaded, check roi size matches image size
    if isfield(TSdata,'roi') && ~isempty(TSdata.roi)
        if ~isequal(imsize,size(TSdata.roi(1).mask))
            TSdata.roi = []; % Existing ROIs size does not match loaded images; delete ROIs.
        end
    end
    %If ROIs are present, compute timeseries data (requires loading file), or use scanbox realtime.mat file
    if isfield(TSdata,'file') && ~isempty(TSdata.file(1).name) && isfield(TSdata,'roi') && ~isempty(TSdata.roi)
        if ~strcmp(TSdata.file(1).type,'scanbox')
            for n = cnt+1:length(TSdata.file)
                skipch2 = [];
                if n>1; skipch2 = strfind(TSdata.file(n).name,'_ch2'); end
                if isempty(skipch2)
                    loadFileComputeTimeSeries(n);
                end
            end
        else %scanbox data, check for realtime.mat file(s)
            for n = cnt+1:length(TSdata.file)
                if ~isempty(dir(fullfile(TSdata.file(n).dir,[TSdata.file(n).name(1:end - 4) '_realtime.mat'])))
                    %load realtime file: if all ROIs match use realtime, otherwise loadComputeTimeSeries
                    realtime = load(fullfile(TSdata.file(n).dir,[TSdata.file(n).name(1:end - 4) '_realtime.mat']));
                    sameRois = 0; %make sure all rois match
                    for j = 1:numel(TSdata.roi)
                        roipix = find(TSdata.roi(j).mask);
                        if numel(realtime.roipix) >= j
                            sameRois = sameRois + isequal(roipix,realtime.roipix{j}); %rois match
                        end
                    end
                    if sameRois == numel(TSdata.roi) %all rois match
                        for j = 1:numel(TSdata.roi)
                            TSdata.file(n).roi(j).series = double(intmax('uint16'))-realtime.rtdata(:,j);
                        end
                        % get the frameRate/frames (no file loaded) and Aux signals
                        [~,sbxinfo] = mysbxread(fullfile(TSdata.file(1).dir,TSdata.file(1).name(1:end-4)),0,0);
                        sbxinfo.frameRate = sbxinfo.resfreq/sbxinfo.recordsPerBuffer; TSdata.file(n).frameRate = sbxinfo.frameRate;
                        sbxinfo.frames = sbxinfo.max_idx+1; TSdata.file(n).frames = sbxinfo.frames;
                        if isfield(sbxinfo,'event_id') && ~isempty(sbxinfo.event_id)
                            [TSdata.file(n).aux1,TSdata.file(n).aux2,TSdata.file(n).aux3] = loadScanboxStimulus(sbxinfo);
                        end
                        %load ephys data - currently, scanbox is only type with ephys files
                        if isfile(fullfile(TSdata.file(1).dir,[TSdata.file(1).name(1:end-4) '.ephys']))
                            TSdata.file(n).ephys = loadScanboxEphys(fullfile(TSdata.file(1).dir,[TSdata.file(1).name(1:end-4) '.ephys']));
                            if isempty(TSdata.file(n).ephys); TSdata.file(n)=rmfield(TSdata.file(n),'ephys'); end
                        end
                    else %realtime rois do not match
                        skipch2 = [];
                        if n>1; skipch2 = strfind(TSdata.file(n).name,'_ch2'); end
                        if isempty(skipch2)
                            loadFileComputeTimeSeries(n);
                        end
                    end
                else %no realtime.mat file
                    skipch2 = [];
                    if n>1; skipch2 = strfind(TSdata.file(n).name,'_ch2'); end
                    if isempty(skipch2)
                    	loadFileComputeTimeSeries(n);
                    end
                end
            end
        end
    end
    hTS.UserData.TSdata = TSdata;
    CBSelectStimulus;
end

function CBclearFiles(~,~) %clear selected files and related timeseries
    if isempty(TSdata.file); return; end
    tab = htabgroup.SelectedTab;
    selectedfiles = get(findobj(tab,'Tag','FILE_listbox'),'Value');
    keep = setdiff(1:length(TSdata.file),selectedfiles);
    TSdata.file = TSdata.file(keep);
    if isempty(TSdata.file) %cleared all files, reinitialize variables for next time
        TSdata.file = [];
    end
    set(findobj(tab,'Tag','FILE_listbox'),'Value',1);
    hTS.UserData.TSdata = TSdata;
    CBSelectStimulus;
end

function CBaddROIs(~,~) %load/add ROIs and compute timeseries
    tab = htabgroup.SelectedTab;
    if isempty(TSdata.file)
        newrois = loadROIs;
    else
        newrois = loadROIs(TSdata.file(1).dir);
    end
    if ~isempty(newrois)
        if isfield(TSdata,'file') && ~isempty(TSdata.file) && ~isempty(TSdata.file(1).name)
            imsize = TSdata.file(1).size;
            if ~isequal(imsize,size(newrois(1).mask))
                errordlg('New ROIs size does not match image size'); uiwait;
                clear newrois; return;
            end
        elseif isfield(TSdata,'roi') && ~isempty(TSdata.roi)
            if ~isequal(size(TSdata.roi(1).mask),size(newrois(1).mask))
                errordlg('New ROIs size does not match old ROI size'); uiwait;
                clear newrois; return;
            end
        end
        % add to list of rois
        if isfield(TSdata,'roi') && ~isempty(TSdata.roi)
            cnt = length(TSdata.roi);
        else; cnt = 0;
        end
        for rr = 1:length(newrois)
            TSdata.roi(cnt+rr).mask = newrois(rr).mask;
        end
        set(findobj(tab,'Tag','ROI_listbox'),'Value',1);
        %roi labels/options - only if no files are loaded
        if ~isempty(newrois)
            roistr = cell(numel(TSdata.roi),1);
            for i = 1:numel(TSdata.roi)
                roistr{i} = ['ROI #' num2str(i)];  
            end
            set(findobj(tab,'Tag','ROI_listbox'), 'String', roistr);
        end
        %compute timeseries data or use scanbox realtime.mat file for new ROIs
        if isfield(TSdata,'file') && ~isempty(TSdata.file) && ~isempty(TSdata.file(1).name)...
                && isfield(TSdata,'roi') && ~isempty(TSdata.roi)
            for n = 1:length(TSdata.file)
                if ~isempty(dir(fullfile(TSdata.file(n).dir,[TSdata.file(n).name(1:end - 4) '_realtime.mat'])))
                    %load realtime file: if all ROIs match use realtime, otherwise loadComputeTimeSeries
                    realtime = load(fullfile(TSdata.file(n).dir,[TSdata.file(n).name(1:end - 4) '_realtime.mat']));
                    sameRois = 0; %make sure all rois match
                    for j = 1:numel(TSdata.roi)
                        roipix = find(TSdata.roi(j).mask);
                        if numel(realtime.roipix) >= j
                            sameRois = sameRois + isequal(roipix,realtime.roipix{j}); %rois match
                        end
                    end
                    if sameRois == numel(TSdata.roi) %all rois match
                        fprintf('using realtime data, file %d\n',n);
                        for j = 1:numel(TSdata.roi)
                            TSdata.roi(j).time_series{n} = double(intmax('uint16'))-realtime.rtdata(:,j);
                            %tcrtcrtcr might want to check at least one timeframe by computation
                        end
                        sbxtmp = load(fullfile(TSdata.file(1).dir,TSdata.file(1).name(1:end-4)));
                        sbxtmp.info.frameRate = sbxtmp.info.resfreq/sbxtmp.info.recordsPerBuffer;
                        %tcrtcrtcr repeat of potential error
                        sbxtmp.info.max_idx = TSdata.frames-1;
                        TSdata.file(n).frameRate = sbxtmp.info.frameRate;
                        %get aux signals
                        if isfield(sbxtmp.info,'event_id') && ~isempty(sbxtmp.info.event_id)
                            [TSdata.file(n).aux1,TSdata.file(n).aux2,TSdata.file(n).aux3] = loadScanboxStimulus(sbxtmp.info);
                        end
                        % load scanbox Ephys file
                        if isfile(fullfile(TSdata.file(1).dir,[TSdata.file(1).name(1:end-4) '.ephys']))
                            TSdata.file(n).ephys = loadScanboxEphys(fullfile(TSdata.file(1).dir,[TSdata.file(1).name(1:end-4) '.ephys']));
                            if isempty(TSdata.file(n).ephys); TSdata.file(n)=rmfield(TSdata.file(n),'ephys'); end
                        end
                    else %rois do not match ***currently recomputes all rois
                        fprintf('computing time series, file %d\n',n);
                        skipch2 = [];
                        if n>1; skipch2 = strfind(TSdata.file(n).name,'_ch2'); end
                        if isempty(skipch2)
                            %check for name changes due to alignment and two-channel data
                            al = strfind(TSdata.file(n).name,'_align'); dot = strfind(TSdata.file(n).name,'.');
                            if ~isempty(al); TSdata.file(n).name = [TSdata.file(n).name(1:al-1) TSdata.file(n).name(dot:end)]; end
                            ch = strfind(TSdata.file(n).name,'_ch1'); dot = strfind(TSdata.file(n).name,'.');
                            if ~isempty(ch); TSdata.file(n).name = [TSdata.file(n).name(1:ch-1) TSdata.file(n).name(dot:end)]; end
                            loadFileComputeTimeSeries(n);
                        end
                    end
                else %no realtime.mat file
                    %skip channel 2
                    skipch2 = [];
                    if n>1; skipch2 = strfind(TSdata.file(n).name,'_ch2'); end
                    if isempty(skipch2)
                        %check for name changes due to alignment and two-channel data
                        al = strfind(TSdata.file(n).name,'_align'); dot = strfind(TSdata.file(n).name,'.');
                        if ~isempty(al); TSdata.file(n).name = [TSdata.file(n).name(1:al-1) TSdata.file(n).name(dot:end)]; end
                        ch = strfind(TSdata.file(n).name,'_ch1'); dot = strfind(TSdata.file(n).name,'.');
                        if ~isempty(ch); TSdata.file(n).name = [TSdata.file(n).name(1:ch-1) TSdata.file(n).name(dot:end)]; end
                        loadFileComputeTimeSeries(n);
                    end
                end
            end
        end
        hTS.UserData.TSdata = TSdata;
        CBSelectStimulus; %CBSelectAndSortColors;
    end
    clear newrois;
end

function CBclearROIs(~,~) %clear selected ROIs and related data
    if ~isfield(TSdata,'roi') || isempty(TSdata.roi); return; end
    tab = htabgroup.SelectedTab;
    selectedrois = get(findobj(tab,'Tag','ROI_listbox'),'Value');
    keepers = setdiff(1:length(TSdata.roi),selectedrois);
    if isempty(keepers)
        TSdata.roi = [];
        if isfield(TSdata.file,'roi'); TSdata.file = rmfield(TSdata.file,'roi'); end
    else
        TSdata.roi = TSdata.roi(keepers);
        for f = 1:length(TSdata.file)
            if isfield(TSdata.file(f),'roi')
            	TSdata.file(f).roi = TSdata.file(f).roi(keepers);
            end
        end
    end
    set(findobj(tab,'Tag','ROI_listbox'),'Value',1);
    hTS.UserData.TSdata = TSdata;
    CBSelectStimulus; %CBSelectAndSortColors;
end

function loadFileComputeTimeSeries(n) %load image file and compute time series (one at a time)
    tmpname = TSdata.file(n).name;
    if strcmp(TSdata.file(n).type,'neuroplex')
        tmpdata = loadFile_MWLab(TSdata.file(n).type,TSdata.file(n).dir,tmpname,TSdata.aux2bncmap);
    else
        tmpdata = loadFile_MWLab(TSdata.file(n).type,TSdata.file(n).dir,tmpname);
    end
    %automatically align file if tmpname.align is present
    dot = strfind(tmpdata.name,'.');
    alignfile = fullfile(tmpdata.dir,[tmpdata.name(1:dot) 'align']);
    if exist(alignfile,'file')==2
        tmp = load(alignfile,'-mat');
        T = tmp.T; idx = tmp.idx;
        if iscell(tmpdata.im)
            for f = 1:length(idx)
                tmpdata.im{1}(:,:,idx(f)) = circshift(tmpdata.im{1}(:,:,idx(f)),T(f,:));
                tmpdata.im{2}(:,:,idx(f)) = circshift(tmpdata.im{2}(:,:,idx(f)),T(f,:));
            end
        else
            for f = 1:length(idx)
                tmpdata.im(:,:,idx(f)) = circshift(tmpdata.im(:,:,idx(f)),T(f,:));
            end
        end
        tmpname = [tmpname(1:dot-1) '_align' tmpname(dot:end)];
    end
    if iscell(tmpdata.im)
        dot = strfind(tmpdata.name,'.');
        TSdata.file(n).name = [tmpname(1:dot-1) '_ch1' tmpname(dot:end)];
        TSdata.file(n+1).name = [tmpname(1:dot-1) '_ch2' tmpname(dot:end)];
        TSdata.file(n).frameRate = tmpdata.frameRate; TSdata.file(n).frames = size(tmpdata.im{1},3);
        TSdata.file(n+1).frameRate = tmpdata.frameRate; TSdata.file(n+1).frames = size(tmpdata.im{2},3);
        tmptsdata.file = TSdata.file(n:n+1); tmptsdata.roi = TSdata.roi;
        tmptsdata.file(1).im = tmpdata.im{1}; tmptsdata.file(2).im = tmpdata.im{2};
        tmptsdata = computeTimeSeries(tmptsdata,tmptsdata.roi);
        tmptsdata.file = rmfield(tmptsdata.file,'im');
        TSdata.file(n).roi = []; TSdata.file(n+1).roi = [];
        TSdata.file(n) = tmptsdata.file(1);TSdata.file(n+1) = tmptsdata.file(2);
        %Save the stimulus signals here, use later when file(s) selected!
        TSdata.file(n).aux1 = []; TSdata.file(n).aux2 = [];
        TSdata.file(n+1).aux1 = []; TSdata.file(n+1).aux2 = [];
        if isfield(tmpdata,'aux1')
            TSdata.file(n).aux1 = tmpdata.aux1; TSdata.file(n+1).aux1 = tmpdata.aux1;
        end
        if isfield(tmpdata,'aux2')
            TSdata.file(n).aux2 = tmpdata.aux2; TSdata.file(n+1).aux2 = tmpdata.aux2;
        end
        if isfield(tmpdata,'aux3')
            TSdata.file(n).aux3 = tmpdata.aux3; TSdata.file(n+1).aux3 = tmpdata.aux3;
        end
        if isfield(tmpdata,'ephys')
            TSdata.file(n).ephys = tmpdata.ephys; TSdata.file(n+1).ephys = tmpdata.ephys;
        end
    else %single channel
        TSdata.file(n).name = tmpname;
        TSdata.file(n).frameRate = tmpdata.frameRate; TSdata.file(n).frames = size(tmpdata.im,3);
        tmptsdata.file = TSdata.file(n); 
        tmptsdata.file.im = tmpdata.im;
        tmptsdata = computeTimeSeries(tmptsdata,TSdata.roi);
        tmptsdata.file = rmfield(tmptsdata.file,'im');
        TSdata.file(n).roi = []; TSdata.file(n) = tmptsdata.file;
        %Save the stimulus signals here, use later when file(s) selected!
        TSdata.file(n).aux1 = []; TSdata.file(n).aux2 = [];
        if isfield(tmpdata,'aux1')
            TSdata.file(n).aux1 = tmpdata.aux1;
        end
        if isfield(tmpdata,'aux2')
            TSdata.file(n).aux2 = tmpdata.aux2;
        end
        if isfield(tmpdata,'aux3')
            TSdata.file(n).aux3 = tmpdata.aux3;
        end
        if isfield(tmpdata,'ephys')
            TSdata.file(n).ephys = tmpdata.ephys;
        end
    end
    clear tmpdata;
    hTS.UserData.TSdata = TSdata;
end

function CBSelectStimulus(~,~)
    tab = htabgroup.SelectedTab;
    if ~isfield(TSdata,'file') || isempty(TSdata.file)
        set(findobj(tab,'Tag','stimselect'),'Value',1);
    end
    bDefaultSelectAllOdorTrials = 1;
    doAux_combo;
    CBSelectAndSortColors;
end

function doAux_combo %create or remove aux_combo stimulus
    tab = htabgroup.SelectedTab;
    if get(findobj(tab,'Tag','stimselect'),'Value')==4
        odorDuration = [];
        for nn = 1:length(TSdata.file)
            if isfield(TSdata.file(nn),'aux1') && isfield(TSdata.file(nn),'aux2')
                if strcmp(TSdata.file(nn).type,'scanimage') %&& strcmp(TSdata.file(nn).name(end-2:end),'tif')
                    if isempty(odorDuration)
                        odorDuration = str2double(get(findobj(tab,'Tag','duration'),'String'));
                        onFrames = floor(odorDuration/(TSdata.file(nn).aux1.times(2)-TSdata.file(nn).aux1.times(1))); %duration/sampling period
                    end
                    TSdata.file(nn).aux_combo = doAuxCombo(TSdata.file(nn).aux1, TSdata.file(nn).aux2, odorDuration);
                else %scanbox
                    TSdata.file(nn).aux_combo = doAuxCombo(TSdata.file(nn).aux1, TSdata.file(nn).aux2);
                end
            else
                fprintf('Error in Aux_combo: aux1 and/or aux2 not found for file %s\n',TSdata.file(nn).name);
                set(findobj(tab,'Tag','stimselect'),'Value',1);
            end
        end
    else
        if isfield(TSdata.file,'aux_combo'); TSdata.file = rmfield(TSdata.file,'aux_combo'); end
    end
    hTS.UserData.TSdata = TSdata;
end

function CBdefineStimulus(~,~) %manually define a stimulus signal
    tab = htabgroup.SelectedTab;
    files = get(findobj(tab,'Tag','FILE_listbox'), 'Value');
    if isempty(TSdata.file(files(1)))
        set(findobj(tab,'Tag','definestim'),'Value',0);
    end
    Max = TSdata.file(files(1)).roi(1).time(end);
    if length(files) > 1
        for f = 2:length(files)
            if TSdata.file(files(f)).roi(1).time(end)>Max
                Max = TSdata.file(files(f)).roi(1).time(end);
            end
        end
    end
    delay = str2double(get(findobj(tab,'Tag','delay'),'String')); % #frames delay
    duration = str2double(get(findobj(tab,'Tag','duration'),'String')); % #frames duration
    interval = str2double(get(findobj(tab,'Tag','interval'),'String')); % #frames interval
    trials = str2double(get(findobj(tab,'Tag','trials'),'String'));
    trials = min(trials,round((Max-delay+interval)/(duration+interval)));
    set(findobj(tab,'Tag','trials'),'String',trials);
    CBSelectStimulus;
end

function CBSupOrAvgTrials(~,~) %superimpose or average trials
    tab = htabgroup.SelectedTab;
    clicked = hTS.CurrentObject;
    if clicked.Value %radiobutton - one is clicked, the other turns off
        if strcmp(clicked.Tag,'superimpose')
            set(findobj(tab,'Tag','avgtrials'),'Value',0);
        else
            set(findobj(tab,'Tag','superimpose'),'Value',0);
        end
    end
    CBSelectAndSortColors;
end

function CBdeltaF(~,~) %deltaF or deltaFoverF button click
    tab = htabgroup.SelectedTab;
    clicked = hTS.CurrentObject;
    if clicked.Value %radiobutton - one is clicked, the other turns off
        if strcmp(clicked.Tag,'deltaf')
            set(findobj(tab,'Tag','deltafoverf'),'Value',0);
        else
            set(findobj(tab,'Tag','deltaf'),'Value',0);
        end
    end
    CBSelectAndSortColors;
end
    
function CBSelectAndSortColors(~, ~) %select Files, ROIs, OdorTrials and colorscheme for plot
    tab = htabgroup.SelectedTab;
    files = get(findobj(tab,'Tag','FILE_listbox'), 'Value');
    if ~isfield(TSdata,'file') || isempty(TSdata.file) || ~isfield(TSdata,'roi') || isempty(TSdata.roi)
        set(findobj(tab,'Tag','stimselect'),'Value',1);
    else %Aux: if any aux are missing for selected files, deselect them
        for n = 1:length(files)
            set(findobj(tab,'Tag','ephys'),'Visible','on');
            if ~isfield(TSdata.file(n),'aux1') || isempty(TSdata.file(n).aux1)...
                    && (get(findobj(tab,'Tag','stimselect'),'Value')== 2 || get(findobj(tab,'Tag','stimselect'),'Value')== 4)
                fprintf('No Aux1(odor) signal for file %d\n',files(n)); set(findobj(tab,'Tag','stimselect'),'Value',1);
            end
            if ~isfield(TSdata.file(n),'aux2') || isempty(TSdata.file(n).aux2)...
                && (get(findobj(tab,'Tag','stimselect'),'Value')== 3 || get(findobj(tab,'Tag','stimselect'),'Value')== 4)   
                fprintf('No Aux2(sniff) signal for file %d\n',files(n)); set(findobj(tab,'Tag','stimselect'),'Value',2);
            end
            if ~isfield(TSdata.file(n),'ephys') || isempty(TSdata.file(n).ephys)
                set(findobj(tab,'Tag','ephys'),'Visible','off','Value',1);
            end
        end
    end
    %set visibility of auxiliary options 
    if max(get(findobj(tab,'Tag','stimselect'),'Value') == [1 2 3])
        set(findobj(tab,'Tag','delay'),'Visible','off');set(findobj(tab,'Tag','delaystr'),'Visible','off');
        set(findobj(tab,'Tag','duration'),'Visible','off');set(findobj(tab,'Tag','durationstr'),'Visible','off');
        set(findobj(tab,'Tag','interval'),'Visible','off');set(findobj(tab,'Tag','intervalstr'),'Visible','off');
        set(findobj(tab,'Tag','trials'),'Visible','off');set(findobj(tab,'Tag','trialsstr'),'Visible','off');
    elseif get(findobj(tab,'Tag','stimselect'),'Value') == 4
        set(findobj(tab,'Tag','delay'),'Visible','off');set(findobj(tab,'Tag','delaystr'),'Visible','off');
        if strcmp(TSdata.file(files(1)).type,'scanimage')
            set(findobj(tab,'Tag','duration'),'Visible','on');set(findobj(tab,'Tag','durationstr'),'Visible','on');
        else
            set(findobj(tab,'Tag','duration'),'Visible','off');set(findobj(tab,'Tag','durationstr'),'Visible','off');
        end
        set(findobj(tab,'Tag','interval'),'Visible','off');set(findobj(tab,'Tag','intervalstr'),'Visible','off');
        set(findobj(tab,'Tag','trials'),'Visible','off');set(findobj(tab,'Tag','trialsstr'),'Visible','off');
    elseif get(findobj(tab,'Tag','stimselect'),'Value') == 5
        set(findobj(tab,'Tag','delay'),'Visible','on');set(findobj(tab,'Tag','delaystr'),'Visible','on');
        set(findobj(tab,'Tag','duration'),'Visible','on');set(findobj(tab,'Tag','durationstr'),'Visible','on');
        set(findobj(tab,'Tag','interval'),'Visible','on');set(findobj(tab,'Tag','intervalstr'),'Visible','on');
        set(findobj(tab,'Tag','trials'),'Visible','on');set(findobj(tab,'Tag','trialsstr'),'Visible','on');
    end
    %sort various stimulus options prior to sortby...
    if ~isempty(TSdata.file) && max(get(findobj(tab,'Tag','stimselect'),'Value')==[2 3 4 5])
        set(findobj(tab,'Tag','hidestim'),'Enable','on');
        set(findobj(tab,'Tag','superimpose'),'Enable','on');
        set(findobj(tab,'Tag','avgtrials'),'Enable','on');
        if get(findobj(tab,'Tag','superimpose'),'Value') || get(findobj(tab,'Tag','avgtrials'),'Value')
            set(findobj(tab,'Tag','byodor'),'Enable','on');
            if get(findobj(tab,'Tag','stimselect'),'Value') == 2; set(findobj(tab,'Tag','avgodors'),'Enable','on')
            else; set(findobj(tab,'Tag','avgodors'),'Enable','off','Value',0)
            end
            if get(findobj(tab,'Tag','superimpose'),'Value') %only allow sort bytrial if superimpose
                set(findobj(tab,'Tag','bytrial'),'Enable','on');
            else
                set(findobj(tab,'Tag','bytrial'),'Enable','off');
                if get(findobj(tab,'Tag','bytrial'),'Value'); set(findobj(tab,'Tag','byodor'),'Value',1); end
            end
        else
            set(findobj(tab,'Tag','byodor'),'Enable','off');
            if get(findobj(tab,'Tag','byodor'),'Value'); set(findobj(tab,'Tag','byroi'),'Value',1); end
            set(findobj(tab,'Tag','avgodors'),'Enable','off','Value',0);            
            set(findobj(tab,'Tag','bytrial'),'Enable','off');
            if get(findobj(tab,'Tag','bytrial'),'Value'); set(findobj(tab,'Tag','byroi'),'Value',1); end
        end
    else
        set(findobj(tab,'Tag','hidestim'),'Enable','off','Value',0);
        set(findobj(tab,'Tag','superimpose'),'Enable','off','Value',0);
        set(findobj(tab,'Tag','avgtrials'),'Enable','off','Value',0)
        set(findobj(tab,'Tag','OdorTrial_listbox'), 'String','','Value',1);
        set(findobj(tab,'Tag','byodor'),'Enable','off');
        set(findobj(tab,'Tag','bytrial'),'Enable','off');
        if get(findobj(tab,'Tag','byodor'),'Value') || get(findobj(tab,'Tag','bytrial'),'Value')
            set(findobj(tab,'Tag','byroi'),'Value',1);
        end
        set(findobj(tab,'Tag','avgodors'),'Enable','off','Value',0);
    end
    sortval = get(findobj(tab,'Tag','sortColors'), 'SelectedObject');
    % file labels/options
    if isfield(TSdata,'file') && ~isempty(TSdata.file)
        set(findobj(tab,'Tag','byfile'),'Enable','on');
        if length(files)>1
            set(findobj(tab,'Tag','avgfiles'),'Enable','on')
        else; set(findobj(tab,'Tag','avgfiles'),'Enable','off')
        end
        filestr = cell(length(TSdata.file),1);
        for i = 1:numel(filestr)
            if strcmp(sortval.Tag,'byfile')
                tmpcl = myColors(i).*255;
                filestr{i} = ['<HTML><FONT color=rgb(' num2str(tmpcl(1)) ','...
                    num2str(tmpcl(2)) ',' num2str(tmpcl(3)) ')>' TSdata.file(i).name '</Font></html>'];
            else
                filestr{i} = TSdata.file(i).name;
            end
        end
        set(findobj(tab,'Tag','FILE_listbox'), 'String', filestr);
    else
        set(findobj(tab,'Tag','FILE_listbox'), 'String', '');
        set(findobj(tab,'Tag','byfile'),'Enable','off');
        set(findobj(tab,'Tag','avgfiles'),'Enable','off');
    end    
    %roi labels/options
    if isfield(TSdata,'roi') && ~isempty(TSdata.roi)
        set(findobj(tab,'Tag','byroi'),'Enable','on');
        rois = get(findobj(tab,'Tag','ROI_listbox'), 'Value');
        if length(rois)>1
            set(findobj(tab,'Tag','avgrois'),'Enable','on');
        else; set(findobj(tab,'Tag','avgrois'),'Enable','off');
        end       
        roistr = cell(numel(TSdata.roi),1);
        for i = 1:numel(TSdata.roi)
            if strcmp(sortval.Tag,'byroi')
                tmpcl = myColors(i).*255;
                roistr{i} = ['<HTML><FONT color=rgb(' ...
                    num2str(tmpcl(1)) ',' num2str(tmpcl(2)) ',' num2str(tmpcl(3)) ')>' ['ROI #' num2str(i)] '</Font></html>'];
            else
                roistr{i} = ['ROI #' num2str(i)];  
            end
        end
        set(findobj(tab,'Tag','ROI_listbox'), 'String', roistr);
    else
        set(findobj(tab,'Tag','ROI_listbox'), 'String','');
        set(findobj(tab,'Tag','byroi'),'Enable','off');
        set(findobj(tab,'Tag','avgrois'),'Enable','off');
    end
    if get(findobj(tab,'Tag','subtractbgroi'),'Value')
        bgroinum = str2double(get(findobj(tab,'Tag','bgroi'), 'String'));
        if bgroinum>length(TSdata.roi); set(findobj(tab,'Tag','subtractbgroi'), 'Value', 0); disp('Background ROI # out of range'); end
    end
    if isfield(TSdata,'file') && ~isempty(TSdata.file) && isfield(TSdata,'roi') && ~isempty(TSdata.roi)
        [allOdorTrials, preplotdata] = getPlotData; %get initial plotdata and available odortrials
    end
    % OdorTrials labels/options (if stimulus is selected)
    if get(findobj(tab,'Tag','stimselect'),'Value') ~= 1
        cnt=0; odorstr = [];
        if length(files)>1
            for f = 1:length(files)
                odors = allOdorTrials{f}.odors;
                for o = 1:length(odors)
                    trials = allOdorTrials{f}.odor(o).trials;
                    if strcmp(sortval.Tag,'byodor'); tmpcl = myColors(odors(o)).*255; end
                    for t = trials
                        cnt=cnt+1;
                        if strcmp(sortval.Tag,'bytrial'); tmpcl = myColors(t).*255; end
                        if strcmp(sortval.Tag,'byodor') || strcmp(sortval.Tag,'bytrial')
                            odorstr{cnt} = ['<HTML><FONT color=rgb(' num2str(tmpcl(1))...
                                ',' num2str(tmpcl(2)) ',' num2str(tmpcl(3)) ')>' ['File' num2str(f) 'Odor' num2str(odors(o)) ...
                                'Trial' num2str(t)] '</Font></html>'];
                        else; odorstr{cnt} = ['File' num2str(f) 'Odor' num2str(odors(o)) 'Trial' num2str(t)];
                        end
                    end
                end
            end
        else
            odors = allOdorTrials{1}.odors;
            for o = 1:length(odors)
                trials = allOdorTrials{1}.odor(o).trials;
                if strcmp(sortval.Tag,'byodor'); tmpcl = myColors(odors(o)).*255; end
                for t = trials
                    cnt=cnt+1;
                    if strcmp(sortval.Tag,'bytrial'); tmpcl = myColors(t).*255; end
                    if strcmp(sortval.Tag,'byodor') || strcmp(sortval.Tag,'bytrial')
                        odorstr{cnt} = ['<HTML><FONT color=rgb(' num2str(tmpcl(1))...
                            ',' num2str(tmpcl(2)) ',' num2str(tmpcl(3)) ')>' ['Odor' num2str(odors(o)) ...
                            'Trial' num2str(t)] '</Font></html>'];
                    else; odorstr{cnt} = ['Odor' num2str(odors(o)) 'Trial' num2str(t)];
                    end
                end
            end
        end
        if bDefaultSelectAllOdorTrials %only when new stimulus is selected
            set(findobj(tab,'Tag','OdorTrial_listbox'),'Value',1:length(odorstr));
            bDefaultSelectAllOdorTrials = 0;
        end
        %handle case of selecting file(s) with different odor trials
        vals = get(findobj(tab,'Tag','OdorTrial_listbox'),'Value');
        if max(vals > length(odorstr))
            set(findobj(tab,'Tag','OdorTrial_listbox'),'Value',vals(vals<=length(odorstr)));
        end
        set(findobj(tab,'Tag','OdorTrial_listbox'), 'String', odorstr);
    end
    %do the plot
    if isfield(TSdata,'file') && ~isempty(TSdata.file) && isfield(TSdata,'roi') && ~isempty(TSdata.roi)
        do_time_series_plot(preplotdata);
        figure(hTS);
    else
        tmpfig=findobj('type','figure','Name',sprintf('Plot #%s',tab.Tag));
        if ~isempty(tmpfig); figure(tmpfig); cla(findobj(tmpfig,'Tag','tsax')); end
    end
end

function [allOdorTrials, preplotdata] = getPlotData
    %gets initial selected plotdata and returns a list of all available odortrials
    tab = htabgroup.SelectedTab;
    files = get(findobj(tab,'Tag','FILE_listbox'), 'Value');
    rois = get(findobj(tab,'Tag','ROI_listbox'), 'Value');
    Max = TSdata.file(files(1)).roi(1).time(end);
    if length(files)>1
        for f = 2:length(files)
            if TSdata.file(files(f)).roi(1).time(end) > Max
                Max = TSdata.file(files(f)).roi(1).time(end);
            end
        end
    end
    for f = 1:length(files)
        preplotdata.file(f).name = TSdata.file(files(f)).name;
        preplotdata.file(f).type = TSdata.file(files(f)).type;
        preplotdata.file(f).frameRate = TSdata.file(files(f)).frameRate;
        preplotdata.file(f).frames = TSdata.file(files(f)).frames;
        for r = 1:length(rois)
            %time_series
            preplotdata.file(f).roi(r).number = rois(r);
            preplotdata.file(f).roi(r).time = TSdata.file(files(f)).roi(rois(r)).time;
            preplotdata.file(f).roi(r).series = TSdata.file(files(f)).roi(rois(r)).series;
        end
        %subtract background roi
        if get(findobj(tab,'Tag','subtractbgroi'),'Value')
            bgroinum = str2double(get(findobj(tab,'Tag','bgroi'), 'String'));
            for r = 1:length(rois)
                bgseries = interp1(TSdata.file(files(f)).roi(bgroinum).time,TSdata.file(files(f)).roi(bgroinum).series,...
                    preplotdata.file(f).roi(r).time,'pchip'); %note: rois are time-shifted based on roi y-position (sub-timeframe)
                preplotdata.file(f).roi(r).series=preplotdata.file(f).roi(r).series-bgseries; clear bgseries;
            end
        end
        %average rois; uses a weighted average to combine rois - weights based on #pixels in each roi
        if get(findobj(tab,'Tag','avgrois'),'Value')
            totalpix = 0;
            for r = 1:length(rois)
                totalpix = totalpix + length(find(TSdata.roi(rois(r)).mask));
            end
            preplotdata.file(f).avgroi.time = preplotdata.file(f).roi(1).time;
            weights = zeros(length(preplotdata.file(f).roi),1);
            preplotdata.file(f).avgroi.series = zeros(length(preplotdata.file(f).roi(1).series),1);
            trials = zeros(length(preplotdata.file(f).roi(1).series),length(preplotdata.file(f).roi));
            for r = 1:length(preplotdata.file(f).roi)
                if totalpix > 0 %just in case of blank or missing roi masks
                    weights(r) = length(find(TSdata.roi(rois(r)).mask))/totalpix;
                else; weights(r) = 1/length(preplotdata.file(f).roi);
                end
                trials(:,r) = preplotdata.file(f).roi(r).series;
                preplotdata.file(f).avgroi.series = preplotdata.file(f).avgroi.series + ...
                    trials(:,r).*weights(r);
            end
            preplotdata.file(f).avgroi.confint(1,:) = preplotdata.file(f).avgroi.series + 1.96.*std(trials,weights',2)./sqrt(size(trials,2));
            preplotdata.file(f).avgroi.confint(2,:) = preplotdata.file(f).avgroi.series - 1.96.*std(trials,weights',2)./sqrt(size(trials,2));
            %Note that these confidence intervals may be invalid since we are really just making 1 large ROI, and not
            %doing a true weighted population average (this may depend on the roi population...)
        end
        %aux signals
            if isfield(TSdata.file(files(f)),'aux1') && ~isempty(TSdata.file(files(f)).aux1)
                preplotdata.file(f).aux1.times = TSdata.file(files(f)).aux1.times;
                preplotdata.file(f).aux1.signal = TSdata.file(files(f)).aux1.signal;
            end
            if isfield(TSdata.file(files(f)),'aux2') && ~isempty(TSdata.file(files(f)).aux2)
                preplotdata.file(f).aux2.times = TSdata.file(files(f)).aux2.times;
                preplotdata.file(f).aux2.signal = TSdata.file(files(f)).aux2.signal;
            end
            if isfield(TSdata.file(files(f)),'aux3') && ~isempty(TSdata.file(files(f)).aux3)
                preplotdata.file(f).aux3.times = TSdata.file(files(f)).aux3.times;
                preplotdata.file(f).aux3.signal = TSdata.file(files(f)).aux3.signal;
                preplotdata.file(f).aux3.odors = TSdata.file(files(f)).aux3.odors;
            end
        if get(findobj(tab,'Tag','stimselect'),'Value') == 4
            preplotdata.file(f).aux_combo.times = TSdata.file(files(f)).aux_combo.times;
            preplotdata.file(f).aux_combo.signal = TSdata.file(files(f)).aux_combo.signal;
            if strcmp(preplotdata.file(f).type,'scanimage')
                preplotdata.file(f).aux_combo.odorDuration = TSdata.file(files(f)).aux_combo.odorDuration;
            end
        end
        if strcmp(get(findobj(tab,'Tag','ephys'),'Visible'), 'on')
            preplotdata.file(f).ephys = TSdata.file(files(f)).ephys;
        end
    end
    %defined stimulus
    if get(findobj(tab,'Tag','stimselect'),'Value') == 5 %get(findobj(tab,'Tag','definestim'),'Value')     
        delay = str2double(get(findobj(tab,'Tag','delay'),'String')); % #frames delay
        duration = str2double(get(findobj(tab,'Tag','duration'),'String')); % #frames duration
        interval = str2double(get(findobj(tab,'Tag','interval'),'String')); % #frames interval
        trials = str2double(get(findobj(tab,'Tag','trials'),'String'));
        trials = min(trials,round((Max-delay+interval)/(duration+interval)));
        set(findobj(tab,'Tag','trials'),'String',trials);
        deltaT=1/150; %Stimulus sampling rate is arbitrarily set at 150Hz
        preplotdata.def_stimulus = defineStimulus(0,Max,deltaT,delay,duration,interval,trials);
    end
    %break time series up into odortrials
    allOdorTrials = cell(length(files),1);
    if get(findobj(tab,'Tag','stimselect'),'Value') ~= 1
        [allOdorTrials, preplotdata] = getOdorTrials(preplotdata);
    end
    %modify with filters, deltaF, deconvolution etc.
    if get(findobj(tab,'Tag','lpfilter'),'Value') || get(findobj(tab,'Tag','hpfilter'),'Value') || ...
            get(findobj(tab,'Tag','deltaf'),'Value')  || get(findobj(tab,'Tag','deltafoverf'),'Value')
        for f = 1:length(preplotdata.file)
            if get(findobj(tab,'Tag','avgrois'),'Value')
                preplotdata.file(f).avgroi.series = modify(preplotdata.file(f).avgroi.series,preplotdata.file(f).avgroi.time);
                if isfield(preplotdata.file(f).avgroi,'odor')
                    for o = 1:length(preplotdata.file(f).avgroi.odor)
                        for t = 1:length(preplotdata.file(f).avgroi.odor(o).trial)
                            preplotdata.file(f).avgroi.odor(o).trial(t).series = ...
                                modify(preplotdata.file(f).avgroi.odor(o).trial(t).series,preplotdata.file(f).avgroi.odor(o).trial(t).time);
                        end
                    end
                end
            else
                for r = 1:length(preplotdata.file(f).roi)
                    preplotdata.file(f).roi(r).series = modify(preplotdata.file(f).roi(r).series,preplotdata.file(f).roi(r).time);
                    if isfield(preplotdata.file(f).roi(r),'odor')
                        for o = 1:length(preplotdata.file(f).roi(r).odor)
                            for t = 1:length(preplotdata.file(f).roi(r).odor(o).trial)
                                preplotdata.file(f).roi(r).odor(o).trial(t).series = ...
                                    modify(preplotdata.file(f).roi(r).odor(o).trial(t).series,preplotdata.file(f).roi(r).odor(o).trial(t).time);
                            end
                        end
                    end
                end
            end
        end
    end
end

function [allOdorTrials, preplotdata] = getOdorTrials(preplotdata)
%This function returns allOdorTrials and preplotdata
%allOdorTrials are all "valid" trials - for the odortrials listbox
%preplotdata includes only the "selected" odortrials - from the odortrials listbox
    tab = htabgroup.SelectedTab;
    files = get(findobj(tab,'Tag','FILE_listbox'), 'Value');
    prestimtime = str2double(get(findobj(tab,'Tag','prestim'),'String'));
    poststimtime = str2double(get(findobj(tab,'Tag','poststim'),'String'));
    auxtype = auxstr{get(findobj(tab,'Tag','stimselect'),'Value')};
    allOdorTrials = cell(length(files),1);
    for f = 1:length(files)
        tmpfile = preplotdata.file(f);
        if strcmp(auxtype,auxstr{5}); tmpfile.def_stimulus = preplotdata.def_stimulus; end
        allOdorTrials{f} = getAllOdorTrials(auxtype,prestimtime,poststimtime,tmpfile);
    end 
    %now pull out selected trials (must use same for loops as odortrials listbox string)
    if get(findobj(tab,'Tag','superimpose'),'Value') || get(findobj(tab,'Tag','avgtrials'),'Value')
        odortrialslist = get(findobj(tab,'Tag','OdorTrial_listbox'), 'Value');
        rois = get(findobj(tab,'Tag','ROI_listbox'), 'Value');
        newTS = [];
        for f = 1:length(files)
            switch auxtype
                case auxstr{2}
                    stimtimes = preplotdata.file(f).aux1.times;
                case auxstr{3}
                    stimtimes = preplotdata.file(f).aux2.times;
                case auxstr{4}
                    stimtimes = preplotdata.file(f).aux_combo.times;
                case auxstr{5}
                    stimtimes = preplotdata.def_stimulus.times;
            end
            if get(findobj(tab,'Tag','avgrois'),'Value')
                newTS{f} = interp1(preplotdata.file(f).avgroi.time,preplotdata.file(f).avgroi.series,stimtimes,'pchip');
            else
                for r = 1:length(rois)
                    newTS{f,r}=interp1(preplotdata.file(f).roi(r).time,preplotdata.file(f).roi(r).series,stimtimes,'pchip');
                end
            end
        end
        cnt=0;
        for f = 1:length(files)
            switch auxtype
                case auxstr{2}
                    stimtimes = preplotdata.file(f).aux1.times;
                case auxstr{3}
                    stimtimes = preplotdata.file(f).aux2.times;
                case auxstr{4}
                    stimtimes = preplotdata.file(f).aux_combo.times;
                case auxstr{5}
                    stimtimes = preplotdata.def_stimulus.times;
            end
            numframes = find(stimtimes>(prestimtime+poststimtime), 1, 'first'); %total #frames to grab
            odors = allOdorTrials{f}.odors;
            oo = 0;
            for o = 1:length(odors)
                ttt = 0; %index of valid + selected trials
                trials = allOdorTrials{f}.odor(o).trials; %all the valid trials
                for tt = 1:length(trials) 
                    cnt=cnt+1;
                    if max(cnt == odortrialslist)
                        ttt = ttt+1; if ttt == 1; oo = oo + 1; end
                        %index = allOdorTrials{f}.odor(o).trial(tt).index;
                        index = allOdorTrials{f}.odor(o).trial(tt).auxindex;
                        if get(findobj(tab,'Tag','avgrois'),'Value')
                            tmpTS=newTS{f};
                            preplotdata.file(f).avgroi.odor(oo).trial(ttt).series = tmpTS(index);
                            preplotdata.file(f).avgroi.odor(oo).number = odors(o);
                            preplotdata.file(f).avgroi.odor(oo).trial(ttt).number = trials(tt);
                            preplotdata.file(f).avgroi.odor(oo).trial(ttt).time = stimtimes(1:numframes);
%                             preplotdata.file(f).avgroi.odor(oo).trial(ttt).confint(1,:) = preplotdata.file(f).avgroi.confint(1,index);
%                             preplotdata.file(f).avgroi.odor(oo).trial(ttt).confint(2,:) = preplotdata.file(f).avgroi.confint(2,index);
                        else
                            for r = 1:length(rois)
                                tmpTS=newTS{f,r};
                                preplotdata.file(f).roi(r).odor(oo).trial(ttt).series = tmpTS(index);
                                preplotdata.file(f).roi(r).odor(oo).number = odors(o);
                                preplotdata.file(f).roi(r).odor(oo).trial(ttt).number = trials(tt);
                                preplotdata.file(f).roi(r).odor(oo).trial(ttt).time = stimtimes(1:numframes);
                            end
                        end
                        %Ephys data for each odortrial
                        if strcmp(get(findobj(tab,'Tag','ephys'),'Visible'), 'on')
                            eind1 = find(preplotdata.file(f).ephys.times>=stimtimes(index(1)),1,'first');
                            eind2 = find(preplotdata.file(f).ephys.times<=stimtimes(index(end)),1,'last');
                            preplotdata.file(f).ephys.odors(oo).number = odors(o);
                            preplotdata.file(f).ephys.odors(oo).trials(ttt).number = trials(tt);
                            preplotdata.file(f).ephys.odors(oo).trials(ttt).times = preplotdata.file(f).ephys.times(eind1:eind2) ...
                                - preplotdata.file(f).ephys.times(eind1);
                            preplotdata.file(f).ephys.odors(oo).trials(ttt).odor = preplotdata.file(f).ephys.odor(eind1:eind2);
                            preplotdata.file(f).ephys.odors(oo).trials(ttt).sniff = preplotdata.file(f).ephys.sniff(eind1:eind2);
                            preplotdata.file(f).ephys.odors(oo).trials(ttt).puff = preplotdata.file(f).ephys.puff(eind1:eind2);
                        end
                    end
                end
            end
        end
    end
end

function newts = modify(newts,time)
    tab = htabgroup.SelectedTab;
    if get(findobj(tab,'Tag','lpfilter'),'Value')
        freq = str2double(get(findobj(tab,'Tag','lpfilterparm'), 'String'));
        samp_rate = 1/(time(2)-time(1));
        Wn = freq/(0.5*samp_rate);
        if (Wn>1)
            errordlg(['Maximum filter frequency = ' num2str(0.5*samp_rate)]);
        else
            N = 1;
            [b,a] = butter(N,Wn);
            newts = filtfilt(b,a,newts);
        end
    end
    if get(findobj(tab,'Tag','hpfilter'),'Value')
        freq = str2double(get(findobj(tab,'Tag','hpfilterparm'), 'String'));
        samp_rate = 1/(time(2)-time(1));
        Wn = freq/(0.5*samp_rate);
        N = 1;
        [bhigh, ahigh] = butter(N,Wn, 'high');
        newts = filtfilt(bhigh,ahigh,newts);
    end
    % DeltaF or DeltaF/F - after filters
    if get(findobj(tab,'Tag','deltaf'),'Value')  || get(findobj(tab,'Tag','deltafoverf'),'Value')
        fstart = find(time>str2double(get(findobj(tab,'Tag','fstart'),'String')), 1, 'first');
        fstop = find(time<str2double(get(findobj(tab,'Tag','fstop'),'String')), 1, 'last');
        F0 = mean(newts(fstart:fstop));
        if get(findobj(tab,'Tag','deltafoverf'),'Value')
            set(findobj(tab,'Tag','deltaf'),'Value',0)
            newts = 100*(newts-F0)./F0;
        else %subtract mean of F0
            newts = newts-F0;
        end
    end
% %     if get(findobj(tab,'Tag','deconv'),'Value')
% %         tauf = str2double(get(findobj(tab,'Tag','tauDecay'),'String'));
% %         taur = str2double(get(findobj(tab,'Tag','tauRise'), 'String'));
% %         samp_rate = 1/(time(2)-time(1));
% %         kernellength = round(2 * tauf * samp_rate) - 1;
% %         kernelpad = zeros(1,kernellength);
% %         kernel = exp((-1:-1:-kernellength-1)/(tauf*samp_rate)) - ...
% %             exp((-1:-1:-kernellength-1)/(taur*samp_rate));
% %         newts = deconv([newts kernelpad], kernel);
% %         newts = real(newts);
% %     end
end

function do_time_series_plot(preplotdata)
    tab = htabgroup.SelectedTab;
    p = str2num(tab.Tag);
    plotdata{p} = preplotdata;
    fig = findobj('type','figure','Name',sprintf('Plot #%s',tab.Tag));
    if isempty(fig); return; else; figure(fig); end
    tsax = gca; if isempty(tsax); tsax=axes(fig,'Tag','tsax'); end
    if isempty(get(findobj(tab,'Tag','ROI_listbox'),'String')) || isempty(TSdata.file(end).name)
        cla(fig,tsax);
        return;
    end
    files = get(findobj(tab,'Tag','FILE_listbox'), 'Value');
    rois = get(findobj(tab,'Tag','ROI_listbox'), 'Value');
    bsuperimpose = get(findobj(tab,'Tag','superimpose'),'Value');
    bavgtrials = get(findobj(tab,'Tag','avgtrials'),'Value');
    %average files/rois/odors/trials 
    %note: rois are already averaged in getPlotData function - this is treated as expanding the region,
    % so not included here as averaging w/Confidence intervals calculation
    %note: this section of code can get confusing... so I've written loops for each combination
    % of different averages separately so you can see exactly what happens in each case... hopefully.
    % The key is to carefully keep track of how the trials/odors are grouped in each case
    if length(plotdata{p}.file)<2 ;set(findobj(tab,'Tag','avgfiles'),'Value',0); end
    %% average files
    if get(findobj(tab,'Tag','avgfiles'),'Value')
        %% average files/rois
        if get(findobj(tab,'Tag','avgrois'),'Value') %files/rois avg
            %% full timeseries
            if ~bsuperimpose && ~bavgtrials
                maxframes = inf; %only average over length of shortest file selected
                for f = 1:length(plotdata{p}.file); maxframes = min(maxframes,length(plotdata{p}.file(f).roi(1).time)); end                
                avgfile.avgroi.trials = zeros(maxframes,length(files));
                for f = 1:length(files)
                    avgfile.avgroi.trials(:,f) = plotdata{p}.file(f).avgroi.series(1:maxframes);
                end
                plotdata{p}.avgfile.avgroi.time = plotdata{p}.file(1).avgroi.time(1:maxframes);
                plotdata{p}.avgfile.avgroi.series = mean(avgfile.avgroi.trials,2);
                plotdata{p}.avgfile.avgroi.confint(1,:) = plotdata{p}.avgfile.avgroi.series + 1.96.*std(avgfile.avgroi.trials,1,2)./sqrt(size(avgfile.avgroi.trials,2));
                plotdata{p}.avgfile.avgroi.confint(2,:) = plotdata{p}.avgfile.avgroi.series - 1.96.*std(avgfile.avgroi.trials,1,2)./sqrt(size(avgfile.avgroi.trials,2));                
            %% odortrials - superimposed or averaged
            else
                %% average files/rois/odors
                if get(findobj(tab,'Tag','avgodors'),'Value')
                    %% average files/rois/odors/trials
                    if bavgtrials
                        avgfile.avgroi.avgodor.avgtrial.trials = [];
                        for f = 1:length(plotdata{p}.file)
                            if isfield(plotdata{p}.file(f).avgroi,'odor')
                                for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                    for t = 1:length(plotdata{p}.file(f).avgroi.odor(o).trial)
                                        if isempty(avgfile.avgroi.avgodor.avgtrial.trials)
                                            avgfile.avgroi.avgodor.avgtrial.time = plotdata{p}.file(f).avgroi.odor(o).trial(t).time;
                                            avgfile.avgroi.avgodor.avgtrial.trials(:,1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        else
                                            avgfile.avgroi.avgodor.avgtrial.trials(:,end+1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        end
                                    end
                                end
                            end
                        end
                        plotdata{p}.avgfile.avgroi.avgodor.avgtrial.time = avgfile.avgroi.avgodor.avgtrial.time;
                        plotdata{p}.avgfile.avgroi.avgodor.avgtrial.series = mean(avgfile.avgroi.avgodor.avgtrial.trials,2);
                        plotdata{p}.avgfile.avgroi.avgodor.avgtrial.confint(1,:) = plotdata{p}.avgfile.avgroi.avgodor.avgtrial.series + ...
                            1.96.*std(avgfile.avgroi.avgodor.avgtrial.trials,1,2)./sqrt(size(avgfile.avgroi.avgodor.avgtrial.trials,2));
                        plotdata{p}.avgfile.avgroi.avgodor.avgtrial.confint(2,:) = plotdata{p}.avgfile.avgroi.avgodor.avgtrial.series - ...
                            1.96.*std(avgfile.avgroi.avgodor.avgtrial.trials,1,2)./sqrt(size(avgfile.avgroi.avgodor.avgtrial.trials,2));
                    %% average files/rois/odors, superimpose trials
                    else %superimpose trials - files/rois/odors avg
                        %gather all the trials available for each trialIdx, some files/odors may not have same odor trials selected
                        avgfile.avgroi.avgodor.trial = [];
                        for f = 1:length(plotdata{p}.file)
                            if isfield(plotdata{p}.file(f).avgroi,'odor')
                                for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                    for t = 1:length(plotdata{p}.file(f).avgroi.odor(o).trial)
                                        trialIdx = plotdata{p}.file(f).avgroi.odor(o).trial(t).number;
                                        if length(avgfile.avgroi.avgodor.trial)<trialIdx; avgfile.avgroi.avgodor.trial(trialIdx).trials = []; end
                                        if isempty(avgfile.avgroi.avgodor.trial(trialIdx).trials)
                                            avgfile.avgroi.avgodor.trial(trialIdx).time = plotdata{p}.file(f).avgroi.odor(o).trial(t).time;
                                            avgfile.avgroi.avgodor.trial(trialIdx).trials(:,1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        else
                                            avgfile.avgroi.avgodor.trial(trialIdx).trials(:,end+1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found and toss out empty trialIdx's
                        newtrialIdx = 0;
                        for trialIdx = 1:length(avgfile.avgroi.avgodor.trial)
                            if ~isempty(avgfile.avgroi.avgodor.trial(trialIdx).trials)
                                newtrialIdx = newtrialIdx+1;
                                plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).time = avgfile.avgroi.avgodor.trial(trialIdx).time;
                                plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).number = trialIdx;
                                plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).series = mean(avgfile.avgroi.avgodor.trial(trialIdx).trials,2);
                                plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).confint(1,:) = plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).series + ...
                                    1.96.*std(avgfile.avgroi.avgodor.trial(trialIdx).trials,1,2)./sqrt(size(avgfile.avgroi.avgodor.trial(trialIdx).trials,2));
                                plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).confint(2,:) = plotdata{p}.avgfile.avgroi.avgodor.trial(newtrialIdx).series - ...
                                    1.96.*std(avgfile.avgroi.avgodor.trial(trialIdx).trials,1,2)./sqrt(size(avgfile.avgroi.avgodor.trial(trialIdx).trials,2));
                            end
                        end
                    end
                %% average files/rois, not odors
                else
                    %% average files/rois/trials, not odors 
                    if bavgtrials
                        %gather all the trials for each odor, since different files may have different odors selected
                        avgfile.avgroi.odor = [];
                        for f = 1:length(plotdata{p}.file)
                            if isfield(plotdata{p}.file(f).avgroi,'odor')
                                for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                    %use odorNum+1 for odorIdx, because we can have odorNum=0, so shift index by +1
                                    odorNum = plotdata{p}.file(f).avgroi.odor(o).number; odorIdx=odorNum+1;
                                    if length(avgfile.avgroi.odor)<odorIdx; avgfile.avgroi.odor(odorIdx).trials = []; end
                                    for t = 1:length(plotdata{p}.file(f).avgroi.odor(o).trial)
                                        if isempty(avgfile.avgroi.odor(odorIdx).trials)
                                            avgfile.avgroi.odor(odorIdx).time = plotdata{p}.file(f).avgroi.odor(o).trial(t).time;
                                            avgfile.avgroi.odor(odorIdx).trials(:,1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        else
                                            avgfile.avgroi.odor(odorIdx).trials(:,end+1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found and toss out empty odorIdx's
                        newodorIdx = 0;
                        for odorIdx = 1:length(avgfile.avgroi.odor)
                            if ~isempty(avgfile.avgroi.odor(odorIdx).trials)
                                newodorIdx = newodorIdx+1;
                                plotdata{p}.avgfile.avgroi.odor(newodorIdx).number = odorIdx-1; %recall than odorNum is odorIdx-1
                                plotdata{p}.avgfile.avgroi.odor(newodorIdx).avgtrial.time = avgfile.avgroi.odor(odorIdx).time;
                                plotdata{p}.avgfile.avgroi.odor(newodorIdx).avgtrial.series = mean(avgfile.avgroi.odor(odorIdx).trials,2);
                                plotdata{p}.avgfile.avgroi.odor(newodorIdx).avgtrial.confint(1,:) = plotdata{p}.avgfile.avgroi.odor(newodorIdx).avgtrial.series + ...
                                    1.96.*std(avgfile.avgroi.odor(odorIdx).trials,1,2)./sqrt(size(avgfile.avgroi.odor(odorIdx).trials,2));
                                plotdata{p}.avgfile.avgroi.odor(newodorIdx).avgtrial.confint(2,:) = plotdata{p}.avgfile.avgroi.odor(newodorIdx).avgtrial.series - ...
                                    1.96.*std(avgfile.avgroi.odor(odorIdx).trials,1,2)./sqrt(size(avgfile.avgroi.odor(odorIdx).trials,2));
                            end
                        end
                    %% average files/rois, not odors/trials(superimpose)
                    else
                        %gather all the odortrials for each odorIdx/trialIdx
                        avgfile.avgroi.odor = [];
                        for f = 1:length(plotdata{p}.file)
                            if isfield(plotdata{p}.file(f).avgroi,'odor')
                                for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                    odorNum = plotdata{p}.file(f).avgroi.odor(o).number; odorIdx=odorNum+1;
                                    if length(avgfile.avgroi.odor)<odorIdx; avgfile.avgroi.odor(odorIdx).trial = []; end
                                    for t = 1:length(plotdata{p}.file(f).avgroi.odor(o).trial)
                                        trialIdx = plotdata{p}.file(f).avgroi.odor(o).trial(t).number;
                                        if length(avgfile.avgroi.odor(odorIdx).trial)<trialIdx; avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials = []; end
                                        if isempty(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials)
                                            avgfile.avgroi.odor(odorIdx).trial(trialIdx).time = plotdata{p}.file(f).avgroi.odor(o).trial(t).time;
                                            avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials(:,1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        else
                                            avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials(:,end+1) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found and toss out empty odorIdx's/trialIdx's
                        newodorIdx = 0; newtrialIdx = zeros(length(avgfile.avgroi.odor),1);
                        for odorIdx = 1:length(avgfile.avgroi.odor)
                            newtrialIdx(odorIdx) = 0; odorNum=odorIdx-1; %recall that odorIdx=odorNum+1
                            for trialIdx = 1:length(avgfile.avgroi.odor(odorIdx).trial)
                                if ~isempty(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials)
                                    newtrialIdx(odorIdx) = newtrialIdx(odorIdx)+1;
                                    if newtrialIdx(odorIdx) == 1; newodorIdx = newodorIdx+1; plotdata{p}.avgfile.avgroi.odor(newodorIdx).number = odorNum; end
                                    plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).time = avgfile.avgroi.odor(odorIdx).trial(trialIdx).time;
                                    plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).number = trialIdx;
                                    plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).series = mean(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials,2);
                                    plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).confint(1,:) = plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).series + ...
                                        1.96.*std(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials,1,2)./sqrt(size(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials,2));
                                    plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).confint(2,:) = plotdata{p}.avgfile.avgroi.odor(newodorIdx).trial(newtrialIdx(odorIdx)).series - ...
                                        1.96.*std(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials,1,2)./sqrt(size(avgfile.avgroi.odor(odorIdx).trial(trialIdx).trials,2));
                                end
                            end
                        end
                    end
                end
            end
        %% average files, not rois
        else
            %% full time series
            if ~bsuperimpose && ~bavgtrials
                maxframes = inf; %only average over length of shortest file selected
                for f = 1:length(plotdata{p}.file); maxframes = min(maxframes,length(plotdata{p}.file(f).roi(1).time)); end   
                for r = 1:length(rois)
                    avgfile.roi(r).trials = zeros(maxframes,length(files));
                    for f = 1:length(files)
                        avgfile.roi(r).trials(:,f) = plotdata{p}.file(f).roi(r).series(1:maxframes);
                    end
                    plotdata{p}.avgfile.roi(r).time = plotdata{p}.file(1).roi(r).time(1:maxframes);
                    plotdata{p}.avgfile.roi(r).series = mean(avgfile.roi(r).trials,2);
                    plotdata{p}.avgfile.roi(r).confint(1,:) = plotdata{p}.avgfile.roi(r).series + 1.96.*std(avgfile.roi(r).trials,1,2)./sqrt(size(avgfile.roi(r).trials,2));
                    plotdata{p}.avgfile.roi(r).confint(2,:) = plotdata{p}.avgfile.roi(r).series - 1.96.*std(avgfile.roi(r).trials,1,2)./sqrt(size(avgfile.roi(r).trials,2));
                end
            %% odortrials - superimposed or averaged
            else
                %% average files/odors, not rois
                if get(findobj(tab,'Tag','avgodors'),'Value')
                    %% average files/odors/trials, not rois
                    if bavgtrials
                        avgfile.roi = [];
                        for f = 1:length(plotdata{p}.file)
                            for r = 1:length(plotdata{p}.file(f).roi)
                                if isfield(plotdata{p}.file(f).roi(r),'odor')
                                    if length(avgfile.roi)<r; avgfile.roi(r).avgodor.avgtrial.trials = []; end
                                    for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                        for t = 1:length(plotdata{p}.file(f).roi(1).odor(o).trial)
                                            if isempty(avgfile.roi(r).avgodor.avgtrial.trials)
                                                avgfile.roi(r).avgodor.avgtrial.time = plotdata{p}.file(f).roi(r).odor(o).trial(t).time;
                                                avgfile.roi(r).avgodor.avgtrial.trials(:,1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            else
                                                avgfile.roi(r).avgodor.avgtrial.trials(:,end+1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found
                        for r = 1:length(avgfile.roi)
                            if ~isempty(avgfile.roi(r).avgodor.avgtrial.trials)
                                plotdata{p}.avgfile.roi(r).avgodor.avgtrial.time = avgfile.roi(r).avgodor.avgtrial.time;
                                plotdata{p}.avgfile.roi(r).avgodor.avgtrial.series = mean(avgfile.roi(r).avgodor.avgtrial.trials,2);
                                plotdata{p}.avgfile.roi(r).avgodor.avgtrial.confint(1,:) = plotdata{p}.avgfile.roi(r).avgodor.avgtrial.series + ...
                                    1.96.*std(avgfile.roi(r).avgodor.avgtrial.trials,1,2)./sqrt(size(avgfile.roi(r).avgodor.avgtrial.trials,2));
                                plotdata{p}.avgfile.roi(r).avgodor.avgtrial.confint(2,:) = plotdata{p}.avgfile.roi(r).avgodor.avgtrial.series - ...
                                    1.96.*std(avgfile.roi(r).avgodor.avgtrial.trials,1,2)./sqrt(size(avgfile.roi(r).avgodor.avgtrial.trials,2));
                            end
                        end
                    %% average files/odors, not rois/trials(superimpose)
                    else
                        %gather all the trials for each trialIdx
                        avgfile.roi = [];
                        for f = 1:length(plotdata{p}.file)
                            for r = 1:length(plotdata{p}.file(f).roi)
                                if length(avgfile.roi)<r; avgfile.roi(r).avgodor.trial = []; end
                                if isfield(plotdata{p}.file(f).roi(r),'odor')
                                    for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                        for t = 1:length(plotdata{p}.file(f).roi(1).odor(o).trial)
                                            trialIdx = plotdata{p}.file(f).roi(1).odor(o).trial(t).number;
                                            if length(avgfile.roi(r).avgodor.trial)<trialIdx; avgfile.roi(r).avgodor.trial(trialIdx).trials = []; end
                                            if isempty(avgfile.roi(r).avgodor.trial(trialIdx).trials)
                                                avgfile.roi(r).avgodor.trial(trialIdx).time = plotdata{p}.file(f).roi(r).odor(o).trial(t).time;
                                                avgfile.roi(r).avgodor.trial(trialIdx).trials(:,1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            else
                                                avgfile.roi(r).avgodor.trial(trialIdx).trials(:,end+1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found and toss out empty trialIdx
                        for r = 1:length(avgfile.roi)
                            newtrialIdx = 0;
                            for trialIdx = 1:length(avgfile.roi(r).avgodor.trial)
                                if ~isempty(avgfile.roi(r).avgodor.trial(trialIdx).trials)
                                    newtrialIdx = newtrialIdx+1;
                                    plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).time = avgfile.roi(r).avgodor.trial(trialIdx).time;
                                    plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).number = trialIdx;
                                    plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).series = mean(avgfile.roi(r).avgodor.trial(trialIdx).trials,2);
                                    plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).confint(1,:) = plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).series + ...
                                        1.96.*std(avgfile.roi(r).avgodor.trial(trialIdx).trials,1,2)./sqrt(size(avgfile.roi(r).avgodor.trial(trialIdx).trials,2));
                                    plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).confint(2,:) = plotdata{p}.avgfile.roi(r).avgodor.trial(newtrialIdx).series - ...
                                        1.96.*std(avgfile.roi(r).avgodor.trial(trialIdx).trials,1,2)./sqrt(size(avgfile.roi(r).avgodor.trial(trialIdx).trials,2));
                                end
                            end
                        end
                    end
                %% average files, not rois/odors
                else
                    %% average files/trials, not rois/odors
                    if bavgtrials
                        %gather all the trials for each odor (note: different files may have different odortrials selected)
                        avgfile.roi = [];
                        for f = 1:length(plotdata{p}.file)
                            for r = 1:length(plotdata{p}.file(f).roi)
                                if isfield(plotdata{p}.file(f).roi(r),'odor')
                                    if length(avgfile.roi)<r; avgfile.roi(r).odor = []; end
                                    for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                        odorNum = plotdata{p}.file(f).roi(1).odor(o).number; odorIdx=odorNum+1;
                                        if length(avgfile.roi(r).odor)<odorIdx; avgfile.roi(r).odor(odorIdx).trials = []; end
                                        for t = 1:length(plotdata{p}.file(f).roi(1).odor(o).trial)
                                            if isempty(avgfile.roi(r).odor(odorIdx).trials)
                                                avgfile.roi(r).odor(odorIdx).time = plotdata{p}.file(f).roi(r).odor(o).trial(t).time;
                                                avgfile.roi(r).odor(odorIdx).trials(:,1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            else
                                                avgfile.roi(r).odor(odorIdx).trials(:,end+1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found and toss out empty odorIdx's
                        for r = 1:length(avgfile.roi)
                            newodorIdx = 0;
                            for odorIdx = 1:length(avgfile.roi(r).odor)
                                odorNum = odorIdx-1; %recall that odorIdx=odorNum+1;
                                if ~isempty(avgfile.roi(r).odor(odorIdx).trials)
                                    newodorIdx = newodorIdx+1;
                                    plotdata{p}.avgfile.roi(r).odor(newodorIdx).number = odorNum;
                                    plotdata{p}.avgfile.roi(r).odor(newodorIdx).avgtrial.time = avgfile.roi(r).odor(odorIdx).time;
                                    plotdata{p}.avgfile.roi(r).odor(newodorIdx).avgtrial.series = mean(avgfile.roi(r).odor(odorIdx).trials,2);
                                    plotdata{p}.avgfile.roi(r).odor(newodorIdx).avgtrial.confint(1,:) = plotdata{p}.avgfile.roi(r).odor(newodorIdx).avgtrial.series + ...
                                        1.96.*std(avgfile.roi(r).odor(odorIdx).trials,1,2)./sqrt(size(avgfile.roi(r).odor(odorIdx).trials,2));
                                    plotdata{p}.avgfile.roi(r).odor(newodorIdx).avgtrial.confint(2,:) = plotdata{p}.avgfile.roi(r).odor(newodorIdx).avgtrial.series - ...
                                        1.96.*std(avgfile.roi(r).odor(odorIdx).trials,1,2)./sqrt(size(avgfile.roi(r).odor(odorIdx).trials,2));
                                end
                            end
                        end
                    %% average files, not rois/odors/trials(superimpose)
                    else
                        %gather all the trials foreach odor foreach file
                        avgfile.roi = [];
                        for f = 1:length(plotdata{p}.file)
                            for r = 1:length(plotdata{p}.file(f).roi)
                                trialIdx = zeros(256,1); %current multi-odor system allows 256 odors
                                if length(avgfile.roi)<r; avgfile.roi(r).odor = []; end
                                if isfield(plotdata{p}.file(f).roi(r),'odor')
                                    for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                        if ~isempty(plotdata{p}.file(f).roi(r).odor(o))
                                            odorNum = plotdata{p}.file(f).roi(1).odor(o).number; odorIdx=odorNum+1;
                                            if length(avgfile.roi(r).odor)<odorIdx % keep track of trials for each odor, make list as long as highest odorIdx
                                                trialIdx(odorIdx) = []; avgfile.roi(r).odor(odorIdx).trial = [];
                                            end
                                            for t = 1:length(plotdata{p}.file(f).roi(1).odor(o).trial)
                                                if ~isempty(plotdata{p}.file(f).roi(1).odor(o).trial(t))
                                                    trialIdx(odorIdx) = plotdata{p}.file(f).roi(1).odor(o).trial(t).number;
                                                    if length(avgfile.roi(r).odor(odorIdx).trial)<trialIdx(odorIdx)
                                                        avgfile.roi(r).odor(odorIdx).trial(trialIdx(odorIdx)).trials = [];
                                                    end
                                                    if isempty(avgfile.roi(r).odor(odorIdx).trial(trialIdx(odorIdx)).trials)
                                                        avgfile.roi(r).odor(odorIdx).trial(trialIdx(odorIdx)).time(1,:) = plotdata{p}.file(f).roi(r).odor(o).trial(t).time;
                                                        avgfile.roi(r).odor(odorIdx).trial(trialIdx(odorIdx)).trials(:,1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                                    else
                                                        avgfile.roi(r).odor(odorIdx).trial(trialIdx(odorIdx)).trials(:,end+1) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        %sort through what you found and toss out empty odor#s/trial#s
                        for r = 1:length(avgfile.roi)
                            newodorIdx = 0;
                            for odorIdx = 1:length(avgfile.roi(r).odor)
                                newodorNum=odorIdx-1; %recall odorIdx=odorNum+1
                                %first check to see if this odor has any trials selected?
                                for trialIdx = 1:length(avgfile.roi(r).odor(odorIdx).trial)
                                    if ~isempty(avgfile.roi(r).odor(odorIdx).trial(trialIdx))
                                        newodorIdx=newodorIdx+1;
                                        plotdata{p}.avgfile.roi(r).odor(newodorIdx).number = newodorNum;
                                        newtrialIdx(newodorIdx)= 0; break;
                                    end
                                end
                                % grab ~empty odortrials and average
                                for trialIdx = 1:length(avgfile.roi(r).odor(odorIdx).trial)
                                    if ~isempty(avgfile.roi(r).odor(odorIdx).trial(trialIdx).trials)
                                        newtrialIdx(newodorIdx) = newtrialIdx(newodorIdx)+1;
                                        plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).time = avgfile.roi(r).odor(odorIdx).trial(trialIdx).time;
                                        plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).number = trialIdx;
                                        plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).series = mean(avgfile.roi(r).odor(odorIdx).trial(trialIdx).trials,2);
                                        plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).confint(1,:) = plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).series + ...
                                            1.96.*std(avgfile.roi(r).odor(odorIdx).trial(trialIdx).trials,1,2)./sqrt(size(avgfile.roi(r).odor(odorIdx).trial(trialIdx).trials,2));
                                        plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).confint(2,:) = plotdata{p}.avgfile.roi(r).odor(newodorIdx).trial(newtrialIdx(newodorIdx)).series - ...
                                            1.96.*std(avgfile.roi(r).odor(odorIdx).trial(trialIdx).trials,1,2)./sqrt(size(avgfile.roi(r).odor(odorIdx).trial(trialIdx).trials,2));
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    %% do not average files
    else
        %% average rois, not files
        if get(findobj(tab,'Tag','avgrois'),'Value')
            %% full time series
            if ~bsuperimpose && ~bavgtrials
                %nothing to do, rois are already averaged - everything else
                %in this section involves odortrials - superimposed or averaged
            end
            %% average rois/odors, not files
            if get(findobj(tab,'Tag','avgodors'),'Value')
                %% average rois/odors/trials, not files
                if bavgtrials % rois/odors/trials avg, no files
                    for f = 1:length(plotdata{p}.file)
                        if isfield(plotdata{p}.file(f).avgroi,'odor') %note: different files may have different odortrials selected
                            tt = 0; trials = []; %trials = avgroi.avgodor.avgtrial.trials, tt = total number of trials
                            for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                ntrials = length(plotdata{p}.file(f).avgroi.odor(o).trial);
                                trials(:,tt+1:tt+ntrials) = zeros(length(plotdata{p}.file(f).avgroi.odor(o).trial(1).series),ntrials);
                                for t = 1:ntrials
                                    tt = tt + 1;
                                    trials(:,tt)= plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                end
                            end
                            plotdata{p}.file(f).avgroi.avgodor.avgtrial.time = plotdata{p}.file(f).avgroi.odor(o).trial(1).time;
                            plotdata{p}.file(f).avgroi.avgodor.avgtrial.series =  mean(trials,2);
                            plotdata{p}.file(f).avgroi.avgodor.avgtrial.ntrials = size(trials,2);
                            plotdata{p}.file(f).avgroi.avgodor.avgtrial.confint(1,:) = plotdata{p}.file(f).avgroi.avgodor.avgtrial.series + 1.96.*std(trials,1,2)./sqrt(size(trials,2));
                            plotdata{p}.file(f).avgroi.avgodor.avgtrial.confint(2,:) = plotdata{p}.file(f).avgroi.avgodor.avgtrial.series - 1.96.*std(trials,1,2)./sqrt(size(trials,2));
                        end
                    end
                %% average rois/odors, not files/trials(superimpose)    
                else
                    for f = 1:length(plotdata{p}.file)
                        if isfield(plotdata{p}.file(f).avgroi,'odor') %note: different files may have different odortrials selected
                            numodors = []; trial = []; trialNums = []; %trial = avgroi.avgodor.trial{trialIdx}
                            for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                for t = 1:length(plotdata{p}.file(f).avgroi.odor(o).trial)
                                    trialIdx = plotdata{p}.file(f).avgroi.odor(o).trial(t).number;
                                    if length(numodors)<trialIdx || isempty(trial) || ~max(trialIdx == trialNums)
                                        numodors(trialIdx) = 1; trialNums = [trialNums trialIdx];
                                        plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).number = trialIdx;
                                        plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).time = plotdata{p}.file(f).avgroi.odor(o).trial(t).time;
                                        trial{trialIdx}(:,numodors(trialIdx)) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                    else
                                        numodors(trialIdx) = numodors(trialIdx) + 1;
                                        trial{trialIdx}(:,numodors(trialIdx)) = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                    end
                                end
                            end
                            for trialIdx = 1:length(numodors)
                                plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).series =  mean(trial{trialIdx},2);
                                plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).ntrials = size(trial{trialIdx},2);
                                plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).confint(1,:) = plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).series + 1.96.*std(trial{trialIdx},1,2)./sqrt(numodors(trialIdx));
                                plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).confint(2,:) = plotdata{p}.file(f).avgroi.avgodor.trial(trialIdx).series - 1.96.*std(trial{trialIdx},1,2)./sqrt(numodors(trialIdx));
                            end
                            plotdata{p}.file(f).avgroi.avgodor.trial = plotdata{p}.file(f).avgroi.avgodor.trial(numodors>0); %get rid of any trialIdx's with no odors selected
                        end
                    end
                end
            %% average rois, not files/odors
            else
                %% average rois/trials, not files/odors
                if bavgtrials
                    for f = 1:length(plotdata{p}.file)
                        if isfield(plotdata{p}.file(f).avgroi,'odor') %note: some files may not have odortrials selected
                            for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                ntrials = length(plotdata{p}.file(f).avgroi.odor(o).trial);
                                trials = zeros(length(plotdata{p}.file(f).avgroi.odor(o).trial(1).series),ntrials);
                                for t = 1:ntrials
                                    trials(:,t)= plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                end
                                plotdata{p}.file(f).avgroi.odor(o).avgtrial.time = plotdata{p}.file(f).avgroi.odor(o).trial(1).time;
                                plotdata{p}.file(f).avgroi.odor(o).avgtrial.series =  mean(trials,2);
                                plotdata{p}.file(f).avgroi.odor(o).avgtrial.ntrials = size(trials,2);
                                plotdata{p}.file(f).avgroi.odor(o).avgtrial.confint(1,:) = plotdata{p}.file(f).avgroi.odor(o).avgtrial.series + 1.96.*std(trials,1,2)./sqrt(ntrials);
                                plotdata{p}.file(f).avgroi.odor(o).avgtrial.confint(2,:) = plotdata{p}.file(f).avgroi.odor(o).avgtrial.series - 1.96.*std(trials,1,2)./sqrt(ntrials);
                            end
                        end                   
                    end
                %% average rois, not files/odors/trials(superimpose)
                else
                   % nothing to do here, rois are already averaged
                end
            end
        %% no files/rois averaging
        else
            %% full time series
            if ~bsuperimpose && ~bavgtrials
                % do nothing - everything else in this section involves odortrials - superimposed or averaged
            end
            %% average odors, not files/rois
            if get(findobj(tab,'Tag','avgodors'),'Value')
                %% average odors/trials, not files/rois
                if bavgtrials
                    for f = 1:length(plotdata{p}.file)
                        for r = 1:length(plotdata{p}.file(f).roi)
                            if isfield(plotdata{p}.file(f).roi(r),'odor') %note: some files may not have odortrials selected
                                totaltrials = 0; trials = []; %file(f).roi(r).avgodor.avgtrial
                                for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                    ntrials = length(plotdata{p}.file(f).roi(r).odor(o).trial); %number of trials for this odor
                                    trials(:,totaltrials+1:totaltrials+ntrials) = zeros(length(plotdata{p}.file(f).roi(r).odor(o).trial(1).series),ntrials);
                                    for t = 1:ntrials
                                        totaltrials = totaltrials + 1;
                                        trials(:,totaltrials)= plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                    end
                                end
                                plotdata{p}.file(f).roi(r).avgodor.avgtrial.time = plotdata{p}.file(f).roi(r).odor(o).trial(1).time;
                                plotdata{p}.file(f).roi(r).avgodor.avgtrial.series =  mean(trials,2);
                                plotdata{p}.file(f).roi(r).avgodor.avgtrial.ntrials = size(trials,2);
                                plotdata{p}.file(f).roi(r).avgodor.avgtrial.confint(1,:) = plotdata{p}.file(f).roi(r).avgodor.avgtrial.series + 1.96.*std(trials,1,2)./sqrt(totaltrials);
                                plotdata{p}.file(f).roi(r).avgodor.avgtrial.confint(2,:) = plotdata{p}.file(f).roi(r).avgodor.avgtrial.series - 1.96.*std(trials,1,2)./sqrt(totaltrials);
                            end
                        end
                    end
                %% average odors, not files/rois/trials(superimpose)
                else
                    for f = 1:length(plotdata{p}.file)
                        for r = 1:length(plotdata{p}.file(f).roi)
                            numodors = []; trials = []; trialslist = [];
                            if isfield(plotdata{p}.file(f).roi(r),'odor') %note: some files may not have odortrials selected
                                for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                   for t = 1:length(plotdata{p}.file(f).roi(r).odor(o).trial)
                                       trialIdx = plotdata{p}.file(f).roi(r).odor(o).trial(t).number;
                                       if length(numodors)<trialIdx || isempty(trials) || ~max(trialIdx == trialslist)
                                           numodors(trialIdx) = 1; trialslist = [trialslist trialIdx];
                                           plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).number = trialIdx;
                                           plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).time = plotdata{p}.file(f).roi(r).odor(o).trial(t).time;
                                           trials{trialIdx}(:,numodors(trialIdx)) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                       else
                                           numodors(trialIdx) = numodors(trialIdx) + 1;
                                           trials{trialIdx}(:,numodors(trialIdx)) = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                       end
                                   end
                                end
                                for trialIdx = 1:length(numodors)
                                   plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).series =  mean(trials{trialIdx},2);
                                   plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).ntrials = size(trials{trialIdx},2);
                                   plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).confint(1,:) = plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).series ...
                                       + 1.96.*std(trials{trialIdx},1,2)./sqrt(numodors(trialIdx));
                                   plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).confint(2,:) = plotdata{p}.file(f).roi(r).avgodor.trial(trialIdx).series ...
                                       - 1.96.*std(trials{trialIdx},1,2)./sqrt(numodors(trialIdx));
                                end
                                plotdata{p}.file(f).roi(r).avgodor.trial = plotdata{p}.file(f).roi(r).avgodor.trial(numodors>0);
                            end
                        end
                    end
                end
            %% no files/rois/odors averaging
            else
                %% average trials, not files/rois/odors
                if bavgtrials
                   for f = 1:length(plotdata{p}.file)
                        for r = 1:length(plotdata{p}.file(f).roi)
                            if isfield(plotdata{p}.file(f).roi(r),'odor') %note: some files may not have odortrials selected
                                for o = 1:length(plotdata{p}.file(f).roi(r).odor)
                                    ntrials = length(plotdata{p}.file(f).roi(r).odor(o).trial);
                                    trials = zeros(length(plotdata{p}.file(f).roi(r).odor(o).trial(1).series),ntrials);
                                    for t = 1:ntrials
                                        trials(:,t)= plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                    end
                                    plotdata{p}.file(f).roi(r).odor(o).avgtrial.time = plotdata{p}.file(f).roi(r).odor(o).trial(1).time;
                                    plotdata{p}.file(f).roi(r).odor(o).avgtrial.series =  mean(trials,2);
                                    plotdata{p}.file(f).roi(r).odor(o).avgtrial.ntrials = size(trials,2);
                                    plotdata{p}.file(f).roi(r).odor(o).avgtrial.confint(1,:) = plotdata{p}.file(f).roi(r).odor(o).avgtrial.series + 1.96.*std(trials,1,2)./sqrt(ntrials);
                                    plotdata{p}.file(f).roi(r).odor(o).avgtrial.confint(2,:) = plotdata{p}.file(f).roi(r).odor(o).avgtrial.series - 1.96.*std(trials,1,2)./sqrt(ntrials);
                                end
                            end
                        end                       
                   end
                %% not files/rois/odors/trials(superimpose)
                else
                   %do nothing
                end
            end
        end
    end
    
    % now make the plots
    sortgroup = findobj(tab,'Tag','sortColors');
    sortby = sortgroup.SelectedObject.Tag;
    ymax = -inf;
    ymin = inf;
    Tmax = 0;
    cla(tsax); hold(tsax,'on');
    if get(findobj(tab,'Tag','avgfiles'),'Value')
        if get(findobj(tab,'Tag','byfile'),'Value');tmpcl = myColors(files(1)); tmplabel = 'File Average'; end
        if get(findobj(tab,'Tag','avgrois'),'Value')
            if strcmp(sortby,'byroi'); tmpcl = myColors(rois(1)); tmplabel = 'ROI Average'; end
            if bsuperimpose || bavgtrials
                if get(findobj(tab,'Tag','avgodors'),'Value')
                    if strcmp(sortby,'byodor')
                        tmpcl = myColors(plotdata{p}.file(1).avgroi.odor(1).number);
                        tmplabel = 'Odor Average';
                    end
                    if bavgtrials
                        if strcmp(sortby,'bytrial')
                            tmpcl = myColors(plotdata{p}.file(1).avgroi.odor(1).trial(1).number); tmplabel = 'Trial Average';
                        end
                        time = plotdata{p}.avgfile.avgroi.avgodor.avgtrial.time;
                        ts = plotdata{p}.avgfile.avgroi.avgodor.avgtrial.series;
                        line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                        ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                        if get(findobj(tab,'Tag','confint'),'Value')
                            disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                            ci = plotdata{p}.avgfile.avgroi.avgodor.avgtrial.confint;
                            jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                        end
                    else %superimpose
                        for t = 1:length(plotdata{p}.avgfile.avgroi.avgodor.trial)
                            if strcmp(sortby,'bytrial')
                                tmpcl = myColors(plotdata{p}.avgfile.avgroi.avgodor.trial(t).number);
                                tmplabel = ['Trial' num2str(plotdata{p}.avgfile.avgroi.avgodor.trial(t).number)];
                            end
                            time = plotdata{p}.avgfile.avgroi.avgodor.trial(t).time;
                            ts = plotdata{p}.avgfile.avgroi.avgodor.trial(t).series;
                            line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                            ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                            if get(findobj(tab,'Tag','confint'),'Value')
                                disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                                ci = plotdata{p}.avgfile.avgroi.avgodor.trial(t).confint;
                                jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                            end
                        end
                    end
                else
                    for o = 1:length(plotdata{p}.avgfile.avgroi.odor) %selected odors
                        if strcmp(sortby,'byodor')
                            tmpcl = myColors(plotdata{p}.avgfile.avgroi.odor(o).number);
                            tmplabel = ['Odor' num2str(plotdata{p}.avgfile.avgroi.odor(o).number)];
                        end
                        if bavgtrials
                            if strcmp(sortby,'bytrial'); tmpcl = myColors(t); tmplabel = 'Trial Average'; end
                            time = plotdata{p}.avgfile.avgroi.odor(o).avgtrial.time;
                            ts = plotdata{p}.avgfile.avgroi.odor(o).avgtrial.series;
                            line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                            ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                            if get(findobj(tab,'Tag','confint'),'Value')
                                disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                                ci = plotdata{p}.avgfile.avgroi.odor(o).avgtrial.confint;
                                jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                            end
                        else %superimpose
                            for t = 1:length(plotdata{p}.avgfile.avgroi.odor(o).trial)
                                if strcmp(sortby,'bytrial'); tmpcl = myColors(t); tmplabel = ['Trial' num2str(t)]; end
                                time = plotdata{p}.avgfile.avgroi.odor(o).trial(t).time;
                                ts = plotdata{p}.avgfile.avgroi.odor(o).trial(t).series;
                                line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                if get(findobj(tab,'Tag','confint'),'Value')
                                    disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                                    ci = plotdata{p}.avgfile.avgroi.odor(o).trial(t).confint;
                                    jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                end
                            end
                        end
                    end                    
                end
            else %full time series - File & ROI averaging
                time = plotdata{p}.avgfile.avgroi.time;
                ts = plotdata{p}.avgfile.avgroi.series;
                line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                if get(findobj(tab,'Tag','confint'),'Value')
                    disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                    ci = plotdata{p}.avgfile.avgroi.confint;
                    jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                end
            end
        else %avg files, not rois
            for r = 1:length(rois)
                if strcmp(sortby,'byroi'); tmpcl = myColors(rois(r)); tmplabel = ['ROI #' num2str(rois(r))]; end
                if bsuperimpose || bavgtrials
                    if get(findobj(tab,'Tag','avgodors'),'Value')
                        if strcmp(sortby,'byodor')
                            tmpcl = myColors(plotdata{p}.file(1).roi(1).odor(1).number);
                            tmplabel = 'Odor Average';
                        end
                        if bavgtrials
                            time = plotdata{p}.avgfile.roi(r).avgodor.avgtrial.time;
                            ts = plotdata{p}.avgfile.roi(r).avgodor.avgtrial.series;
                            line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                            ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                            if get(findobj(tab,'Tag','confint'),'Value')
                                ci = plotdata{p}.avgfile.roi(r).avgodor.avgtrial.confint;
                                jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                            end
                        else
                            for t = 1:length(plotdata{p}.avgfile.roi(r).avgodor.trial)
                                if strcmp(sortby,'bytrial')
                                    tmpcl = myColors(plotdata{p}.avgfile.roi(r).avgodor.trial(t).number);
                                    tmplabel = ['Trial' num2str(plotdata{p}.avgfile.roi(r).avgodor.trial(t).number)];
                                end
                                time = plotdata{p}.avgfile.roi(r).avgodor.trial(t).time;
                                ts = plotdata{p}.avgfile.roi(r).avgodor.trial(t).series;
                                line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                if get(findobj(tab,'Tag','confint'),'Value')
                                    ci = plotdata{p}.avgfile.roi(r).avgodor.trial(t).confint;
                                    jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                end
                            end
                        end
                    else %not avgodor
                        if isfield(plotdata{p}.avgfile.roi(r),'odor')
                            if bavgtrials
                                for o = 1:length(plotdata{p}.avgfile.roi(r).odor)
                                    if strcmp(sortby,'byodor')
                                        tmpcl = myColors(plotdata{p}.avgfile.roi(r).odor(o).number);
                                        tmplabel = ['Odor' num2str(plotdata{p}.avgfile.roi(r).odor(o).number)];
                                    end
                                    time = plotdata{p}.avgfile.roi(r).odor(o).avgtrial.time;
                                    ts = plotdata{p}.avgfile.roi(r).odor(o).avgtrial.series;
                                    line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                    ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                    if get(findobj(tab,'Tag','confint'),'Value')
                                        ci = plotdata{p}.avgfile.roi(r).odor(o).avgtrial.confint;
                                        jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                    end
                                end
                            else %superimpose, avg files
                                for o = 1:length(plotdata{p}.avgfile.roi(r).odor) %selected odors
                                    if strcmp(sortby,'byodor')
                                        tmpcl = myColors(plotdata{p}.avgfile.roi(r).odor(o).number);
                                        tmplabel = ['Odor' num2str(plotdata{p}.avgfile.roi(r).odor(o).number)];
                                    end
                                    for t = 1:length(plotdata{p}.avgfile.roi(r).odor(o).trial)
                                        if strcmp(sortby,'bytrial')
                                            tmpcl = myColors(plotdata{p}.avgfile.roi(r).odor(o).trial(t).number);
                                            tmplabel = ['Trial' num2str(plotdata{p}.avgfile.roi(r).odor(o).trial(t).number)];
                                        end
                                        time = plotdata{p}.avgfile.roi(r).odor(o).trial(t).time;
                                        ts = plotdata{p}.avgfile.roi(r).odor(o).trial(t).series;
                                        line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                        ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                        if get(findobj(tab,'Tag','confint'),'Value')
                                            ci = plotdata{p}.avgfile.roi(r).odor(o).trial(t).confint;
                                            jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                        end
                                    end
                                end
                            end
                        end
                    end
                else %full time series, avg files
                    time = plotdata{p}.avgfile.roi(r).time;
                    ts = plotdata{p}.avgfile.roi(r).series;
                    line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                    ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                    if get(findobj(tab,'Tag','confint'),'Value')
                        ci = plotdata{p}.avgfile.roi(r).confint;
                        jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                    end
                end
            end
        end
    else %no file averaging
        for f = 1:length(plotdata{p}.file)
            if strcmp(sortby,'byfile'); tmpcl = myColors(files(f)); tmplabel = plotdata{p}.file(f).name; end
            if get(findobj(tab,'Tag','avgrois'),'Value')
                if strcmp(sortby,'byroi'); tmpcl = myColors(rois(1)); tmplabel = 'ROI Average'; end
                if bsuperimpose || bavgtrials
                    if isfield(plotdata{p}.file(f).avgroi,'odor')
                        if get(findobj(tab,'Tag','avgodors'),'Value')
                            if strcmp(sortby,'byodor')
                                tmpcl = myColors(plotdata{p}.file(f).avgroi.odor(1).number);
                                tmplabel = 'Odor Average';
                            end
                            if bavgtrials
                                if strcmp(sortby,'bytrial')
                                    tmpcl = myColors(plotdata{p}.file(f).avgroi.odor(1).trial(1).number);
                                    tmplabel = 'Trial Average';
                                end
                                time = plotdata{p}.file(f).avgroi.avgodor.avgtrial.time;
                                ts = plotdata{p}.file(f).avgroi.avgodor.avgtrial.series;
                                line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                if get(findobj(tab,'Tag','confint'),'Value')
                                    disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                                    ci = plotdata{p}.file(f).avgroi.avgodor.avgtrial.confint;
                                    jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                end
                            else %avg rois,odors - superimpose
                                for t = 1:length(plotdata{p}.file(f).avgroi.avgodor.trial)
                                    if strcmp(sortby,'bytrial')
                                        tmpcl = myColors(plotdata{p}.file(f).avgroi.avgodor.trial(t).number);
                                        tmplabel = ['Trial' num2str(plotdata{p}.file(f).avgroi.avgodor.trial(t).number)];
                                    end
                                    time = plotdata{p}.file(f).avgroi.avgodor.trial(t).time;
                                    ts = plotdata{p}.file(f).avgroi.avgodor.trial(t).series;
                                    line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                    ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                    if get(findobj(tab,'Tag','confint'),'Value')
                                        disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                                        ci = plotdata{p}.file(f).avgroi.avgodor.trial(t).confint;
                                        jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                    end
                                end
                            end
                        else % avg rois, not odors
                            if bavgtrials
                                for o = 1:length(plotdata{p}.file(f).avgroi.odor)
                                    if strcmp(sortby,'byodor')
                                        tmpcl = myColors(plotdata{p}.file(f).avgroi.odor(o).number);
                                        tmplabel = ['Odor' num2str(plotdata{p}.file(f).avgroi.odor(o).number)];
                                    end
                                    %if strcmp(sortby,'bytrial'); tmpcl = myColors(1); tmplabel = 'Average Trial'; end
                                    time = plotdata{p}.file(f).avgroi.odor(o).avgtrial.time;
                                    ts = plotdata{p}.file(f).avgroi.odor(o).avgtrial.series;
                                    line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                    ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                    if get(findobj(tab,'Tag','confint'),'Value')
                                        disp('FYI: Confidence Intervals do not take into account roi averaging');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
                                        ci = plotdata{p}.file(f).avgroi.odor(o).avgtrial.confint;
                                        jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                    end
                                end                        
                            else %superimpose, avg rois
                                for o = 1:length(plotdata{p}.file(f).avgroi.odor) %selected odors
                                    if strcmp(sortby,'byodor')
                                        tmpcl = myColors(plotdata{p}.file(f).avgroi.odor(o).number);
                                        tmplabel = ['Odor' num2str(plotdata{p}.file(f).avgroi.odor(o).number)];
                                    end
                                    for t = 1:length(plotdata{p}.file(f).avgroi.odor(o).trial)
                                        if strcmp(sortby,'bytrial')
                                            tmpcl = myColors(plotdata{p}.file(f).avgroi.odor(o).trial(t).number);
                                            tmplabel = ['Trial' num2str(plotdata{p}.file(f).avgroi.odor(o).trial(t).number)];
                                        end
                                        time = plotdata{p}.file(f).avgroi.odor(o).trial(t).time;
                                        ts = plotdata{p}.file(f).avgroi.odor(o).trial(t).series;
                                        line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                        ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                        if get(findobj(tab,'Tag','confint'),'Value')
                                            disp('FYI: Confidence Intervals are not computed for this case');
% confidence intervals are not computed/shown for "average ROIs", since it is equivalent to just enlarging/combining regions
%                                             ci = plotdata{p}.file(f).avgroi.odor(o).trial(t).confint;
%                                             jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                        end
                                    end
                                end
                            end
                        end
                    end
                else %full time series - ROI averaging
                    time = plotdata{p}.file(f).avgroi.time;
                    ts = plotdata{p}.file(f).avgroi.series;
                    line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                    ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                    %not showing avgroi confidence intervals here to avoid confusion - tcr
%                     if get(findobj(tab,'Tag','confint'),'Value') && isfield(plotdata{p}.file(f).avgroi,'confint')
%                         ci = plotdata{p}.file(f).avgroi.confint;
%                         jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
%                     end
                end
            else %no file/roi averaging
                for r = 1:length(plotdata{p}.file(f).roi)
                    if strcmp(sortby,'byroi'); tmpcl = myColors(rois(r)); tmplabel = ['ROI #' num2str(plotdata{p}.file(f).roi(r).number)]; end
                    if bsuperimpose || bavgtrials
                        if isfield(plotdata{p}.file(f).roi(r),'odor')
                            if get(findobj(tab,'Tag','avgodors'),'Value')
                                if strcmp(sortby,'byodor'); tmpcl = myColors(plotdata{p}.file(f).roi(r).odor(1).number); tmplabel = 'Odor Average'; end
                                %if strcmp(sortby,'byodor'); tmpcl = myColors(filenum(f).odors(1)); tmplabel = 'Odor Average'; end
                                if bavgtrials
                                    if strcmp(sortby,'bytrial'); tmpcl = myColors(plotdata{p}.file(f).roi(r).odor(1).trial(1).number); tmplabel = 'Trial Average'; end
                                    time = plotdata{p}.file(f).roi(r).avgodor.avgtrial.time;
                                    ts = plotdata{p}.file(f).roi(r).avgodor.avgtrial.series;
                                    line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                    ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                    if get(findobj(tab,'Tag','confint'),'Value') && isfield(plotdata{p}.file(f).roi(r).avgodor.avgtrial,'confint')
                                        ci = plotdata{p}.file(f).roi(r).avgodor.avgtrial.confint;
                                        jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                    end
                                else %odor average only
                                    for t = 1:length(plotdata{p}.file(f).roi(r).avgodor.trial)
                                        if strcmp(sortby,'bytrial')
                                            tmpcl = myColors(plotdata{p}.file(f).roi(r).avgodor.trial(t).number);
                                            tmplabel = ['Trial' num2str(plotdata{p}.file(f).roi(r).avgodor.trial(t).number)];
                                        end
                                        if ~isempty(plotdata{p}.file(f).roi(r).avgodor.trial(t))
                                            time = plotdata{p}.file(f).roi(r).avgodor.trial(t).time;
                                            ts = plotdata{p}.file(f).roi(r).avgodor.trial(t).series;
                                            line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                            ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                            if get(findobj(tab,'Tag','confint'),'Value') && isfield(plotdata{p}.file(f).roi(r).avgodor.trial(t),'confint')
                                                ci = plotdata{p}.file(f).roi(r).avgodor.trial(t).confint;
                                                jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                            end                                            
                                        end
                                    end
                                end
                            else %no file/roi/odor averaging
                                if bavgtrials
                                    for o = 1:length(plotdata{p}.file(f).roi(r).odor) %selected odors
                                        if strcmp(sortby,'byodor')
                                            tmpcl = myColors(plotdata{p}.file(f).roi(r).odor(o).number);
                                            tmplabel = ['Odor' num2str(plotdata{p}.file(f).roi(r).odor(o).number)];
                                        end
                                        if strcmp(sortby,'bytrial'); tmpcl = myColors(plotdata{p}.file(f).roi(r).odor(o).trial(1).number); tmplabel = 'Trial Average'; end
                                        time = plotdata{p}.file(f).roi(r).odor(o).avgtrial.time;
                                        ts = plotdata{p}.file(f).roi(r).odor(o).avgtrial.series;
                                        line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                        ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                        if get(findobj(tab,'Tag','confint'),'Value') && isfield(plotdata{p}.file(f).roi(r).odor(o).avgtrial,'confint')
                                            ci = plotdata{p}.file(f).roi(r).odor(o).avgtrial.confint;
                                            jbfill(time, ci(1,:), ci(2,:), tmpcl, [1 1 1], 1, 0.2);
                                        end
                                    end
                                else %just superimpose, w/no file/roi/odor/trials averaging
                                    for o = 1:length(plotdata{p}.file(f).roi(r).odor) %selected odors
                                        if strcmp(sortby,'byodor')
                                            tmpcl = myColors(plotdata{p}.file(f).roi(r).odor(o).number);
                                            tmplabel = ['Odor' num2str(plotdata{p}.file(f).roi(r).odor(o).number)];
                                        end
                                        for t = 1:length(plotdata{p}.file(f).roi(r).odor(o).trial)
                                            if strcmp(sortby,'bytrial')
                                                tmpcl = myColors(plotdata{p}.file(f).roi(r).odor(o).trial(t).number);
                                                tmplabel = ['Trial' num2str(plotdata{p}.file(f).roi(r).odor(o).trial(t).number)];
                                            end
                                            time = plotdata{p}.file(f).roi(r).odor(o).trial(t).time;
                                            ts = plotdata{p}.file(f).roi(r).odor(o).trial(t).series;
                                            line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                                            ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                                        end
                                    end
                                end
                            end
                        end
                    else %just full time series - no averaging
                        time = plotdata{p}.file(f).roi(r).time;
                        ts = plotdata{p}.file(f).roi(r).series;
                        line(tsax, time, ts, 'Color', tmpcl, 'LineWidth', 2, 'DisplayName', tmplabel);
                        ymin = min(ymin, min(ts)); ymax = max(ymax, max(ts)); Tmax = max(Tmax,time(end));
                    end
                end
            end
        end
    end

    % Get Time Limits, or use time:0 to end
    if get(findobj(tab,'Tag','Tlims'),'Value')
        if isempty(get(findobj(tab,'Tag','Tmin'),'String')); set(findobj(tab,'Tag','Tmin'),'String','0'); end
        if isempty(get(findobj(tab,'Tag','Tmax'),'String')); set(findobj(tab,'Tag','Tmax'),'String','end'); end
        t1 = str2double(get(findobj(tab,'Tag','Tmin'), 'String'));
        t2 = get(findobj(tab,'Tag','Tmax'), 'String');
        if strcmp(t2,'end')
            t2 = Tmax; set(findobj(tab,'Tag','Tmax'), 'String',num2str(t2))
        else
            t2 = str2double(t2);
        end
    else
        t1 = 0;
        t2 = Tmax;
    end

    %make it pretty
    set(tsax, 'Xgrid', 'On', 'Xtickmode', 'Auto');

    % Limit Ymin/Ymax option
    if get(findobj(tab,'Tag','Ylims'),'Value')
        if isempty(get(findobj(tab,'Tag','Ymin'),'String')); set(findobj(tab,'Tag','Ymin'),'String',num2str(ymin,3)); end
        if isempty(get(findobj(tab,'Tag','Ymax'),'String')); set(findobj(tab,'Tag','Ymax'),'String',num2str(ymax,3)); end
        ymin = str2double(get(findobj(tab,'Tag','Ymin'), 'String'));
        ymax = str2double(get(findobj(tab,'Tag','Ymax'), 'String'));
    else
        set(findobj(tab,'Tag','Ymin'),'String',sprintf('%5.2f',ymin)); set(findobj(tab,'Tag','Ymax'),'String',sprintf('%5.2f',ymax));
    end
    legendlines = numel(findobj(tsax,'type','line'));
    
    % show aux or manually defined stimulus
    tshift = 0.0;
    if get(findobj(tab,'Tag','stimselect'),'Value')==2 && ~get(findobj(tab,'Tag','hidestim'),'Value')
        if bsuperimpose || bavgtrials || length(files)>2 % plot 1 stimulus
            stim = plotdata{p}.file(1).aux1;
            for i=2:length(stim.signal) %skip first frame in case signal is on at scan start
                if stim.signal(i)>0 && stim.signal(i-1)==0
                    tOn=stim.times(i); break;
                end
            end
            tshift = tOn-str2double(get(findobj(tab,'Tag','prestim'),'String'));
            aux1stim = normalizeStimulus(plotdata{p}.file(1).aux1.signal,ymin,ymax);
            tmpLine = line(plotdata{p}.file(1).aux1.times-tshift,aux1stim,'Color',['red' .5]);
            tmpPlot = area(plotdata{p}.file(1).aux1.times-tshift, aux1stim, 'EdgeColor',[0.5 0.5 0.5],...
                'FaceColor', 'red','FaceAlpha',.5,'Basevalue', ymin);
            uistack([tmpLine tmpPlot],'bottom');
        else %plot all file stimuli
            for nn = 1:length(files) %note: this assumes all the files have aux stimulus
                aux1stim{nn} = normalizeStimulus(plotdata{p}.file(nn).aux1.signal,ymin,ymax);
            end
            for f = 1:length(files)
                if bsuperimpose || bavgtrials
                    stim = plotdata{p}.file(f).aux1;
                    for i=2:length(stim.signal) %skip first frame in case signal is on at scan start
                        if stim.signal(i)>0 && stim.signal(i-1)==0
                            tOn=stim.times(i); break;
                        end
                    end
                    tshift = tOn-str2double(get(findobj(tab,'Tag','prestim'),'String'));
                end
                if strcmp(sortby,'byfile')
                    tmpLine = line(plotdata{p}.file(f).aux1.times-tshift,aux1stim{f},'Color',[myColors(files(f)) .5]);
                    tmpPlot = area(plotdata{p}.file(f).aux1.times-tshift, aux1stim{f}, 'EdgeColor',[0.5 0.5 0.5],...
                        'FaceColor', myColors(files(f)),'FaceAlpha',.5,'Basevalue', ymin);
                else
                    tmpLine = line(plotdata{p}.file(f).aux1.times-tshift,aux1stim{f},'Color',['red' .5]);
                    tmpPlot = area(plotdata{p}.file(f).aux1.times-tshift, aux1stim{f}, 'EdgeColor',[0.5 0.5 0.5],...
                        'FaceColor', 'red','FaceAlpha',.5,'Basevalue', ymin);
                end
                uistack([tmpLine,tmpPlot],'bottom');
            end
        end
    end
    if get(findobj(tab,'Tag','stimselect'),'Value')==3 && ~get(findobj(tab,'Tag','hidestim'),'Value')
        for nn = 1:length(files)
            aux2stim{nn} = normalizeStimulus(plotdata{p}.file(nn).aux2.signal,ymin,ymax);
        end
        for f = 1:length(files)
            if bsuperimpose || bavgtrials
                stim = plotdata{p}.file(f).aux2;
                for i=2:length(stim.signal) %skip first frame in case signal is on at scan start
                    if stim.signal(i)==1 && stim.signal(i-1)==0
                        tOn=stim.times(i); break;
                    end
                end
                tshift = tOn-str2double(get(findobj(tab,'Tag','prestim'),'String'));
            end
            if strcmp(sortby,'byfile')
                tmpLine = line(plotdata{p}.file(f).aux2.times-tshift,aux2stim{f},'Color',[myColors(files(f)) .5]);
            else
                tmpLine = line(plotdata{p}.file(f).aux2.times-tshift,aux2stim{f},'Color',['green' .5]);
            end
            uistack(tmpLine,'bottom');
        end
    end
    if get(findobj(tab,'Tag','stimselect'),'Value')==4 && ~get(findobj(tab,'Tag','hidestim'),'Value')
        for nn = 1:length(files) %note: this assumes all the files have aux stimulus
            aux_combo{nn} = normalizeStimulus(plotdata{p}.file(nn).aux_combo.signal,ymin,ymax);
        end           
        for f = 1:length(files)
            if bsuperimpose || bavgtrials
                stim = plotdata{p}.file(f).aux_combo;
                for i=2:length(stim.signal) %skip first frame in case signal is on at scan start
                    if stim.signal(i)==1 && stim.signal(i-1)==0
                        tOn=stim.times(i); break;
                    end
                end
                tshift = tOn-str2double(get(findobj(tab,'Tag','prestim'),'String'));
            end
            if strcmp(sortby,'byfile')
                tmpLine = line(plotdata{p}.file(f).aux_combo.times-tshift, aux_combo{f}, 'Color',[myColors(files(f)) .5]);
            else
                tmpLine = line(plotdata{p}.file(f).aux_combo.times-tshift, aux_combo{f}, 'Color',['magenta' .5]);
            end
            uistack(tmpLine,'bottom');
        end
    end
    if get(findobj(tab,'Tag','stimselect'),'Value')==5 && ~get(findobj(tab,'Tag','hidestim'),'Value')
        newstimulus = normalizeStimulus(plotdata{p}.def_stimulus.signal,ymin,ymax);
        if bsuperimpose || bavgtrials
            tshift = plotdata{p}.def_stimulus.delay-str2double(get(findobj(tab,'Tag','prestim'),'String'));
        end
        if verLessThan('Matlab','8.6')
            stimAreaPlot = area(plotdata{p}.def_stimulus.times-tshift, newstimulus, 'FaceColor', [.9 .9 .9],...
                'Basevalue', ymin);
        else
            stimAreaPlot = area(plotdata{p}.def_stimulus.times-tshift, newstimulus, 'FaceColor', 'blue',...
                'FaceAlpha',.5,'Basevalue', ymin);
        end
        uistack(stimAreaPlot,'bottom');
    end
    %show Ephys signals
    otherlines = 0;
    if strcmp(get(findobj(tab,'Tag','ephys'),'Visible'), 'on') &&  min(get(findobj(tab,'Tag','ephys'),'Value'))>1 ...
            && ~get(findobj(tab,'Tag','hidestim'),'Value')
        %go through entire loop as above
        for nn = 1:length(plotdata{p}.file)
            if bsuperimpose || bavgtrials
                if isfield(plotdata{p}.file(nn).roi(1),'odor')
                    for oo = 1:length(plotdata{p}.file(nn).roi(1).odor)
                        for tt = 1:length(plotdata{p}.file(nn).roi(1).odor(oo).trial)
                            if ismember(2,get(findobj(tab,'Tag','ephys'),'Value')) %plot ephys odor
                                otherlines = otherlines+1;
                                ephystimes = plotdata{p}.file(nn).ephys.odors(oo).trials(tt).times;
                                ephysodor = normalizeStimulus(plotdata{p}.file(nn).ephys.odors(oo).trials(tt).odor,ymin-0.25*(ymax-ymin),ymin);
                                line(ephystimes,ephysodor,'LineStyle','--','Color','black');
                            end
                            if ismember(3,get(findobj(tab,'Tag','ephys'),'Value')) %plot ephys sniff
                                otherlines = otherlines+1;
                                ephystimes = plotdata{p}.file(nn).ephys.odors(oo).trials(tt).times;
                                ephyssniff = normalizeStimulus(plotdata{p}.file(nn).ephys.odors(oo).trials(tt).sniff,ymin-0.25*(ymax-ymin),ymin);
                                line(ephystimes,ephyssniff,'LineStyle','-','Color','black');
                            end
                            if ismember(4,get(findobj(tab,'Tag','ephys'),'Value')) %plot ephys puff
                                otherlines = otherlines+1;
                                ephystimes = plotdata{p}.file(nn).ephys.odors(oo).trials(tt).times;
                                %tcr - need to work on this puff is +-5volts, some trials are just noise
                                ephyspuff = normalizeStimulus(plotdata{p}.file(nn).ephys.odors(oo).trials(tt).puff,ymin-0.25*(ymax-ymin),ymin);
                                line(ephystimes,ephyspuff,'LineStyle','-','Color','magenta');
                            end
                        end
                    end
                end
            else %full length trials
                if ismember(2,get(findobj(tab,'Tag','ephys'),'Value')) %plot ephys odor
                    otherlines = otherlines+1;
                    ephystimes = plotdata{p}.file(nn).ephys.times;
                    ephysodor = normalizeStimulus(plotdata{p}.file(nn).ephys.odor,ymin-0.25*(ymax-ymin),ymin);
                    line(ephystimes,ephysodor,'LineStyle','--','Color','black');
                end
                if ismember(3,get(findobj(tab,'Tag','ephys'),'Value')) %plot ephys sniff
                    otherlines = otherlines+1;
                    ephystimes = plotdata{p}.file(nn).ephys.times;
                    ephyssniff = normalizeStimulus(plotdata{p}.file(nn).ephys.sniff,ymin-0.25*(ymax-ymin),ymin);
                    line(ephystimes,ephyssniff,'LineStyle','-','Color','black');
                end
                if ismember(4,get(findobj(tab,'Tag','ephys'),'Value')) %plot ephys puff
                    otherlines = otherlines+1;
                    ephystimes = plotdata{p}.file(nn).ephys.times;
                    ephyspuff = normalizeStimulus(plotdata{p}.file(nn).ephys.puff,ymin-0.25*(ymax-ymin),ymin);
                    line(ephystimes,ephyspuff,'LineStyle','-','Color','magenta');
                end
            end
        end
    end
    
    if ymin==inf; fprintf('Undefined values in TimeSeries plot\n');return; end
    if ymax==ymin; ymax=ymin+1; end
    set(tsax,'YLim',[ymin ymax]);
    %resize for Ephys signals
    if strcmp(get(findobj(tab,'Tag','ephys'),'Visible'), 'on') && min(get(findobj(tab,'Tag','ephys'),'Value'))>1 ...
            && ~get(findobj(tab,'Tag','hidestim'),'Value')
        set(tsax,'YLim',[ymin-0.25*(ymax-ymin) ymax]);
    end
    if t1 == 0
        set(tsax,'XLim',[t1 t2+1/(plotdata{p}.file(1).frameRate*2)]); %tcrtcrtcr
    else
        set(tsax,'XLim',[t1-1/(plotdata{p}.file(1).frameRate*2) t2+1/(plotdata{p}.file(1).frameRate*2)]);%tcrtcrtcr
    end
    xlabel(tsax,'Time (sec)', 'FontSize', 12);
    lines = findobj(tsax,'type','line'); lines = lines(otherlines+1:otherlines+legendlines); %used later for legend
    % show mean change
    basestart = str2double(get(findobj(tab,'Tag','basestart'),'String'));
    basedur = str2double(get(findobj(tab,'Tag','basedur'),'String'));
    if basestart > tsax.XLim(2)-basedur; basestart = tsax.XLim(2)-basedur; end
    if basestart < tsax.XLim(1); basestart = tsax.XLim(1); end
    set(findobj(tab,'Tag','basestart'),'String',num2str(basestart));
    set(findobj(tab,'Tag','baseslider'),'Min',tsax.XLim(1));
    if basedur <0; basedur = 0;
    elseif basedur > tsax.XLim(2)-tsax.XLim(1); basedur = tsax.XLim(2)-tsax.XLim(1);
    end
    set(findobj(tab,'Tag','basedur'),'String',num2str(basedur));
    if get(findobj(tab,'Tag','baseslider'),'Value') < tsax.XLim(1)
        set(findobj(tab,'Tag','baseslider'),'Value',tsax.XLim(1));
    elseif get(findobj(tab,'Tag','baseslider'),'Value') > tsax.XLim(2)-basedur
        set(findobj(tab,'Tag','baseslider'),'Value',tsax.XLim(2)-basedur);
    else
        set(findobj(tab,'Tag','baseslider'),'Value',basestart);
    end
    if tsax.XLim(2)-basedur > 0
        set(findobj(tab,'Tag','baseslider'),'Max',tsax.XLim(2)-basedur);
    else
        set(findobj(tab,'Tag','baseslider'),'Max',1);
    end
    steps = length(find(lines(1).XData<tsax.XLim(2)-basedur))-1;
    if steps<10, steps = 10; end
    set(findobj(tab,'Tag','baseslider'),'SliderStep',[1/steps 10/steps]);
    %change slider
    respstart = str2double(get(findobj(tab,'Tag','respstart'),'String'));
    respdur = str2double(get(findobj(tab,'Tag','respdur'),'String'));
    if respstart > tsax.XLim(2)-respdur; respstart = tsax.XLim(2)-respdur; end
    if respstart < tsax.XLim(1); respstart = tsax.XLim(1); end
    set(findobj(tab,'Tag','respstart'),'String',num2str(respstart));
    set(findobj(tab,'Tag','changeslider'),'Min',tsax.XLim(1));
    if respdur<0; respdur = 0;
    elseif respdur > tsax.XLim(2)-tsax.XLim(1); respdur = tsax.XLim(2)-tsax.XLim(1);
    end
    set(findobj(tab,'Tag','respdur'),'String',num2str(respdur));
    if get(findobj(tab,'Tag','changeslider'),'Value') < tsax.XLim(1)
        set(findobj(tab,'Tag','changeslider'),'Value',tsax.XLim(1));
    elseif get(findobj(tab,'Tag','changeslider'),'Value') > tsax.XLim(2)-respdur
        set(findobj(tab,'Tag','changeslider'),'Value',tsax.XLim(2)-respdur);
    else
        set(findobj(tab,'Tag','changeslider'),'Value',respstart);
    end
    if tsax.XLim(2)-respdur > 0
        set(findobj(tab,'Tag','changeslider'),'Max',tsax.XLim(2)-respdur);
    else
        set(findobj(tab,'Tag','changeslider'),'Max',1);
    end
    steps = length(find(lines(1).XData<tsax.XLim(2)-respdur));
    if steps<10, steps = 10; end
    set(findobj(tab,'Tag','changeslider'),'SliderStep',[1/steps 10/steps]);
    if get(findobj(tab,'Tag','showchange'),'Value')
        baseregion.time = 0:1/plotdata{p}.file(1).frameRate:tsax.XLim(2);
        baseregion.series(1:length(baseregion.time)) = ymax;
        baseregion.series(baseregion.time<basestart) = ymin;
        baseregion.series(baseregion.time>basestart+basedur) = ymin;
        %plot regions & show values
        if verLessThan('Matlab','8.6')
            baseRegionPlot = area(baseregion.time, baseregion.series, 'FaceColor', [.8 .8 .8], 'Basevalue', ymin);
        else
            baseRegionPlot = area(baseregion.time, baseregion.series, 'FaceColor', 'yellow', 'FaceAlpha',.5,'Basevalue', ymin);
        end
        uistack(baseRegionPlot,'bottom');
        changeregion.time = 0:1/plotdata{p}.file(1).frameRate:tsax.XLim(2);
        changeregion.series(1:length(changeregion.time)) = ymax;
        changeregion.series(changeregion.time<respstart) = ymin;
        changeregion.series(changeregion.time>respstart+respdur) = ymin;
        %plot regions & show values
        if verLessThan('Matlab','8.6')
            changeRegionPlot = area(changeregion.time, changeregion.series, 'FaceColor', [.4 .4 .4], 'Basevalue', ymin);
        else
            changeRegionPlot = area(changeregion.time, changeregion.series, 'FaceColor', 'green', 'FaceAlpha',.5,'Basevalue', ymin);
        end
        uistack(changeRegionPlot,'bottom');
        for l = 1:length(lines)
            b_ind1 = find(lines(l).XData>=basestart,1,'first');
            b_ind2 = find(lines(l).XData>(basestart+basedur),1,'first');
            basemean = mean(lines(l).YData(b_ind1:b_ind2));
            ch_ind1 = find(lines(l).XData>=respstart,1,'first');
            ch_ind2 = find(lines(l).XData>(respstart+respdur),1,'first');
            respmean = mean(lines(l).YData(ch_ind1:ch_ind2));
            if get(findobj(tab,'Tag','deltaf'),'Value') || get(findobj(tab,'Tag','deltafoverf'),'Value')
                text((respstart+respdur),respmean-basemean,num2str(respmean-basemean));
            else
                text((basestart+basedur),basemean,num2str(basemean));
                text((respstart+respdur),respmean,num2str(respmean));
            end
        end
    end
    % Legend
    leg = legend(flip(lines)); %leg = legend('show');
    leg.Interpreter ='none'; %helps with underscore in file names
    hTS.UserData.plotdata{p} = plotdata{p};
end

function outstim = normalizeStimulus(instim,ymin,ymax) %normalize stimulus signal to plot window ymin/ymax
    if (max(instim)-min(instim)) <= 0 %div by zero situation, stimulus is likely all zeros
        outstim = instim+ymin;
    else
        outstim = ymin + (instim - min(instim))*(ymax-ymin)/(max(instim)-min(instim));
    end
end

function CBplotLimits(~,~)
    tab = htabgroup.SelectedTab;
    if get(findobj(tab,'Tag','Tlims'),'Value')
        set(findobj(tab,'Tag','Tmin'),'Enable','on')
        set(findobj(tab,'Tag','Tmax'),'Enable','on')
    else
        set(findobj(tab,'Tag','Tmin'),'Enable','off')
        set(findobj(tab,'Tag','Tmax'),'Enable','off')
    end
    if get(findobj(tab,'Tag','Ylims'),'Value')
        set(findobj(tab,'Tag','Ymin'),'Enable','on')
        set(findobj(tab,'Tag','Ymax'),'Enable','on')
    else
        set(findobj(tab,'Tag','Ymin'),'Enable','off')
        set(findobj(tab,'Tag','Ymax'),'Enable','off')
    end
    CBSelectAndSortColors;
end

function CBsaveFigure(~,~) %Save current figure
    tab = htabgroup.SelectedTab;
    files = get(findobj(tab,'Tag','FILE_listbox'), 'Value');
    tmpdir = TSdata.file(files(1)).dir;
    if ~exist(tmpdir, 'dir'); tmpdir = ''; end %just in case tmpdir is not there
    if ~exist(fullfile(tmpdir, 'Figures'), 'dir')
        mkdir(fullfile(tmpdir, 'Figures'));
    end
    filetype = questdlg('Select file format: .svg(replaces .eps) -or- MATLAB .fig)','Save Plot','.svg','.fig','.svg');
    if isempty(filetype); return; end
    fig = findobj('type','figure','Name',sprintf('Plot #%s',tab.Tag));
    if isempty(fig); return; else; figure(fig); end
    if strcmp(filetype,'.svg')
        [filename,pathname] = uiputfile('*.svg','Figure Name', fullfile(tmpdir, 'Figures', 'myfigure'));
        if ~filename; return; end
        %saveas(fig,fullfile(pathname,filename),'epsc'); %problems with rendering area plot
        print(fig,fullfile(pathname,filename),'-painters','-dsvg');
    elseif strcmp(filetype,'.fig')
        [filename,pathname] = uiputfile('*.fig','Figure Name', fullfile(tmpdir, 'Figures', 'myfigure'));
        if ~filename; return; end
        tsax = gca; if isempty(tsax); tsax=axes(fig,'Tag','tsax'); end
        tmpfig = figure;
        tmpax = copyobj(tsax,tmpfig);
        set(tmpax,'Position','default'); %tcr: I can't remember why we do this...
        savefig(fullfile(pathname,filename));
        close(tmpfig);
    end
end

function CBsaveFigData(~,~)
    outtype = questdlg('Save plotdata as ''struct'', or ''cell'' (w/XData, YData, Label)','Save Plot Data','struct','cell','struct');
    if isempty(outtype); return; end
    %save data structure used to make the current plot
    tab = htabgroup.SelectedTab;
    p = str2num(tab.Tag);
    [fn,path,ok] = uiputfile('*.mat','Select file name', sprintf('plot%d_data.mat',p));
    if ~ok; return; end
    if strcmp(outtype,'struct')
        myplotdata = hTS.UserData.plotdata{p};
        save(fullfile(path, fn), 'myplotdata');
    elseif strcmp(outtype,'cell')
        %save lines in cell -tcrtcrtcr
        fig = findobj('type','figure','Name',sprintf('Plot #%s',tab.Tag));
        tmpax = findobj(fig,'type','axes');
        lines = findobj(tmpax,'type','line');
        lines = flip(lines);
        for l = 1:numel(lines)
            myplotdata{l}.XData = lines(l).XData;
            myplotdata{l}.YData = lines(l).YData;
            myplotdata{l}.Label = lines(l).DisplayName;
        end
        save(fullfile(path, fn), 'myplotdata');
    end
end
function CBBehave(~,~)
    %current takes all TSdata and makes trials - might want to just use selected files/rois or plotdata
    if ~isfield(TSdata.file(1),'ephys'); disp('No ephys data found'); return; end
    tab = htabgroup.SelectedTab;
    stimval = get(findobj(tab,'Tag','stimselect'),'Value');
    if stimval==1; disp('No Stimulus Signals Selected'); return; end
    auxstr = get(findobj(tab,'Tag','stimselect'),'String');
    stim2use = auxstr{stimval};
    %defined stim not present in TSdata...
    tsdata = hTS.UserData.TSdata;
    if stimval==5
        for f = 1:length(tsdata.file)
            tsdata.file(f).def_stimulus = hTS.UserData.plotdata{tab}.def_stimulus;
        end
    end
    prestimtime = str2num(get(findobj(tab,'Tag','prestim'),'String'));
    poststimtime = str2num(get(findobj(tab,'Tag','poststim'),'String'));
    behaviordata = TSdata2BehaviorData(tsdata,stim2use,prestimtime,poststimtime); clear tsdata;
    BehaviorAnalysis_MWLab(behaviordata);
end
function CBsaveTSData(~,~) %Save TSdata in .mat file; To reload: load('mydata'); TimeSeriesAnalysis_MWLab(TSdata)
    [fn,path,ok] = uiputfile('*.mat','Select file name', 'myTSdata.mat');
    if ~ok; return; end
    save(fullfile(path, fn), 'TSdata');
end
function CBloadTSData(~, ~)
    if ~isempty(TSdata.file) %|| ~isempty(TSdata.file(1).name)
        answer = questdlg(sprintf(['Loading TSdata will clear all current data...\n'...
            'Are you sure you want to continue?']),'Load TSData','Yes','No','Yes');
        if ~strcmp(answer,'Yes'); return; end
    end
    [fn,path,ok] = uigetfile('*.mat','Select file', 'mydata.mat');
    if ~ok; return; end
    load(fullfile(path,fn),'TSdata');
    if isfield(TSdata,'file') && ~isempty(TSdata.file(1).name) && isfield(TSdata,'roi') && ~isempty(TSdata.roi)
        if isfield(TSdata.file(1).roi(1),'series') && ~isempty(TSdata.file(1).roi(1).series)
            CBSelectStimulus; %CBSelectAndSortColors;
        else
            CBaddFiles;
        end
    end
    hTS.UserData.TSdata = TSdata;
end
function CBEditBaseline(~,~)
    tab = htabgroup.SelectedTab;
    basestart = str2double(get(findobj(tab,'Tag','basestart'),'String'));
    set(findobj(tab,'Tag','baseslider'),'Value',basestart);
    %tcrtcrtcr not working
    respstart = str2double(get(findobj(tab,'Tag','respstart'),'String'));
    set(findobj(tab,'Tag','changeslider'),'Value',respstart);
    CBSelectAndSortColors;
end
function CBAdjustSlider(~,~)
    tab = htabgroup.SelectedTab;
    basestart = get(findobj(tab,'Tag','baseslider'),'Value');
    set(findobj(tab,'Tag','basestart'),'String',num2str(basestart));
    respstart = get(findobj(tab,'Tag','changeslider'),'Value');
    set(findobj(tab,'Tag','respstart'),'String',num2str(respstart));
    CBSelectAndSortColors;
end

end
