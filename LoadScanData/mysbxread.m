function [x,sbxinfo] = mysbxread(fname,k,N,varargin)
% img = sbxread(fname,k,N,varargin)
% Reads from frame k to k+N-1 in file fname
% fname - the file name (e.g., 'xx0_000_001')
% k     - the index of the first frame to be read.  The first index is 0.
% N     - the number of consecutive frames to read starting with k.
%
% If N>1 it returns a 4D array of size = [#pmt rows cols N]
% If N=1 it returns a 3D array of size = [#pmt rows cols]
%
% #pmts is the number of pmt channels being sampled (1 or 2)
% rows is the number of lines in the image
% cols is the number of pixels in each line
%
% The function also creates a global 'sbxinfo' variable with additional
% information about the file

tmp = load(fname);
sbxinfo = tmp.info;

if(~isfield(sbxinfo,'sz'))
    sbxinfo.sz = [512 796];    % it was only sz = ....
end
if(~isfield(sbxinfo,'scanmode'))
    sbxinfo.scanmode = 1;      % unidirectional
end
if(sbxinfo.scanmode==0)
    recordsPerBuffer = sbxinfo.recordsPerBuffer*2;
else
    recordsPerBuffer = sbxinfo.recordsPerBuffer;
end
if sbxinfo.scanbox_version == 3
    switch sbxinfo.channels
        
        case 1
            sbxinfo.chan.nchan = 2;      % both PMT0 & 1
            factor = 1;
        case -1
            sbxinfo.chan.nchan = 1;      % PMT 0
            factor = 2;
        case 3
            sbxinfo.chan.nchan = 1;      % PMT 1
            factor = 2;
    end
        sbxinfo.nsamples = (sbxinfo.sz(2) * recordsPerBuffer * 2 * sbxinfo.chan.nchan);
else
    switch sbxinfo.channels
        case 1
            sbxinfo.nchan = 2;      % both PMT0 & 1
            factor = 1;
        case 2
            sbxinfo.nchan = 1;      % PMT 0
            factor = 2;
        case 3
            sbxinfo.nchan = 1;      % PMT 1
            factor = 2;
    end
        sbxinfo.nsamples = (sbxinfo.sz(2) * recordsPerBuffer * 2 * sbxinfo.nchan);
end


sbxinfo.fid = fopen([fname '.sbx']);
d = dir([fname '.sbx']);
   % bytes per record
if isfield(sbxinfo,'scanbox_version') && sbxinfo.scanbox_version >= 2 && sbxinfo.scanbox_version < 3
    sbxinfo.max_idx =  d.bytes/recordsPerBuffer/sbxinfo.sz(2)*factor/4 - 1;
elseif isfield(sbxinfo,'scanbox_version') && sbxinfo.scanbox_version >= 3
            sbxinfo.max_idx = d.bytes/prod(sbxinfo.sz)/sbxinfo.chan.nchan/2 -1;
            sbxinfo.nsamples = prod(sbxinfo.sz)*sbxinfo.chan.nchan*2;
else
    sbxinfo.max_idx =  d.bytes/sbxinfo.bytesPerBuffer*factor - 1;
end

if(isfield(sbxinfo,'fid') && sbxinfo.fid ~= -1) && ~(N==0)
    wait = waitbar(1/4,'Loading File');
    try
        fseek(sbxinfo.fid,k*sbxinfo.nsamples,'bof');
        x = fread(sbxinfo.fid,sbxinfo.nsamples/2 * N,'uint16=>uint16');
        waitbar(3/4,wait);
        if sbxinfo.scanbox_version == 3
            x = reshape(x,[sbxinfo.chan.nchan sbxinfo.sz(2) recordsPerBuffer  N]);
        else
            x = reshape(x,[sbxinfo.nchan sbxinfo.sz(2) recordsPerBuffer  N]);
        end
    catch
        error('Cannot read frame.  Index range likely outside of bounds.');
    end
    x = intmax('uint16')-permute(x,[1 3 2 4]);
    close(wait);
else
    x = [];
end
% for bidirectional scan, make bright bands where data was not acquired into dark bands
if(sbxinfo.scanmode==0); x(x>=65535)=0; end
fclose(sbxinfo.fid);