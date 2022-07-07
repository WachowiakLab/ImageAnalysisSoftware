function [] = avgNeuroplexFilesGUI()
%select and average neuroplex odor files

[filenames,filepath] = uigetfile('*.da','****Select Raw Data Neuroplex Files****','MultiSelect','on');
if ~iscellstr(filenames); return; end
[listname,listpath] = uigetfile('*.txt','****Select Odor Number/Name List****');
listfid = fopen(fullfile(listpath,listname));
odorlist = textscan(listfid,'%f %s %s','Delimiter','\t');
fclose(listfid);
avgfilenames = [];

odornums = cell(numel(filenames),1); odornumstr = cell(numel(filenames),1); odornames = cell(numel(filenames),1);
for f = 1:numel(filenames)
    if f ==1; aux2bnc = assignNeuroplexBNC; end
    [~,~,aux3] = loadNeuroplexStimulus(fullfile(filepath,filenames{f}),aux2bnc);
    if ~isempty(aux3) && isfield(aux3,'odors')
        odornums{f} = aux3.odors;
    else
        odornums{f} = 0;
    end
    odornumstr{f} = ''; odornames{f} = '';
    for o = 1:length(odornums{f})
        if isempty(odornumstr{f})
            odornumstr{f} = num2str(odornums{f}(o));
        else
            odornumstr{f} = [odornumstr{f} ', ' num2str(odornums{f}(o))];
        end
    end
    for o = 1:length(odornums{f})
        idx = find(odorlist{1} == odornums{f}(o));
        if isempty(odornames{f})
            if isempty(idx)
                odornames{f} = 'NA';
            else
                odornames{f} = [cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx))];
            end
        else
            if isempty(idx)
                odornames{f} = [odornames{f} ', NA'];
            else
                odornames{f} = [odornames{f} ', ' cell2mat(odorlist{2}(idx)) ' ' cell2mat(odorlist{3}(idx))];
            end
        end
    end
end

h.fig = figure('NumberTitle','off','Name','Average Neuroplex Files','units','normalized','position',[.15 .1 .7 .8]);
uicontrol(h.fig,'style','text','Fontsize',14,'FontWeight','bold','string','Raw Data Files:',...
    'units','normalized','position',[.02 .94 .12 .04]);
h.filelist = uicontrol(h.fig,'style','listbox','units','normalized','position',[.02 .05 .12 .9],...
    'string',filenames,'Max',numel(filenames),'Callback',@CBSelect);
uicontrol(h.fig,'style','text','Fontsize',14,'FontWeight','bold','string','Odors:',...
    'units','normalized','position',[.15 .94 .08 .04]);
h.odornumlist = uicontrol(h.fig,'style','listbox','units','normalized','position',[.15 .05 .08 .9],...
    'string',odornumstr,'Max',numel(odornumstr),'Callback',@CBSelect,'ButtonDownFcn',@CBAutoSelect);
uicontrol(h.fig,'style','text','Fontsize',14,'FontWeight','bold','string','Odor Names:',...
    'units','normalized','position',[.24 .94 .2 .04]);
h.odornamelist = uicontrol(h.fig,'style','listbox','units','normalized','position',[.24 .05 .2 .9],...
    'string',odornames,'Max',numel(odornames),'Callback',@CBSelect,'ButtonDownFcn',@CBAutoSelect);

uicontrol(h.fig,'style','text','Fontsize',12,'string','# Files Selected:',...
    'units','normalized','position',[.46 .92 .1 .02]);
h.numfileselected = uicontrol(h.fig,'style','text','Fontsize',12,'BackgroundColor','white',...
    'units','normalized','position',[.46 .89 .1 .02],'String','1');
uicontrol(h.fig,'style','text','Fontsize',12,'string','# Odors Selected:',...
    'units','normalized','position',[.46 .84 .1 .02]);
h.numodorselected = uicontrol(h.fig,'style','text','Fontsize',12,'BackgroundColor','white',...
    'units','normalized','position',[.46 .81 .1 .02],'String','1');
%Average
h.avgselected = uicontrol(h.fig,'style','pushbutton','Fontsize',12,'FontWeight','bold','String','Average Selected',...
    'units','normalized','position',[.58 .88 .2 .06],'Callback',@CBAvgSelected);
%Odor-Average
h.autoaverage = uicontrol(h.fig,'Style', 'pushbutton','Units','normalized','Position', ...
    [.58 .79 .2 .06],'String','Average Selected by Odor','FontSize',12,'FontWeight','Bold','Callback',@CBAvgSelectedByOdor);
uicontrol(h.fig,'style','text','Fontsize',12,'string','Filename Prefix:',...
    'units','normalized','position',[.58 .75 .1 .02]);
h.nameprefix = uicontrol(h.fig,'style','edit','Fontsize',12,'BackgroundColor','white',...
    'units','normalized','position',[.68 .745 .1 .03]);

%Results List
uicontrol(h.fig,'style','text','Fontsize',14,'FontWeight','bold','string','Saved Averaged File(s):',...
    'units','normalized','position',[.46 .65 .52 .04]);
