function [out] = DetectSniffsGUI(behaviordata)
% [out] = DetectSniffsGUI(behaviordata)
%   Uses a modified version of MATLAB's findpeaks function (findpeaks_mwlab.m) to find inhalation
%   and exhalation peaks in ephys sniff data. This function is called from BehaviorAnalysis_MWLab.

tmppath=which(mfilename);
[guipath,guiname,~]=fileparts(tmppath);
pathparts=strsplit(guipath,filesep);
figurename = [pathparts{end} '/' guiname];
prev = findobj('Name',figurename);
if ~isempty(prev); close(prev); end

if ~nargin
    disp(help(mfilename)); return;
end

%load previous settings file
try
    load(fullfile(guipath,'DSsettings.mat'),'-mat','DSsettings');
catch
end

if ~exist('DSsettings','var')
    getDefaultSettings;
end
function getDefaultSettings(~,~)
    DSsettings.LPval = 12;
    DSsettings.HPval = 1;
    DSsettings.MinHeight = 0;
    DSsettings.MinProm = 0.3;
    DSsettings.MinPeriod = 0;
    DSsettings.MinWidth = 0.03;
    DSsettings.MaxWidth = 1;
end

out(length(behaviordata.trials)) = struct();
% create figure
hDS = figure('NumberTitle','off','Name',guiname,'Menubar','none','ToolBar','figure',...
    'Units', 'Normalized', 'Position', [0.1 0.45 0.8 0.45],'CloseRequestFcn',@CB_CloseFig);
hmenu = uimenu(hDS,'Text','GUI Settings');
uimenu(hmenu,'Text','Save Settings','Callback',@CBSaveSettings);
uimenu(hmenu,'Text','Load Settings','Callback',@CBLoadSettings);
uimenu(hmenu,'Text','Default Settings','Callback',@CBDefaultSettings);

function CB_CloseFig(~,~)
    %save settings
    getSettings;
    save(fullfile(guipath,'DSsettings.mat'),'-mat','DSsettings');
    delete(hDS);
end

fsize = 12; %font size
uicontrol(hDS,'style','text','String','Low Pass Filter Cutoff (Hz):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .9 .16 .04]);
hLPedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.LPval),'Units','Normalized',...
    'Position',[.17 .9 .04 .04],'Callback',@CBadjustLP);
hLP = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .84 .2 .04],...
    'Callback',@CBadjustLP,'Value',DSsettings.LPval,'Min',1,'Max',25);
uicontrol(hDS,'style','text','String','High Pass Filter Cutoff (Hz):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .78 .16 .04]);
hHPedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.HPval),'Units','Normalized',...
    'Position',[.17 .78 .04 .04],'Callback',@CBadjustHP);
hHP = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .72 .2 .04],...
    'Callback',@CBadjustHP,'Value',DSsettings.HPval,'Min',0,'Max',1);
uicontrol(hDS,'style','text','String','Min Peak Height:','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .66 .16 .04]);
hMPHedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.MinHeight),'Units','Normalized',...
    'Position',[.17 .66 .04 .04],'Callback',@CBadjustMPH);
hMPH = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .6 .2 .04],...
    'Callback',@CBadjustMPH,'Value',DSsettings.MinHeight,'Min',-5,'Max',5);
uicontrol(hDS,'style','text','String','Min Peak Prominence:','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .54 .16 .04],...
    'ToolTipString',['The prominence of a peak measures how much the peak stands out ' ...
    'due to its intrinsic height and its location relative to other peaks']);
hMPPedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.MinProm),'Units','Normalized',...
    'Position',[.17 .54 .04 .04],'Callback',@CBadjustMPP);
hMPP = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .48 .2 .04],...
    'Callback',@CBadjustMPP,'Value',DSsettings.MinProm,'Min',0,'Max',2);
%'Min Peak Distance (sec):' changed to Period
uicontrol(hDS,'style','text','String','Min Peak Period (sec):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .42 .16 .04],...
    'ToolTipString','Minimum peak separation (inverse of max sniff frequency)');
hMPDedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.MinPeriod),'Units','Normalized',...
    'Position',[.17 .42 .04 .04],'Callback',@CBadjustMPD);
hMPD = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .36 .2 .04],...
    'Callback',@CBadjustMPD,'Value',DSsettings.MinPeriod,'Min',0,'Max',0.2);
uicontrol(hDS,'style','text','String','Min Peak Width (sec):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .3 .16 .04]);
hMPWedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.MinWidth),'Units','Normalized',...
    'Position',[.17 .3 .04 .04],'Callback',@CBadjustMPW);
hMPW = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .24 .2 .04],...
    'Callback',@CBadjustMPW,'Value',DSsettings.MinWidth,'Min',0,'Max',.1);
uicontrol(hDS,'style','text','String','Max Peak Width (sec):','FontSize',fsize,...
    'HorizontalAlignment','right','Units','Normalized','Position',[.01 .18 .16 .04]);
hMxPWedit = uicontrol(hDS,'style','edit','String',num2str(DSsettings.MaxWidth),'Units','Normalized',...
    'Position',[.17 .18 .04 .04],'Callback',@CBadjustMxPW);
hMxPW = uicontrol(hDS,'style','slider','Units','Normalized','Position',[.012 .12 .2 .04],...
    'Callback',@CBadjustMxPW,'Value',DSsettings.MaxWidth,'Min',0.1,'Max',2);
uicontrol(hDS,'style','pushbutton','String','Save Trial','Units','Normalized',...
    'Position',[.01 .04 .06 .05],'Callback',@CB_SaveTrial);
uicontrol(hDS,'style','pushbutton','String','Save All','Units','Normalized',...
    'Position',[.08 .04 .06 .05],'Callback',@CB_SaveAll);
uicontrol(hDS,'style','pushbutton','String','Done','Units','Normalized',...
    'Position',[.15 .04 .06 .05],'Callback',@CB_CloseFig);

hAx = axes(hDS,'Position',[0.25 0.05 .7 .9]);

trialstr = '';
for T = 1:length(behaviordata.trials)
    trialstr{T}=num2str(T);
end
hTrial = uicontrol(hDS,'style','listbox','String',trialstr,'Units','Normalized','Position',...
    [0.95 0.05 .04 .9],'Callback',@CBgetsniffs);

CBgetsniffs;

waitfor(hDS); %return detected sniff info for all trials when figure closes;

%callbacks
function CBSaveSettings(~, ~)
    getSettings;
    [setfile,setpath] = uiputfile(fullfile(guipath,'myDSsettings.mat'));
    save(fullfile(setpath,setfile),'DSsettings');
end
function CBLoadSettings(~, ~)
    [setfile,setpath] = uigetfile(fullfile(guipath,'*.mat'));
    load(fullfile(setpath,setfile),'-mat','DSsettings');
    setSettings;
end
function CBDefaultSettings(~,~)
    getDefaultSettings;
    setSettings;
end
function getSettings
    DSsettings.LPval = hLP.Value;
    DSsettings.HPval = hHP.Value;
    DSsettings.MinHeight = hMPH.Value;
    DSsettings.MinProm = hMPP.Value;
    DSsettings.MinPeriod = hMPD.Value;
    DSsettings.MinWidth = hMPW.Value;
    DSsettings.MaxWidth = hMxPW.Value;
end
function setSettings
    hLP.Value = DSsettings.LPval; hLPedit.String = num2str(hLP.Value);
    hHP.Value = DSsettings.HPval; hHPedit.String = num2str(hHP.Value);
    hMPH.Value = DSsettings.MinHeight; hMPHedit.String = num2str(hMPH.Value);
    hMPP.Value = DSsettings.MinProm; hMPPedit.String = num2str(hMPP.Value);
    hMPD.Value = DSsettings.MinPeriod; hMPDedit.String = num2str(hMPD.Value);
    hMPW.Value = DSsettings.MinWidth; hMPWedit.String = num2str(hMPW.Value);
    hMxPW.Value = DSsettings.MaxWidth; hMxPWedit.String = num2str(hMxPW.Value);
    CBgetsniffs;
