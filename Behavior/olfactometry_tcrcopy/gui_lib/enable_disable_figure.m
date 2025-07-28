function enable_disable_figure(handle)
    u = get(handle,'userdata');
    if isstruct(u) && isfield(u,'enable_disable_figure_struct')
        set(u.enable_disable_figure_struct.els,'Enable','on')
        set(handle,'userdata',u.enable_disable_figure_struct.orig_userdata)
    else
        els = findall(handle,'Enable','on');
        set(els,'Enable','off')
        set(handle,'userdata',struct('enable_disable_figure_struct',struct('els',els,'orig_userdata',u)))
    end
end