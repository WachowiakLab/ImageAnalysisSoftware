function thresh = get_pre_odor_noise_thresh(o,rois)
    tr_n = zeros(size(rois));
    tr_m = zeros(size(rois));
    tr_v = zeros(size(rois));
    for t = 1:length(o.trials)
        if isfield(o.trials(t).measurement,'odor_onoff')
            [tf, loc] = ismember(o.trials(t).rois.nums,rois);
            if any(tf)
                if isempty(o.trials(t).measurement.odor_onoff.odor_onset)
                    onset = o.trials(t).rois.datasize(1);
                else
                    onset = floor(o.trials(t).measurement.odor_onoff.odor_onset * o.trials(t).rois.samplingrate);
                end
                for ri = 1:length(tf)
                    if tf(ri)
                        r = loc(ri);
                        tr = o.trials(t).rois.traces(ri,1:onset) ./ o.trials(t).rois.RLIs(ri);
                        s = sum(tr); n = length(tr); v = var(tr);
                        N = tr_n(r) + n;
                        M = (tr_n(r)*tr_m(r) + s) / N;
                        tr_v(r) = (tr_n(r)*tr_v(r) + n*v  +  tr_n(r)*(tr_m(r)-M)^2 + n*(s/n-M)^2) / N;
                        tr_m(r) = M;
                        tr_n(r) = N;
                    end
                end
            end
        end
    end

    thresh = sqrt(tr_v) .* 2.5;
end


%% original:
% function thresh = get_pre_odor_noise_thresh(o,rois)
%     noises = cell(length(rois),length(o.trials));
%     for t = 1:length(o.trials)
%         if isfield(o.trials(t).measurement,'odor_onoff') && isfield(o.trials(t).measurement,'stim_times') && isfield(o.trials(t).measurement,'roi_stim_noise')
%             [tf, loc] = ismember(o.trials(t).rois.nums,rois);
%             if any(tf)
%                 if isempty(o.trials(t).measurement.odor_onoff.odor_onset)
%                     onset = o.trials(t).trial_length;
%                 else
%                     onset = o.trials(t).measurement.odor_onoff.odor_onset;
%                 end
%                 noise = o.trials(t).measurement.roi_stim_noise;
%                 noise = noise([noise.stimtime] < onset);
%                 
%                 for ri = 1:length(tf)
%                     if tf(ri)
%                         f = [noise.roi_num] == ri;
%                         noises{loc(ri),t} = [noise(f).max] - [noise(f).min];
%                     end
%                 end
%             end
%         end
%     end
%     noise = cell(1,length(rois));
%     for ri = 1:length(rois)
%         noise{ri} = [noises{ri,:}];
%     end
%     thresh = 4 .* cellfun(@std,noise); % + cellfun(@mean,noise)
% end