end

function CBadjustHP(src,~)
    if strcmp(src.Style,'edit')
        hHP.Value = str2double(src.String);
    else
        hHPedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBadjustLP(src,~)
    if strcmp(src.Style,'edit')
        hLP.Value = str2double(src.String);
    else
        hLPedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBadjustMPH(src,~)
    if strcmp(src.Style,'edit')
        hMPH.Value = str2double(src.String);
    else
        hMPHedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBadjustMPP(src,~)
    if strcmp(src.Style,'edit')
        hMPP.Value = str2double(src.String);
    else
        hMPPedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBadjustMPD(src,~)
    if strcmp(src.Style,'edit')
        hMPD.Value = str2double(src.String);
    else
        hMPDedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBadjustMPW(src,~)
    if strcmp(src.Style,'edit')
        hMPW.Value = str2double(src.String);
    else
        hMPWedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBadjustMxPW(src,~)
    if strcmp(src.Style,'edit')
        hMxPW.Value = str2double(src.String);
    else
        hMxPWedit.String = num2str(src.Value);
    end
    CBgetsniffs;
end
function CBgetsniffs(~,~)
    %show detected sniffs for current trial using current settings
    %Note that peaks are exhalation(high pressure), troughs are inhalation  
    if isempty(behaviordata); return; end
    cla(hAx); hold(hAx,'on');
    tnum = hTrial.Value;
    times = behaviordata.trials(tnum).ephys.times - behaviordata.trials(tnum).ephys.times(1);
    samp_rate = 1/diff(times(1:2));
    Ztemp = zscore(behaviordata.trials(tnum).ephys.sniff);
    %lowpass filter 
    lpval = str2double(hLPedit.String);
    Wn_lp = lpval/(0.5*samp_rate); %For digital filters cutoff must lie between 0 and 1, where 1 corresponds to Nyquist rate
    if (Wn_lp>=1)
        errordlg(['Maximum filter frequency = ' num2str(0.5*samp_rate)]);
        hLPedit.String = num2str(0.5*samp_rate); hLP.Value = 0.5*samp_rate; hLP.Max = hLP.Value;
        lpval = str2double(hLPedit.String); Wn_lp = lpval/(0.5*samp_rate);
    end
    N = 1;
    [b,a] = butter(N,Wn_lp, 'low');
    Ztemp = filtfilt(b,a,Ztemp);
    %highpass filter
    hpval = str2double(hHPedit.String);
    Wn_hp = hpval/(0.5*samp_rate);
    if (Wn_hp>0)
        N = 1;
        [bhigh, ahigh] = butter(N,Wn_hp, 'high');
        Ztemp = filtfilt(bhigh,ahigh,Ztemp);
    end
    %notes:
    %MinPeriod = hMPD.Value*samp_rate;
    %MinWidth = hMPW.Value*samp_rate;
    %MaxWidth = hMxPW.Value*samp_rate;    
    findpeaks_mwlab(hAx,times,Ztemp,'MinPeakHeight',hMPH.Value,'MinPeakProminence',hMPP.Value,...
        'MinPeakDistance',hMPD.Value*samp_rate,'MinPeakWidth',hMPW.Value*samp_rate,'MaxPeakWidth',hMxPW.Value*samp_rate,'Annotate','extents');
%     plot(hAx,times,Ztemp); plot(hAx,times(locs),pks,'o');
     plot(hAx,times,hMPH.Value*ones(1,length(behaviordata.trials(tnum).ephys.times)),'--g','DisplayName','Min Peak Height');
    hAx.YLim = [-5 5];
    [inpks,inlocs] = findpeaks_mwlab(hAx,times,-Ztemp,'MinPeakHeight',hMPH.Value,'MinPeakProminence',hMPP.Value,...
        'MinPeakDistance',hMPD.Value*samp_rate,'MinPeakWidth',hMPW.Value*samp_rate,'MaxPeakWidth',hMxPW.Value*samp_rate,'Annotate','extents');
    plot(hAx,times(inlocs),-inpks,'or','DisplayName','troughs');
