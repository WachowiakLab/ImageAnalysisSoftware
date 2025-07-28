function [display_trace, horz_lines, detected_sniffs] = stimtime_sniff_thermo(tr, samplingrate, thresh,revert,det_meth)

tr = tr(2:end);
trz = (tr-mean(tr))./std(tr); %zscore
lookahead = samplingrate/50;
%filtering (LPF smooths it; HPF removes any offset):
trf = lpf(trz,samplingrate,2,12);                       %%default  trf = lpf(trz,samplingrate,2,25);
trf = hpf(trf,samplingrate,2,1); %assume that transient effect of sniffing is over in < 1 s    %% default trf = hpf(trf,samplingrate,2,1);
if revert
    trf = -trf; %inverted polarity!
end

display_trace = trf;

if strcmp(det_meth,'Zero-X')
    horz_lines = [0, thresh]; %display both the zero and the threshold for debugging
    detected_sniffs = find(trf(1:end-1-lookahead) < 0 & trf(2:end-lookahead) >= 0 & trf(2+lookahead:end) > thresh)' ./ samplingrate;
elseif strcmp(det_meth,'Trough')
    [~, mintab] = peakdet(trf,thresh);
    detected_sniffs = mintab(:,1) ./ samplingrate;
    horz_lines = [0-thresh./2, thresh./2]; %display both the zero and the threshold for debugging
end