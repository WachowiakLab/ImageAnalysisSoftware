function [varargout] = RegistrationGUI_MWLab(varargin)

fsize = 11; %fontsize

hReg = figure('Name','MWLab ImageRegistration', 'NumberTitle','off', 'Units','Normalized',...
    'Position',[.1 .1 .8 .8],'KeyReleaseFcn',@CBKeyShift,'CloseRequestFcn',@CBCloseFig);
hReg.UserData.file = [];

instr = {'Instructions: Select magnification type and enter digital zoom values on the left.', ...
    'Click on image with left mouse button; then, use <arrow> keys to move the image left/right/up/down.',...
    'Use <j,k> keys to rotate the image. Use <shift>+<arrow> or <j,k> for smaller increments.'};
tipstr = sprintf(['When this program is called with an output argument (e.g. using the button in MapsAnalysis), ' ...
    'the\ncurrent registration is saved as the output variable (in the ORdata file using the MapsAnalysis button.']);
uicontrol(hReg,'Style','Text','String',instr,'FontSize',fsize,'HorizontalAlignment','center',...
    'Units','Normalized','Position',[.25 .85 .7 .1],'TooltipString',tipstr);
uicontrol(hReg,'Style','Pushbutton','String','Load File(s)','FontSize',fsize, ...
    'Units','Normalized','Position',[.02 .9 .08 .05],'Callback',@CBLoadFile);
uicontrol(hReg,'Style','Pushbutton','String','Clear File(s)','FontSize',fsize, ...
    'Units','Normalized','Position',[.11 .9 .08 .05],'Callback',@CBClearFile);
% uicontrol(hReg,'Style','text','String','Select Moving Image','FontSize',fsize, ...
%     'Units','Normalized','Position',[.02 .85 .16 .03]);
hmoving = uicontrol(hReg,'Style','checkbox','String','Show Moving Image','FontSize',fsize, ...
    'Units','Normalized','Position',[.05 .85 .12 .03],'Value',1,'Callback',@CBShowMovingImage);
hmovingfile = uicontrol(hReg,'Style','ListBox','FontSize',fsize, 'Units', ...
    'Normalized','Position',[.02 .7 .16 .15],'Callback',@CBSelectMoving);
cmapstrings = getcmaps;
uicontrol(hReg,'Style', 'text', 'String', 'Colormap: ','Units','normalized' ...
    ,'Fontsize',fsize,'HorizontalAlignment','right','Position',[.02 .64 .07 .03]);
hmovingcmap = uicontrol(hReg,'Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [.09 .645 .08 .03], 'String', cmapstrings,'Callback', @CBShowMovingImage, ...
    'Value',1, 'BackgroundColor', [1 1 1],'FontSize',11);
uicontrol(hReg,'Style','Text','String','Magnification and Zoom','FontSize',fsize, ...
    'Units','Normalized','Position',[.02 .57 .16 .05]);
%magnifications measured using micrometer slide and 15 micrometer fluorescent beads
%scanimage - neuroplex have a lensing effect - magnification varies slightly across field-of view
%2P images pixels are not equal in x/y dimensions - this is subject to rig adjustments
pix.name = {'Neuroplex-InVivo-4x','Neuroplex-ScanImage-5x', 'Neuroplex-InVivo-10x', ...
    'Neuroplex-ScanImage-16X','2P-ScanImage-16x','2P-Scanbox-16x','-unregistered-'};

% pixel sizes were determined experimentally (data saved in "RegistrationGUIData_2018_12_18")
%   -for neuroplex-in vivo and neuroplex-scanimage rigs by imaging a micro-ruler
%   -for 2p rigs, microspheres were imaged and the mean image was analyzed in imageJ using the "measure particles" function
pix.size = {[17.86 17.86],[13.16 13.16],[7.09 7.09],[4.9 4.9],[1.58 2.0],[1.53 2.5],[1 1]}; % micrometers/pixel, measured Dec. 2018;
hpixeltype = uicontrol(hReg,'Style','PopUpMenu','String',pix.name,'FontSize',fsize, ...
    'Units','Normalized','Position',[.02 .54 .13 .05],'Callback',@CBChangePixelType);