end

function CB_SaveTrial(~,~)
    %show detected sniffs for current trial using current settings (and save results for this trial)
    %Note that peaks are exhalation(high pressure), troughs are inhalation  
    tnum = hTrial.Value;
    times = behaviordata.trials(tnum).ephys.times - behaviordata.trials(tnum).ephys.times(1);
    samp_rate = 1/diff(times(1:2));
    Ztemp = zscore(behaviordata.trials(tnum).ephys.sniff);
    %lowpass filter
    lpval = hLP.Value;
    Wn_lp = lpval/(0.5*samp_rate); %For digital filters cutoff must lie between 0 and 1, where 1 corresponds to Nyquist rate
    if (Wn_lp>=1)
        errordlg(['Maximum filter frequency = ' num2str(0.5*samp_rate)]);
        hLP.Value = 0.5*samp_rate; hLP.Max = hLP.Value; hLPedit.String = num2str(0.5*samp_rate); 
        lpval = hLP.Value; Wn_lp = lpval/(0.5*samp_rate);
    end
    N = 1;
    [b,a] = butter(N,Wn_lp, 'low');
    Ztemp = filtfilt(b,a,Ztemp);
    %highpass filter
    hpval = hHP.Value;
    Wn_hp = hpval/(0.5*samp_rate);
    if (Wn_hp>0)
        N = 1;
        [bhigh, ahigh] = butter(N,Wn_hp, 'high');
        Ztemp = filtfilt(bhigh,ahigh,Ztemp);
    end
    %notes:
    %MinPeriod = hMPD.Value*samp_rate;
    %MinWidth = hMPW.Value*samp_rate;
    %MaxWidth = hMxPW.Value*samp_rate;
    %peaks
    [peaks,plocs,pwidths,~]= findpeaks_mwlab(hAx,times,Ztemp,'MinPeakHeight',hMPH.Value,'MinPeakProminence',hMPP.Value,...
        'MinPeakDistance',hMPD.Value*samp_rate,'MinPeakWidth',hMPW.Value*samp_rate,'MaxPeakWidth',hMxPW.Value*samp_rate);
    out(tnum).peaks = peaks;
    out(tnum).peaks_index = plocs;
    out(tnum).peaks_times = times(plocs);
    out(tnum).peaks_freq = diff(out(tnum).peaks_times); 
    out(tnum).peaks_freq = 1./out(tnum).peaks_freq;
    out(tnum).peaks_freq_times = out(tnum).peaks_times(1:end-1) + diff(out(tnum).peaks_times)/2;
    out(tnum).peaks_widths = pwidths;
    %troughs
    [troughs,tlocs,twidths,~]= findpeaks_mwlab(hAx,times,-Ztemp,'MinPeakHeight',hMPH.Value,'MinPeakProminence',hMPP.Value,...
        'MinPeakDistance',hMPD.Value*samp_rate,'MinPeakWidth',hMPW.Value*samp_rate,'MaxPeakWidth',hMxPW.Value*samp_rate);
    out(tnum).troughs = troughs;
    out(tnum).troughs_index = tlocs;
    out(tnum).troughs_times = times(tlocs);
    out(tnum).troughs_freq = diff(out(tnum).troughs_times); 
    out(tnum).troughs_freq = 1./out(tnum).troughs_freq;
    out(tnum).troughs_freq_times = out(tnum).troughs_times(1:end-1) + diff(out(tnum).troughs_times)/2;
    out(tnum).troughs_widths = twidths;
    %find peak starts - inflection points
    dZ = [0 diff(Ztemp)]; ddZ = [0 diff(dZ)];
    for i = 1:length(plocs)
        if isempty(find(tlocs<plocs(i),1,'last'))
            [~,maxind] = max(dZ(1:plocs(i)).*ddZ(1:plocs(i)));
            out(tnum).peaks_startindex(i) = maxind;
            out(tnum).peaks_starttimes(i) = times(out(tnum).peaks_startindex(i));
        else
            lastind = find(tlocs<plocs(i),1,'last');
            [~,maxind] = max(dZ(tlocs(lastind):plocs(i)).*ddZ(tlocs(lastind):plocs(i)));
            out(tnum).peaks_startindex(i) = tlocs(lastind)-1+maxind;
            out(tnum).peaks_starttimes(i) = times(out(tnum).peaks_startindex(i));
        end
    end
    %find trough starts - inflection points
    for i = 1:length(tlocs)
        if isempty(find(plocs<tlocs(i),1,'last'))
            [~,maxind] = max(dZ(1:tlocs(i)).*ddZ(1:tlocs(i)));
            out(tnum).troughs_startindex(i) = maxind;
            out(tnum).troughs_starttimes(i) = times(out(tnum).troughs_startindex(i));
        else
            lastind = find(plocs<tlocs(i),1,'last');
            [~,maxind] = max(dZ(plocs(lastind):tlocs(i)).*ddZ(plocs(lastind):tlocs(i)));
            out(tnum).troughs_startindex(i) = plocs(lastind)-1+maxind;
            out(tnum).troughs_starttimes(i) = times(out(tnum).troughs_startindex(i));
        end
    end
    %settings
    out(tnum).sniffs = Ztemp;
    out(tnum).settings.LPval = hLP.Value; %low pass filter
    out(tnum).settings.HPval = hHP.Value; %high pass filter
    out(tnum).settings.MinHeight = hMPH.Value; %min peak height
    out(tnum).settings.MinProm = hMPP.Value; %min peak prominence
    out(tnum).settings.MinPeriod = hMPD.Value*samp_rate; %min peak period(distance)
    out(tnum).settings.MinWidth = hMPW.Value*samp_rate; %min peak width
    out(tnum).settings.MaxWidth = hMxPW.Value*samp_rate; %max peak width
