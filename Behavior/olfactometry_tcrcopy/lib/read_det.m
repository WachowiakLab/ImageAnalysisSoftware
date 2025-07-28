function [o, comments] = read_det(filepath)
    % reads a neuroplex detector file, returns each of the ROIs in a cell array
    % where each cell contains an array with a ROI's pixel numbers
    o = {};
    comments = {};
    if nargin == 0
        [filename, pathstr] = uigetfile(['',{'*.det','Neuroplex detector files (*.det)'}],'Choose *.det file');
        if isequal(filename,0)
            return
        end
    else
        [pathstr, name, ext] = fileparts(filepath);
        filename = [name,ext];
    end
    try
        fid = fopen(fullfile(pathstr, filename));
        fseek(fid,0,'bof'); %seek the begining of file
        n = 1;
        while ~feof(fid)
            tline = fgetl(fid);
            if isequal(tline,',')
                n = n + 1;
            else
                if n > length(o)
                    o{n} = [];
                    comments{n} = '';
                end
                a = regexp(tline,'(\d+)(?:\ )?(.*)?','tokens','once');
                val = str2double(a{1});
                if ~isnan(val)
                    o{n} = [o{n} val];
                end
                if ~isempty(a{2})
                    comments{n} = a{2};
                end
            end
        end
        fclose(fid);
    catch
        error(['The selected file was not found: ' fullfile(pathstr, filename)])
    end
end