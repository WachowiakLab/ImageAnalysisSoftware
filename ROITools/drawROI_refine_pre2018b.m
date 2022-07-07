function rois = drawROI_refine_pre2018b(rois,bgimage,imstack,varargin)
%function rois = drawROI_refine(rois,bgimage,imstack,varargin)

prev = findobj('Name','Draw ROI');
disp(prev);
if ~isempty(prev)
    close(prev);
    clear h;
    %clear hROI.fig;
end
% create ROI figure
global hROI ROIdata;
hROI.fig = figure('NumberTitle','off','Name','Draw ROI','Menubar','none','ToolBar','figure',...
    'Units', 'Normalized', 'Position', [0.2 0.2 0.6 0.7],'CloseRequestFcn',@CB_CloseFig);
% Zoomin,Zoomout,Pan, & selectROI Menu
tbh=findall(hROI.fig,'Type','uitoolbar');
tools=findall(tbh);
delete(tools(2:9));
if numel(tools)>10; delete(tools(14:17)); end
hROI.Zoom=zoom(hROI.fig);

function CB_CloseFig(~,~)
    delete(hROI.fig);
    rois=ROIdata.rois;
    clearvars -global ROIdata;
    clearvars -global hROI;
end
%Buttons/Controls
%hROI.methodbuttongroup = uibuttongroup('units','normalized','position',[0 .9 .5 .1],'SelectionChangedFcn',@CBROImethod);
hROI.polygonmethod =  uicontrol(hROI.fig,'Style','pushbutton','units','normalized','position',...
    [0.02 .96 .16 .03],'String','Polygon Method','Callback',@CBpolygon);
uicontrol(hROI.fig,'Style','text','units','normalized','position',[.02 .92 .16 .04],'HorizontalAlignment','center',...
    'String',sprintf('<Click to create a polygon>\nUse "Esc" key to quit'));
hROI.quickmethod =  uicontrol(hROI.fig,'Style','togglebutton','units','normalized','position',...
    [0.19 .96 .16 .03],'String','Quick Square Method','Callback',@CBquicksquare);
uicontrol(hROI.fig,'Style','text','units','normalized','position',[.19 .94 .16 .02],'HorizontalAlignment','center',...
    'String',sprintf('<Click to select a spot>'));
uicontrol(hROI.fig,'Style','text','units','normalized','position',[.19 .91 .09 .02],'String','length/width (pixels):');
hROI.quicksize_edit = uicontrol(hROI.fig,'style','edit','units','normalized','position',[.28 .91 .06 .02],...
    'BackgroundColor',[1 1 1],'String',10);
hROI.thresholdmethod =  uicontrol(hROI.fig,'Style','togglebutton','units','normalized','position',...
    [.36 0.96 .16 .03],'String','Threshold Method','Callback',@CBthreshold);
uicontrol(hROI.fig,'Style','text','units','normalized','position',[.36 .90 .18 .06],'HorizontalAlignment','center',...
    'String',sprintf('<Click for auto-thresholding>\nScrollwheel adjusts threshold.\nLeft click to save ROI.'));
hROI.numrois_text = uicontrol(hROI.fig,'style','text','units','normalized','position',...
    [.53 .97 .16 .02],'Fontsize',10,'Fontweight','bold','String','Number of ROIs: 0');
uicontrol(hROI.fig,'style','text','units','normalized','position',[.52 .94 .09 .02],'HorizontalAlignment','right',...
    'String','Current threshold:');
hROI.thresh_edit = uicontrol(hROI.fig,'style','edit','units','normalized','position',[.62 .94 .1 .02],...
    'BackgroundColor',[1 1 1]);
hROI.invert_thresh = uicontrol(hROI.fig,'style','togglebutton','units','normalized',...
    'position',[.54 .91 .18 .025],'String','Invert threshold','Callback',@CBInvert);
%Cmin/Cmax
hROI.autoCaxis = uicontrol(hROI.fig,'Style', 'checkbox',  'Units', 'normalized', 'Position', ...
    [0.75 0.96 0.2 0.02], 'String', 'Auto Caxis (0.2-99.8%)','Value', 1,'Callback', @CBsetClim);
