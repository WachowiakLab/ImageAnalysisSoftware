function [o ext_filename] = import_ext_file(o,opts,patchfcn)
if nargin < 3 || ~isa(patchfcn, 'function_handle')
    patchfcn = @(n) deal;
end

if isempty(opts.source.file)
    if ~ispref('Olfactometry','previous_ext_filename')
        setpref('Olfactometry','previous_ext_filename','')
    end
    [rdfile, pathname] = uigetfile(['',{'*.ext','EXTracted data file (*.ext)'}],'Choose EXT file',getpref('Olfactometry','previous_ext_filename'));
    if isequal(rdfile,0)
        ext_filename = '';
        return
    end
    opts.source.file = [pathname,rdfile];
end
setpref('Olfactometry','previous_ext_filename',opts.source.file)
[basedir, ext_filename] = fileparts(opts.source.file);
session_name = regexprep(ext_filename,'(rcr)(0)?([^_]+)(.*)','$1$3');
try
    imp = import_ext(opts.source.file);
catch
    error('Error loading ext file. Is format correct?')
end

use_rois = listdlg('PromptString','Select rois to use:','ListString',cellfun(@num2str,num2cell(1:imp.numrois),'UniformOutput',false),'InitialValue',[],'OKString','Select');

for t = 1:imp.numfiles
    patchfcn(t/imp.numfiles)

    m = regexp(imp.filelist{t},'^(?:PRO|Pro2|Pro3_[^_]+)_(.+)','tokens','once');
    if isempty(m)
        o.trials(t).name = imp.filelist{t};
    else
        o.trials(t).name = m{1};
    end
    
    o.trials(t).timestamp = imp.acqtimes(t) / (24*60*60); %convert to matlab format (fraction of day)
    o.trials(t).numtrialavg = 1;
    o.trials(t).trial_length = imp.numpoints / imp.samprate;

    o.trials(t).rois = struct('samplingrate',imp.samprate,... %Hz
                              'datasize',[imp.numpoints, 256, 256],...
                              'nums',use_rois,...
                              'traces',imp.allsignal(2:end,use_rois,t)',...
                              'RLIs',imp.rlis(1,use_rois,t)');

    o.trials(t).other = struct('samplingrate',imp.samprate,...
                               'sniff_pressure',imp.snifftraces(:,t)',...
                               'odor_onoff',imp.odortraces(:,t));

    o.trials(t).measurement = struct;
    o.trials(t).measurement_param = struct;
    
	o.trials(t).measurement.odor_onoff.odor_onset = find(o.trials(t).other.odor_onoff > 1000, 1) / o.trials(t).other.samplingrate;
	o.trials(t).measurement.odor_onoff.odor_offset = find(o.trials(t).other.odor_onoff > 1000, 1, 'last') / o.trials(t).other.samplingrate;
    o.trials(t).measurement_param.odor_onoff = struct('thresh',1000);

    o.trials(t).measurement.licktime = imp.licktimes(t) / o.trials(t).other.samplingrate;
    % define "licked" as licking between 3 and 8 seconds
    if o.trials(t).measurement.licktime >= 3 && o.trials(t).measurement.licktime <= 8
        o.trials(t).measurement.licked = 'licked';
    else
        o.trials(t).measurement.licked = '';
    end
    o.trials(t).measurement_param.licked = struct('lick_min',3,'lick_max',8);
    
    o.trials(t).detail.comment = imp.comments{t};
	o.trials(t).detail.session = session_name;
    
    if isfield(o.trials(t).measurement, 'odor_onoff')
        o.trials(t).detail.odorant_name = imp.odorlist{t};
        o.trials(t).detail.odorant_concentration = imp.concs(t);
        if imp.valence(t) > 0
            o.trials(t).detail.odorant_valence = '+';
        else
            o.trials(t).detail.odorant_valence = '-';
        end
    else
        o.trials(t).detail.odorant_name = 'blank';
        o.trials(t).detail.odorant_concentration = 0;
        o.trials(t).detail.odorant_valence = '';
    end
    o.trials(t).import = opts;
end

o.rois = struct('name',[ext_filename '.ext'],'source',opts.source.file,'index',num2cell(1:length(imp.Xposits)),'points',[],'position',num2cell([imp.Xposits imp.Yposits],2)','measurement',[],'measurement_param',[],'detail',[]);

end