end

function CB_SaveAll(~,~)
    %Note that peaks are exhalation(high pressure), troughs are inhalation  
    for tnum = 1:length(behaviordata.trials)
        times = behaviordata.trials(tnum).ephys.times - behaviordata.trials(tnum).ephys.times(1);
        samp_rate = 1/diff(times(1:2));
        Ztemp = zscore(behaviordata.trials(tnum).ephys.sniff);
        %lowpass filter
        lpval = hLP.Value;
        Wn_lp = lpval/(0.5*samp_rate); %For digital filters cutoff must lie between 0 and 1, where 1 corresponds to Nyquist rate
        if (Wn_lp>=1)
            errordlg(['Maximum filter frequency = ' num2str(0.5*samp_rate)]);
            hLP.Value = 0.5*samp_rate; hLP.Max = hLP.Value; hLPedit.String = num2str(0.5*samp_rate);
            lpval = hLP.Value; Wn_lp = lpval/(0.5*samp_rate);
        end
        N = 1;
        [b,a] = butter(N,Wn_lp, 'low');
        Ztemp = filtfilt(b,a,Ztemp);
        %highpass filter
        hpval = hHP.Value;
        Wn_hp = hpval/(0.5*samp_rate);
        if (Wn_hp>0)
            N = 1;
            [bhigh, ahigh] = butter(N,Wn_hp, 'high');
            Ztemp = filtfilt(bhigh,ahigh,Ztemp);
        end
        %notes:
        %MinPeriod = hMPD.Value*samp_rate;
        %MinWidth = hMPW.Value*samp_rate;
        %MaxWidth = hMxPW.Value*samp_rate;
        %peaks
        [peaks,plocs,pwidths,~]= findpeaks_mwlab(hAx,times,Ztemp,'MinPeakHeight',hMPH.Value,'MinPeakProminence',hMPP.Value,...
            'MinPeakDistance',hMPD.Value*samp_rate,'MinPeakWidth',hMPW.Value*samp_rate,'MaxPeakWidth',hMxPW.Value*samp_rate);
        out(tnum).peaks = peaks;
        out(tnum).peaks_index = plocs;
        out(tnum).peaks_times = times(plocs);
        out(tnum).peaks_freq = diff(out(tnum).peaks_times); 
        out(tnum).peaks_freq = 1./out(tnum).peaks_freq;
        out(tnum).peaks_freq_times = out(tnum).peaks_times(1:end-1) + diff(out(tnum).peaks_times)/2;
        out(tnum).peaks_widths = pwidths;
        %troughs
        [troughs,tlocs,twidths,~]= findpeaks_mwlab(hAx,times,-Ztemp,'MinPeakHeight',hMPH.Value,'MinPeakProminence',hMPP.Value,...
            'MinPeakDistance',hMPD.Value*samp_rate,'MinPeakWidth',hMPW.Value*samp_rate,'MaxPeakWidth',hMxPW.Value*samp_rate);
        out(tnum).troughs = troughs;
        out(tnum).troughs_index = tlocs;
        out(tnum).troughs_times = times(tlocs);
        out(tnum).troughs_freq = diff(out(tnum).troughs_times); 
        out(tnum).troughs_freq = 1./out(tnum).troughs_freq;
        out(tnum).troughs_freq_times = out(tnum).troughs_times(1:end-1) + diff(out(tnum).troughs_times)/2;
        out(tnum).troughs_widths = twidths;
        %find peak starts - inflection points
        dZ = [0 diff(Ztemp)]; ddZ = [0 diff(dZ)];
        for i = 1:length(plocs)
            if isempty(find(tlocs<plocs(i),1,'last'))
                [~,maxind] = max(dZ(1:plocs(i)).*ddZ(1:plocs(i)));
                out(tnum).peaks_startindex(i) = maxind;
                out(tnum).peaks_starttimes(i) = times(out(tnum).peaks_startindex(i));
            else
                lastind = find(tlocs<plocs(i),1,'last');
                [~,maxind] = max(dZ(tlocs(lastind):plocs(i)).*ddZ(tlocs(lastind):plocs(i)));
                out(tnum).peaks_startindex(i) = tlocs(lastind)-1+maxind;
                out(tnum).peaks_starttimes(i) = times(out(tnum).peaks_startindex(i));
            end
        end
        %find trough starts - inflection points
        for i = 1:length(tlocs)
            if isempty(find(plocs<tlocs(i),1,'last'))
                [~,maxind] = max(dZ(1:tlocs(i)).*ddZ(1:tlocs(i)));
                out(tnum).troughs_startindex(i) = maxind;
                out(tnum).troughs_starttimes(i) = times(out(tnum).troughs_startindex(i));
            else
                lastind = find(plocs<tlocs(i),1,'last');
                [~,maxind] = max(dZ(plocs(lastind):tlocs(i)).*ddZ(plocs(lastind):tlocs(i)));
                out(tnum).troughs_startindex(i) = plocs(lastind)-1+maxind;
                out(tnum).troughs_starttimes(i) = times(out(tnum).troughs_startindex(i));
            end
        end
        %settings
        out(tnum).sniffs = Ztemp;
        out(tnum).settings.LPval = hLP.Value; %low pass filter
        out(tnum).settings.HPval = hHP.Value; %high pass filter
        out(tnum).settings.MinHeight = hMPH.Value; %min peak height
        out(tnum).settings.MinProm = hMPP.Value; %min peak prominence
        out(tnum).settings.MinPeriod = hMPD.Value*samp_rate; %min peak period(distance)
        out(tnum).settings.MinWidth = hMPW.Value*samp_rate; %min peak width
        out(tnum).settings.MaxWidth = hMxPW.Value*samp_rate; %max peak width
    end
end

end