hzoom = uicontrol(hReg,'Style','edit','string','','FontSize',fsize, ...
    'Units','Normalized','Position',[.16 .56 .03 .03],'Callback',@CBShowMovingImage);
uicontrol(hReg,'Style','Text','String','X-Position:','FontSize',fsize, ...
    'HorizontalAlignment','right','Units','Normalized','Position',[.02 .51 .1 .025]);
hxpos = uicontrol(hReg,'Style','Edit','FontSize',fsize,'Units','Normalized', ...
    'Position',[.135 .51 .035 .03],'Callback',@CBShowMovingImage);
uicontrol(hReg,'Style','Text','String','Y-Position:','FontSize',fsize, ...
    'HorizontalAlignment','right','Units','Normalized','Position',[.07 .46 .05 .025]);
hypos = uicontrol(hReg,'Style','Edit','FontSize',fsize,'Units','Normalized', ...
    'Position',[.135 .46 .035 .03],'Callback',@CBShowMovingImage);
uicontrol(hReg,'Style','Text','String','CW Rotation (degrees):','FontSize',fsize, ...
    'HorizontalAlignment','right','Units','Normalized','Position',[.02 .41 .11 .025]);
hdeg = uicontrol(hReg,'Style','Edit','FontSize',fsize,'Units','Normalized', ...
    'Position',[.135 .41 .035 .03],'Callback',@CBShowMovingImage);
uicontrol(hReg,'Style','Pushbutton','String','Delete Registration','FontSize',fsize, ...
    'Units','Normalized','Position',[.01 .34 .09 .05],'Callback',@CBDeleteReg);
uicontrol(hReg,'Style','Pushbutton','String','Save Registration','FontSize',fsize, ...
    'Units','Normalized','Position',[.1 .34 .09 .05],'Callback',@CBSaveReg);
uicontrol(hReg,'Style','Pushbutton','String','Apply to ROIs','FontSize',fsize, ...
    'Units','Normalized','Position',[.055 .28 .09 .05],'Callback',@CBApplyReg);
