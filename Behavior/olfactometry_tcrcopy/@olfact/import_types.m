function types = import_types(o)

types = struct('preptype',{},'source',{});

i = 1;
types(i).preptype = 'Artificial sniff';
types(i).source.type = 'da/det';
types(i).source.BNCs = {'odor_onoff', '', '', 'sniff_pressure', '', '', '', ''};
types(i).source.digits_in_trial_number = 2; % for regular expression identifying files
types(i).source.da_dir = '';
types(i).source.det_dir = '';

i = 2;
types(i).preptype = 'Freely breathing';
types(i).source.type = 'da/det';
types(i).source.BNCs = {'odor_onoff', '', '', '', '', '', '', ''};
types(i).source.digits_in_trial_number = 2;
types(i).source.da_dir = '';
types(i).source.det_dir = '';

i = 3;
types(i).preptype = 'Stimulated in vivo';
types(i).source.type = 'da/det';
types(i).source.BNCs = {'', '', 'elec_stim', '', '', '', '', ''};
types(i).source.digits_in_trial_number = 2;
types(i).source.da_dir = '';
types(i).source.det_dir = '';

i = 4;
types(i).preptype = 'Stimulated in vitro';
types(i).source.type = 'da/det';
types(i).source.BNCs = {'elec_stim', '', '', '', '', '', '', ''};
types(i).source.digits_in_trial_number = 2;
types(i).source.da_dir = '';
types(i).source.det_dir = '';

i = 5;
types(i).preptype = 'Awake behaving rat (EXT-file)';
types(i).source.type = 'ext-file';
types(i).source.file = '';

i = 6;
types(i).preptype = 'Awake behaving rat (behavior file)';
types(i).source.type = 'behavior-file';
types(i).source.file = '';
types(i).source.boolean_cutoff = 2.5;
types(i).source.pre_odor_time = 10; %sec
types(i).source.post_odor_time = 4; %sec

i = 7;
types(i).preptype = 'Artificial sniff (ofd file)';
types(i).source.type = 'ofd-file';
types(i).source.mapping = struct('command','sniff_control',...
                                 'pressure','sniff_pressure',...
                                 'thermocouple','sniff_thermocouple',...
                                 'syringe_pressure','sniff_syringe_pressure');
types(i).source.trial_length_fcn = @(imp) length(imp.command) ./ imp.samplingrate;
types(i).source.digits_in_trial_number = 3;
types(i).source.ofd_dir = '';
