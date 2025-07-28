
% Optotune calibration

global scanbox_h sbconfig

sbconfig.optocal = [];          % make it empty

h = guihandles(scanbox_h);

oval = sbconfig.optoval;        % sequence of current values

% set animal and unit numbers

h.animal.String = 'xx0'; h.animal.Callback(h.animal,[]);
h.unit.String = '000';   h.unit.Callback(h.unit,[]);
h.expt.String = '000';   h.expt.Callback(h.unit,[]);

cd([h.dirname.String '\' h.animal.String]);

system('del xx0*');                                 % removes xx0 files

tri_send('KBY',0,12,0); % set knobby to super fine

h.tfilter.Value = 3; h.tfilter.Callback(h.tfilter,[]);  % accumulate

% set knobby params + table

h.zrange.String = num2str(sbconfig.optorange);  
h.zstep.String = num2str(sbconfig.optostep);
h.framesperstep.String = num2str(sbconfig.optoframes);
h.zrange.Callback(h.zrange,h);   % update fields and table

% set number of frames to collect

h.frames.String = num2str(h.knobby_table.Data(end,end) + str2double(h.framesperstep.String));
h.frames.Callback(h.frames,[]);  % total number of frames to collect

% Get the button
g = findobj(scanbox_h,'tag','grabb');

% assumes pollen grains in focus

tri_send('KBY',0,0,40); % move up by 35um
pause(0.2);
tri_send('KBY',0,30,0); % zero knobby
pause(0.2);

% make sure it returns to first location

h.returnbox.Value=1; h.returnbox.Callback(h.returnbox,[]);

% collect the data
for i = 1:length(oval)
    h.knobby_enable.Value = 1; h.knobby_enable.Callback(h.knobby_enable,[]);
    % set the optoslider
    h.optoslider.Value = oval(i);
    h.optoslider.Callback(h.optoslider,h);
    h.grabb.Callback(h.grabb,[]);
    pause(2);
end

h.returnbox.Value=0; h.returnbox.Callback(h.returnbox,[]); % disable return


% process

clear otcalibration;

wb = waitbar(0,'Processing...  Please wait.');
for i = 1:length(oval)
    fn = sprintf('xx0_000_%03d',i-1);
    z = sbxreadzstack(fn);    
    z = z(128:384,199:597,:);   % take central 1/4 of the image
    z = reshape(z,[],size(z,3));
    %z = median(z,1);
    z = std(z,[],1)./mean(z,1);
    otcalibration(i).m = z;
    [~,lmidx] = max(z);
    otcalibration(i).idx = lmidx;
    waitbar(i/length(oval),wb);
end
delete(wb);


global info
fclose(info.fid);
info = [];

% compute calibration curve
z = 0:sbconfig.optostep:sbconfig.optorange;
depth = -z([otcalibration(:).idx]);

f = figure;
plot(oval,depth,'-o');
otcoeff = polyfit(oval,depth,2);
hold on
plot(min(oval):max(oval),polyval(otcoeff,min(oval):max(oval)),'r-');
xlabel('DAC ETL Value');
ylabel('Depth (um)');
title('Optotune Calibration');
f.NumberTitle = 'off';
f.MenuBar = 'none';

fn = [handles.objective.String{handles.objective.Value} '.mat'];

sbxroot = fileparts(which('scanbox'));

try
    save([sbxroot '\..\calibration\' fn],'otcoeff','otcalibration','-append'); % append etl to spatial calibration 
catch
    warndlg(sprintf('Warning: ETL calibration not saved. Check spatial calibration for this objective is present?'\n', errorToText(retCode)),'scanbox');
end

% sbxroot = fileparts(which('scanbox'));
% save([sbxroot '\otcal.mat'],'otcoeff','otcalibration'); % save otcal in the core directory (otcalibration is too big!)

clear otcalibration                     % delete huge variable


