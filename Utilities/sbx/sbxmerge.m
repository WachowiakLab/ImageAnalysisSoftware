function sbxmerge(fn)

% Merge OT segment and signal files

dsig = dir([fn '*ot*.signals']);
dseg = dir([fn '*ot*.segment']);
type = 'ot';

if isempty(dsig)
    dsig = dir([fn '*roi*.signals']);
    dseg = dir([fn '*roi*.segment']);
    type = 'roi';
end

if length(dsig) ~= length(dseg)
    fprintf(2,'Mismatch number of signal and segment files\n');
    return;
end

ns = length(dsig); % number of slices or ROIs

ncells = 0;
nsamples = 0;
nc = zeros(1,ns);

for i = 1:ns
    seg_ot(i) = load('-mat',dseg(i).name);
    sig_ot(i) =  load('-mat',dsig(i).name);
    nchan = size(sig_ot(i).sig,1);
    if(nchan==1)
        nc(i) = size(sig_ot(i).sig,2);
        ncells = ncells+nc(i);
        nsamples = nsamples + size(sig_ot(i).sig,1);
    else
        nc(i) = size(sig_ot(i).sig,3);
        ncells = ncells+nc(i);
        nsamples = nsamples + size(sig_ot(i).sig,2);
    end
end

sig = NaN*zeros(nchan,nsamples,ncells);
spks = zeros(size(sig));

k=1;
mask = zeros([size(seg_ot(i).mask) ns]);
for s=1:ns
    sig(:,s:ns:end,k:k+nc(s)-1) = sig_ot(s).sig;
    mask(:,:,s) = seg_ot(s).mask + k - 1;
    k = k+nc(s);
end

% drop other channels if present....

sig = squeeze(sig(1,:,:));
spks = squeeze(spks(1,:,:));

% interpolate signals and deconvolve

for i = 1:size(sig,2)
    idx = find(~isnan(sig(:,i)));
    vq = interp1(idx,sig(idx,i),1:size(sig,1),'pchip');
    sig(:,i) = vq;         
    spks(:,i) = deconv(sig(:,i), [1.5    1.8503    0.2958    9.3894]);
end

switch type
    case 'ot'
        save([fn '_merged.signals'],'sig','spks','sig_ot');
        save([fn '_merged.segment'],'mask','seg_ot');
    case 'roi'
        sig_roi = sig_ot;
        seg_roi = seg_ot;
        save([fn '_merged.signals'],'sig','spks','sig_roi');
        save([fn '_merged.segment'],'mask','seg_roi');
end



function y = deconv(y,x)

s = x(1);   % sigma
th = x(2);  % theta
b = x(3);   % beta
a = x(4);   % alpha

nsamp = size(y,1);

% Odd filter

t = 0:nsamp-1;
w = t.*exp(-t.^2 / (2*s^2));
w(2:end) = (w(2:end)-w(end:-1:2));
w = -w';
w = w/norm(w);

% Even filter

w0 = zeros(nsamp,1);
w0 = exp(-t.^2 / (2*s^2));
w0(2:end) = (w0(2:end)+w0(end:-1:2));
w0 = w0';
w0 = w0/norm(w0);
 
% Filtered signals

wf0 = fft(w0);
xf0 = real(ifft(fft(y(1:nsamp)).*wf0));
xf0 = zscore(xf0);

wf = fft(w);
xf = real(ifft(fft(y(1:nsamp)).*wf));
xf = zscore(xf);

% Of course one can combine the filters first and convolve once...
% but for historical reasons I kept them separate.

% Linear combination of filtered signals

xf = cosd(a)*xf+sind(a)*xf0;

% Output nonlinearity

y(1:nsamp) = (xf-th).^b .* (xf>=th);






    