h.avgfilelist = uicontrol(h.fig,'style','listbox','String',avgfilenames,'Max',length(filenames),...
    'units','normalized','position',[.46 .05 .52 .6]);

function CBSelect(~,~)
    clicked = h.fig.CurrentObject;
    h.filelist.Value = clicked.Value;
    h.odornumlist.Value = clicked.Value;
    h.odornamelist.Value = clicked.Value;
    h.numfileselected.String = num2str(length(clicked.Value));
    ind = clicked.Value;
    odors = [];
    for i = 1:length(ind)
        tmpodor = h.odornumlist.String{ind(i)};
        tmpidx = find(strcmp(odors,tmpodor),1);
        if isempty(tmpidx)
            odors{end+1} = tmpodor;
        end
    end
    h.numodorselected.String = num2str(length(odors));
end
function CBAutoSelect(~,~)
    clicked = h.fig.CurrentObject;
    ind = clicked.Value;
    match = [];
    for i = 1:length(ind)
        tmpmatch = find(strcmp(clicked.String,clicked.String{ind(i)}));
        match = union(match,tmpmatch);
    end
    h.filelist.Value = match;
    h.odornumlist.Value = match;
    h.odornamelist.Value = match;
    h.numfileselected.String = num2str(length(match));
end
function CBAvgSelected(~,~)
    tmpval = h.filelist.Value;
    tmpbar=waitbar(0,'Averaging Selected Files');
    for nn = 1:length(tmpval)
        waitbar(nn/length(tmpval),tmpbar);
        fid(nn) = fopen(fullfile(filepath,filenames{tmpval(nn)}));
        header = fread(fid(nn), 2560, 'int16');
        dat = fread(fid(nn), inf, 'int16');
        if nn == 1; allsize = length(dat);
        elseif length(dat) ~= allsize; msgbox('Error, File sizes do not match!'); return; end
        fclose(fid(nn));
        if nn==1
            im = dat;
        else
            im = im+dat;
        end   
    end
    delete(tmpbar);
    im = im./length(tmpval);
    tmpname = h.odornamelist.String{tmpval(1)};
    if ~isempty(h.nameprefix.String); tmpname = [h.nameprefix.String tmpname]; end
    if isdir([listpath 'Odor Averaged Data']);  tmpname = fullfile([listpath 'Odor Averaged Data'],tmpname); end
    [newfilename,newpath]=uiputfile('*.da','Save Averaged Neuroplex File',tmpname);
    nfid = fopen(fullfile(newpath,newfilename),'w');
    fwrite(nfid,[header;im],'int16');
    fclose(nfid);
    h.avgfilelist.String{end+1} = fullfile(newpath,newfilename);
    if ~isfield(h,'avgfilelistodornum'); h.avgfilelistodornum = []; end
    h.avgfilelistodornum{end+1} = h.odornumlist.String{tmpval(1)};
end

function CBAvgSelectedByOdor(~,~)
    %find odors, save with matching files
    tmpval = h.filelist.Value;
    newname = []; newheader = []; newdat = []; cnt = []; newodornum = [];
    tmpbar = waitbar(0,'Averaging Selected Files by Odor');
    for n = 1:length(tmpval)
        waitbar(n/length(tmpval),tmpbar);
        fid = fopen(fullfile(filepath,filenames{tmpval(n)}));
        header = fread(fid, 2560, 'int16');
        dat = fread(fid, inf, 'int16');
        fclose(fid);
        tmpname = h.odornamelist.String{tmpval(n)};
        tmpodornum = str2num(h.odornumlist.String{tmpval(n)});
        tmpidx = find(strcmp(newname,tmpname));
        if isempty(tmpidx)
            newname{end+1} = tmpname;
            newodornum{end+1} = tmpodornum;
            idx(n) = length(newname); 
            newheader{end+1} = header;
            newdat{end+1} = dat;
            cnt(end+1) = 1;
        else
            idx(n) = tmpidx; 
            newdat{tmpidx} = newdat{tmpidx}+dat;
            cnt(tmpidx) = cnt(tmpidx)+1;
        end
    end
    delete(tmpbar);
    %average matching odors
    if isdir([listpath 'Odor Averaged Data']); newpath = [listpath 'Odor Averaged Data']; else; newpath = listpath; end
    newpath = uigetdir(newpath,'Select Folder to save Averaged Files');
    if isempty(newpath); return; end
    nameprefix = h.nameprefix.String;
    if ~isfield(h,'avgfilelistodornum'); h.avgfilelistodornum = []; end
    for i = 1:length(newname)
        newdat{i} = newdat{i}./cnt(i);
        newname{i} = fullfile(newpath,[nameprefix newname{i} '.da']);
        nfid(i) = fopen(newname{i},'w');
        fwrite(nfid(i),[newheader{i};newdat{i}],'int16');
        fclose(nfid(i));
        h.avgfilelist.String{end+1} = newname{i};
        h.avgfilelistodornum{end+1} = newodornum{i};
    end
end

end