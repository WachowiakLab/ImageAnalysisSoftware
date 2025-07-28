function [o session_name] = import_da_files_from_idh(o,data,path,channels,bnc_boolean_thresh,use_preprocessed,resample_freq)

    data = data(~cellfun(@isempty,{data.detector_file})); %remove the files with no detector file defined
    
    session_name = '';

    [basedir, session_name] = fileparts(path);

    all_detfiles = setdiff(unique({data.detector_file}),{''});
    det_framesizes = repmat({[]},size(all_detfiles));
    if isempty(all_detfiles)
        msgbox('Please assign detector files to use.','Olfactometry','warn','modal')
        return
    end
    rois = o.rois;
    for j = 1:length(all_detfiles) %maybe give warning for empty detfiles/ empty dets?
        [dets comments] = read_det(all_detfiles{j});
        [pathstr, name, ext] = fileparts(all_detfiles{j});
        filename = [name ext];
        for k = 1:length(dets)
            if length(dets{k}) > 1
                rois(end+1).name = filename;
                rois(end).full_filename = all_detfiles{j};
                rois(end).index = k;
                rois(end).points = dets{k};
                rois(end).comment = comments{k}; %should use comment to define framesize!
            end
        end
    end
    
    channel_name_map = struct('elec_stim','Elect. Stim.','odor_onoff','Odor On/Off','lick','Lick','odor_valence','S+/S-','sniff_pressure','Sniff Pressure','sniff_thermo','Sniff Thermocouple','odor_coding','Odor coding');
    f = fieldnames(channel_name_map);
    for fi = 1:length(f)
        chan = find(strcmp(channel_name_map.(f{fi}), channels), 1);
        if ~isempty(chan)
            channels{chan} = f{fi};
        end
    end

    
    cancelled = false;
    wait_h = waitbar(0, 'Extracting traces...','CreateCancelBtn',@cancel,'Name','Olfactometry');


    for j = 1:length(data)
        waitbar(j/length(data),wait_h)
        if use_preprocessed && ~isempty(data(j).preprocessed_filename)
            filesource = fullfile(path,data(j).preprocessed_filename);
        else
            filesource = fullfile(path,data(j).name);
        end
        imp = import_da(filesource);
        if ~isempty(imp) && ~imp.corrupted
            det_index = find(strcmp(all_detfiles,data(j).detector_file),1);
            if isempty(det_framesizes{det_index})
                framesize = size(imp.data);
                det_framesizes{det_index} = [framesize(2) framesize(3)];
            end
            use_rois = find(strcmp({rois.full_filename},data(j).detector_file));
            o.trials(end+1) = assemble_trial_struct;
            clear imp
        end
        if cancelled
            o = olfact;
            session_name = '';
            return
        end
    end
    function cancel(varargin)
        delete(wait_h)
        cancelled = true;
    end
    if ~cancelled
        delete(wait_h)
    end
    for i = 1:length(rois) %need to do this at the end, since framesize is defined by trials
        det_index = find(strcmp(all_detfiles,rois(i).full_filename),1);
        [x y] = ind2sub(det_framesizes{det_index},rois(i).points);
        rois(i).position = [mean(x) mean(y)];
    end
    
    o.rois = rmfield(rois,{'full_filename','comment'});

    %% helper function
    function a = assemble_trial_struct

        a = struct;
        m = regexp(data(j).name,'^(.+)\.da$','tokens','once');
        a.name = m{1};
        a.timestamp = imp.timestamp;
        a.numtrialavg = imp.numtrialavg;
        a.trial_length = imp.acquisition_time / 1000;

        % extract data for the rois we want:
        points = {rois(use_rois).points};
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

        if ~isempty(resample_freq)
            for tr_i = 1:length(traces_cell)
                traces_cell{tr_i} = resample(traces_cell{tr_i}, resample_freq, imp.samplingrate);
            end
        end
        
        a.rois = struct('samplingrate',imp.samplingrate,...
            'datasize',size(imp.data),...
            'nums',use_rois(keep),...
            'traces',[traces_cell{:}]',...
            'RLIs',RLIs');

        a.other = struct('samplingrate',imp.samplingrate .* imp.BNCfactor);
        
        for bnc = 1:8
            if ~isempty(channels{bnc})
                a.other.(channels{bnc}) = double(imp.BNCs(bnc,:));
                if ~isempty(resample_freq)
                    a.other.(channels{bnc}) = resample(a.other.(channels{bnc}), resample_freq, a.other.samplingrate);
                end
            end
        end

        if ~isempty(resample_freq)
            a.rois.datasize(1) = ceil(a.rois.datasize(1) * resample_freq / a.rois.samplingrate);
            a.rois.samplingrate = resample_freq;
            a.other.samplingrate = resample_freq;
        end
        
        a.measurement = struct;
        a.measurement_param = struct;
        a.detail.comment = data(j).comment;
        a.detail.session = session_name;

        if isfield(a.other,'odor_onoff')
            a.measurement.odor_onoff.odor_onset = find(a.other.odor_onoff > bnc_boolean_thresh, 1) / a.other.samplingrate;
            a.measurement.odor_onoff.odor_offset = find(a.other.odor_onoff > bnc_boolean_thresh, 1, 'last') / a.other.samplingrate;
            a.measurement_param.odor_onoff = struct('thresh',bnc_boolean_thresh);
            if ~isempty(a.measurement.odor_onoff.odor_onset)
                a.detail.odorant_name = data(j).odorant_name;
                a.detail.odorant_concentration = data(j).odorant_concentration;
                a.detail.odorant_valence = data(j).odorant_valence;
            else
                a.detail.odorant_name = 'blank';
                a.detail.odorant_concentration = 0;
                a.detail.odorant_valence = '';
            end
        end
        if isfield(a.other,'lick')
            a.measurement.licktime = find(a.other.lick < bnc_boolean_thresh, 1) / a.other.samplingrate;
            if isempty(a.measurement.licktime)
                a.measurement.licktime = 0;
            end
            % define "licked" as licking between 3 and 8 seconds
            if a.measurement.licktime >= 3 && a.measurement.licktime <= 8
                a.measurement.licked = 'licked';
            else
                a.measurement.licked = '';
            end
            a.measurement_param.licked = struct('lick_min',3,'lick_max',8);
        end
        
        a.import = struct('preptype','IDH_configured','source',struct('file',filesource,'type','da/det','channels',{channels},'resample_freq',resample_freq));

    end
end

