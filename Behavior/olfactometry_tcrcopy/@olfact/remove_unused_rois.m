function o = remove_unused_rois(o)
    %clean up roi references:
    rois = false(size(o.rois));
    for ti = 1:length(o.trials)
        rois(o.trials(ti).rois.nums) = true;
    end
    remove = find(~rois);
    if ~isempty(remove)
    for ti = 1:length(o.trials)
        o.trials(ti).rois.nums = arrayfun(@(e) e - sum(remove < e),o.trials(ti).rois.nums);
    end
    end
    o.rois = o.rois(rois);
end