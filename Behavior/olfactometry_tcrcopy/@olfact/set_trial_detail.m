function [o wasmodified fieldchange] = set_trial_detail(o,tr,detailname,newvalue)
    wasmodified = false;
    
    if isnan(newvalue)
        for ti = 1:length(tr)
            if isfield(o.trials(tr(ti)).detail,detailname)
                wasmodified = true;
                o.trials(tr(ti)).detail = rmfield(o.trials(tr(ti)).detail,detailname);
            end
        end
        data = extract_trial_info(o);
        fieldchange = ~isfield(data,detailname);
    else
        data = extract_trial_info(o);
        fieldchange = ~isfield(data,detailname);
        for ti = 1:length(tr)
            if ~isfield(o.trials(tr(ti)).detail,detailname) || length(o.trials(tr(ti)).detail.(detailname)) ~= length(newvalue) || any(o.trials(tr(ti)).detail.(detailname) ~= newvalue)
                wasmodified = true;
                o.trials(tr(ti)).detail.(detailname) = newvalue;
            end
        end
    end
end