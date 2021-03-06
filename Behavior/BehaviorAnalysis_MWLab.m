function hBA = BehaviorAnalysis_MWLab(varargin)
%behavior analysis program (similar to olfactometry of old)

% Definitions
tmppath=which(mfilename);
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
figurename = [pathparts{end} '/' guiname];

prev = findobj('Name',figurename);
if ~isempty(prev); close(prev); end

% typestr = {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif','-select datatype-'};
%typestr = getdatatypes;
% stimstr = {'Aux1(odor)', 'Aux2(sniff)', 'AuxCombo', 'Manually Defined Stimulus'};
stimstr = getauxtypes;

%load previous settings file
try
    load(fullfile(guipath,'BAsettings.mat'),'-mat','BAsettings');
catch
end
if ~exist('BAsettings','var')
    BAsettings.LastDir = './';
end
% Read command line arguments
if nargin
    behaviordata = varargin{1}; %verify?
    for t = 1:length(behaviordata.trials)
        trialnames{t} = sprintf('%s, odor%d, trial%d',behaviordata.trials(t).name,behaviordata.trials(t).odornumber, behaviordata.trials(t).trialnumber);
    end
    if ~isempty(behaviordata.trials) && ~isempty(behaviordata.trials(1).roi)
        for r = 1:length(behaviordata.trials(1).roi)
            roistr{r} = sprintf('roi # %d',r);
        end
    else; roistr = {''};
    end    
else
    behaviordata.stim2use = stimstr{1};
    behaviordata.prestimtime = 4;
    behaviordata.poststimtime = 8;
    behaviordata.trials = [];
    trialnames = {''}; roistr = {''};
end
%%
% GUI figure setup
BGCol = [.75 .75 .75]; %GUI Background Color
hBA = figure('NumberTitle','off','Name',figurename,'Units',...
        'Normalized','Position', [0.0276 0.05 0.9448 0.85],'Color',...
        BGCol,'CloseRequestFcn',@CB_CloseFig);
hBA.UserData.BAdata = behaviordata;
set(hBA, 'DefaultAxesLineWidth', 2, 'DefaultAxesFontSize', 12); %Used by axes objects with plots
hloaddatamenu = uimenu(hBA,'Text','GUI Data');
uimenu(hloaddatamenu,'Text','Load behaviordata','Callback',@loadBehaviorData);
uimenu(hloaddatamenu,'Text','Save behaviordata','Callback',@saveBehaviorData);
uimenu(hloaddatamenu,'Text','Export behaviordata','Callback',@exportBehaviorData);

uicontrol(hBA,'tag','trialnames','style','listbox','Units','Normalized','Position',...
    [0 .56 .19 .44],'String',trialnames,'Value',1,'Callback',@CB_UpdatePlot);
uicontrol(hBA,'tag','sortbyodor','Style','checkbox','Units','Normalized','Position',...
    [0.03 .53 .13 .03],'String','Sort trials by odor number','FontSize',9,...
    'BackgroundColor',BGCol,'HorizontalAlignment','center','Callback',@CBSortbyOdor);
%panel with trials settings
tspanel = uipanel(hBA,'Units','Normalized','Position',[0 .45 .19 .08]);
uicontrol(tspanel,'style','text','String','Stimulus Signal:','Units','Normalized',...
    'Position',[.05 .7 .4 .2],'FontSize',9);
uicontrol(tspanel,'tag','stim2use','style','popupmenu','String',stimstr,...
    'Units','Normalized','Position',[.05 .4 .4 .2],'Enable','off');
uicontrol(tspanel,'style','text','String','PreStimulus(sec):','Units','Normalized',...
    'Position',[.5 .55 .32 .2],'FontSize',9);
uicontrol(tspanel,'tag','prestim','style','edit','Units','Normalized','Position',...
    [.83 .55 .12 .3],'Enable','off');
uicontrol(tspanel,'style','text','String','PostStimulus(sec):','Units','Normalized',...
    'Position',[.5 .2 .32 .2],'FontSize',9);
uicontrol(tspanel,'tag','poststim','style','edit','Units','Normalized','Position',...
    [.83 .2 .12 .3],'Enable','off');
%bgsubtract/filter/df
uicontrol(hBA,'tag','bgsubtract','style','checkbox','String','Subtract Background of ROI #:',...
    'FontSize',9,'Units','Normalized','Position',[0.01 .405 .11 .02],'BackgroundColor',BGCol,...
    'Callback',@CB_UpdatePlot);
uicontrol(hBA,'tag','bgroi','style','edit','Units','Normalized','Position',[0.12 .4 .03 .03]);
uicontrol(hBA,'tag','hpfilter','style','checkbox','String','High Pass Filter @ cutoff (Hz):',...
    'FontSize',9,'Units','Normalized','Position',[0.01 .355 .11 .02],'BackgroundColor',BGCol,...
    'Callback',@CB_UpdatePlot);
uicontrol(hBA,'tag','hpval','style','edit','Units','Normalized','Position',[0.12 .35 .03 .03]);
uicontrol(hBA,'tag','lpfilter','style','checkbox','String','Low Pass Filter @ cutoff (Hz):',...
    'FontSize',9,'Units','Normalized','Position',[0.01 .305 .11 .02],'BackgroundColor',BGCol,...
    'Callback',@CB_UpdatePlot);
uicontrol(hBA,'tag','lpval','style','edit','Units','Normalized','Position',[0.12 .3 .03 .03]);
fpanel = uipanel(hBA,'Units','Normalized','Position',[0 .20 .19 .08]);
fgroup = uibuttongroup(fpanel,'Units','Normalized','Position',[0 0 1 1],'Visible','off',...
    'SelectionChangedFcn',@CB_UpdatePlot);
uicontrol(fgroup,'Tag','F','Style','radiobutton','String','Fluorescence','FontSize',9,'Units',...
    'Normalized','Position',[.05 .6 .3 .3]);
uicontrol(fgroup,'Tag','dF','Style','radiobutton','String','Delta F (F-FO)','FontSize',9,'Units',...
    'Normalized','Position',[.38 .6 .3 .3]);
uicontrol(fgroup,'Tag','dFF','Style','radiobutton','String','Delta F/F)','FontSize',9,'Units',...
    'Normalized','Position',[.72 .6 .3 .3]);
fgroup.Visible='on';
uicontrol(fpanel,'Style','text','String','FO Time Window:','FontSize',9,'Units',...
    'Normalized','Position',[.2 .2 .3 .25]);
uicontrol(fpanel,'Tag','fstart','Style','edit','Units','Normalized','Position',[.5 .2 .15 .3]);
uicontrol(fpanel,'Style','text','String','to','FontSize',9,'Units',...
    'Normalized','Position',[.65 .2 .05 .25]);
uicontrol(fpanel,'Tag','fstop','Style','edit','Units','Normalized','Position',[.7 .2 .15 .3]);
uicontrol(fpanel,'Style','text','String','(Secs)','FontSize',9,'Units',...
    'Normalized','Position',[.85 .2 .13 .25]);
%prev/next
uicontrol(hBA,'style','pushbutton','Units','Normalized','Position',[.01 .02 .08 .05],...
    'String','Previous','Callback',@CB_previous);
uicontrol(hBA,'style','pushbutton','Units','Normalized','Position',[.10 .02 .08 .05],...
    'String','Next','Callback',@CB_next);
%axes
hpanel = uipanel(hBA,'Units','Normalized','Position',[.195 0.01 .7 .98]);
hAx = axes(hpanel,'Units','Normalized','Position',[ 0 0.03 1 .97]);
%ephys list
ephysstr = {'Aux1(odor)','Aux2(sniff)','ephys-odor','ephys-sniff','ephys-puff','det-sniff','ephys-lick','ephys-reward','ephys-valence'};
uicontrol(hBA,'style','text','Units','Normalized','Position',[.9 .97 .1 .02], ...
    'FontSize',9,'String','EPhys Signals to Display:','BackgroundColor',BGCol);
uicontrol(hBA,'tag','ephys','style','listbox','Units','Normalized','Position',...
    [.9 0.85 .1 .12],'String',ephysstr,'Max',5,'Callback',@CB_UpdatePlot); %allow multi-select w/max>min
%detect sniffs
uicontrol(hBA,'style','pushbutton','String','Detect Sniffs','Units','Normalized',...
    'Position',[.9 0.79 .09 .05],'Callback',@CB_DetectSniffs);
%other things to plot
otherstr = {'none','exhalations','exhalations_starts','exhalations frequency','exhalations widths',...
    'inhalations','inhalations_starts','inhalations frequency','inhalations widths'};
uicontrol(hBA,'style','text','Units','Normalized','Position',[.9 .75 .1 .02], ...
    'FontSize',9,'String','Detected Signals to Display:','BackgroundColor',BGCol);
uicontrol(hBA,'tag','other','style','listbox','Units','Normalized','Position',...
    [.9 0.62 .1 .13],'String',otherstr,'Max',5,'Callback',@CB_UpdatePlot); %allow multi-select w/max>min
%signal window
uicontrol(hBA,'style','text','Units','Normalized','Position',[0.9 0.59 .07 .02],...
    'FontSize',9,'String','Signals Start (sec):','BackgroundColor',BGCol);
uicontrol(hBA,'tag','signalstart','style','edit','Units','Normalized','Position',[0.97 0.59 .02 .025]);
uicontrol(hBA,'style','text','Units','Normalized','Position',[.9 0.56 .07 .02],...
    'FontSize',9,'String','Signals Stop (sec):','BackgroundColor',BGCol);
uicontrol(hBA,'tag','signalstop','style','edit','Units','Normalized','Position',[0.97 0.56 .02 .025]);
%period threshold
uicontrol(hBA,'style','text','Units','Normalized','Position',[.9 0.53 .07 .02],...
    'FontSize',9,'String','Min Period (sec):','BackgroundColor',BGCol);
uicontrol(hBA,'tag','minperiod','style','edit','Units','Normalized','Position',[0.97 0.53 .02 .025]);
%export sniff responses / sniff-trigger window
uicontrol(hBA,'style','pushbutton','String','Extract Sniff Responses','Units','Normalized',...
    'Position',[.9 0.47 .09 .05],'Callback',@CB_ExtractSniffs);
uicontrol(hBA,'style','text','Units','Normalized','Position',[0.9 0.44 .07 .02],...
    'FontSize',9,'String','Sniff-Trig Start (sec):','BackgroundColor',BGCol);
uicontrol(hBA,'tag','sniffstart','style','edit','Units','Normalized','Position',[0.97 0.44 .02 .025]);
uicontrol(hBA,'style','text','Units','Normalized','Position',[.9 0.41 .07 .02],...
    'FontSize',9,'String','Sniff-Trig Stop (sec):','BackgroundColor',BGCol);
uicontrol(hBA,'tag','sniffstop','style','edit','Units','Normalized','Position',[0.97 0.41 .02 .025]);
%rois list
uicontrol(hBA,'style','text','Units','Normalized','Position',[.9 .31 .1 .02], ...
    'FontSize',9,'String','Choose ROIs to Display:','BackgroundColor',BGCol);
uicontrol(hBA,'tag','roilist','style','listbox','Units','Normalized','Position',...
    [.9 0.01 .1 .3],'String',roistr,'Max',100,'Callback',@CB_UpdatePlot);

CB_UpdatePlot;

%Nested Callbacks
function CB_CloseFig(~,~)
    %save settings file
    save(fullfile(guipath,'BAsettings.mat'),'-mat','BAsettings');
    %close and clear
    delete(hBA);
end
function loadBehaviorData(~,~)
    inpath = BAsettings.LastDir;
    [infile,inpath] = uigetfile([inpath '/*.mat'],'Load <behaviordata>.m File');
    if ~ischar(infile); return; end
    BAsettings.LastDir = inpath;
    load(fullfile(inpath,infile),'behaviordata');
    if strcmp(behaviordata.stim2use,'AuxCombo'); behaviordata.stim2use = stimstr{3}; end %this fixes aux names for older saved behaviordata
    if strcmp(behaviordata.stim2use,'Manually Defined Stimulus');behaviordata.stim2use = stimstr{4}; end
    hBA.UserData.BAdata = behaviordata;
    trialnames = {''};
    for tt = 1:length(behaviordata.trials)
        trialnames{tt} = sprintf('%s, odor%d, trial%d',behaviordata.trials(tt).name, ...
            behaviordata.trials(tt).odornumber, behaviordata.trials(tt).trialnumber);
    end
    if ~isempty(behaviordata.trials) && ~isempty(behaviordata.trials(1).roi)
        for rr = 1:length(behaviordata.trials(1).roi)
            roistr{rr} = sprintf('roi # %d',rr);
        end
    else; roistr = {''};
    end 
    set(findobj(hBA,'tag','trialnames'),'String',trialnames,'Value',1);
    set(findobj(hBA,'tag','roilist'),'String',roistr,'Value',1);
    stimval = find(cellfun(@(x) strcmp(behaviordata.stim2use,x),stimstr));
    set(findobj(hBA,'tag','stim2use'),'Value',stimval);
    set(findobj(hBA,'tag','prestim'),'String',num2str(behaviordata.prestimtime));
    set(findobj(hBA,'tag','poststim'),'String',num2str(behaviordata.poststimtime));
    clear behaviordata;
    CB_UpdatePlot;
end
function saveBehaviorData(~,~)
    behaviordata = hBA.UserData.BAdata;
    [outfile,outpath] = uiputfile('mybehaviordata.mat','Enter Name for Trials Data File');
    if ischar(outfile); save(fullfile(outpath,outfile),'behaviordata','-mat'); end
end
function exportBehaviorData(~,~)
    behaviordata = hBA.UserData.BAdata;
    assignin('base','behaviordata',behaviordata);
end
function CBSortbyOdor(~,~)
    persistent sortind;
    tmpdata = hBA.UserData.BAdata;
    tmpvalue = get(findobj(hBA,'tag','trialnames'),'Value');
    if get(findobj(hBA,'tag','sortbyodor'),'Value')
        odors = zeros(length(tmpdata.trials),1);
        for tt = 1:length(tmpdata.trials)
            odors(tt) = tmpdata.trials(tt).odornumber;
        end
        [~,sortind] = sort(odors);
        hBA.UserData.BAdata.trials = tmpdata.trials(sortind);
        set(findobj(hBA,'tag','trialnames'),'Value',find(tmpvalue==sortind));
    else
        hBA.UserData.BAdata.trials(sortind) = hBA.UserData.BAdata.trials;
        [~,sortind] = sort(sortind); %oh yeah!
        set(findobj(hBA,'tag','trialnames'),'Value',find(tmpvalue==sortind));
    end
    trialnames = {''};
    for tt = 1:length(hBA.UserData.BAdata.trials)
        trialnames{tt} = sprintf('%s, odor%d, trial%d',hBA.UserData.BAdata.trials(tt).name, ...
           hBA.UserData.BAdata.trials(tt).odornumber,hBA.UserData.BAdata.trials(tt).trialnumber);
    end
    if ~isempty(hBA.UserData.BAdata.trials) && ~isempty(hBA.UserData.BAdata.trials(1).roi)
        for rr = 1:length(hBA.UserData.BAdata.trials(1).roi)
            roistr{rr} = sprintf('roi # %d',rr);
        end
    else; roistr = {''};
    end 
    set(findobj(hBA,'tag','trialnames'),'String',trialnames);
    CB_UpdatePlot;
end
function CB_previous(~,~)
    t = get(findobj(hBA,'tag','trialnames'),'Value');
    if t>1; set(findobj(hBA,'tag','trialnames'),'Value',t-1); end
    CB_UpdatePlot
end
function CB_next(~,~)
    t = get(findobj(hBA,'tag','trialnames'),'Value');
    if t<length(trialnames); set(findobj(hBA,'tag','trialnames'),'Value',t+1); end
    CB_UpdatePlot
end

function CB_UpdatePlot(~,~)
    cla(hAx); hold(hAx,'on');
    behaviordata = hBA.UserData.BAdata;
    if isempty(behaviordata.trials); return; end
    T = get(findobj(hBA,'tag','trialnames'),'Value');
    esig = get(findobj(hBA,'tag','ephys'),'Value');
    for e = 1:length(esig)
        switch ephysstr{esig(e)}
            case ephysstr{1} %Aux1(odor)
                tim = behaviordata.trials(T).aux1.times-behaviordata.trials(T).aux1.times(1);
                sig = ( ( behaviordata.trials(T).aux1.signal - min(behaviordata.trials(T).aux1.signal(:)) )./ ...
                    range(behaviordata.trials(T).aux1.signal) ).*0.2 +0.8; 
                plot(hAx,tim,sig);
            case ephysstr{2} %Aux2(sniff)
                tim = behaviordata.trials(T).aux2.times-behaviordata.trials(T).aux2.times(1);
                sig = ( ( behaviordata.trials(T).aux2.signal - min(behaviordata.trials(T).aux2.signal(:)) )./ ...
                    range(behaviordata.trials(T).aux2.signal) ).*0.2 +0.8;
                plot(hAx,tim,sig);
            case ephysstr{3} %ephys-odor
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).ephys.odor - min(behaviordata.trials(T).ephys.odor(:)) )./ ...
                    max(range(behaviordata.trials(T).ephys.odor),5) ).*0.2 +0.8;
                 plot(hAx,tim,sig);
            case ephysstr{4} %ephys-sniff
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).ephys.sniff - min(behaviordata.trials(T).ephys.sniff(:)) )./ ...
                    range(behaviordata.trials(T).ephys.sniff) ).*0.2 +0.8;
