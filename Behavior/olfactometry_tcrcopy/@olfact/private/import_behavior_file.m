function [o behavior_filename] = import_behavior_file(o,opts,patchfcn)
if nargin < 3 || ~isa(patchfcn, 'function_handle')
    patchfcn = @(n) deal;
end

if isempty(opts.source.file)
    if ~ispref('Olfactometry','previous_behavior_filename')
        setpref('Olfactometry','previous_behavior_filename','')
    end
    [rdfile, pathname] = uigetfile({'*','Behavior Files'},'Choose behavior file',getpref('Olfactometry','previous_behavior_filename'));
    if isequal(rdfile,0)
        behavior_filename = '';
        return
    end
    opts.source.file = [pathname,rdfile];
end
setpref('Olfactometry','previous_behavior_filename',opts.source.file)
[basedir, behavior_filename, ext] = fileparts(opts.source.file);
behavior_filename = [behavior_filename ext];
session_name = behavior_filename;
try
    imp = import_behavior(opts.source.file);
catch
    error('Error loading behavior file. Is format correct?')
end

odor_present = imp.data(:,3) > opts.source.boolean_cutoff;
odorons = find(~odor_present(1:end-1) & odor_present(2:end)) + 1;

% select only certain trials by nearest time
use_times_string = inputdlg('Approximate trial start times (separate by spaces):',['Import ' behavior_filename]);
a = textscan(use_times_string{1},'%n');
use_times = a{1};
use_odorons = use_times;
odorons_times = odorons / imp.samprate;
for ti = 1:length(use_times)
    %find closest odoron time
    [m, loc] = min(abs(odorons_times - use_times(ti)));
    use_odorons(ti) = odorons(loc);
end
disp(use_odorons / imp.samprate)
odorons = use_odorons;
time_labels = use_times;

keep = false(size(odorons));

for t = 1:length(odorons)
    patchfcn(t/length(odorons))
    
    trial_start = odorons(t) - opts.source.pre_odor_time * imp.samprate;
    if trial_start < 1
        trial_start = 1;
    end
    odoroff = find(~odor_present(odorons(t):end),1) + odorons(t);
    if isempty(odoroff) || (odoroff - odorons(t)) < (0.1 * imp.samprate) %if odorant presentation is less than 100 ms, it's a glitch
        continue
    end
    trial_end = odoroff + opts.source.post_odor_time * imp.samprate;
    if trial_end > imp.datasize(1)
        trial_end = imp.datasize(1);
    end
    
    o.trials(t).name = [session_name '-' num2str(time_labels(t))];
    o.trials(t).timestamp = imp.timestamp + trial_start/imp.samprate/(24*60*60);
    o.trials(t).numtrialavg = 1;
    o.trials(t).trial_length = (trial_end-trial_start) / imp.samprate;

    o.trials(t).rois = struct('samplingrate',imp.samprate,... %Hz
                              'datasize',[0, 0, 0],...
                              'nums',[],...
                              'traces',[],...
                              'RLIs',[]);

    o.trials(t).other = struct('samplingrate',imp.samprate,...
                               'sniff_pressure',imp.data(trial_start:trial_end,1)',...
                               'licking',imp.data(trial_start:trial_end,2)',...
                               'odor_onoff',imp.data(trial_start:trial_end,3)');

    o.trials(t).measurement = struct;
    o.trials(t).measurement_param = struct;
    
	o.trials(t).measurement.odor_onoff.odor_onset = (odorons(t) - trial_start) / o.trials(t).other.samplingrate;
	o.trials(t).measurement.odor_onoff.odor_offset = (odoroff - trial_start) / o.trials(t).other.samplingrate;
    o.trials(t).measurement_param.odor_onoff = struct('thresh',opts.source.boolean_cutoff);

    o.trials(t).measurement.licktime = find(o.trials(t).other.licking < opts.source.boolean_cutoff,1) / o.trials(t).other.samplingrate;
    if isempty(o.trials(t).measurement.licktime)
        o.trials(t).measurement.licktime = 0;
    end
    % define "licked" as licking between odorant on and five seconds later seconds
    if o.trials(t).measurement.licktime >= o.trials(t).measurement.odor_onoff.odor_onset && o.trials(t).measurement.licktime <= o.trials(t).measurement.odor_onoff.odor_onset + 5
        o.trials(t).measurement.licked = 'licked';
    else
        o.trials(t).measurement.licked = '';
    end
    o.trials(t).measurement_param.licked = struct('thresh',opts.source.boolean_cutoff,'lick_min',o.trials(t).measurement.odor_onoff.odor_onset,'lick_max',o.trials(t).measurement.odor_onoff.odor_onset+5);
    
    o.trials(t).detail.comment = '';
	o.trials(t).detail.session = session_name;
    
    o.trials(t).import = opts;
    keep(t) = true;
end
o.trials = o.trials(keep);
o.rois = struct('name',{},'source',{},'index',{},'points',{},'position',{},'measurement',{},'measurement_param',{},'detail',{});

end