function [numChannels] = getNumChannels(datatype,imfile)
% [numChannels] = getNumChannels(datatype,imfile)
%   datatype: 'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'
%   imfile must be full path name (e.g. pathname/filename.tif)

typestr = getdatatypes; % {'scanimage', 'scanbox', 'prairie', 'neuroplex', 'tif'};
switch datatype
    case typestr{1} %'scanimage' % ScanImage .tif (aka MWScope)
        if strcmp(imfile(end-2:end),'tif') %scanimage .tif file
            tmptiff = Tiff(imfile, 'r');
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
            %fprintf('Total number of channels detected: %d\n',numChannels);
            tmptiff.close(); clear tmptiff;
        elseif strcmp(imfile(end-2:end),'dat')
            load([imfile(1:end-3),'mat'],'-mat');
            numChannels = SIinfo.numChannels;
        end
    case typestr{2} %'scanbox' % 'Scanbox .sbx'
        tmp = load(imfile(1:end-4));
        if (tmp.info.scanbox_version == 3)
           channel = tmp.info.channels;
           switch channel
            case 2
                numChannels = 2; % both PMT0 & 1
            case -1
                numChannels = 1;      % PMT 0
            case 3
                numChannels = 1;      % PMT 1
            end
        else
           channel = tmp.info.channels;
        
        switch channel
            case 1
                numChannels = 2; % both PMT0 & 1
            case 2
                numChannels = 1;      % PMT 0
            case 3
                numChannels = 1;      % PMT 1
        end
        end
    case typestr{3} %'prairie'  % 'Prairie .xml'
        numChannels = 1; %tcrtcr this is just temporary!
%         iminfo = xml2struct(imfile);
%         [path,~,~] = fileparts(imfile);
%         tifName = iminfo.PVScan.Sequence.Frame{1, 1}.File{1, 1}.Attributes.filename;
%         file = fullfile(path,tifName);
%         info=imfinfo(file,'tif');
%         rows = info(1).Height;
%         columns = info(1).Width;
%         if nargout >2; varargout{1} = length(iminfo.PVScan.Sequence.Frame); end
    case typestr{4} %'neuroplex' % 'Neuroplex .da'
        numChannels = 1; %tcrtcr this is just temporary!
%         sizeA = 2560; % # of integers of header info
%         fid = fopen(imfile);
%         header = fread(fid, sizeA, 'int16');
%         fclose(fid);
%         rows = header(385);
%         columns = header(386);
%         if nargout >2; varargout{1} = header(5); end
    case typestr{5} %'tif' % Standard .tif
        numChannels = 1; %tcrtcr this is just temporary!
%         info=imfinfo(imfile,'tif');
%         rows = info(1).Height;
%         columns = info(1).Width;
%         if nargout >2; varargout{1} = length(info); end
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