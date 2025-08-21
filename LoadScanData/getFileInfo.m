function getFileInfo(datatype,datadir,datafile)
%fileInfo(datatype,dir,file)
% where datatype is datatype is 'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'
% dir: directory path (char)
% file: filename(s), (char) if 1 file
%                    (cell) if multiple files
%EXAMPLE:
% fileInfo(2,'Nov1412-CCK-GC3reporter_ScanImage\','a0001.tif')

typestr = getdatatypes; % {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};

% Create Info Figure    
fileInfoFig =  figure('NumberTitle','off','Name','File Information');
bcol = [0.3922 0.4745 0.6353];
set(fileInfoFig,'Units', 'Normalized', 'Position', [0.25 0.1 0.3 0.5], 'Color', bcol);
filename_box = uicontrol(fileInfoFig,'Style', 'Text', 'Units', 'Normalized', 'Position', ...
    [.05 0.935 .5 0.04], 'FontWeight', 'Bold', 'HorizontalAlignment', ...
    'Left','Fontsize', 10,'BackgroundColor',bcol);
uicontrol(fileInfoFig,'Style','text','String','MetaData:','Units','normalized',...
    'BackgroundColor',bcol,'ForegroundColor',[1 1 1],'Position',[0.05 0.88 0.2 0.05],...
    'HorizontalAlignment','Left');
metadata_box = uicontrol(fileInfoFig,'Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [.05 0.55 .9 .35], 'FontWeight', 'Bold', 'String', 'No Metadata Available');
uicontrol(fileInfoFig,'Style','text','String','Notes:','Units','normalized',...
    'BackgroundColor',bcol,'ForegroundColor',[1 1 1],'Position',[0.05 0.49 0.2 0.05],...
    'HorizontalAlignment','Left');
notes_box = uicontrol(fileInfoFig,'Style', 'listbox', 'Units', 'normalized', 'Position', ...
    [.05 0.01 .9 .5], 'FontWeight', 'Bold');

if iscellstr(datafile) % Multiple Images
%     warndlg('Acquiring metadata for 1st file');
    imfile = fullfile(datadir,datafile{1});
    set(filename_box,'String', ['Image File: ' datafile{1} ' (of Multiple)']);
elseif ischar(datafile) % Single Image
    imfile = fullfile(datadir,datafile);
    set(filename_box,'String', ['Image File: ' datafile]);
end 
switch datatype
    case typestr{1} %'scanimage' %MW Scope / scanimage .tif
        if strcmp(imfile(end-3:end),'.tif')
            tmptiff = Tiff(imfile, 'r');
            try metastr = tmptiff.getTag('Software');
            catch
                try metastr = tmptiff.getTag('ImageDescription');
                catch
                    metastr = [];
                end
            end
            tmptiff.close;
        elseif strcmp(imfile(end-3:end),'.dat')
            load([imfile(1:end-4) '.mat']);
            metastr = SIinfo.ImageDescription;
        end
        set(metadata_box,'String',metastr,'ListboxTop',1); % tcrtcrtcr ??? "Max", 2,"Value", [24 26]
    case typestr{2} %'scanbox' %Scanbox .sbx
        imfile = imfile(1:end-4);
        [~,sbxinfo] = mysbxread(imfile,0,0);
        %metastr = evalc('sbxinfo'); omitted by MW. This is silly.
        metastr=['file info: ', newline];
        tmpfields = fields(sbxinfo);
        %assignin('base','sbxinfo',sbxinfo);  %mwadded
        for f=1:length(tmpfields)
%             if ~isstruct(sbxinfo.(tmpfields{f}))
%                 metastr = [metastr sprintf('sbxinfo.%s: ',tmpfields{f}) sprintf(' %s',string(sbxinfo.(tmpfields{f}))) newline];
%             end %this shows too much ttl stuff for sbxinfo.(frame,line,event_id)
            if strcmp(tmpfields{f},'config')
                %tmpsubfields = fields(sbxinfo.(tmpfields{f}));
                sbxconfig=sbxinfo.config;
                %for i = 1:length(tmpsubfields)
%                     metastr = [metastr sprintf('sbxinfo.%s.%s: ',tmpfields{f},tmpsubfields{i}) ...
%                         sprintf(' %s',string(sbxinfo.(tmpfields{f}).(tmpsubfields{i}))) newline];
                metastr = [metastr, sprintf('wavelength: %d', sbxconfig.wavelength) ,newline];
                %mag=sbxconfig.magnification_list(sbxconfig.magnification);
                metastr = [metastr, sprintf('zoom: %s', sbxconfig.magnification_list(sbxconfig.magnification,:)) ,newline];
                metastr = [metastr, sprintf('xpos: %.2f', sbxconfig.knobby.pos.x) ,newline];
                metastr = [metastr, sprintf('ypos: %.2f', sbxconfig.knobby.pos.y) ,newline];
                metastr = [metastr, sprintf('zpos: %.2f', sbxconfig.knobby.pos.z) ,newline];
                metastr = [metastr, sprintf('angle: %.2f', sbxconfig.knobby.pos.a) ,newline];
               % end
%             elseif strcmp(tmpfields{f},'calibration')
%                 tmpsubfields = fields(sbxinfo.(tmpfields{f}));
%                 for i = 1:length(tmpsubfields)
%                     metastr = [metastr sprintf('sbxinfo.%s(%d).%s: ',tmpfields{f},sbxinfo.config.magnification,tmpsubfields{i}) ...
%                         sprintf(' %s',string(sbxinfo.(tmpfields{f})(sbxinfo.config.magnification).(tmpsubfields{i}))) newline];
%                 end
            end
         if strcmp(tmpfields{f},'usernotes')
             metastr = [metastr, sbxinfo.usernotes];
         end
        end
        set(metadata_box,'String',metastr,'ListboxTop',1);
    case typestr{3} %'prairie' %Prairie .xml
        %warndlg('Metadata not available');
    case typestr{4} %'neuroplex'
        if strcmp(imfile(end-2:end),'.da')
            %see: http://www.redshirtimaging.com/support/dfo.html for info on Neuroplex
            sizeA = 2560; % # of integers of header info
            fid = fopen(imfile);
            header = fread(fid, sizeA, 'int16');
            metastr = sprintf('Frames = %d\n',header(5));
            metastr = [metastr sprintf('Rows = %d\n',header(386))];
            metastr = [metastr sprintf('Columns = %d\n',header(385))];
            deltaT = header(389); 
            if deltaT >= 10; deltaT = deltaT*header(391); end %note: header(391) is called the "dividing factor"
            deltaT = deltaT/1000000;%microsec to sec
            frameRate = 1/deltaT;
            metastr = [metastr sprintf('Frame Rate = %3.3f /sec\n',frameRate)];
            %read comment
            metastr = [metastr sprintf('Comments:\n')];
            fseek(fid,256,'bof');
            metastr = [metastr char((fread(fid,159,'char',1))')]; %Added text can be as long as 257 bytes (this code is from read_NP.m)
            fclose(fid);
            set(metadata_box,'String',metastr,'ListboxTop',1);
        else % neuroplex .tsm
            sizeA = 2880; % # of integers of header info
            fid = fopen(imfile);
            header = fread(fid, sizeA,'uint8=>char');
            fclose(fid);
            %convert header to iminfo
            for i = 1:36
                %headers consist of 36x80byte "cards" w/keyword, value, (optional comment)
                %last keyword is "END", the rest of header is empty
                ctmp = textscan(header(i*80-79:i*80),'%s %s','Delimiter','=');
                if ~isempty(ctmp{1}) && ~isequal(strip(ctmp{1}{1}),'END')
                    tsminfo.(strip(ctmp{1}{1})) = strip(ctmp{2}{1});
                end
            end
            tsminfo.frames = str2double(tsminfo.NAXIS3);
            xpix = str2double(tsminfo.NAXIS1);
            ypix = str2double(tsminfo.NAXIS2);
            tsminfo.size = [ypix,xpix];
            
            deltaT = str2double(tsminfo.EXPOSURE);
            tsminfo.frameRate = 1/deltaT;
            metastr = evalc('tsminfo');
            set(metadata_box,'String',metastr,'ListboxTop',1);
        end
    case typestr{5} %'tif' %Standard .tif
        %info = imfinfo(imfile, 'tif');
%             warndlg('Metadata not available');
    otherwise
        fprintf('datatype not recognized. see getdatatypes.m\n');
        return;           
end   

% Find Notes
tmp = dir(fullfile(datadir,'*notes*.txt'));
if isempty(tmp)
    notesfile = '';
elseif numel(tmp) == 1
    notesfile = tmp(1).name;
    notesfile = fullfile(datadir,notesfile);
else
    [tmp, path] = uigetfile('.txt', 'Select .txt file (e.g. Notes.txt)', datadir);
    notesfile = fullfile(path,tmp);
    figure(fileInfoFig); %move fig to front
end

notestr = cell(500,1); %stores up to 500 lines w/out error
line_len = 80;

if ~isempty(notesfile)
    fid = fopen(notesfile);
    cnt = 0;
    temp = fgetl(fid);
    while ischar(temp) %go until end of file
        DONE = 0;
        while ~DONE %this loop wraps long lines
            if (numel(temp)<=line_len)
                cnt = cnt+1;
                notestr{cnt} = temp;
                DONE = 1;
            else
                cnt = cnt+1;
                notestr{cnt} = temp(1:line_len);
                temp = temp(line_len+1:end);
            end
        end
        temp = fgetl(fid);
    end
    notestr = notestr(1:cnt);
    fclose(fid);
    set(notes_box,'String',notestr);
else
    set(notes_box,'String','No notes file found in this directory');
end