%                 sig = sig/50+0.9; %shows zscore +/- 5 in y=0.8to1.0 window
                plot(hAx,tim,sig); 
            case ephysstr{5} %ephys-puff
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).ephys.puff - min(behaviordata.trials(T).ephys.puff(:)) )./ ...
                    max(range(behaviordata.trials(T).ephys.puff),5) ).*0.2 +0.8;
                plot(hAx,tim,sig);
            case ephysstr{6} %'det-sniff'
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).det_sniffs.sniffs - min(behaviordata.trials(T).det_sniffs.sniffs(:)) )./ ...
                    max(range(behaviordata.trials(T).det_sniffs.sniffs),5) ).*0.2 +0.8;
                plot(hAx,tim,sig);
            case ephysstr{7} %'ephys-lick'
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).ephys.lick - min(behaviordata.trials(T).ephys.lick(:)) )./ ...
                    max(range(behaviordata.trials(T).ephys.lick),5) ).*0.2 +0.8;
                plot(hAx,tim,sig);
            case ephysstr{8} %'ephys-reward'
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).ephys.reward - min(behaviordata.trials(T).ephys.reward(:)) )./ ...
                    max(range(behaviordata.trials(T).ephys.reward),5) ).*0.2 +0.8;
                plot(hAx,tim,sig);
            case ephysstr{9} %'ephys-valence'
                tim = behaviordata.trials(T).ephys.times-behaviordata.trials(T).ephys.times(1);
                sig = ( ( behaviordata.trials(T).ephys.valence - min(behaviordata.trials(T).ephys.valence(:)) )./ ...
                    max(range(behaviordata.trials(T).ephys.valence),5) ).*0.2 +0.8;
                plot(hAx,tim,sig);
        end
    end
    if isfield(behaviordata.trials(T),'det_sniffs') && ~isempty(behaviordata.trials(T).det_sniffs)
        othersig = get(findobj(hBA,'tag','other'),'Value');
        sigstart = str2double(get(findobj(hBA,'tag','signalstart'),'String'));
        sigstop = str2double(get(findobj(hBA,'tag','signalstop'),'String'));
        minperiod = str2double(get(findobj(hBA,'tag','minperiod'),'String'));
        for o = 1:length(othersig)
            switch otherstr{othersig(o)}
                case otherstr{2} %Exhalations
                    tim = behaviordata.trials(T).det_sniffs.exhalations_times;
                    if ~isnan(minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,[tim;tim],repmat([0;1],[1,length(tim)]),'--c');
                case otherstr{3} %Exhalations_starts
                    tim = behaviordata.trials(T).det_sniffs.exhalations_starttimes;
                    if ~isnan(minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,[tim;tim],repmat([0;1],[1,length(tim)]),'--m');
                case otherstr{4} %Exhalation Frequency
                    tim = behaviordata.trials(T).det_sniffs.exhalations_freq_times;
                    sig = ( ( behaviordata.trials(T).det_sniffs.exhalations_freq - min(behaviordata.trials(T).det_sniffs.exhalations_freq(:)) )./ ...
                        range(behaviordata.trials(T).det_sniffs.exhalations_freq) ).*0.2 +0.8;
                    if ~isnan(minperiod); sig = sig([0 diff(tim)] > minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); sig = sig(tim>=sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); sig = sig(tim<sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,tim,sig,'LineStyle','--','Color',[.5 .5 .5]);
                case otherstr{5} %Exhalation Widths - shape width
                    tim = behaviordata.trials(T).det_sniffs.exhalations_times;
                    sig = ( ( behaviordata.trials(T).det_sniffs.exhalations_widths - min(behaviordata.trials(T).det_sniffs.exhalations_widths) )./ ...
                        range(behaviordata.trials(T).det_sniffs.exhalations_widths) ).*0.2 +0.8;
                    if ~isnan(minperiod); sig = sig([0 diff(tim)] > minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); sig = sig(tim>=sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); sig = sig(tim<sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,tim,sig,'LineStyle',':','Color',[1 .5 0]);
                case otherstr{6} %Inhalations
                    tim = behaviordata.trials(T).det_sniffs.inhalations_times;
                    if ~isnan(minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,[tim;tim],repmat([0;1],[1,length(tim)]),'--g');
                case otherstr{7} %Inhalations_starts
                    tim = behaviordata.trials(T).det_sniffs.inhalations_starttimes;
                    if ~isnan(minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,[tim;tim],repmat([0;1],[1,length(tim)]),'--r');
                case otherstr{8} %Inhalation Frequency
                    tim = behaviordata.trials(T).det_sniffs.inhalations_freq_times;
                    sig = ( ( behaviordata.trials(T).det_sniffs.inhalations_freq - min(behaviordata.trials(T).det_sniffs.inhalations_freq(:)) )./ ...
                        range(behaviordata.trials(T).det_sniffs.inhalations_freq) ).*0.2 +0.8;
                    if ~isnan(minperiod); sig = sig([0 diff(tim)] > minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); sig = sig(tim>=sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); sig = sig(tim<sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,tim,sig,'--k');
                case otherstr{9} %Inhalation Widths - shape width
                    tim = behaviordata.trials(T).det_sniffs.inhalations_times;
                    sig = ( ( behaviordata.trials(T).det_sniffs.inhalations_widths - min(behaviordata.trials(T).det_sniffs.inhalations_widths) )./ ...
                        range(behaviordata.trials(T).det_sniffs.inhalations_widths) ).*0.2 +0.8;
                    if ~isnan(minperiod); sig = sig([0 diff(tim)] > minperiod); tim = tim([0 diff(tim)]>= minperiod); end
                    if ~isnan(sigstart); sig = sig(tim>=sigstart); tim = tim(tim>=sigstart); end
                    if ~isnan(sigstop); sig = sig(tim<sigstop); tim = tim(tim<sigstop); end
                    plot(hAx,tim,sig,':r');
            end
        end
    end
    
    rois = get(findobj(hBA,'tag','roilist'),'Value');
    %bgsubtract
    roitimes = zeros(length(rois),length(behaviordata.trials(T).roi(1).time));
    roisigs = zeros(length(rois),length(behaviordata.trials(T).roi(1).series));
    if get(findobj(hBA,'tag','bgsubtract'),'Value') && ~isempty(get(findobj(hBA,'tag','bgroi'),'String'))
        nBGroi = str2double(get(findobj(hBA,'tag','bgroi'),'String'));
        for rr = 1:length(rois)
            roisigs(rr,:) = behaviordata.trials(T).roi(rois(rr)).series - behaviordata.trials(T).roi(nBGroi).series;
            roitimes(rr,:) = behaviordata.trials(T).roi(rois(rr)).time - behaviordata.trials(T).roi(rois(rr)).time(1);
        end
    else
        set(findobj(hBA,'tag','bgsubtract'),'Value',0);
        for rr = 1:length(rois)
            roisigs(rr,:) = behaviordata.trials(T).roi(rois(rr)).series;
            roitimes(rr,:) = behaviordata.trials(T).roi(rois(rr)).time - behaviordata.trials(T).roi(rois(rr)).time(1);
        end
    end
    %filters
    samp_rate = 1/diff(roitimes(1,1:2));
    if get(findobj(hBA,'tag','hpfilter'),'Value') && ~isempty(get(findobj(hBA,'tag','hpval'),'String'))
        freq = str2double(get(findobj(hBA,'Tag','hpval'), 'String'));
        Wn = freq/(0.5*samp_rate);
        N = 1;
        [bhigh, ahigh] = butter(N,Wn, 'high');
        for rr = 1:length(rois)
            roisigs(rr,:) = filtfilt(bhigh,ahigh,roisigs(rr,:));
        end
    else
        set(findobj(hBA,'tag','hpfilter'),'Value',0)
    end
    if get(findobj(hBA,'tag','lpfilter'),'Value') && ~isempty(get(findobj(hBA,'tag','lpval'),'String'))
        freq = str2double(get(findobj(hBA,'Tag','lpval'), 'String'));
        Wn = freq/(0.5*samp_rate);
        if (Wn>1)
            errordlg(['Maximum filter frequency = ' num2str(0.5*samp_rate)]);
        else
            N = 1;
            [b,a] = butter(N,Wn);
            for rr = 1:length(rois)
                roisigs(rr,:) = filtfilt(b,a,roisigs(rr,:));
            end
        end
    else
        set(findobj(hBA,'tag','lpfilter'),'Value',0)
    end
    %df
    if get(findobj(hBA,'tag','dF'),'Value') || get(findobj(hBA,'tag','dFF'),'Value')
        tstart = str2double(get(findobj(hBA,'Tag','fstart'),'String'));
        tstop = str2double(get(findobj(hBA,'Tag','fstop'),'String'));
        if isnan(tstart) || isnan(tstop)
            set(findobj(hBA,'tag','F'),'Value',1); 
            set(findobj(hBA,'tag','dF'),'Value',0);
            set(findobj(hBA,'tag','dFF'),'Value',0);
            CB_UpdatePlot;
        end
    end
    if get(findobj(hBA,'tag','dF'),'Value') %deltaF
        for rr = 1:length(rois)
            istart = find(roitimes(rr,:)>tstart,1,'first');
            istop = find(roitimes(rr,:)<tstop,1,'last');
            FO = mean(roisigs(rr,istart:istop));
            roisigs(rr,:)=roisigs(rr,:)-FO;
        end
    elseif get(findobj(hBA,'tag','dFF'),'Value') %deltaF/F
        for rr = 1:length(rois)
            istart = find(roitimes(rr,:)>tstart,1,'first');
            istop = find(roitimes(rr,:)<tstop,1,'last');
            FO = mean(roisigs(rr,istart:istop));
            roisigs(rr,:)=(roisigs(rr,:)-FO)./FO;
        end
    end    
    %scale & plot
    scalefactor = 0; %scale all the same... based on the one with biggest range
    for rr = 1:length(rois)
        scalefactor = max(scalefactor,range(roisigs(rr,:)));
    end
    scalefactor = 0.8*scalefactor*length(rois);
    for rr = 1:length(rois)
        tim = roitimes(rr,:);
        sig = roisigs(rr,:)./scalefactor;
        sig = sig-mean(sig);
        offset = .8*(rr/(length(rois)+1));
        plot(hAx,tim,sig-mean(sig)+offset,'Color',myColors(rr));
        text(hAx,.5,offset,sprintf('ROI #%d',rois(rr)),'Color',myColors(rr));
    end
    hAx.YLim = [0 1]; hAx.XLim = [0 tim(end)];
    hAx.XTick = 0:1:floor(tim(end));