uicontrol(hROI.fig,'Style', 'text', 'String', 'Cmin: ','Units','normalized' ...
    ,'Position',[0.75 0.935 0.05 0.02],'HorizontalAlignment','Right');
uicontrol(hROI.fig,'Style', 'text', 'String', 'Cmax: ','Units','normalized' ...
    ,'Position',[0.75 0.91 0.05 0.02],'HorizontalAlignment','Right');
hROI.cmin_edit = uicontrol(hROI.fig,'Style', 'edit', 'String', '0','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.8 0.935 0.06 0.02],'HorizontalAlignment','Right', ...
    'Callback', @CBsetClim);
hROI.cmax_edit = uicontrol(hROI.fig,'Style', 'edit', 'String', '1','Units','normalized' ...
    ,'BackgroundColor',[1 1 1],'Position',[0.8 0.91 0.06 0.02],'HorizontalAlignment','Right',...
    'Callback', @CBsetClim);
hROI.min = uicontrol(hROI.fig,'Style', 'text', 'String', '(Min = 0)','Units','normalized' ...
    ,'Position',[0.87 0.935 0.15 0.02],'HorizontalAlignment','Left');
hROI.max = uicontrol(hROI.fig,'Style', 'text', 'String', '(Max = 0)','Units','normalized' ...
    ,'Position',[0.87 0.91 0.15 0.02],'HorizontalAlignment','Left');

% axes for image display
hROI.newaxes = axes;
% inputs
ROIdata.rois = rois; ROIdata.bgimage=bgimage; ROIdata.imstack=imstack;
hROI.th_min=floor(double(min(ROIdata.bgimage(:)))); hROI.min.String = sprintf('(Min = %5.3f)',hROI.th_min); 
hROI.th_max=ceil(double(max(ROIdata.bgimage(:)))); hROI.max.String = sprintf('(Max = %5.3f)',hROI.th_max);
hROI.thresh_edit.String = sprintf('%5.3f',hROI.th_max);
hROI.stepsize = (hROI.th_max-hROI.th_min)/100;
if nargin >3 %colormap
    hROI.cmap=varargin{1};
else
    hROI.cmap=gray(256);
end
if nargin >4 %caxis
    tmplim=varargin{2};
    hROI.autoCaxis.Value = 0;
    hROI.cmin_edit.String = sprintf('%5.3f',tmplim(1));
    hROI.cmax_edit.String = sprintf('%5.3f',tmplim(2));
else
    hROI.autoCaxis.Value = 1;
    hROI.cmin_edit.Enable = 'off'; hROI.cmax_edit.Enable = 'off';
end
drawBG;
hROI.polyactive = 0; hROI.pixvalue=[]; bw=[];
waitfor(hROI.fig); %Wait until figure closes to return value of rois!

function drawBG %draw background image
    hold(hROI.newaxes,'off');
    %imagesc(hROI.newaxes,ROIdata.bgimage); %doesn't work with matlab 2015a
    axis(hROI.newaxes);
    imagesc(ROIdata.bgimage);
    axis(hROI.newaxes,'off');
    axis(hROI.newaxes,'image');
    hROI.newaxes.XLimMode = 'manual'; hROI.newaxes.YLimMode = 'manual'; hROI.newaxes.ZLimMode = 'manual';
    set(hROI.newaxes, 'Position', [0 0 1 .9]);
    try
        if isempty(find(hROI.cmap~=gray(length(hROI.cmap)),1))
            hROI.bGray = 1;
        else
            hROI.bGray = 0;
        end
    catch
        hROI.bGray = 0;
    end
    colormap(hROI.newaxes,hROI.cmap);
    if hROI.autoCaxis.Value
        tmplim = qprctile(ROIdata.bgimage(:),[0.2 99.8]);
