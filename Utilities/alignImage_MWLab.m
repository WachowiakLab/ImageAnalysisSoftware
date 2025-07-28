function varargout = alignImage_MWLab(varargin)
%Intensity-based rigid transformation image alignment
%varargin/varargout - this program is designed to work with an image, mwfile struct, or no input
%   A) varargin{1} = image matrix
%       varargin{2} is optional - index of frames to align (example, 1:100), default aligns all frames
%       outputs: varargout{1} = aligned image
%                varargout{2} = (m) mean aligned image
%                varargout{3} = (T) frame shifts matrix (1:frames, [rowshift, colshift])
%      example: [newim, m, T] = alignImage_MWLab(oldim)
%
%   B) varargin{1} = mwfile struct (see loadFile_MWLab for details)
%       varargin{2} is optional - index of frames to align (example, 1:100), default aligns all frames
%       outputs: varargout{1} = mwfile, w/ mwfile.im aligned and mwfile.bAligned = 1;
%                varargout{2} = (m) mean aligned image;
%                varargout{3} = (T) frame shifts matrix (1:frames, [rowshift, colshift])
%                Also, always saves m, T, idx in mwfile.name.align
%       if  mwfile.name.align file exists and idx matches, then you will be asked if you want to 
%       use it (so delete old .align files if you do not want to be asked this question)
%      example: [mwfile, ~, ~] = alignImage_MWLab(mwfile)
%
%   C) no input provided
%       The program uses loadFile_MWLab to select a file and create an mwfile struct.
%       outputs: same as in previous example using mwfile as input.
%
%   Currently if the mwfile.im is a cell (two-channel images), the first channel is used to compute 
%   alignments and results are applied to both channels.
%   Also, the last image frame is always the target of the alignment...

%future suggestions: it may be useful to have an optional input of a target image or frame# for alignment

if nargin
    if isnumeric(varargin{1}) %input is image matrix
        image = varargin{1};
    elseif isstruct(varargin{1}) %input is mwfile struct
        mwfile = varargin{1};
        if isfield(mwfile,'bAligned') && mwfile.bAligned; disp('Image is already aligned'); return; end
        if ~isfield(mwfile,'im'); disp('Image not found'); return; end
        if iscell(mwfile.im)
            image = mwfile.im{1}; disp('Using Channel 1 for alignment');
        else
            image = mwfile.im;
        end
    else
        disp('Input should be image matrix or mwfile struct(see loadFile_MWLab.m)');
    end
    if nargin>1; idx = varargin{2}; else; idx = 1:size(image,3); end
else %no inputs, loadfile_MWLab
    mwfile = loadFile_MWLab;
    if ~isfield(mwfile,'im'); disp('Image not found'); return; end
    if iscell(mwfile.im)
        image = mwfile.im{1}; disp('Using Channel 1 for alignment');
    else
        image = mwfile.im;
    end
    idx = 1:size(image,3);
end
frames = size(image,3);
if frames<2; disp('Image must have 2 or more frames'); return; end
if nargin && isnumeric(varargin{1}) %output is image matrix
    tmpbar = waitbar(0,'Computing alignment (this may take several minutes)...');
    [m,T] = alignFrames(image,idx);
    close(tmpbar);
    if nargout
        %apply shifts
        for f = 1:length(idx)
            image(:,:,idx(f)) = circshift(image(:,:,idx(f)),T(f,:));
        end
        varargout{1} = image; varargout{2} = m; varargout{3} = T;
    end
else %output is mwfile struct - save the .align file
    %check for existing .align file
    dot = strfind(mwfile.name,'.'); if isempty(dot); dot=length(mwfile.name)+1; end
    alignfile = fullfile(mwfile.dir,[mwfile.name(1:dot) 'align']);
    useit = 0;
    if exist(alignfile,'file')==2
        tmp = load(alignfile,'-mat');
        m=tmp.m; T = tmp.T; if ~isfield(tmp,'idx'); tmp.idx = 1:size(tmp.T,1); end %just in case it's a version that didn't save idx
        if ~isempty(T) && isequal(idx,tmp.idx)
            use = questdlg('Existing .align file found, Would you like to use it?',...
                'Use existing?','Yes','No','Yes');
            if strcmp(use,'Yes'); useit = 1; end
        end
    end
    if ~useit %Align
        tmpbar = waitbar(0,'Computing alignment (this may take several minutes)...');
        %MW note 6/23: try instead aligning to mean of last 50 frames; replace last
        %frame of 'image' array with mean of its last 50 - an experiment for now.
        revidx=flip(idx);
        target=mean(image(:,:,revidx(1:50)),3);
        lastidx=size(image,3);
        image(:,:,lastidx)=target;  %rpelace last frame with target image
        [m,T] = alignFrames(image,idx);
        close(tmpbar);
    end
    %save .align file
    save(alignfile,'m','T','idx');
    if nargout
        %apply shifts
        for f = 1:length(idx)
            if iscell(mwfile.im)
                mwfile.im{1}(:,:,idx(f)) = circshift(mwfile.im{1}(:,:,idx(f)),T(f,:));
                mwfile.im{2}(:,:,idx(f)) = circshift(mwfile.im{2}(:,:,idx(f)),T(f,:));
            else
                mwfile.im(:,:,idx(f)) = circshift(mwfile.im(:,:,idx(f)),T(f,:));
            end
        end
        mwfile.bAligned = 1;
        varargout{1}=mwfile; varargout{2} = m; varargout{3} = T;
    end
end

function [m,T] = alignFrames(image,idx)
% Aligns image for all indices in idx
%   TCR note: everything gets aligned to the last image frame...
% m - mean image after the alignment
% T - optimal translation for each frame

if(length(idx)==1)
    A = image(:,:,idx(1));
    m = A;
    T = [0 0];
elseif (length(idx)==2)
    A = image(:,:,idx(1));
    B = image(:,:,idx(2));
    
    [u, v] = fftalign(A,B);
    
    Ar = circshift(A,[u,v]);
    m = (Ar+B)/2;
    T = [[u v] ; [0 0]];
else
    idx0 = idx(1:floor(end/2));
    idx1 = idx(floor(end/2)+1 : end);
    [A,T0] = alignFrames(image,idx0);
    [B,T1] = alignFrames(image,idx1);
   
    [u, v] = fftalign(A,B);
     
    Ar = circshift(A,[u, v]);
    m = (Ar+B)/2;
    T = [(ones(size(T0,1),1)*[u v] + T0) ; T1];
end

function [u,v] = fftalign(A,B)
    N = min(size(A))-20;    % leave margin

    yidx = round(size(A,1)/2)-N/2 + 1 : round(size(A,1)/2)+ N/2;
    xidx = round(size(A,2)/2)-N/2 + 1 : round(size(A,2)/2)+ N/2;

    A = A(yidx,xidx);
    B = B(yidx,xidx);

    C = fftshift(real(ifft2(fft2(A).*fft2(rot90(B,2)))));
    [~,i] = max(C(:));
    [ii, jj] = ind2sub(size(C),i);

    u = N/2-ii;
    v = N/2-jj;
end
end
end