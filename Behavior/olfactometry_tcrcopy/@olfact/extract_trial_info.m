function data = extract_trial_info(o)
    data = struct('name',{o.trials.name},'timestamp',cellstr(datestr([o.trials.timestamp]))','trial_length',num2cell([o.trials.trial_length]),'numtrialavg',num2cell([o.trials.numtrialavg]));
    for di = 1:length(data)
        add_field(o.trials(di),'measurement')
        add_field(o.trials(di),'detail')
    end
    
    function add_field(struc,field)
        if isstruct(struc.(field)) && length(struc.(field)) == 1
            fields = fieldnames(struc.(field));
            for fi = 1:length(fields)
                add_field(struc.(field),fields{fi}) %recurse through sub-structures
            end
        elseif ischar(struc.(field)) || ((isnumeric(struc.(field)) || islogical(struc.(field))) && length(struc.(field)) == 1)
            data(di).(field) = struc.(field);
        end
    end
end