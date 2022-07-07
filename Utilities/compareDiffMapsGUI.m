function [] = compareDiffMapsGUI()
%compare difference maps in Tif format using expID vs odor
%expIDs are taken from original filename - from start to last underscore

expIDs = {[]}; odors = {[]}; maps.im = []; maps.expID = []; maps.odor = []; maps.bRotate = [];

%figure
h.fig = figure('NumberTitle','off','Name','Compare Difference Maps','units','normalized','position',[.03 .35 .2 .55]);
uicontrol(h.fig,'style','pushbutton','Fontsize',14,'FontWeight','bold','string','Add Files',...
    'units','normalized','position',[.02 .94 .45 .05],'Callback',@CBAddFiles);
uicontrol(h.fig,'style','pushbutton','Fontsize',14,'FontWeight','bold','string','Display',...
    'units','normalized','position',[.52 .94 .45 .05],'Callback',@CBdisplay);
%List of Colormaps
uicontrol(h.fig,'Style', 'text', 'String', 'Colormaps: ','Units','normalized', ...
    'FontWeight','bold','HorizontalAlignment','left','Position',[.02 .90 .35 .03]);
cmapstrings = getcmaps;
uicontrol(h.fig,'Style', 'popupmenu', 'Tag','cmap_popupmenu','Units', 'normalized', 'Position', ...
    [.02 .87 .35 .03], 'String', cmapstrings, 'FontSize', 9, 'Value', 1);
uicontrol(h.fig,'Style', 'text', 'String', 'Colormap Limits: ','Units','normalized', ...
    'FontWeight','bold','HorizontalAlignment', 'left','Position',[.42 .90 .35 .03]);
uicontrol(h.fig,'Style', 'checkbox', 'Units', 'normalized', 'Position', [.42 .87 .35 .03], ...
    'Value', 1, 'String', 'Auto (min-max)','Tag','clim1','Callback',@CBmapLimits);
uicontrol(h.fig,'Style', 'checkbox', 'Units', 'normalized', 'Position', [.42 .84 .35 .03], ...
    'Value', 0, 'String', 'Auto (0.2-99.8%)', 'Tag','clim2','Callback',@CBmapLimits);
uicontrol(h.fig,'Style', 'checkbox', 'Units', 'normalized', 'Position', [.75 .89 .35 .03],...
    'Value', 0, 'String', 'Manual', 'Tag','clim3','Callback',@CBmapLimits);
uicontrol(h.fig,'Style', 'text', 'String', 'Cmin: ','Units','normalized' ...
    ,'Position',[.75 .85 .1 .03],'HorizontalAlignment','Right');
uicontrol(h.fig,'Style', 'edit', 'String', '0','Units','normalized', 'Callback', @CBmapLimits, ...
    'BackgroundColor',[1 1 1],'Position',[.85 .85 .1 .03],'HorizontalAlignment','Right', ...
    'Tag', 'Cmin', 'Enable', 'Off');
uicontrol(h.fig,'Style', 'text', 'String', 'Cmax: ','Units','normalized' ...
    ,'Position',[.75 .82 .1 .03],'HorizontalAlignment','Right');
uicontrol(h.fig,'Style', 'edit', 'String', '1','Units','normalized', 'Callback', @CBmapLimits, ...
    'BackgroundColor',[1 1 1],'Position',[.85 .82 .1 .03],'HorizontalAlignment','Right', ...
    'Tag', 'Cmax', 'Enable', 'Off');
%expID's and odors lists
uicontrol(h.fig,'style','text','Fontsize',14,'FontWeight','bold','string','ExpIDs:',...
    'units','normalized','position',[.02 .77 .35 .04]);
h.expIDlist = uicontrol(h.fig,'style','listbox','units','normalized','position',[.02 .02 .35 .75],...
    'string',expIDs,'Max',numel(expIDs),'Callback',@CBSelect);
uicontrol(h.fig,'style','text','Fontsize',14,'FontWeight','bold','string','Odors:',...
    'units','normalized','position',[.42 .77 .55 .04]);
h.odorlist = uicontrol(h.fig,'style','listbox','units','normalized','position',[.42 .02 .55 .75],...
    'string',odors,'Max',numel(odors),'Callback',@CBSelect);

function CBAddFiles(~,~)
    [tmpfilenames,filepath,ok] = uigetfile('*.tif','Select Tiff Maps (must have details in header)','MultiSelect','on');
    if ~ok; return; end
    if ~iscellstr(tmpfilenames); tmpfilenames = {tmpfilenames}; end
    if isfield(maps,'im') && ~isempty(maps(1).im); cnt = length(maps); else; cnt = 0; end
    for f = 1:numel(tmpfilenames)
        tmpinfo = imfinfo(fullfile(filepath,tmpfilenames{f}));
        for d = 1:numel(tmpinfo)
            cnt=cnt+1;
            maps(cnt).im = imread(fullfile(filepath,tmpfilenames{f}),d);
            %read details to get expid/odor
            tmp=strfind(tmpinfo(d).ImageDescription,'Details:');
            details = tmpinfo(d).ImageDescription(tmp+9:end);
            X=strsplit(details,'/'); %split details into file/odor/trial categories
            expidstr = ''; odorstr = ''; bRotate = 0; %bIsNeuroplex used to rotate the neuroplex images
            for x = 1:numel(X)
                switch rem(x,3)
                    case 1 %pull out expID(s) from file category
                        %here we decided to make expID be from start up to the last underscore in a filename
                        uscores = strfind(X{x},'_');
                        tmpid = X{x}(1:uscores(end)-1);
                        if isempty(expidstr); expidstr = tmpid; 
                        elseif ~contains(expidstr,tmpid); expidstr = [expidstr ', ' tmpid];
                        end
                        if contains(X{x},'.da'); bRotate = 1; end 
                    case 2 %pull out odor(s) from odor category
                        if isempty(odorstr); odorstr = X{x};
                        elseif ~contains(odorstr,X{x}); odorstr = [odorstr ', ' X{x}];
                        end
                end
            end
            maps(cnt).expID = expidstr;
            maps(cnt).odor = odorstr;
            maps(cnt).bRotate = bRotate;
        end
    end
    expIDs = []; odors = [];
    for f = 1:length(maps)
        if isempty(expIDs); expIDs{1}=maps(f).expID;
        else; expIDs = union(expIDs,maps(f).expID);
        end
        if isempty(odors); odors{1}=maps(f).odor;
        else; odors = union(odors,maps(f).odor);
        end
    end
    h.expIDlist.String = expIDs; h.expIDlist.Max = numel(expIDs);
    h.odorlist.String = odors; h.odorlist.Max = numel(odors);
