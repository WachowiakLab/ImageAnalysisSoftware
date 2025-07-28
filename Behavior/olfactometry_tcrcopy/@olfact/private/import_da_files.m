function [o session_name] = import_da_files(o,opts,patchfcn)
if nargin < 3 || ~isa(patchfcn, 'function_handle')
    patchfcn = @(n) deal;
end
session_name = '';

if isempty(opts.source.da_dir)
    if ~ispref('Olfactometry','previous_src_dirname')
        setpref('Olfactometry','previous_src_dirname','')
    end
    opts.source.da_dir = uigetdir(getpref('Olfactometry','previous_src_dirname'),'Choose directory containing *.da files');
    if isequal(opts.source.da_dir,0)
        o = olfact;
        return
    end
end
setpref('Olfactometry','previous_src_dirname',opts.source.da_dir)

if isempty(opts.source.det_dir)
    if ~ispref('Olfactometry','previous_det_dirname')
        setpref('Olfactometry','previous_det_dirname','')
    end
    opts.source.det_dir = uigetdir(getpref('Olfactometry','previous_det_dirname'),'Choose directory containing *.det files');
    if isequal(opts.source.det_dir,0)
        o = olfact;
        return
    end
end
setpref('Olfactometry','previous_det_dirname',opts.source.det_dir)

[basedir, session_name] = fileparts(opts.source.da_dir);

files = dir(fullfile(opts.source.det_dir,'*.det'));
if length(files) < 1
    return
end

for j = 1:length(files)
    dets = read_det(fullfile(opts.source.det_dir,files(j).name));
    for k = 1:length(dets)
        if length(dets{k}) > 1
            o.rois(end+1).name = files(j).name;
            o.rois(end).index = k;
            o.rois(end).points = dets{k};
        end
    end
end

files = dir(fullfile(opts.source.da_dir,'*.da'));
%s = regexp({files.name},[session_name repmat('\d',1,opts.source.digits_in_trial_number) '\.da']); %reg exp = dirname + any N digits + '.da'

if length(files) < 1% || isempty([s{:}])
    return
end

%realfiles = files(~cellfun('isempty',s));
realfiles = files;

[c,ix] = sort({realfiles.date});
date_sorted_files = realfiles(ix);
all_dets = unique({o.rois.name});

dets_selection = choose_detector({date_sorted_files.name},all_dets); %show choose_detector GUI

date_sorted_files = date_sorted_files(sum(dets_selection,2) > 0);
dets_selection = dets_selection(sum(dets_selection,2) > 0, :);

%remove dets/rois that aren't being used
o.rois = o.rois(ismember({o.rois.name},all_dets(sum(dets_selection,1) > 0)));

framesize = [];

for j = 1:length(date_sorted_files)
    patchfcn(j/length(date_sorted_files))

    use_rois = [];
    for i = find(dets_selection(j,:))
        use_rois = [use_rois find(strcmp({o.rois.name},all_dets(i)))];
    end
    if ~isempty(use_rois) %don't import files without any dets/rois
        imp = import_da(fullfile(opts.source.da_dir,date_sorted_files(j).name));
        if ~isempty(imp) && ~imp.corrupted
            if isempty(framesize)
                framesize = size(imp.data);
                framesize = [framesize(2) framesize(3)];
            end
            if imp.numtrialavg > 1 && false
                numtrialavg = imp.numtrialavg;
                comment = imp.comment;
                clear imp
                [a,b,c] = fileparts(date_sorted_files(j).name);
                for k = 1:numtrialavg
                    imp = import_da(fullfile(opts.source.da_dir,[b num2str(k,'%02d') c]));
                    imp.comment = comment;
                    if ~isempty(imp) && ~imp.corrupted %should probably deal with missing files (above)
                        o.trials(end+1) = assemble_trial_struct;
                    end
                    clear imp
                end
            else
                o.trials(end+1) = assemble_trial_struct;
                clear imp
            end
        end
    end

end

for i = 1:length(o.rois) %need to do this at the end, since framesize is defined by trials
    [x y] = ind2sub(framesize,o.rois(i).points);
    o.rois(i).position = [mean(x) mean(y)];
end


