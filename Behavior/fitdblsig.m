function fits = fitdblsig(behaviordata,odorDuration)

inflectthresh = 1e-8;%0.5e-6;
% fits = cell(length(behaviordata.trials,length(behaviordata.trials(t).rois));
% noise = cell(length(behaviordata.trials,length(behaviordata.trials(t).rois));
for t = 1:length(behaviordata.trials)
trial = behaviordata.trials(1);
iOdorOn = find(trial.aux1.signal>0,1,'first')-1;
tmpOdorOnTime = trial.aux1.times(iOdorOn);
iOdorOff = find(trial.aux1.times>tmpOdorOnTime+odorDuration,1,'first');
OdorOnTime = tmpOdorOnTime-trial.aux1.times(1); %delay from start
for r = 1:length(trial.roi)
    sigthresh = 2.5*std(trial.roi(r).series(1:iOdorOn)); %threshold for significance of responses
    %get trace while odor is on
    tr_times = trial.roi(r).time(iOdorOn:iOdorOff)-trial.roi(r).time(1);
    tr = (trial.roi(r).series(iOdorOn:iOdorOff)-mean(trial.roi(r).series(1:iOdorOn)))./mean(trial.roi(r).series(1:iOdorOn)); %df/f
    figure; plot(tr_times,tr); hold on;
    ftr = denoise(hpf(lpf(tr,trial.frameRate,2,4),trial.frameRate,2,0.4)); %notch and wavelet filters
    plot(tr_times,ftr);
    dtr = [0 diff(ftr)]; %first derivative - slope
    lmins = find(dtr(1:end-1) < 0 & dtr(2:end) >= 0);
    tdtr = dtr .* (dtr > 0); %thresholded version
    ddtr = [0 diff(dtr)]; %second derivative - concavity
    tddtr = ddtr .* (ddtr > 0); %thresholded version 
    comb = tdtr .* tddtr; %slope*concavity
    comb = comb .* (comb > inflectthresh); %THRESHOLD it
    dcomb = [0 diff(comb)];
    pcomb = find(dcomb(1:end-1) > 0 & dcomb(2:end) <= 0); %find times of all local max(slope*concavity) (above a threshold)
    if ~isempty(pcomb)
        vcomb = find(dcomb(1:end-1) <= 0 & dcomb(2:end) > 0, length(pcomb)); %find times of all local min...
        inflections = pcomb(comb(vcomb) == 0);
    else
        inflections = [];
    end
    starts = inflections; starts_times = tr_times(inflections);
    stops = [starts(2:end) length(tr)]; stops_times = [starts_times(2:end) tr_times(end)];
    stem(starts_times,ones(size(starts_times)));
    %using detected sniffs
    if ~isfield(trial,'det_sniffs') || isempty(trial.det_sniffs); break; end
    include = trial.det_sniffs.inhalations_times>=OdorOnTime &  trial.det_sniffs.inhalations_times<(OdorOnTime+odorDuration); %odor on sniffs
    sniffs_times = trial.det_sniffs.inhalations_times(include);
    stem(sniffs_times,ones(size(sniffs_times)));
    for s = 1:length(sniffs_times)-1
        inwindow = find(starts_times>=sniffs_times(s) & starts_times<sniffs_times(s+1));
        disp(inwindow);
        if length(inwindow)>1
            [~,imax] = max( comb(inwindow)); %find the maximum slope*concavity in the window
            inwindow = inwindow(imax);
        end

%         stimtime(inwindow) = sniffs_times(s);
%         resptime(inwindow) = starts(inwindow);
        disp(starts(inwindow));
        lastmin = find(lmins <= starts(inwindow),1,'last');
        if ~isempty(lastmin) && lmins(lastmin) > sniffs_times(s) %move start back to either last local min
            starts(inwindow) = lmins(lastmin);  
            starts_times(inwindow) = tr_times(lastmin);
        else % or to sniff start (whichever is later)
            starts(inwindow) = find(tr_times>=sniffs_times(s),1,'first');
            starts_times(inwindow) = tr_times(starts(inwindow)); 
        end
        %should adjust stops too!

        %do noise calculation (max/min within first 500 ms after sniff):
        tmptr = tr(tr_times>=starts_times(inwindow) & tr_times<starts_times(inwindow)+0.5);
        %subtr_end = min(stims_samp(s+1),stims_samp(s)+floor(0.5 * trial.rois.samplingrate));
        noise_mins(s) = min(tmptr);
        noise_maxs(s) = max(tmptr);
        
    end
    
    %stem(starts_times,ones(size(starts_times)));
            
            

    fits = struct('stimtime',num2cell(starts ./ trial.frameRate),'start',num2cell(starts ./ trial.frameRate),...
        'inflection',num2cell(inflections(inwindow) ./ trial.frameRate),'rise_amplitude',[],'onset_time',[],...
        'rise_time',[],'fall_amplitude',[],'offset_time',[],'fall_time',[],'resp_amplitude',[],'t_10',[],...
        't_peak',[],'t_50',[],'t_50b',[],'roi_num',[],'end',[],'y_offset',[]);
    noise = struct('stimtime',{},'min',{},'max',{},'roi_num',{});

    isgood = true(size(fits));
    for n = 1:length(fits)

        fits(n).y_offset = tr(starts(n));
        subtr = tr(starts(n):ends(n)) - fits(n).y_offset;
        %find first local max (within first 200 ms):
        [maxx,maxlag] = max(subtr(1:min(end,floor(0.2 * trial.frameRate))));

        %initialize the estimates:
        estimates = struct;
        estimates.rise_amplitude = maxx;
        estimates.onset_time = find(subtr>(maxx.*0.5),1); %midpoint of rise
        estimates.rise_time = find(subtr>(maxx.*0.9),1)-find(subtr>(maxx.*0.1),1);
        if estimates.rise_time == 0
            estimates.rise_time = 1;
        end
        if isempty(maxlag) || isempty(estimates.onset_time) || isempty(estimates.rise_time)
            isgood(n) = false;
        end
        offset_time = [maxlag+find(subtr(maxlag:end)<(maxx.*0.5+subtr(end).*(1-0.5)),1) estimates.onset_time+3*estimates.rise_time]; %empirically derived default offset time
        estimates.offset_time = offset_time(1); %midpoint of fall
        estimates.fall_time = find(subtr(maxlag:end)<(maxx.*0.1+subtr(end).*(1-0.1)),1)-find(subtr(maxlag:end)<(maxx.*0.9+subtr(end).*(1-0.9)),1);
        if isempty(estimates.fall_time)
            if maxx ~= subtr(end) %use some empirically derived falltimes
                estimates.fall_time = (length(subtr)-maxlag)*(maxx-subtr(end))/(maxx-subtr(end));
            else
                estimates.fall_time = 3*estimates.rise_time;
            end
        end
        if estimates.fall_time == 0
            estimates.fall_time = 1;
        end
        estimates.fall_amplitude = maxx - subtr(end);
        if estimates.fall_amplitude < 0
            estimates.fall_amplitude = realmin * 2;
        end
            

        A = dbl_sigmoid_struct2arr(estimates);
        ub = A + abs(A)/2 + realmin;
        lb = A - abs(A)/2 - realmin;
        opt = optimset('Display','off','MaxIter',1);
        warning_backup = warning('query','all');
        warning('off','optim:lsqncommon:SwitchToLineSearch')
%             B=([A(1) 1 A(2) 0.5*A(1) .5 A(5)]);
%             figure; plot(1:length(subtr),subtr); hold on;
%             plot(1:length(subtr),dbl_sigmoid_arr(A,0:length(subtr)-1));
%             opt = optimset('Display','off','MaxIter',10);
        try
            A = lsqcurvefit(@dbl_sigmoid_arr,A,0:length(subtr)-1,subtr,lb,ub,opt);
%                 disp(A);
%                 ub = abs(B)*5;
%                 lb = abs(B)/5;
%                 B = lsqcurvefit(@diff_sigmoid_arr,B,1:length(subtr),subtr,lb,ub,opt);
%                 disp(B);
            %goodness = xcorr(dbl_sigmoid_arr(A,1:length(subtr)),subtr,0,'coeff');
%                 [~,maxind]=max(subtr);
%                 subtrA=subtr(1:maxind+1); subtrB=subtr(maxind+1:end);
%                 disp('tcr')
%                 newA=A(1:3); newB=A([1 5 6]);
%                 ubA = newA + abs(newA)/2 + realmin; %ubB = newB + abs(newB)/2 + realmin;
%                 lbA = newA - abs(newA)/2 - realmin; %lbB = newB - abs(newB)/2 - realmin;
%                 newA = lsqcurvefit(@sigmoid_arr,newA,0:length(subtrA)-1,subtrA,lbA,ubA,opt);
%                 newB = lsqcurvefit(@sigmoid_decay,newB,0:length(subtrB)-1,subtrB,lbB,ubB,opt);
        catch
            isgood(n) = false;
        end
            %visualize fit results
%             plot(1:length(subtr),dbl_sigmoid_arr(A,0:length(subtr)-1));
%             plot(1:length(subtr),diff_sigmoid_arr(B,1:length(subtr)));
        fits(n) = dbl_sigmoid_arr_add2struct(fits(1), A);
%             disp(newA); disp(newB);
%             plot(1:length(subtrA),sigmoid_arr(newA,0:length(subtrA)-1));
% 
        fits(n).onset_time = fits(n).onset_time / trial.frameRate;
        fits(n).rise_time = fits(n).rise_time / trial.frameRate;
        fits(n).offset_time = fits(n).offset_time / trial.frameRate;
        fits(n).fall_time = fits(n).fall_time / trial.frameRate;

        if fits(n).onset_time > 0.4 || fits(n).fall_amplitude < 0 %|| goodness < 0.98
            isgood(n) = false;
        end
%             
%             if isfield(fits(n),'flowrate_mag')
%                 flowrate = trial.measurement.flowrate;
%                 rate = flowrate((fits(n).start >= flowrate(1:end-1,1) & fits(n).start < flowrate(2:end,1)),:);
%                 if size(rate,1) == 1
%                     fits(n).flowrate_mag = rate(3);
%                     fits(n).flowrate_diff = rate(5);
%                 elseif  size(rate,1) > 1
%                     fits(n).flowrate_mag = rate(1,3);
%                     fits(n).flowrate_diff = rate(1,5);
%                 else
%                     fits(n).flowrate_mag = nan;
%                     fits(n).flowrate_diff = nan;
%                 end
%             end
        %upsample by factor of 10 to calculate t_10, t_peak, duration
        subtr = dbl_sigmoid(fits(n),(0:length(subtr)*10) / trial.rois.samplingrate / 10) - fits(n).y_offset;
        [maxx,maxlag] = max(subtr);
        fits(n).resp_amplitude = maxx;
        fits(n).t_10 = find(subtr >= (maxx.*0.1),1) / trial.rois.samplingrate / 10;
        fits(n).t_peak = maxlag / trial.rois.samplingrate / 10;
        fits(n).t_50 = find(subtr >= (maxx.*0.5),1) / trial.rois.samplingrate / 10;
        t_50b = find(subtr(maxlag:end) <= (maxx.*0.5),1);
        if isempty(t_50b)
            fits(n).t_50b = NaN;
        else
            fits(n).t_50b = (t_50b + maxlag - 1) / trial.rois.samplingrate / 10;
        end                

        fits(n).end = fits(n).start + fits(n).offset_time + fits(n).fall_time/2;
    end
    fits = fits(isgood);

end
end

function y = dbl_sigmoid_arr(A,t)
    y = A(1)./(exp(-4.4*(t - A(2))./A(3)) + 1) - A(4)./(exp(-4.4*(t - A(5))./A(6)) + 1);
end
function y = diff_sigmoid_arr(A,t)
    y = A(1)*sigmf(t,[A(2) A(3)]) - A(4)*sigmf(t,[A(5) A(6)]);
end

function B = dbl_sigmoid_arr_add2struct(B,A)
    B.rise_amplitude = A(1); B.onset_time = A(2); B.rise_time = A(3); B.fall_amplitude = A(4); B.offset_time = A(5); B.fall_time = A(6);
end

function A = dbl_sigmoid_struct2arr(B)
    A = [B.rise_amplitude B.onset_time B.rise_time B.fall_amplitude B.offset_time B.fall_time];
end
end