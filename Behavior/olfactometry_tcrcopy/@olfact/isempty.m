function tf = isempty(o)
    tf = isempty(o.trials) && isempty(o.rois);
end