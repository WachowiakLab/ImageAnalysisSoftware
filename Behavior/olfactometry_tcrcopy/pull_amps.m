function amplitudes=pull_amps(od_s)
    
    hm_trials=max(unique([od_s.during.trial_num]));
    rois=unique([od_s.during.roi]);
    amplitudes=zeros(length(rois),hm_trials);
    for i=rois
        sniff=1;
        amps=[od_s.during([od_s.during.roi]==i & [od_s.during.sniff_num]==sniff).amplitude];
        if isempty(amps)
            sniff=sniff+1;
            amps=[od_s.during([od_s.during.roi]==i & [od_s.during.sniff_num]==sniff).amplitude];
        end
        amplitudes(i,1:length(amps))=amps;
    end



end
