function r = sbxlocate_log_segmented(id)

% searches for logs with the given id and returns all of them that have
% been sorted and have eye movements 

d = sbxdatadirs;
r = {};

for i = 1:length(d)
    q = dir(d{i});       % for each entry in the directory
    for k =1:length(q)
        if q(k).name(1) ~= '.' && q(k).isdir
            root = [d{i} '\' q(k).name];
            m = dir([root '\*log_' num2str(id)]);
            for t = 1:length(m)
                fn = strtok(m(t).name,'.');
                if exist([m(t).folder '\' fn '_rigid.signals'],'file') && exist([m(t).folder '\' fn '_eye.mat'],'file') && exist([m(t).folder '\' fn '_quadrature.mat'],'file')
                    r{end+1} = {m(t).folder fn};
                end
            end
        end 
    end
end