%         if abs(tmplim(2))>10; round tmplim; end
        if tmplim(2) == tmplim(1); tmplim(2) = tmplim(1)+1; end %just in case the image is all zeros    
        hROI.newaxes.CLim = tmplim;
        hROI.cmin_edit.String = sprintf('%5.3f',tmplim(1));
        hROI.cmax_edit.String = sprintf('%5.3f',tmplim(2));
    else 
        hROI.newaxes.CLim = [str2num(hROI.cmin_edit.String) str2num(hROI.cmax_edit.String)];
    end
    CBsetClim;
    hold(hROI.newaxes,'on');
    % Draw existing ROIs if present
    if isempty(ROIdata.rois)
        ROIdata.nROI = 0;
    else             
        ROIdata.nROI = length(ROIdata.rois);
        for n=1:length(ROIdata.rois)
            warning('off','MATLAB:contour:ConstantData');
            contour(ROIdata.rois(n).mask, [1,1].*0.5,'LineColor',myColors(n),'LineWidth',1.5);
            warning('on','MATLAB:contour:ConstantData');
        end
    end
    hROI.numrois_text.String = sprintf('Number of ROIs: %s',num2str(ROIdata.nROI));
end

function CBsetClim(~,~)
    if hROI.autoCaxis.Value
        hROI.cmin_edit.Enable = 'off';hROI.cmax_edit.Enable = 'off';
        tmplim = qprctile(ROIdata.bgimage(:),[0.2 99.8]);
%         if abs(tmplim(2))>10; round tmplim; end
        hROI.newaxes.CLim = tmplim;
        hROI.cmin_edit.String = sprintf('%5.3f',tmplim(1));
        hROI.cmax_edit.String = sprintf('%5.3f',tmplim(2));
    else
        hROI.cmin_edit.Enable = 'on';hROI.cmax_edit.Enable = 'on';
        hROI.newaxes.CLim = [str2num(hROI.cmin_edit.String) str2num(hROI.cmax_edit.String)];
    end
    hROI.th_min=hROI.newaxes.CLim(1); hROI.th_max=hROI.newaxes.CLim(2);
    hROI.stepsize = (hROI.th_max-hROI.th_min)/100;
    thresh=str2num(hROI.thresh_edit.String);
    if thresh < hROI.th_min; thresh=hROI.th_min; end
    if thresh > hROI.th_max; thresh=hROI.th_max; end
    hROI.thresh_edit.String = sprintf('%5.3f',thresh);
end

function CBInvert(~,~)
    if hROI.invert_thresh.Value
        hROI.thresh_edit.String = sprintf('%5.3f',hROI.newaxes.CLim(1));
        hROI.invert_thresh.ForegroundColor = 'red';
    else
        hROI.thresh_edit.String = sprintf('%5.3f',hROI.newaxes.CLim(2));
        hROI.invert_thresh.ForegroundColor = 'black';
    end
end

function CBpolygon(~,~)
    persistent newcontour;
    if strcmp(hROI.Zoom.Enable,'on'); hROI.Zoom.Enable='off'; end
    if isfield(hROI,'pixvalue') && ~isempty(hROI.pixvalue); delete(hROI.pixvalue); end    
    hROI.polyactive=1;
    hROI.polygonmethod.ForegroundColor = 'green';
    if exist('newcontour','var'); delete(newcontour); end
%     hROI.fig.WindowButtonMotionFcn=[];
    hROI.fig.WindowScrollWheelFcn=[];
    hROI.fig.WindowButtonDownFcn=[];
    hROI.thresholdmethod.Value=0; hROI.thresholdmethod.ForegroundColor = 'black';
    hROI.quickmethod.Value = 0; hROI.quickmethod.ForegroundColor = 'black';
    newROI = impoly(hROI.newaxes, []);
    if isempty(newROI)
        delete(newROI);
    else
        newmask = createMask(newROI); delete(newROI);
        warning('off','MATLAB:contour:ConstantData');
        [~,newcontour] = contour(double(newmask), 1, 'LineColor','white');
        warning('on','MATLAB:contour:ConstantData');
        answr = questdlg('Are you Done, or would you like to Refine the ROI?', 'Refine ROI?', 'Refine', 'Done', 'Done');
        if exist('newcontour','var'); delete(newcontour); end
        if strcmp(answr,'Refine')
            newmask=refine(newmask);
        end
        if ~isempty(newmask)
            ROIdata.nROI=ROIdata.nROI+1;
            ROIdata.rois(ROIdata.nROI).mask = newmask;
        end
        clear newmask;
    end
    hROI.polygonmethod.ForegroundColor = 'black';
    hROI.polyactive=0;
    xl=hROI.newaxes.XLim; yl=hROI.newaxes.YLim;
    drawBG;
    hROI.newaxes.XLim=xl; hROI.newaxes.YLim=yl;
