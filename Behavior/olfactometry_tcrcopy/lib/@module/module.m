function m = module(varargin)
    %{
% A module can be used to access functions in a namespaced manner
%
% This is an example module file (named 'Example.m'):
function m = Example
    m = module(@one,@two);
function r = oneplus(a)
        r = 1 + a;
    end

function r = two
        r = 2;
    end
end

% To use a function, call:
>> require Example
>> Example.one(3) => 4

% Alternatively, call:
>> Example:@two => 2
% (this only works if the function doesn't take any arguments)


% To add the functions 'one' and 'two' to the current namespace, call:
>> include(Example)
>> two() => 2

    %}

    if nargin == 1 && isa(varargin{1},'module')
        m = varargin{1};
    else
        st = dbstack(1);
        m = struct('name',st(1).name,'public',struct);
        for n = 1:nargin
            if isa(varargin{n},'module')
                fs = fieldnames(varargin{n}.public);
                for fi = 1:length(fs)
                    m.public.(fs{fi}) = varargin{n}.public.(fs{fi});
                end
            elseif isa(varargin{n},'function_handle')
                m.public.(regexprep(func2str(varargin{n}), '(\w+)\/','')) = varargin{n};
            elseif ~strcmp(inputname(n),'')
                m.public.(inputname(n)) = varargin{n};
            end
        end
        m = class(m,'module');
    end
end