%show fixed image
uicontrol(hReg,'Style','text','String','_______________________________', ...
    'FontSize',fsize','Units','Normalized','Position',[.02 .25 .16 .03]);
hfixed = uicontrol(hReg,'Style','Checkbox','String','Show Fixed Image','FontSize',fsize, ...
    'Units','Normalized','Position',[.05 .22 .12 .03],'Callback',@CBShowFixedImage);
hfixedfile = uicontrol(hReg,'Style','ListBox','FontSize',fsize, 'Units', ...
    'Normalized','Position',[.02 .09 .16 .12],'Callback',@CBShowFixedImage);
uicontrol(hReg,'Style', 'text', 'String', 'Colormap: ','Units','normalized' ...
    ,'Fontsize',fsize,'HorizontalAlignment','right','Position',[.02 .03 .07 .03]);
hfixedcmap = uicontrol(hReg,'Style', 'popupmenu', 'Units', 'normalized', 'Position', ...
    [.09 .035 .08 .03], 'String', cmapstrings,'Callback', @CBShowFixedImage, ...
    'Value',1, 'BackgroundColor', [1 1 1],'FontSize',11);

%set up axes and grid lines - 5.0mm=5000um scale since Neuroplex-InVivo-4x image is 17.86*256=~4572 micrometers
%moving image
hAxM = axes(hReg,'Units','Normalized','Position',[.2 .05 .75 .8],'DataAspectRatio',[1 1 1], 'Visible','off');
hold on; plot(hAxM,[0 0],[-1000 3600],'Color',[.3 .3 .3],'LineWidth',4);
hold on; plot(hAxM,[-2500 2500],[0 0],'Color',[.3 .3 .3],'LineWidth',4);
minangle = -pi/4; maxangle = pi/4; numpoints = 100; radius = 1800; ycenter = 1000; xcenter = 0;
angles = linspace(minangle,maxangle,numpoints);
tmpx = radius*sin(angles)+xcenter;
tmpy = radius*cos(angles)+ycenter;
hold on; plot(hAxM,tmpx,tmpy,'Color',[.3 .3 .3],'LineWidth',4,'LineStyle',':');
hAxM.YLim = [-1000 3600]; hAxM.XLim = [-2500 2500];
%fixed image
hAxF = axes(hReg,'Units','Normalized','Position',hAxM.Position,'DataAspectRatio',[1 1 1], ...
    'YLim', [-1000 3600],'XLim',[-2500 2500], 'Visible','off'); hold on;
linkaxes([hAxM,hAxF],'xy');

if nargin
    tmpdata = varargin{1};
    hReg.UserData.file.name = tmpdata.file.name;
    hReg.UserData.file.dir = tmpdata.file.dir;
    hReg.UserData.file.im = tmpdata.file.im;
    filestr = cell(1,length(hReg.UserData.file));
    for f = 1:length(hReg.UserData.file)
        filestr{f} = hReg.UserData.file(f).name;
    end
    hmovingfile.String = filestr; hfixedfile.String = filestr;
    CBSelectMoving;
end
nout=nargout; %call nargout in body of main function
waitfor(hReg);

%nested callback functions
    function CBCloseFig(~,~)
        registration = struct('pixelsize',[],'zoom',[],'xpos',[],'ypos',[],'rotation',[]);
        registration.pixelsize = pix.size{hpixeltype.Value};
        registration.zoom = hzoom.String;
        registration.xpos = str2double(hxpos.String);
        registration.ypos = str2double(hypos.String);
        registration.rotation = str2double(hdeg.String);
        if nout; varargout{1} = registration; end
        delete(hReg);
    end
    function CBLoadFile(~,~)
        ext = '.tif'; %should work with any 2D indexed image (modify rgb)
        [filename, pathname, ok] = uigetfile(ext, 'Select data file(s)', 'MultiSelect', 'On');
        if ok == 0; return; end
        if ~isempty(hReg.UserData.file); cnt = length(hReg.UserData.file); else; cnt = 0; end
        if ischar(filename) %add 1 file to list
            hReg.UserData.file(cnt+1).name = filename;
            hReg.UserData.file(cnt+1).dir = pathname;
            hReg.UserData.file(cnt+1).im = imread(fullfile(pathname,filename));
            if size(hReg.UserData.file(cnt+1).im,3)==3
                hReg.UserData.file(cnt+1).im = rgb2gray(hReg.UserData.file(cnt+1).im);
            end
            hReg.UserData.file(cnt+1).im = single(hReg.UserData.file(cnt+1).im);
            if exist(fullfile(pathname,[filename(1:end-4) '.mwlab_reg']),'file')
                 tmp = load(fullfile(pathname,[filename(1:end-4) '.mwlab_reg']),'registration','-mat');
                 hReg.UserData.file(cnt+1).registration = tmp.registration; clear tmp;
            else %unregistered
                hReg.UserData.file(cnt+1).registration.pixelsize = pix.size{end};
                hReg.UserData.file(cnt+1).registration.zoom = '';
                hReg.UserData.file(cnt+1).registration.xpos = 0;
                hReg.UserData.file(cnt+1).registration.ypos = 0;
                hReg.UserData.file(cnt+1).registration.rotation = 0;
            end
        else %add more than 1 file to list
            for f = 1:length(filename) %add the images 
                hReg.UserData.file(cnt+f).name = filename{f};
                hReg.UserData.file(cnt+f).dir = pathname;
                hReg.UserData.file(cnt+f).im = imread(fullfile(pathname,filename{f}));
                if size(hReg.UserData.file(cnt+f).im,3)==3
                    hReg.UserData.file(cnt+f).im = rgb2gray(hReg.UserData.file(cnt+f).im);
                end
                hReg.UserData.file(cnt+f).im = single(hReg.UserData.file(cnt+f).im);
                if exist(fullfile(pathname,[filename{f}(1:end-4) '.mwlab_reg']),'file')
                     tmp = load(fullfile(pathname,[filename{f}(1:end-4) '.mwlab_reg']),'registration','-mat');
                     hReg.UserData.file(cnt+f).registration = tmp.registration; clear tmp;
                else
                    hReg.UserData.file(cnt+f).registration.pixelsize = pix.size{end};
                    hReg.UserData.file(cnt+f).registration.zoom = '';
                    hReg.UserData.file(cnt+f).registration.xpos = 0;
                    hReg.UserData.file(cnt+f).registration.ypos = 0;
                    hReg.UserData.file(cnt+f).registration.rotation = 0;
                end
            end
        end
        filestr = cell(1,length(hReg.UserData.file));
        for f = 1:length(hReg.UserData.file)
            filestr{f} = hReg.UserData.file(f).name;
        end
        hmovingfile.String = filestr; hfixedfile.String = filestr;
        CBSelectMoving;
    end

    function CBClearFile(~,~)
        if isempty(hReg.UserData.file); return; end
        M = hmovingfile.Value;
        hReg.UserData.file =  hReg.UserData.file(1:length(hReg.UserData.file)~=M);
        filestr = cell(1,length(hReg.UserData.file));
        for f = 1:length(hReg.UserData.file)
            filestr{f} = hReg.UserData.file(f).name;
        end
        hmovingfile.String = filestr; hfixedfile.String = filestr;
        hmovingfile.Value = 1;
        if ~isempty(hReg.UserData.file); CBSelectMoving; end
    end

    function CBSelectMoving(~,~)
        M = hmovingfile.Value;
        pathname = hReg.UserData.file(M).dir; filename = hReg.UserData.file(M).name;
        if exist(fullfile(pathname,[filename(1:end-4) '.mwlab_reg']),'file')
             tmp = load(fullfile(pathname,[filename(1:end-4) '.mwlab_reg']),'registration','-mat');
             hReg.UserData.file(M).registration = tmp.registration; clear tmp;
        else %unregistered
            hReg.UserData.file(M).registration.pixelsize = pix.size{end};
            hReg.UserData.file(M).registration.zoom = '';
            hReg.UserData.file(M).registration.xpos = 0;
            hReg.UserData.file(M).registration.ypos = 0;
            hReg.UserData.file(M).registration.rotation = 0;
        end
        for p = 1:numel(pix.size)
            if hReg.UserData.file(M).registration.pixelsize == pix.size{p}; hpixeltype.Value = p; break; end
        end
        hzoom.String = hReg.UserData.file(M).registration.zoom;
        hxpos.String = sprintf('%.0f',hReg.UserData.file(M).registration.xpos);
        hypos.String = sprintf('%.0f',hReg.UserData.file(M).registration.ypos);
        hdeg.String = sprintf('%.2f',hReg.UserData.file(M).registration.rotation);
        hAxM.YLim = [-1000 3600]; hAxM.XLim = [-2500 2500];
        CBShowMovingImage;
    end
    
    function CBChangePixelType(~,~)
        if isempty(hReg.UserData.file); return; end
        M = hmovingfile.Value;
        for p = 1:numel(pix.size)
            if hReg.UserData.file(M).registration.pixelsize == pix.size{p}; oldValue = p; break; end
        end
        if hpixeltype.Value == oldValue; return; end %no change of settings
        hReg.UserData.file(M).registration.pixelsize = pix.size{hpixeltype.Value};
        switch hpixeltype.Value %move image to a "reasonable" starting position
            case {1,3} %neuroplex in-vivo-(4x,10x)
                disp('tcr-1,3');
                hReg.UserData.file(M).registration.zoom = '';
                hReg.UserData.file(M).registration.xpos = 0;
                hReg.UserData.file(M).registration.ypos = 1000;
                hReg.UserData.file(M).registration.rotation = 90;
            case {2,4} %neuroplex scanimage-(5x,16x)
                hReg.UserData.file(M).registration.zoom = '';
                hReg.UserData.file(M).registration.xpos = 0;
                hReg.UserData.file(M).registration.ypos = 1000;
                hReg.UserData.file(M).registration.rotation = 0;
            case {5,6} %2P-Scanimage/Scanbox 16x
                hReg.UserData.file(M).registration.zoom = '';
                hReg.UserData.file(M).registration.xpos = 0;
                hReg.UserData.file(M).registration.ypos = 1500;
                hReg.UserData.file(M).registration.rotation = 0;                
            case 7 %unregistered
                hReg.UserData.file(M).registration.zoom = '';
                hReg.UserData.file(M).registration.xpos = 0;
                hReg.UserData.file(M).registration.ypos = 0;
                hReg.UserData.file(M).registration.rotation = 0;
        end
        hzoom.String = hReg.UserData.file(M).registration.zoom;
        hxpos.String = sprintf('%.0f',hReg.UserData.file(M).registration.xpos);
        hypos.String = sprintf('%.0f',hReg.UserData.file(M).registration.ypos);
        hdeg.String = sprintf('%.2f',hReg.UserData.file(M).registration.rotation);
        hAxM.YLim = [-1000 3600]; hAxM.XLim = [-2500 2500];
        CBShowMovingImage;
    end

    function CBShowMovingImage(~,~)
        if isempty(hReg.UserData.file); return; end
        %clear old image - always the bottom layer
        if ~isempty(findobj(hAxM.Children(end),'Type','Image'))
            delete(hAxM.Children(end));
        end
        if hmoving.Value
            M = hmovingfile.Value;
            newim = flipud(hReg.UserData.file(M).im); %normally, images are displayed on an axes w/ydir='reverse'
            pixsize = pix.size{hpixeltype.Value}; %list values are um/pixel
            if ~isempty(hzoom.String) && isfinite(str2double(hzoom.String)); pixsize = pixsize./str2double(hzoom.String); end
            xpos = str2double(hxpos.String); %
            ypos = str2double(hypos.String);
            %do stretch first, then rotate later
            if pixsize(1) < pixsize(2) %stretch the image in Y to make pixels same size
                newim = imresize(newim,[size(newim,1)*pixsize(2)/pixsize(1) size(newim,2)]);
                pixsize(2)=pixsize(1);
            elseif pixsize(2) < pixsize(1) %stretch in X (currently not used for any of our images)
                newim = imresize(newim,[size(newim,1) size(newim,2)*pixsize(1)/pixsize(2)]);
                pixsize(1)=pixsize(2);
            end
            theta = str2double(hdeg.String);
            [rows,cols] = size(newim); %use to determine xd/yd ratio
            xd = [-.5*cols*pixsize(1) .5*cols*pixsize(1)]+xpos;
            yd = [-.5*rows*pixsize(2) .5*rows*pixsize(2)]+ypos;
            if theta~=0
                oldsize = size(newim);
                tform = affine2d([cosd(theta) sind(theta) 0; -sind(theta) cosd(theta) 0; 0 0 1]);
                newim = fillmissing(newim,'constant',min(newim(:)));
                newim = imwarp(newim,tform,'FillValues',nan);
                ratios = size(newim)./oldsize; %note that image size changes with rotation so recompute xd,yd
                xd = [mean(xd)-diff(xd)/2*ratios(2) mean(xd)+diff(xd)/2*ratios(2)];
                yd = [mean(yd)-diff(yd)/2*ratios(1) mean(yd)+diff(yd)/2*ratios(1)];
            end
            %display new image
            xltmp = hAxM.XLim; yltmp = hAxM.YLim;
            him = imagesc(hAxM,newim,'Xdata',xd,'YData',yd);
            hAxM.XLim = xltmp; hAxM.YLim = yltmp;
            him.AlphaData = ~isnan(newim);
            hAxM.CLim = [min(newim(~isnan(newim))) max(newim(~isnan(newim)))];
            axes(hAxM);
            colormap(hAxM,[cmapstrings{hmovingcmap.Value} '(256)']);
            uistack(him,'bottom');
        end
        if hfixed.Value; CBShowFixedImage; end
    end

    function CBShowFixedImage(~,~)
        if isempty(hReg.UserData.file); return; end
        if ~isempty(hAxF.Children)
            delete(hAxF.Children(1));
        end
        if hfixed.Value %show fixed image
            F = hfixedfile.Value;
            fixim = flipud(hReg.UserData.file(F).im); %normally, images are displayed on an axes w/ydir='reverse'
            if ~isempty(hReg.UserData.file(F).registration) %load saved registration values
                fpixsize = hReg.UserData.file(F).registration.pixelsize;
                fzoom = hReg.UserData.file(F).registration.zoom;
                if ~isempty(fzoom) && isfinite(str2double(fzoom)); fpixsize = fpixsize./str2double(fzoom); end
                fxpos = hReg.UserData.file(F).registration.xpos;
                fypos = hReg.UserData.file(F).registration.ypos;
                ftheta = hReg.UserData.file(F).registration.rotation;
            else
                fpixsize = pix.size{1}; fxpos = 0; fypos = 0; ftheta = 0;
            end
            %do stretch first, then rotate later
            if fpixsize(1) < fpixsize(2) %stretch the image in Y to make pixels same size
                fixim = imresize(fixim,[size(fixim,1)*fpixsize(2)/fpixsize(1) size(fixim,2)]);
                fpixsize(2)=fpixsize(1);
            elseif fpixsize(2) < fpixsize(1) %stretch in X (currently not used for any of our images)
                fixim = imresize(fixim,[size(fixim,1) size(fixim,2)*fpixsize(1)/fpixsize(2)]);
                fpixsize(1)=fpixsize(2);
            end            
            [frows,fcols] = size(fixim);
            fxd = [-.5*fcols*fpixsize(1) .5*fcols*fpixsize(1)]+fxpos;
            fyd = [-.5*frows*fpixsize(2) .5*frows*fpixsize(2)]+fypos;
            if ftheta~=0
                oldsize = size(fixim);
                tform = affine2d([cosd(ftheta) sind(ftheta) 0; -sind(ftheta) cosd(ftheta) 0; 0 0 1]);
                fixim = fillmissing(fixim,'constant',min(fixim(:)));
                fixim = imwarp(fixim,tform,'FillValues',nan);
                ratios = size(fixim)./oldsize;
                fxd = [mean(fxd)-diff(fxd)/2*ratios(2) mean(fxd)+diff(fxd)/2*ratios(2)];
                fyd = [mean(fyd)-diff(fyd)/2*ratios(1) mean(fyd)+diff(fyd)/2*ratios(1)];
            end
            xltmp = hAxM.XLim; yltmp = hAxM.YLim;
            hfim = imagesc(hAxF,fixim,'Xdata',fxd,'YData',fyd);
            hAxF.XLim = xltmp; hAxF.YLim = yltmp; %hAxF.YDir = 'reverse';
            hfim.AlphaData = ~isnan(fixim).*0.5;
            %hfim.AlphaData = ones(size(fixim));
            colormap(hAxF,[cmapstrings{hfixedcmap.Value} '(256)']);
            uistack(hAxF,'top');
        end
    end

    function CBSaveReg(~,~)
        registration.pixelsize = pix.size{hpixeltype.Value};
        registration.zoom = hzoom.String;
        registration.xpos = str2double(hxpos.String);
        registration.ypos = str2double(hypos.String);
        registration.rotation = str2double(hdeg.String);
        M = hmovingfile.Value; hReg.UserData.file(M).registration = registration;
        [~,tmpname,~]=fileparts(hReg.UserData.file(M).name);
        save(fullfile(hReg.UserData.file(M).dir,[tmpname '.mwlab_reg']),'registration','-mat');
        disp('registration file saved');
    end

    function CBDeleteReg(~,~)
        M = hmovingfile.Value;
        hReg.UserData.file(M).registration = [];
        tmpname = fullfile(hReg.UserData.file(M).dir,[hReg.UserData.file(M).name(end-4) '.mwlab_reg']);
        if isfile(tmpname); delete tmpname; end
    end

    function CBApplyReg(~,~)
        %load rois files, compute positions, output to base workspace,
        rois = loadROIs;
        reg.pixelsize = pix.size{hpixeltype.Value};
        reg.zoom = hzoom.String;
        reg.xpos = str2double(hxpos.String);
        reg.ypos = str2double(hypos.String);
        reg.rotation = str2double(hdeg.String);
        ROIpositions = centroids_RegGUI(rois,reg);
        disp(ROIpositions);
        assignin('base','ROIpositions',ROIpositions);
        %?show an image of results?
    end

    function CBKeyShift(~,keydata)
        him = findobj(hAxM.Children,'Type','Image');
        if isempty(him); return; end
        if strcmp(keydata.Key,'rightarrow') && isempty(keydata.Modifier)
            him.XData = him.XData+100; hxpos.String = sprintf('%.0f',him.XData(1)+diff(him.XData)/2);
        elseif strcmp(keydata.Key,'rightarrow') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
                him.XData = him.XData+10; hxpos.String = sprintf('%.0f',him.XData(1)+diff(him.XData)/2);
        elseif strcmp(keydata.Key,'leftarrow') && isempty(keydata.Modifier)
            him.XData = him.XData-100; hxpos.String = sprintf('%.0f',him.XData(1)+diff(him.XData)/2);
        elseif strcmp(keydata.Key,'leftarrow') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
            him.XData = him.XData-10; hxpos.String = sprintf('%.0f',him.XData(1)+diff(him.XData)/2);
        end
%         if hflipy.Value %do the opposite y-pos and theta
            if strcmp(keydata.Key,'uparrow') && isempty(keydata.Modifier)
                him.YData = him.YData+100; hypos.String = sprintf('%.0f',him.YData(1)+diff(him.YData)/2);
            elseif strcmp(keydata.Key,'uparrow') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
                him.YData = him.YData+10; hypos.String = sprintf('%.0f',him.YData(1)+diff(him.YData)/2);
            elseif strcmp(keydata.Key,'downarrow') && isempty(keydata.Modifier)
                him.YData = him.YData-100; hypos.String = sprintf('%.0f',him.YData(1)+diff(him.YData)/2);
            elseif strcmp(keydata.Key,'downarrow') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
                him.YData = him.YData-10; hypos.String = sprintf('%.0f',him.YData(1)+diff(him.YData)/2);
            elseif strcmp(keydata.Key,'j') && isempty(keydata.Modifier)
                hdeg.String = num2str(str2double(hdeg.String)+5); CBShowMovingImage; return;
            elseif strcmp(keydata.Key,'j') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
                hdeg.String = num2str(str2double(hdeg.String)+1); CBShowMovingImage; return;
            elseif strcmp(keydata.Key,'k') && isempty(keydata.Modifier)
                hdeg.String = num2str(str2double(hdeg.String)-5); CBShowMovingImage; return;
            elseif strcmp(keydata.Key,'k') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
                hdeg.String = num2str(str2double(hdeg.String)-1); CBShowMovingImage; return;
            end
%         else
%             if strcmp(keydata.Key,'uparrow') && isempty(keydata.Modifier)
%                 him.YData = him.YData-100; hypos.String = sprintf('%.0f',-(him.YData(1)+diff(him.YData)/2));
%             elseif strcmp(keydata.Key,'uparrow') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
%                 him.YData = him.YData-10; hypos.String = sprintf('%.0f',-(him.YData(1)+diff(him.YData)/2));
%             elseif strcmp(keydata.Key,'downarrow') && isempty(keydata.Modifier)
%                 him.YData = him.YData+100; hypos.String = sprintf('%.0f',-(him.YData(1)+diff(him.YData)/2));
%             elseif strcmp(keydata.Key,'downarrow') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
%                 him.YData = him.YData+10; hypos.String = sprintf('%.0f',-(him.YData(1)+diff(him.YData)/2));
%             elseif strcmp(keydata.Key,'j') && isempty(keydata.Modifier)
%                 hdeg.String = num2str(str2double(hdeg.String)-5); CBShowMovingImage; return;
%             elseif strcmp(keydata.Key,'j') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
%                 hdeg.String = num2str(str2double(hdeg.String)-1); CBShowMovingImage; return;
%             elseif strcmp(keydata.Key,'k') && isempty(keydata.Modifier)
%                 hdeg.String = num2str(str2double(hdeg.String)+5); CBShowMovingImage; return;
%             elseif strcmp(keydata.Key,'k') && ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1},'shift')
%                 hdeg.String = num2str(str2double(hdeg.String)+1); CBShowMovingImage; return;
%             end
%         end
    end
end