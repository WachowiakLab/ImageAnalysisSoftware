function [rows,columns,varargout] = getImageSize(datatype,imfile)
% [rows,columns,varargout] = getImageSize(datatype,imfile)
%   datatype: 'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'
%   imfile must be full path name (e.g. pathname/filename.tif)
%   varargout{1} is frames - this takes a bit longer

typestr = getdatatypes; % {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};
switch datatype
    case typestr{1} %'scanimage' % ScanImage .tif (aka MWScope)
        if strcmp(imfile(end-3:end),'.tif')
            tmptiff = Tiff(imfile, 'r');
            tmptiff.setDirectory(1);
            rows = tmptiff.getTag('ImageLength');
            columns = tmptiff.getTag('ImageWidth');            
            if nargout > 2
                try SImeta = tmptiff.getTag('Software');
                catch
                    SImeta = [];
                end
                if isempty(SImeta) %old versions, before scanimage 5.2
                    SIinfo = tmptiff.getTag('ImageDescription');
                    if ~isempty(strfind(SIinfo,'scanimage'))
                        Channels = getVal_ver5(SIinfo,'scanimage.SI.hChannels.channelSave');
                        numChannels=length(Channels);
                    elseif ~isempty(strfind(SIinfo,'state'))
                        numChannels = getVal(SIinfo,'state.acq.numberOfChannelsSave');    
                    else
                        warndlg('Problem reading header');
                        numChannels = 1;
                    end
                else %version 5.2
                    if ~isempty(strfind(SImeta,'SI'))
                        Channels = getVal_ver5(SImeta,'SI.hChannels.channelSave');
                        numChannels=length(Channels);
                    else
                        warndlg('Problem reading header');
                        numChannels = 1;
                    end
                end
                if ~isempty(SImeta)
                    frames = getVal_ver5(SImeta,'SI.hStackManager.framesPerSlice');
                elseif numChannels && ~isempty(strfind(SIinfo,'scanimage')) %tcr: see if this works for >1 channel...
                    frames = getVal_ver5(SIinfo,'scanimage.SI.hStackManager.framesPerSlice');
                else
                    frames = 0;
                    while true
                        frames = frames + 1;
                        if tmptiff.lastDirectory(), break; end
                        try tmptiff.nextDirectory(); catch; break; end
                    end
                    frames = frames/numChannels;
                end
                varargout{1} = frames;
            end
            tmptiff.close(); clear tmptiff; 
        elseif strcmp(imfile(end-3:end),'.dat')
            load([imfile(1:end-4) '.mat']);
            rows = SIinfo.size(1);
            columns = SIinfo.size(2);
            if nargout > 2
                varargout{1} = SIinfo.size(3);
            end
        end
    case  typestr{2} %'scanbox' % 'Scanbox .sbx'
        tmp = load(imfile(1:end-4));
        if isfield(tmp.info,'sz')
            rows=tmp.info.sz(1);
            columns=tmp.info.sz(2);
        else
            if isfield(tmp.info,'scanmode') && tmp.info.scanmode == 0 % bidirectional
                rows=512;
                columns=809;
            else %unidirectional
                rows=512;
                columns=796;
            end
        end
        if nargout > 2
            %compute #frames (see loadScanbox.m or sbxread.m for more details)
            if ~isfield(tmp.info,'scanmode')
                tmp.info.scanmode = 1;      % unidirectional
            end
            if tmp.info.scanmode==0 
                recordsPerBuffer = tmp.info.recordsPerBuffer*2;
            else
                recordsPerBuffer = tmp.info.recordsPerBuffer;
            end
            d = dir(imfile);
            switch tmp.info.channels % info needed to compute #frames
                case 1
                    factor = 1;
                case 2
                    factor = 2;
                case 3
                    factor = 2;
            end
            varargout{1} =  d.bytes/recordsPerBuffer/columns*factor/4;
        end
    case  typestr{3} %'prairie'  % 'Prairie .xml'
        iminfo = xml2struct(imfile);
        [path,~,~] = fileparts(imfile);
        tifName = iminfo.PVScan.Sequence.Frame{1, 1}.File{1, 1}.Attributes.filename;
        file = fullfile(path,tifName);
        info=imfinfo(file,'tif');
        rows = info(1).Height;
        columns = info(1).Width;
        if nargout >2; varargout{1} = length(iminfo.PVScan.Sequence.Frame); end
    case  typestr{4} %'neuroplex'
        if strcmp(imfile(end-2:end),'.da')
            sizeA = 2560; % # of integers of header info
            fid = fopen(imfile);
            header = fread(fid, sizeA, 'int16');
            fclose(fid);
            rows = header(385);
            columns = header(386);
            if nargout >2; varargout{1} = header(5); end
        else % neuroplex .tsm file
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
                    iminfo.(strip(ctmp{1}{1})) = strip(ctmp{2}{1});
                end
            end
            rows = str2double(iminfo.NAXIS1);
            columns = str2double(iminfo.NAXIS2);
            if nargout >2; varargout{1} = str2double(iminfo.NAXIS3); end
        end
    case  typestr{5} %'tif' % Standard .tif
        info=imfinfo(imfile,'tif');
        rows = info(1).Height;
        columns = info(1).Width;
        if nargout >2; varargout{1} = length(info); end
    otherwise
        errordlg('Unrecognized Data Type; see getdatatypes.m')
end
end

function val = getVal(metadata, field)
    ind1 = strfind(metadata, field);
    if (~isempty(ind1))
        ind2 = strfind(metadata(ind1:end), 13); %find line breaks
        if isempty(ind2); ind2=strfind(metadata(ind1:end), 10); end %find DOS line breaks
        ind2 = ind2(1);
        line = metadata(ind1:ind1+ind2-2);
        val = sscanf(line,[field '=%f']);
    else
        disp('Error - Invalid metadata field');
        val = 100;
    end
end
function val = getVal_ver5(metadata, field)
    ind1 = strfind(metadata, field);
    if (~isempty(ind1))
        ind2 = strfind(metadata(ind1:end), 13); %find line breaks
        if isempty(ind2); ind2=strfind(metadata(ind1:end), 10); end %find DOS line breaks
        ind2 = ind2(1);
        line = metadata(ind1:ind1+ind2-2);
        val = sscanf(line,[field ' = %f']);
        if isempty(val); val=sscanf(line,[field ' = [%f;%f]']);end
        %tcrtcrtcr this will fail for >2 channels!
    else
        disp('Error - Invalid metadata field');
        val = 100;
    end
end