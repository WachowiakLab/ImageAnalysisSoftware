function o = update(o, varargin)
    if mod(nargin,2) ~= 1
        error('arguments must be in pairs')
    end
    for n = 2:2:nargin
        eval(['o.' varargin{n-1} ' = varargin{n};'])
    end
end