
% Spatial calibration for galvo/galvo

global scanbox_h sbconfig calibration objective_h

h = guihandles(scanbox_h);

delta = [100 100 80 70 60 50 40 35 30 25 20 20 15]*16; % deltas for each mag in DAC units

% set some vars...

h.frames.String = '120'; h.frames.Callback(h.frames,[]);
h.animal.String = 'xx0'; h.animal.Callback(h.animal,[]);
h.unit.String = '000';   h.unit.Callback(h.unit,[]);
h.expt.String = '000';   h.expt.Callback(h.unit,[]);

orgwd = pwd;
cd([h.dirname.String '\' h.animal.String]);

[~,~] = system('del xx0*');                                 % removes xx0 files

h.tfilter.Value = 3; h.tfilter.Callback(h.tfilter,[]);      % selects average

% Get the button
g = findobj(scanbox_h,'tag','grabb');

sb_galvoactive(1);


for mag = 1:13

    m = findobj(scanbox_h,'tag','magnification');
    h.magnification.Value = mag; h.magnification.Callback(h.magnification,[]);
    h.frames.String = '120'; h.frames.Callback(h.frames,[]); % enforce 120 frames!

    dxy = [zeros(1,60) repmat(delta(mag),1,60)];
    etl_seq = h.optoslider.Value*ones(1,length(dxy));
    pock_seq = h.pockval.Value*ones(1,length(dxy));
    sb_galvocontrol(-dxy,dxy,etl_seq,pock_seq);
    
    h.grabb.Callback(h.grabb,[]);
    pause(2);
end

sb_galvoactive(0);

% process

clear cal;
for mag = 1:13
    fn = sprintf('xx0_000_%03d',mag-1);
    z0 = sbxread(fn,30,30);      % to allow mirror warmup
    z1 = sbxread(fn,80,30);
    z0 = squeeze(mean(z0(1,:,:,:),4));
    z1 = squeeze(mean(z1(1,:,:,:),4));
    [u,v] = fftalign(z0,z1); 
    cal(mag).uv = [u v];
    cal(mag).delta = delta(mag);
    cal(mag).x = delta(mag)/v;       % DAC/pix
    cal(mag).y = delta(mag)/u;
end

fclose('all');
global info
info = [];

x = [cal.x]';
y = [cal.y]';
mag = str2num(h.magnification.String);

fxg = fit(mag,x,'exp2');
fig = figure('MenuBar','None','NumberTitle','off','Name','Galvo Spatial Calibration');
fig.Position = [693   494   884   350];
subplot(1,2,1);
plot(fxg,mag,x','o')
xlabel('Magnification');
ylabel('Pixel width [DAC]');
legend off 
box off;

subplot(1,2,2);
fyg = fit(mag,y,'exp2');
plot(fyg,mag,y,'o')
xlabel('Magnification');
ylabel('Pixel height [DAC]');
legend off 
box off;

calibration.fxg = fxg;
calibration.fyg = fyg;

fn = [objective_h.String{objective_h.Value} '.mat'];

sbxroot = fileparts(which('scanbox'));
save([sbxroot '\..\calibration\' fn],'calibration'); % save the calibration 
warndlg({sprintf('Galvo calibration for %s complete and saved!',objective_h.String{objective_h.Value})});;

