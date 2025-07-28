function details = extract_trial_details(o)
    if isempty(o.trials)
        details = struct('name',{''},'numeric',false,'choices',{''});
        return
    end
    data = struct('name',{o.trials.name});
    for di = 1:length(data)
        fields = fieldnames(o.trials(di).detail);
        for fi = 1:length(fields)
            data(di).(fields{fi}) = o.trials(di).detail.(fields{fi});
        end
    end
    data = rmfield(data,'name');
    if isfield(data,'comment')
        data = rmfield(data,'comment');
    end
    
    details = struct('name',fieldnames(data));
    for fi = 1:length(details)
        details(fi).numeric = isnumeric([data.(details(fi).name)]);
        if details(fi).numeric
            details(fi).choices = unique([data.(details(fi).name)]);
        else
            dat = {data.(details(fi).name)};
            details(fi).choices = unique(dat(cellfun(@ischar,dat)));
        end
    end
end