end
function CBquicksquare(~,~)
    if strcmp(hROI.Zoom.Enable,'on'); hROI.Zoom.Enable='off'; end
    hROI.thresholdmethod.Value = 0; hROI.thresholdmethod.ForegroundColor = 'black';
    if hROI.polyactive
        %use java robot to press escape key - in case impoly is still active
        robot = java.awt.Robot;
        robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
        robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE);
        clear robot;
        hROI.thresholdmethod.Value=0;
        return;
    else
        %iptPointerManager(hROI.fig, 'disable'); %deals with bug in impoly
%         hROI.fig.WindowScrollWheelFcn=[];
        hROI.fig.WindowButtonDownFcn=[];
        if hROI.quickmethod.Value
            hROI.quickmethod.ForegroundColor = 'green';
            if isempty(hROI.fig.WindowButtonDownFcn)
                iptaddcallback(hROI.fig,'WindowButtonDownFcn',@CBQuickClick);
            end
        else
            hROI.quickmethod.ForegroundColor = 'black';
        end
    end
end
function CBthreshold(~,~)
    if strcmp(hROI.Zoom.Enable,'on'); hROI.Zoom.Enable='off'; end
    if isfield(hROI,'pixvalue') && ~isempty(hROI.pixvalue); delete(hROI.pixvalue); end    
    hROI.quickmethod.Value = 0; hROI.quickmethod.ForegroundColor = 'black';
    if hROI.polyactive
        %use java robot to press escape key - in case impoly is still active
        robot = java.awt.Robot;
        robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
        robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE);
        clear robot;
        hROI.thresholdmethod.Value=0;
        return;
    else
        %iptPointerManager(hROI.fig, 'disable'); %deals with bug in impoly
        hROI.fig.WindowScrollWheelFcn=[];
        hROI.fig.WindowButtonDownFcn=[];
        if hROI.thresholdmethod.Value
            hROI.thresholdmethod.ForegroundColor = 'green';
            if isempty(hROI.fig.WindowScrollWheelFcn)
                iptaddcallback(hROI.fig,'WindowScrollWheelFcn',@CBScroll);
            end
            if isempty(hROI.fig.WindowButtonDownFcn)
                iptaddcallback(hROI.fig,'WindowButtonDownFcn',@CBClick);
            end
        else
            hROI.thresholdmethod.ForegroundColor = 'black';
        end
    end
end
%--------------------%
function CBScroll(~,cbdata)
    persistent newcontour;
    pause(.01); if strcmp(hROI.Zoom.Enable,'on'); hROI.Zoom.Enable='off'; end
    if exist('newcontour','var'); delete(newcontour); end
    if isfield(hROI,'pixvalue') && ~isempty(hROI.pixvalue); delete(hROI.pixvalue); end
    z = round(hROI.newaxes.CurrentPoint);
    z = z(1,1:2);
    if z(1)>hROI.newaxes.XLim(1) && z(2)>hROI.newaxes.YLim(1) && z(1)<hROI.newaxes.XLim(2) && z(2)<hROI.newaxes.YLim(2)
        hROI.pixvalue = text(z(1)+2,z(2)-2,sprintf('%5.3f',ROIdata.bgimage(z(2),z(1))),'color','red');
        if hROI.invert_thresh.Value
            thresh = str2num(hROI.thresh_edit.String)+cbdata.VerticalScrollCount*hROI.stepsize;
            if thresh>hROI.th_max; thresh=hROI.th_max; end
            if thresh<hROI.th_min; thresh=hROI.th_min; end
            imgth = gather(ROIdata.bgimage<thresh);
        else
            thresh = str2num(hROI.thresh_edit.String)-cbdata.VerticalScrollCount*hROI.stepsize;
            if thresh>hROI.th_max; thresh=hROI.th_max; end
            if thresh<hROI.th_min; thresh=hROI.th_min; end
            imgth = gather(ROIdata.bgimage>thresh);
        end
        hROI.thresh_edit.String = sprintf('%5.3f',thresh);
        D = bwdistgeodesic(imgth,z(1,1),z(1,2)); clear imgth;
        %bw = imdilate(isfinite(D),strel('disk',1)); clear D; bw=imfill(bw,'holes');% this way makes the ROI dilate 1 pixel radius beyond threshold region
        bw=isfinite(D); clear D;
        hROI.newmask=imfill(bw,'holes');
        warning('off','MATLAB:contour:ConstantData');
        if hROI.bGray
            [~,newcontour] = contour(double(hROI.newmask), 1, 'LineColor','red');
        else
            [~,newcontour] = contour(double(hROI.newmask), 1, 'LineColor','black');
        end
        warning('on','MATLAB:contour:ConstantData');
        drawnow;
    end
