function o = subsref(o,index)
%SUBSREF Olfactometry class
%o = subsref(struct(o),index);

for n = 1:length(index)
    switch index(n).type
    case '()'
%        if isa(index(n).subs{:},'char') && isstruct(o) && isfield(o,'filename')
%            index(n).subs = {ismember(index(n).subs{:},{o.filename})};
%        end
        o = o(index(n).subs{:});
    case '{}'
        o = o{index(n).subs{:}};
    case '.'
%        if isfield(struct(o),index(n).subs)
%            switch length(o)
%                case 0
%                    o = [];
%                case 1
%                    o = o.(index(n).subs);
%                otherwise
%                    switch class([o.(index(n).subs)])
%                        case 'char' % errors with this if there's only one trial
%                            switch length(o)
%                                case 1
                                    o = o.(index(n).subs);
%                                otherwise
%                                    o = {o.(index(n).subs)};
%                            end
%                       otherwise
%                           if length(o) > 1 && length(o(1).(index(n).subs)) > 1
%                               d = ndims(o)+1;
%                             else
%                                 d = ndims(o);
%                             end
%                             o = cat(d,o.(index(n).subs));
%                     end
%            end
%        else
%            o = [];%eval([index(n).subs '(o)']);
%        end
    end
%}
end