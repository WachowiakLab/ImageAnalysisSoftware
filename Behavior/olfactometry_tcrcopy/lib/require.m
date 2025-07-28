function varargout = require(str)
%REQUIRE  Loads a module into the current namespace
% Usage:
%    require ModuleName
%    require 'ModuleName'

    if nargout == 0
        assignin('caller',str,eval(str))
    else
        varargout = {eval(str)};
    end
end