end
function CBClick(~,~)
    if max(hROI.newmask(:))>0
        answr = questdlg('Are you Done, or would you like to Refine the ROI?', 'Refine ROI?', 'Refine', 'Done', 'Done');
        if strcmp(answr,'Refine')
            hROI.newmask=refine(hROI.newmask);
            if max(hROI.newmask(:))>0
                ROIdata.nROI=ROIdata.nROI+1;
                ROIdata.rois(ROIdata.nROI).mask = hROI.newmask; %clear newmask;
            end
        else
            ROIdata.nROI=ROIdata.nROI+1;
            ROIdata.rois(ROIdata.nROI).mask = hROI.newmask; %clear newmask;
        end
        xl=hROI.newaxes.XLim; yl=hROI.newaxes.YLim;
        drawBG;
        hROI.newaxes.XLim=xl; hROI.newaxes.YLim=yl;
        CBthreshold;
    end
end
function CBQuickClick(~,~)
    persistent newcontour;
%     pause(.01); if strcmp(hROI.Zoom.Enable,'on'); hROI.Zoom.Enable='off'; end
    if exist('newcontour','var'); delete(newcontour); end
    z = round(hROI.newaxes.CurrentPoint);
    z = z(1,1:2);
    L = str2double(hROI.quicksize_edit.String); %side length
    if z(1)>hROI.newaxes.XLim(1) && z(2)>hROI.newaxes.YLim(1) && z(1)<hROI.newaxes.XLim(2) && z(2)<hROI.newaxes.YLim(2)
        hROI.newmask = zeros(size(ROIdata.bgimage));
        ystart = max(1,z(2)-floor(L/2)); ystart = min(z(2)-floor(L/2),hROI.newaxes.YLim(2)-L);
        xstart = max(1,z(1)-floor(L/2)); xstart = min(z(1)-floor(L/2),hROI.newaxes.XLim(2)-L);
        hROI.newmask(ystart:ystart+L-1,xstart:xstart+L-1) = 1;
        warning('off','MATLAB:contour:ConstantData');
        if hROI.bGray
            [~,newcontour] = contour(double(hROI.newmask), 1, 'LineColor','red');
        else
            [~,newcontour] = contour(double(hROI.newmask), 1, 'LineColor','black');
        end
        warning('on','MATLAB:contour:ConstantData');
        drawnow;
    end
    ROIdata.nROI=ROIdata.nROI+1;
    ROIdata.rois(ROIdata.nROI).mask = hROI.newmask; %clear newmask;
    xl=hROI.newaxes.XLim; yl=hROI.newaxes.YLim;
    drawBG;
    hROI.newaxes.XLim=xl; hROI.newaxes.YLim=yl;
    CBquicksquare;
