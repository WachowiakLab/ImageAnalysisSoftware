function log = sbxreadrandoribase(fname)

fn = [fname '.log_34'];
fid = fopen(fn,'r');
l = fgetl(fid);
k=0;

log = {};
while(l~=-1)
    k = str2num(l(2:end));
    log{k+1} = [];
    e = [];
    l = fgetl(fid);
    while(l~=-1 & l(1)~='T')
        e = [e ; str2num(l)];
        l = fgetl(fid);
    end
    log{k+1} = table(e(:,1),e(:,2),e(:,3),e(:,4),e(:,5),e(:,6),e(:,7),e(:,8),...
    'VariableNames',{'frame' 'ori' 'sphase' 'sper' 'orib' 'sphaseb' 'contrast' 'contrastb'});
end

sbx = load(fname);

% just in case TTL1 is not connected
% scanbox_frame = sbx.info.frame(2:end-1);

scanbox_frame = sbx.info.frame(sbx.info.event_id==1);

% detect missing TTLs and fill in...

% d = diff(scanbox_frame);
% du = unique(d);

% while ~all(du<7)
%     idx = find(d>=7);
%     idx = idx(1);
%     scanbox_frame = [scanbox_frame(1:idx) ; round((scanbox_frame(idx)+scanbox_frame(idx+1))/2) ; scanbox_frame(idx+1:end)];
%     d = diff(scanbox_frame);
%     du = unique(d);
% end

% add sbxframe to all logs...

k = 1;
for j = 1: length(log)
    ov_frame = log{j}.frame;
    fit = polyfit(ov_frame,scanbox_frame(k:k+length(ov_frame)-1),1);           % from ov to sbx
    t = table(floor(polyval(fit,ov_frame)),'VariableName',{'sbxframe'});
    log{j} = [log{j} t];
end

