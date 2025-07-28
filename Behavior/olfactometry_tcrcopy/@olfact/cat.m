function o = cat(o,add_o)
    if isa(add_o,'olfact')
        for ti = 1:length(add_o.trials) %change offset of join table
            add_o.trials(ti).rois.nums = add_o.trials(ti).rois.nums + length(o.rois);
        end
        o.trials = [o.trials add_o.trials];
        o.rois = [o.rois add_o.rois];
    end
end