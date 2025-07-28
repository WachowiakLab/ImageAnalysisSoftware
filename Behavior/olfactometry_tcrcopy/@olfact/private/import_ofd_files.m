function [o sessionname] = import_ofd_files(o,opts,patchfcn)
if nargin < 3 || ~isa(patchfcn, 'function_handle')
    patchfcn = @(n) deal;
end
sessionname = '';

if isempty(opts.source.ofd_dir)
    if ~ispref('Olfactometry','previous_ofd_dirname')
        setpref('Olfactometry','previous_ofd_dirname','')
    end
    opts.source.ofd_dir = uigetdir(getpref('Olfactometry','previous_ofd_dirname'),'Choose directory containing *.ofd files');
    if isequal(opts.source.ofd_dir,0)
        o = olfact;
        return
    end
end
setpref('Olfactometry','previous_ofd_dirname',opts.source.ofd_dir)

[basedir, sessionname] = fileparts(opts.source.ofd_dir);

files = dir(fullfile(opts.source.ofd_dir,'*.ofd'));

%uncomment expressions in line 24, 26, and 30. Ryan commented these out to
%let me import .ofd files that I named in a slightly different way... i.e.
%in blocks such as art014A001.ofd, art014B001.ofd... If these lines are
%uncommented, then olfactometry can't import files with the A001.ofd name
%s = regexp({files.name},[sessionname repmat('\d',1,opts.source.digits_in_trial_number) '\.ofd']); %reg exp = dirname + any N digits + '.ofd'

if length(files) < 1 %|| isempty([s{:}])
    return
end

realfiles = files; %(~cellfun('isempty',s));

[c,ix] = sort([realfiles.datenum]);
date_sorted_files = realfiles(ix);

%rois aren't used

for j = 1:length(date_sorted_files)
    patchfcn(j/length(date_sorted_files))

    imp = read_ofd(fullfile(opts.source.ofd_dir,date_sorted_files(j).name));
    if ~isempty(imp)
        o.trials(end+1) = assemble_trial_struct(date_sorted_files(j).datenum);
    end

end


%% helper function
    function a = assemble_trial_struct(timestamp)

        a = struct;
        a.name = imp.filename;
        a.timestamp = timestamp;
        a.numtrialavg = 1;
        a.trial_length = opts.source.trial_length_fcn(imp);

        if isfield(imp,'samplingrate')
            samplingrate = imp.samplingrate;
        else
            samplingrate = 1;
        end
        
        a.rois = struct('samplingrate',samplingrate,...
                        'datasize',[0 0 0],...
                        'nums',[],...
                        'traces',[],...
                        'RLIs',[]);

        a.other = struct('samplingrate',samplingrate);
        
        original_names = fieldnames(opts.source.mapping);
        for f = 1:length(original_names)
            if isfield(imp,original_names{f})
                a.other.(opts.source.mapping.(original_names{f})) = imp.(original_names{f});
            end
        end
        
        a.measurement = struct;
        a.measurement_param = struct;
       
        if isfield(a.other,'odor_onoff')
            a.measurement.odor_onoff.odor_onset = find(a.other.odor_onoff > 1000, 1) / a.other.samplingrate;
            a.measurement.odor_onoff.odor_offset = find(a.other.odor_onoff > 1000, 1, 'last') / a.other.samplingrate;
            a.measurement_param.odor_onoff = struct('thresh',1000);
        end

        if isfield(imp,'comment')
            a.detail = struct('comment',imp.comment);
        end
        
        a.detail.session = sessionname;
        a.import = opts;
        
    end
end