end
function CB_DetectSniffs(~,~)
    behaviordata = hBA.UserData.BAdata;
    out=DetectSniffsGUI(behaviordata);
    if ~isempty(out)
        for t = 1:length(behaviordata.trials)
            if isfield(out,'peaks')
                behaviordata.trials(t).det_sniffs.exhalations = out(t).peaks;
                behaviordata.trials(t).det_sniffs.exhalations_index = out(t).peaks_index;
                behaviordata.trials(t).det_sniffs.exhalations_times = out(t).peaks_times;
                behaviordata.trials(t).det_sniffs.exhalations_freq = out(t).peaks_freq;
                behaviordata.trials(t).det_sniffs.exhalations_freq_times = out(t).peaks_freq_times;
                behaviordata.trials(t).det_sniffs.exhalations_widths = out(t).peaks_widths;
                behaviordata.trials(t).det_sniffs.exhalations_startindex = out(t).peaks_startindex;
                behaviordata.trials(t).det_sniffs.exhalations_starttimes = out(t).peaks_starttimes;                
                behaviordata.trials(t).det_sniffs.inhalations = out(t).troughs;
                behaviordata.trials(t).det_sniffs.inhalations_index = out(t).troughs_index;
                behaviordata.trials(t).det_sniffs.inhalations_times = out(t).troughs_times;
                behaviordata.trials(t).det_sniffs.inhalations_freq = out(t).troughs_freq;
                behaviordata.trials(t).det_sniffs.inhalations_freq_times = out(t).troughs_freq_times;
                behaviordata.trials(t).det_sniffs.inhalations_widths = out(t).troughs_widths;
                behaviordata.trials(t).det_sniffs.settings = out(t).settings;
                behaviordata.trials(t).det_sniffs.inhalations_startindex = out(t).troughs_startindex;
                behaviordata.trials(t).det_sniffs.inhalations_starttimes = out(t).troughs_starttimes;
                behaviordata.trials(t).det_sniffs.sniffs = out(t).sniffs;
            else
                behaviordata.trials(t).det_sniffs = [];
            end
        end              
    end
    hBA.UserData.BAdata = behaviordata;