end
%--------------------%
function outmask = refine(inmask) %Refine the ROI
    oldscrollfcn = hROI.fig.WindowScrollWheelFcn; hROI.fig.WindowScrollWheelFcn=[];
    olddownfcn = hROI.fig.WindowButtonDownFcn; hROI.fig.WindowButtonDownFcn=[];
    method = questdlg('Choose Refinement Method (Cancel to save current ROI)',...
        'Refinement Methods','Correlation','PCA','Cancel','Cancel');
    if isempty(method) || strcmp(method,'Cancel')
        outmask=inmask;
        return;
    end
    if strcmp(method,'Correlation') %Cross Correlation with current ROI
        newbg = bgCorrelate(inmask);
    elseif strcmp(method,'PCA')
        newbg = bgPCA(inmask);
    end
    % redraw figure
    xl=hROI.newaxes.XLim; yl=hROI.newaxes.YLim;
    hold(hROI.newaxes,'off');
    hROI.newaxes.Children(end).CData = newbg;
    if strcmp(method,'Correlation')
        caxis([-1 1]); %useful for reference
    end
    % if strcmp(method,'PCA')
    %     hotcold = ones(128, 3);
    %     hotcold(1:64, 1) = linspace(0, 1, 64);
    %     hotcold(1:64, 2) = linspace(0, 1, 64);
    %     hotcold(65:128, 2) = linspace(1, 0, 64);
    %     hotcold(65:128, 3) = linspace(1, 0, 64);
    %     colormap(hotcold);
    % end
    hold(hROI.newaxes,'on');
    warning('off','MATLAB:contour:ConstantData');
    [~,incontour] = contour(double(inmask), 1, 'LineColor','red');
    warning('on','MATLAB:contour:ConstantData');        
    axis image off;
    hROI.newaxes.XLim=xl; hROI.newaxes.YLim=yl;        
    if strcmp(method,'Correlation')
        answr = questdlg('What next?','Select ROI','Keep original','Draw New ROI','Auto-Threshold','Keep original');
    elseif strcmp(method,'PCA')
        answr = questdlg('What next?','Select ROI','Keep original','Draw New ROI','Keep original');
    end
    if isempty(answr); outmask=inmask; delete(incontour); return; end
    if strcmp(answr, 'Keep original'); outmask = inmask; delete(incontour); return; end
    if strcmp(answr, 'Draw New ROI') %Define New
        delete(incontour);
        newROI = impoly(hROI.newaxes, []);
        if isempty(newROI); delete(newROI); outmask=inmask; return; end
        outmask = createMask(newROI); delete(newROI);
        hROI.fig.Pointer='arrow'; %deals with bug in impoly
        return;
    end
    if strcmp(answr,'Auto-Threshold')
        xy = round(hROI.newaxes.CurrentPoint);
        xy = xy(1,1:2);
        instruct=text(xy(1)-10, xy(2)-10, 'Draw a polygon around the region you want to include.');
        waitforbuttonpress; delete(instruct);
        box = impoly(hROI.newaxes, []);
        if isempty(box); outmask = inmask; return; end
        outline = createMask(box); delete(box);
        [~,tmpcontour1] = contour(double(outline), 1, 'LineColor','green','LineStyle','--');
        hROI.newaxes.Children(end).CData = outline.*newbg;
        hROI.newaxes.Children(end).CData(outline==0)= NaN;
        clear outline;
        instruct=text(xy(1)-10, xy(2)-10, 'Use Scrollwheel to change threshold. Left click to select ROI','Color','white');
        hROI.fig.WindowScrollWheelFcn=@refineScroll;
        waitforbuttonpress;
        hROI.fig.WindowScrollWheelFcn=oldscrollfcn;hROI.fig.WindowButtonDownFcn=olddownfcn;
        delete(tmpcontour1); delete(instruct);          
        answr = questdlg('Select ROI','Select ROI','Keep original','Accept Auto-Threshold','Keep original');
        delete(findall(hROI.fig.Children(end),'type','contour'));
        delete(findall(hROI.fig.Children(end),'type','text'));
        if strcmp(answr,'Keep original')
            outmask = inmask;
        else
            outmask = hROI.automask; 
        end
    end
