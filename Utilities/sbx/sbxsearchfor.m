function r = sbxsearchfor(fn)

% searches for an experiment in the various data dirs

d = sbxdatadirs;

r = [];

for i = 1:length(d)
    dn = [d{i} '\' strtok(fn,'_')]; 
    if exist([dn '\' fn '.mat'],'file')
        r = dn;
        break;
    end
end


