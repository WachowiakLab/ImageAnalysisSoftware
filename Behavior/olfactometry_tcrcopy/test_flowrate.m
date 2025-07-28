function [display_trace, display_deriv, horz_lines, sniff_flowrate] = test_flowrate(tr, samplingrate, thresh,odor_time)

onset = odor_time.odor_onset
offset = odor_time.odor_offset

tr = tr(2:end);
trz = (tr-mean(tr))./std(tr); %zscore

%lookahead = samplingrate/50;
%filtering (LPF smooths it; HPF removes any offset):
trf = lpf(trz,samplingrate,2,10);
trf = hpf(trf,samplingrate,2,1); %assume that transient effect of sniffing is over in < 1 s
%trf = -trf; %inverted polarity!

trfd=diff(trf,1); %estimates first derivative of filtered sniff trace
horz_lines = [thresh./2, -thresh./2]; %displays set minimum amplitude between peak and trough for debugging

[peaks,troughs] = peakdet(trf,thresh); %detecting peaks and troughs on sniff trace
peaks = [peaks(:,1)./samplingrate peaks(:,2)];
troughs = [troughs(:,1)./samplingrate troughs(:,2)];
 %[dpeaks,~] = peakdet(trfd,thresh./2); %detecting peaks only on derivative
           % dpeaks = [dpeaks(:,1)./samplingrate dpeaks(:,2)];

            peaks_odor = peaks;%(peaks(:,1) <= offset & peaks(:,1) > onset,:);                %restricting results to odor stim
            troughs_odor = troughs;%(troughs(:,1) > onset & troughs(:,1) <= offset,:);        %restricting results to odor stim
                         
            if peaks_odor(1,1)<troughs_odor(1,1)                                            %making sure we deal with entire cycles
                peaks_odor=peaks_odor(2:end,:);
            end
            if peaks_odor(end,1)<troughs_odor(end,1)                                        %making sure we deal with entire cycles
                troughs_odor=troughs_odor(1:end-1,:);
            end
            
            dflow =[];
            while length(find(dflow))/2 ~= size(peaks_odor,1) && thresh > 0
                [dpeaks,~] = peakdet(trfd,thresh); %detecting peaks only on derivative
                thresh = thresh - 0.05;
                if size(dpeaks,1) >= size(peaks_odor,1)
                    dpeaks = [dpeaks(:,1)./samplingrate dpeaks(:,2)];
                    dflow=zeros(size(peaks_odor,1),2);
                    for i=1:length(peaks_odor)
                        dflow_thiscycle = dpeaks(dpeaks(:,1) > troughs_odor(i,1) & dpeaks(:,1) < peaks_odor(i,1),:);
                        if ~isempty(dflow_thiscycle)
                            dflow(i,:)= dflow_thiscycle(find(min(dflow_thiscycle(:,1))),:);  %#ok<FNDSB> %for each trough and peak i get the value of the peak of the derivative (if several peaks, get the first one)
                        end
                    end
                end
            end


% for i=1:length(peaks_odor)
%    dflow_thiscycle = dpeaks(dpeaks(:,1) > troughs_odor(i,1) & dpeaks(:,1) < peaks_odor(i,1),:);
%     dflow= [ dflow;  dflow_thiscycle(find(min(dflow_thiscycle(:,1))),:) ];%              dpeaks(min(dpeaks(dpeaks(:,1) > troughs_odor(i,1) & dpeaks(:,1) < peaks_odor(i,1),:)),:)];  %for each trough and peak i get the peak value of the derivative
%     
% end

sniff_flowrate = [ troughs_odor(:,1) peaks_odor(:,1) peaks_odor(:,2)-troughs_odor(:,2) dflow(:,1) dflow(:,2)]   % put all this together : one row = one cycle, with trough position, peak position, amplitude of the sniff trace between trough and peak, position of peak derivative and peak of the derivative.


display_trace = trf;
display_deriv = trfd;

end





