function [o suggested_filename] = import(varargin)
    o = varargin{1};
    suggested_filename = '';
    types = import_types(o);
    if nargin < 2 || ~ismember(varargin{2}, {types.preptype})
        error('Please specify valid datatype to load.')
    end

    opts = types(strcmp({types.preptype},varargin{2}));
    opts.timestamp = now;

    if isa(varargin{end}, 'function_handle')
        patchfcn = varargin{end};
    else
        patchfcn = [];
    end

    switch opts.source.type
        case 'da/det'
            if nargin > 2 && ischar(varargin{3})
                opts.source.da_dir = varargin{3};
            end
            if nargin > 3 && ischar(varargin{4})
                opts.source.det_dir = varargin{4};
            end
            [o, suggested_filename] = import_da_files(o,opts,patchfcn);
        case 'ext-file'
            if nargin > 2 && ischar(varargin{3})
                opts.source.file = varargin{3};
            end
            [o, suggested_filename] = import_ext_file(o,opts,patchfcn);
        case 'behavior-file'
            if nargin > 2 && ischar(varargin{3})
                opts.source.file = varargin{3};
            end
            [o, suggested_filename] = import_behavior_file(o,opts,patchfcn);
        case 'ofd-file'
            if nargin > 2 && ischar(varargin{3})
                opts.source.ofd_dir = varargin{3};
            end
            [o, suggested_filename] = import_ofd_files(o,opts,patchfcn);
    end
end