%% helper function
    function a = assemble_trial_struct

        a = struct;
        a.name = imp.filename;
        a.timestamp = imp.timestamp;
        a.numtrialavg = imp.numtrialavg;
        a.trial_length = imp.acquisition_time / 1000;

        % extract data for the rois we want:
        points = {o.rois(use_rois).points};
        keep = cellfun(@(pts) all(pts <= length(imp.data(1,:))), points);
        if any(~keep)
            warning('ImportDaFiles:detfileMismatch',['possible detector size mis-match for file ' imp.filename]);
        end
        points = points(keep);

        [traces_cell RLIs] = cellfun(@calc_trace_and_rli, points);
        function [tr, rli] = calc_trace_and_rli(pts)
            rli = mean(mean(double(imp.data(5:10,pts)),2));
            tr = {mean(double(imp.data(:,pts)),2) - rli};
        end

        a.rois = struct('samplingrate',imp.samplingrate,...
                        'datasize',size(imp.data),...
                        'nums',use_rois(keep),...
                        'traces',[traces_cell{:}]',...
                        'RLIs',RLIs');

        a.other = struct('samplingrate',imp.samplingrate .* imp.BNCfactor);

        for bnc = 1:8
            if ~isempty(opts.source.BNCs{bnc})
                a.other.(opts.source.BNCs{bnc}) = double(imp.BNCs(bnc,:));
            end
        end
        
        a.measurement = struct;
        a.measurement_param = struct;
       
        if isfield(a.other,'odor_onoff')
            a.measurement.odor_onoff.odor_onset = find(a.other.odor_onoff > 1000, 1) / a.other.samplingrate;
            a.measurement.odor_onoff.odor_offset = find(a.other.odor_onoff > 1000, 1, 'last') / a.other.samplingrate;
            a.measurement_param.odor_onoff = struct('thresh',1000);
        end

        a.detail = struct('comment',imp.comment,'session',session_name);
        a.import = opts;
        
    end
end

%% choose_detector GUI
function selection = choose_detector(trials, dets)

handles = make_figure;
selection = zeros(length(trials),length(dets));

update_trial_list
set(handles.det_list,'String',dets);

uiwait(handles.fig)
delete(handles.fig)
drawnow

    function set_dets_Callback(varargin)
        d = get(handles.det_list,'Value');
        t = get(handles.trial_list,'Value');
        selection(t,:) = 0;
        selection(t,d) = 1;
        update_trial_list
    end

    function done_Callback(varargin)
        uiresume(handles.fig)
    end

    function trial_list_Callback(varargin)
        t = get(handles.trial_list,'Value');
        if length(t) == 1
            set(handles.det_list,'Value',find(selection(t,:)))
        end
    end

    function update_trial_list
        newlist = {};
        for i = 1:length(trials)
            newlist{i} = [trials{i} '   '];
            for j = find(selection(i,:))
                newlist{i} = [newlist{i} dets{j} '  '];
            end
        end
        set(handles.trial_list,'String',newlist);
    end

%-------------------------------------------------------------------------------
    function handles = make_figure
        % --- FIGURE -------------------------------------
        handles.fig = figure(	'Name', 'Detector Files', ...
            'Units', 'pixels', ...
            'Position', [500 500 550 420], ...
            'MenuBar', 'none', ...
            'Resize', 'off', ...
            'CloseReq', @done_Callback, ...
            'NumberTitle', 'off', ...
            'Color', get(0,'DefaultUicontrolBackgroundColor'));

        % --- PUSHBUTTONS -------------------------------------
        handles.set_dets = uicontrol(	'Parent', handles.fig, ...
            'Style', 'pushbutton', ...
            'Units', 'pixels', ...
            'Position', [315 350 70 24], ...
            'String', '<< Set', ...
            'Callback', @set_dets_Callback);

        handles.done = uicontrol(	'Parent', handles.fig, ...
            'Style', 'pushbutton', ...
            'Units', 'pixels', ...
            'Position', [315 70 70 24], ...
            'String', 'Done', ...
            'Callback', @done_Callback);

        % --- LISTBOXES -------------------------------------
        handles.det_list = uicontrol(	'Parent', handles.fig, ...
            'Style', 'listbox', ...
            'Units', 'pixels', ...
            'Position', [400 20 130 380], ...
            'BackgroundColor', [1 1 1], ...
            'String', '', ...
            'Max', 1000);

        handles.trial_list = uicontrol(	'Parent', handles.fig, ...
            'Style', 'listbox', ...
            'Units', 'pixels', ...
            'Position', [20 20 280 380], ...
            'BackgroundColor', [1 1 1], ...
            'String', '', ...
            'Max', 1000, ...
            'Callback', @trial_list_Callback);
    end
end