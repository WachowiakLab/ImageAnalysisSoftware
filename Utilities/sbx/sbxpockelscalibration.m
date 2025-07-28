
% Pockels calibration

global scanbox_h sbconfig

pockels_val = round(linspace(0,255,32));
pockels_cal = zeros(size(pockels_val));

sb_pockels_lut_identity;    % load identity
sb_setparam(512,0,4);
sb_scan;

fig = figure('MenuBar','None','NumberTitle','off','Name','Pockels Calibration');
xlabel('DAC Value');
ylabel('Power (W)');
xlim([0 256]);
hold on;
for i = 1:length(pockels_val)
    sb_pockels(0,pockels_val(i));
    pause(5);
    pockels_cal(i) = powermeter_read;
    plot(pockels_val(i),pockels_cal(i),'b.','markersize',20);
end

sb_abort

% find max and fit curve

[~,idx] = max(pockels_cal);

xdata = pockels_val(1:idx);
ydata = pockels_cal(1:idx);
p = lsqcurvefit(@(x,xdata) x(1) - x(2) * cos(xdata/x(3)*2*pi),[mean(pockels_cal) mean(pockels_cal)*0.5 8*idx],xdata,ydata);
plot(xdata,p(1)-p(2) * cos(xdata*2*pi/p(3)),'r-')

yy = linspace(p(1)-p(2),p(1)-p(2)*cos(xdata(idx)*2*pi/p(3)),256);
pockels_lut = uint8(round(acos(-(yy-p(1))/p(2))*p(3)/pi/2));

% save 

sbxroot = fileparts(which('scanbox'));
save([sbxroot '\..\calibration\pockelscal.mat'],'pockels_lut'); % save otcal in the core directory (otcalibration is too big!)

% validation
sbconfig.pockels_lut = pockels_lut;
for(i=1:256)
    sb_pockels_lut(i,sbconfig.pockels_lut(i));
end

sb_setparam(512,0,4);
sb_scan;

fig = figure('MenuBar','None','NumberTitle','off','Name','Pockels Calibration Validation');
xlabel('DAC Value');
ylabel('Power (W)');
xlim([0 256]);
hold on;
for i = 1:length(pockels_val)
    sb_pockels(0,pockels_val(i));
    pause(5);
    pockels_cal(i) = powermeter_read;
    plot(pockels_val(i),pockels_cal(i),'b.','markersize',20);
end

sb_abort


