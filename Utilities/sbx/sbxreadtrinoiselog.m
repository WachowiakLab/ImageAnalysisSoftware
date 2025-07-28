function log = sbxreadtrinoiselog(fname,mform)

fn = [fname '.log_59'];
fid = fopen(fn,'r');
l = fgetl(fid); 
log = {};

load(fname); % info

scanbox_frame = info.frame(info.event_id==1);

% detect missing TTLs and fill in...

d = diff(scanbox_frame);
du = unique(d);

while ~all(du<7)
    idx = find(d>=7);
    idx = idx(1);
    scanbox_frame = [scanbox_frame(1:idx) ; round((scanbox_frame(idx)+scanbox_frame(idx+1))/2) ; scanbox_frame(idx+1:end)];
    d = diff(scanbox_frame);
    du = unique(d);
end

f = scanbox_frame;

m = 1;

while(l~=-1)
    
    % fix bug in log file
%     idx = find(l==' ');
%     t = l(1:idx(1));
%     l = l(idx(1)+1:end);
%     idx = find(l==' ');
%     idx = idx(2:2:end)+1;
%     while(~isempty(idx))
%         l = insertAfter(l,idx(1),' ');
%         idx = idx(2:end)+1;
%     end
%     l = [t l];

    % normal processing
    k = str2num(l);
    t = k(1);
    k = reshape(k(2:end),3,[])';
    stim = full(sparse(k(:,1)+1,k(:,2)+1,k(:,3)));
    log{end+1} = {t stim f(m)};
    l = fgetl(fid);
    m = m+1;
end




