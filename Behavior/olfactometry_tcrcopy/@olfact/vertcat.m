function o = vertcat(varargin)
    o = varargin{1};
    for n = 2:nargin
        o = cat(o, varargin{n});
    end
end