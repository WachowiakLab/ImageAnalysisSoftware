function varargout = update_recent_directories(newdirectory)
MAXDIRS = 5;

if ~ispref('Olfactometry','recent_directories')
    setpref('Olfactometry','recent_directories',struct('name',pwd,'last_access',now));
end
dirs = getpref('Olfactometry','recent_directories');

[tmp, ix] = sort([dirs.last_access],'descend');
dirs = dirs(ix);

if nargin
    if ismember(newdirectory,{dirs.name})
        dirs(ismember({dirs.name},newdirectory)).last_access = now;
    else
        dirs(end+1).name = newdirectory;
        dirs(end).last_access = now;
    end
    if length(dirs) > MAXDIRS
        [tmp, ix] = sort([dirs.last_access],'descend');
        dirs = dirs(ix);
        dirs = dirs(1:MAXDIRS);
    end
    setpref('Olfactometry','recent_directories',dirs);
end

if nargout
    varargout{1} = {dirs.name};
end
    