end
%--------------------%
function newbg = bgCorrelate(inmask) %Correlation with current ROI
    %hROI.newaxes.XLim
    wait = waitbar(0,'Correlating...');
    time_series = zeros(size(ROIdata.imstack,3), 1);
    roiIndex = inmask>0.5;
    for i = 1:size(ROIdata.imstack,3)
        corrim = ROIdata.imstack(:,:,i);
        time_series(i) = mean(corrim(roiIndex)); %compute mean value in ROI
    end
    ref = time_series-mean(time_series);
    corrs = zeros(size(inmask));
    
    xl = floor(hROI.newaxes.XLim); xl = max(1,xl);
    yl = floor(hROI.newaxes.YLim); yl = max(1,yl);
    
    for i = yl(1):yl(2)
        tsrow = double(squeeze(ROIdata.imstack(i,xl(1):xl(2),:)))';
        tsrow = tsrow - repmat(mean(tsrow, 1), size(ROIdata.imstack,3), 1);
        [temp, p] = corrcoef([ref tsrow]);
        corrs(i,xl(1):xl(2)) = temp(1,2:end).*(p(1,2:end)<=0.01);
        if exist('wait','var'); waitbar((i-yl(1))/yl(2)-yl(1)); end
    end
    close(wait);
    newbg = corrs;
end
%--------------------%
function newbg = bgPCA(inmask)
    frames = size(ROIdata.imstack,3);
    %Note: Filtering the image prior to PCA can make a big difference!
    xl = floor(hROI.newaxes.XLim); xl = max(1,xl);
    yl = floor(hROI.newaxes.YLim); yl = max(1,yl);
    ff=single(ROIdata.imstack(yl(1):yl(2),xl(1):xl(2),:));
    ypix=size(ff,1);xpix=size(ff,2);pix=ypix*xpix;
    if pix>(128*128)    %may want to warn/cancel if image is "too big" for pca
        check = questdlg('WARNING: Image size is > 128x128(~30sec), this could take awhile...','Continue PCA?','Contine','Cancel','Cancel');
        if isempty(check) || strcmp(check,'Cancel'); return; end
    end
    ff=reshape(ff,[pix,frames]);
    tic
    wait = waitbar(0,'PCA in progress...');
    [coeff, score] = princomp(ff', 'econ'); %tcrtcrtcr
    close(wait);
    clear ff;
    toc    
    Ncomp=3;
    r=zeros(pix,1);g=r;b=r;
    mins = min(coeff, [], 1); maxs = max(coeff, [], 1);
    for j = 1:pix
        clr = zeros(1, Ncomp);
        for i = 1:Ncomp
            clr(i) = (coeff(j,i)-mins(i))./(maxs(i)-mins(i));
        end
        clr = clr.*sum(abs(clr(1:3)))./sum(abs(clr));
        r(j) = clr(1);
        g(j) = clr(2);
        b(j) = clr(3);
    end
    clear coeff;
    rr=reshape(r,ypix,xpix);
    gg=reshape(g,ypix,xpix);
    bb=reshape(b,ypix,xpix);
    pcim=zeros([size(inmask) 3]);
    pcim(yl(1):yl(2),xl(1):xl(2),1)=rr;
    pcim(yl(1):yl(2),xl(1):xl(2),2)=gg;
    pcim(yl(1):yl(2),xl(1):xl(2),3)=bb;
    newbg = pcim;
end
%--------------------%
function refineScroll(~,cbdata)
    persistent tmp thresh threshval step tmpcontour;
    if isempty(tmp); tmp = isfinite(hROI.newaxes.Children(end).CData(:)); end
    if isempty(thresh); thresh=min(tmp(:))+.5*(max(tmp(:))-min(tmp(:))); end
    if isempty(step); step=(max(tmp)-min(tmp))/100; end
    thresh = thresh-step*(cbdata.VerticalScrollCount);
    xy = round(hROI.newaxes.CurrentPoint); xy = xy(1,1:2);
    if exist('threshval','var'); delete(threshval); end
    threshval = text(xy(1), xy(2)-5, sprintf('%5.3f',thresh),'Color','white');
    imgth=hROI.newaxes.Children(end).CData;
    bw=gather(imgth>thresh);
    bw=imfill(bw,'holes');
    if exist('tmpcontour','var'); delete(tmpcontour); end
    warning('off','MATLAB:contour:ConstantData');
    if hROI.bGray
        [~,tmpcontour] = contour(double(bw), 1, 'LineColor','blue');
    else
        [~,tmpcontour] = contour(double(bw), 1, 'LineColor','black');
    end
    warning('on','MATLAB:contour:ConstantData');
    drawnow;         
    hROI.automask=bw;
end

end

