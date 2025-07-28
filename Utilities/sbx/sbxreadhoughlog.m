function log = sbxreadhoughlog(fname)

fn = [fname '.log_54'];
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
    log{k+1} = table(e(:,1),e(:,2),e(:,3),...
    'VariableNames',{'frame' 'angle' 'dist'});
end

sbx = load(fname);

scanbox_frame = sbx.info.frame(sbx.info.event_id==1);
t = table(scanbox_frame,'VariableName',{'sbxframe'});
log{1} = [log{1} t];
    