end
function CBSelect(~,~)
    %could do something snappy like highlight the odors for selected files and vice
    %versa depending on which column you click... or not.
end
function CBdisplay(~,~)
    exp = h.expIDlist.Value;
    od = h.odorlist.Value;
    figHWratio = 1.2*length(exp)/length(od);
    %set up figure
    screens = get(0,'MonitorPositions'); figwidth = .9*screens(1,3); figheight = figwidth*figHWratio;
    if figheight > .8*screens(1,4); figheight = .8*screens(1,4); figwidth = figheight/figHWratio; end
    dfig = figure('Units','pixels','Position',[0.05*figwidth screens(1,4)-50-1.25*figheight figwidth figheight]);
    %setup axes
    axwidth = 1/length(od); axheight = 1/length(exp);
    for e = 1:length(exp)
        for o = 1:length(od)
            tmpax = axes(dfig,'Units','normalized','Position',[(o-1)*axwidth 1-(e*axheight) axwidth axheight], ...
                'DataAspectRatio',[1 1 1],'DataAspectRatioMode','manual','Visible','off');
            for m=1:length(maps)
                if strcmp(maps(m).expID,h.expIDlist.String{exp(e)}) && strcmp(maps(m).odor,h.odorlist.String{od(o)})
                    %what to do if >1 file has same exp/od
                    if ~isempty(tmpax.Children);fprintf(['Warning More than 1 image is present for expID %s,\n' ...
                        'odor %s, only first image will be shown\n'], maps(m).expID,maps(m).odor);
                        %axes(tmpax);
                    else
                        if maps(m).bRotate
                            imagesc(tmpax,rot90(maps(m).im)); axis image off;
                        else
                            imagesc(tmpax,maps(m).im); axis image off;
                        end
                        fsize=5+floor(tmpax.Position(3)*figwidth/80); %This kinda works - otherwise use fsize=6
                        title(sprintf('%s, %s',h.expIDlist.String{exp(e)},h.odorlist.String{od(o)}), ...
                            'FontSize',fsize,'Interpreter','none');
                        %set climits
                        if get(findobj(h.fig,'Tag','clim1'),'Value') %auto(min-max)
                            tmp1 = min(maps(m).im(:)); tmp2 = max(maps(m).im(:));
                            caxis(tmpax,[tmp1 tmp2]);
                        elseif get(findobj(h.fig,'Tag','clim2'),'Value') %auto(0.2-99.8%)
                            tmp = prctile(maps(m).im(:),[.02 99.8]);
                            caxis(tmpax,[tmp(1) tmp(2)]);
                        else %manual
                            tmp1 = str2num(get(findobj(h.fig,'Tag','Cmin'), 'String'));
                            tmp2 = str2num(get(findobj(h.fig,'Tag','Cmax'), 'String'));
                            caxis(tmpax,[tmp1 tmp2]);
                        end
                        val = get(findobj(h.fig,'Tag','cmap_popupmenu'), 'Value');
                        colormap(tmpax,[cmapstrings{val} '(256)']);
                    end
                end
            end
        end
    end
end
function CBmapLimits(~,~)
    clicked = h.fig.CurrentObject;
    if clicked.Value
        if strcmp(clicked.Tag,'clim1')
            set(findobj(h.fig,'Tag','clim2'),'Value',0);
            set(findobj(h.fig,'Tag','clim3'),'Value',0);
            set(findobj(h.fig,'Tag','Cmin'),'Enable','off'); set(findobj(h.fig,'Tag','Cmin'),'Value',0);
            set(findobj(h.fig,'Tag','Cmax'),'Enable','off'); set(findobj(h.fig,'Tag','Cmax'),'Value',1);
        elseif strcmp(clicked.Tag,'clim2')
            set(findobj(h.fig,'Tag','clim1'),'Value',0);
            set(findobj(h.fig,'Tag','clim3'),'Value',0);
            set(findobj(h.fig,'Tag','Cmin'),'Enable','off'); set(findobj(h.fig,'Tag','Cmin'),'Value',0);
            set(findobj(h.fig,'Tag','Cmax'),'Enable','off'); set(findobj(h.fig,'Tag','Cmax'),'Value',1);
        elseif strcmp(clicked.Tag,'clim3')
            set(findobj(h.fig,'Tag','clim1'),'Value',0);
            set(findobj(h.fig,'Tag','clim2'),'Value',0);
            set(findobj(h.fig,'Tag','Cmin'),'Enable','on'); set(findobj(h.fig,'Tag','Cmax'),'Enable','on');
        end
    else
        clicked.Value = 1;
    end
end

end