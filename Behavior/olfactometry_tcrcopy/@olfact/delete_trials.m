function [o wasmodified] = delete_trials(o,trials)
    o.trials(trials) = [];
    o = remove_unused_rois(o);
    wasmodified = ~isempty(trials);
end