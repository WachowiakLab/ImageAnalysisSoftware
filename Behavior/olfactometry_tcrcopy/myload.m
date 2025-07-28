function o = myload

[filename filepath] = uigetfile('*.txt','Choose file to load');
fullfilename=fullfile(filepath,filename);
o = load(fullfilename,'-mat');

% flowrate = o.trial.measurement.flowrate;
% fits = o.trial.measurement.response_fits;
% 
% cycles = zeros(length(fits),1);
% amplitudes = cycles;
% for i = 1:length(fits)
%     cycles(i) = fits(i).stimtime;
%     %amplitudes(i) = fits(i).rise_amplitude ;%+ fits(i).y_offset;
% end

%cyclesredux = cycles(cycles >= flowrate(1,1) & cycles <= flowrate(end,2));

%sig_amplitudes=amplitudes(ismember(cycles,cyclesredux));

%flowrate = [ flowrate sig_amplitudes];

    

end