end
function CB_ExtractSniffs(~,~)
    if isempty(hBA.UserData.BAdata.trials); return; end
    T = get(findobj(hBA,'tag','trialnames'),'Value');
    rois = get(findobj(hBA,'tag','roilist'),'Value');
    sig = get(findobj(hBA,'tag','other'),'Value');
    %make sure you're using a valid signal
    if length(sig)> 1 || ~max(sig==[ 2 3 6 7]) %pick inhalations, exhalations, or their starts
        sig=choosesig;
    end
    function sig = choosesig
        sig=2;
        d=dialog('Units','Normalized','Position',[.4 .7 .2 .1]);
        uicontrol(d,'Style','text','String','Detected Signal to use for sniff extration:',...
            'Units','Normalized','Position',[.1 .6 .8 .2]);
        tmpstr = get(findobj(hBA,'tag','other'),'String'); tmpstr = tmpstr([2 3 6 7]);
        uicontrol(d,'Style','popupmenu','String',tmpstr,'Callback',@tmpselect,...
            'Units','Normalized','Position',[.1 .2 .8 .4]);
        uiwait(d);
        function tmpselect(src,~)
            sig = src.Value;
            if sig==1; sig=2;
            elseif sig == 2; sig=3;
            elseif sig == 3; sig=6;
            elseif sig == 4; sig=7;
            end
            delete(src.Parent);
        end
    end
    switch sig
        case 2 %Exhalations
            trig = behaviordata.trials(T).det_sniffs.exhalations_times;
        case 3 %Exhalations_starts
            trig = behaviordata.trials(T).det_sniffs.exhalations_starttimes;
        case 6 %Inhalations
            trig = behaviordata.trials(T).det_sniffs.inhalations_times;
        case 7 %Inhalations_starts
            trig = behaviordata.trials(T).det_sniffs.inhalations_starttimes;
    end
    sigstart = str2double(get(findobj(hBA,'tag','signalstart'),'String'));
    sigstop = str2double(get(findobj(hBA,'tag','signalstop'),'String'));
    minperiod = str2double(get(findobj(hBA,'tag','minperiod'),'String'));
    if ~isnan(minperiod); trig = trig([0 diff(trig)]>= minperiod); end
    if ~isnan(sigstart); trig = trig(trig>=sigstart); end
    if ~isnan(sigstop); trig = trig(trig<sigstop); end
    %get pre-post sniff window
    sniffstart = str2double(get(findobj(hBA,'tag','sniffstart'),'String'));
    sniffstop = str2double(get(findobj(hBA,'tag','sniffstop'),'String'));
    if isnan(sniffstart) || isnan(sniffstop); disp('enter sniff-trig start/end values'); return; end
    %extract signals export to command window
    for r = 1:length(rois)
        %get responses from command window - append to these if they exist
        tmpstr = sprintf('snifftrig_roi%d',r);
        try
            snifftrig_roi = evalin('base', tmpstr);
        catch
            snifftrig_roi = [];
        end
        %how many frames - make sure it's the same for all traces
        if ~isempty(snifftrig_roi); [cnt,frames] = size(snifftrig_roi); 
        else; cnt=0; frames = floor((sniffstop-sniffstart)*behaviordata.trials(T).frameRate);
        end
        %prepare the trace - bgsubtract,filters,df,etc
        roitimes = behaviordata.trials(T).roi(rois(r)).time - behaviordata.trials(T).roi(rois(r)).time(1);
        %bgsubtract
        if get(findobj(hBA,'tag','bgsubtract'),'Value') && ~isempty(get(findobj(hBA,'tag','bgroi'),'String'))
            nBGroi = str2double(get(findobj(hBA,'tag','bgroi'),'String'));
            roisig = behaviordata.trials(T).roi(rois(r)).series - behaviordata.trials(T).roi(nBGroi).series;
        else
            roisig = behaviordata.trials(T).roi(rois(r)).series;
        end
        %filters
        samp_rate = behaviordata.trials(T).frameRate;
        if get(findobj(hBA,'tag','hpfilter'),'Value') && ~isempty(get(findobj(hBA,'tag','hpval'),'String'))
            freq = str2double(get(findobj(hBA,'Tag','hpval'), 'String'));
            Wn = freq/(0.5*samp_rate);
            N = 1;
            [bhigh, ahigh] = butter(N,Wn, 'high');
            roisig = filtfilt(bhigh,ahigh,roisig);
        end
        if get(findobj(hBA,'tag','lpfilter'),'Value') && ~isempty(get(findobj(hBA,'tag','lpval'),'String'))
            freq = str2double(get(findobj(hBA,'Tag','lpval'), 'String'));
            Wn = freq/(0.5*samp_rate);
            N = 1;
            [b,a] = butter(N,Wn);
            roisig = filtfilt(b,a,roisig);
        end
        %df
        if get(findobj(hBA,'tag','dF'),'Value') %deltaF
            istart = find(roitimes>tstart,1,'first');
            istop = find(roitimes<tstop,1,'last');
            FO = mean(roisig(istart:istop));
            roisig = roisig-FO;
        elseif get(findobj(hBA,'tag','dFF'),'Value') %deltaF/F
            istart = find(roitimes>tstart,1,'first');
            istop = find(roitimes<tstop,1,'last');
            FO = mean(roisig(istart:istop));
            roisig = (roisig-FO)./FO;
        end
        %extract each sniff traces
        for t = 1:length(trig)
            istart = find(roitimes>=trig(t)+sniffstart,1,'first');
            snifftrig_roi(cnt+1,:) = roisig(istart:istart+frames-1);
            cnt = cnt+1;
        end
        assignin('base',tmpstr,snifftrig_roi);
    end    
end
end