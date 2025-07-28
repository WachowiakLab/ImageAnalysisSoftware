function r = sbxtrinoise(fname)

% analyze tri noise experiment

% edit Luis 1/10/17. Allow rigid and nonrigid .signals files as input..
    % -----
    if contains(fname,'rigid') % search for rigid in filename
        si = strfind(fname,'_'); 
        fnamelog = fname( 1:si(end)-1); % remove it
    else 
        fnamelog = fname;
    end
    % -----

%%
log = sbxreadtrinoiselog(fnamelog); % read log

load([fname, '_rigid.signals'],'-mat');    % load signals
if(ndims(spks)>2)
    spks = squeeze(spks(1,:,:));     % keep green channel
    sig =  squeeze(sig(1,:,:));
end

dsig = spks;

bad = find(isnan(sum(spks))); % some bad ROIs?
dsig(:,bad) = abs(randn(size(spks,1),length(bad))); % replace with white noise

ncell = size(dsig,2);
nstim = length(log);

ntau = 20;

[nrow, ncol] = size(log{1}{2});

X = zeros(nstim,nrow*ncol); % data matrix
for i = 1:nstim
    X(i,:) = log{i}{2}(:)' - 1;
end

X = [ones(size(X,1),1) X]; % add intercept 

frame = cellfun(@(x) x{3},log,'UniformOutput',true)';

stat = cell(ncell,10);

for i = 1:ncell
    [i ncell]
    for tau=1:10
        Y = dsig(frame+tau,i);
        b = regress(Y,X);
        stat{i}{tau} = reshape(b(2:end),nrow,ncol);
    end
end

%% find kernel and SNR

clear r;

for i = 1:ncell
    sd = zeros(1,10);
    for tau = 1:10
        sd(tau) = kurtosis(stat{i}{tau}(:));
    end
    [m,topt] = max(sd);
    snr = m;
    r(i).snr = snr;
    r(i).t = topt;
    if(topt>1 && topt<10)
        r(i).kern = (stat{i}{topt-1}+stat{i}{topt}+stat{i}{topt+1})/3;
    else
        r(i).kern = stat{i}{topt};
    end
end


save([fname, '.trinoise'], 'r')

