function [resp, canceled, returnvalue] = input_dialog(title,prompts,defaults,width,modal)
    canceled = true;
    returnvalue = 0;
    if nargin < 5 || modal == true
        modal = 'modal';
    else
        modal = 'normal';
    end
    fig = figure('Name',title,'Units','pixels',...
        'MenuBar', 'none', 'DockControls','off', 'Resize', 'off', 'WindowStyle', modal, ...
        'HandleVisibility','off','NumberTitle', 'off', ...
        'Color', get(0,'DefaultUicontrolBackgroundColor'),...
        'CloseRequestFcn',@cancel);
    cancel_button = uicontrol(fig,'Style','pushbutton','Units','pixels','String','Cancel','Position',[width-60 10 50 25],'Callback',@cancel,'KeyPressFcn',@keypress);
    uicontrol(fig,'Style','pushbutton','Units','pixels','String','OK','Position',[width-120 10 50 25],'Callback',@ok,'KeyPressFcn',@keypress);
    h = zeros(size(prompts));
    height = 50;
    for n = length(prompts):-1:1
        switch class(defaults{n})
            case 'char'
                h(n) = uicontrol(fig,'Style','edit','String',defaults{n},'Min',1,'Max',1,'Position',[20 height width-40 20],'HorizontalAlign','left','BackgroundColor',[1 1 1],'KeyPressFcn',@keypress);
                uicontrol(fig,'Style','text','String',prompts{n},'Position',[20 height+20 width-40 15],'HorizontalAlign','left')
                height = height + 45;
            case 'cell'
                h(n) = uicontrol(fig,'Style','edit','String',defaults{n},'Min',1,'Max',1000,'Position',[20 height width-40 60],'HorizontalAlign','left','BackgroundColor',[1 1 1],'KeyPressFcn',@keypress);
                uicontrol(fig,'Style','text','String',prompts{n},'Position',[20 height+60 width-40 15],'HorizontalAlign','left')
                height = height + 85;
            case 'logical'
                h(n) = uicontrol(fig,'Style','checkbox','String',prompts{n},'Value',double(defaults{n}),'Position',[20 height width-40 20],'KeyPressFcn',@keypress);
                height = height + 30;
            case 'double' %creates button labeled with associated prompt, returns the default value if pressed
                h(n) = uicontrol(fig,'Style','pushbutton','String',prompts{n},'Position',[20 height width-40 20],'Callback',{@buttonpress,defaults{n}},'KeyPressFcn',@keypress);
                height = height + 40;
%            case 'struct' %this defines a custom renderer/editor? Maybe I'll do this later.
                
        end
    end

    set(fig,'Position',getpos(get(0,'ScreenSize'),[0.5 0.5 0 0],[-width/2 -height/2 width height]),'Children',flipud(get(fig,'Children')))
    uicontrol(h(n))
    resp = defaults;
    uiwait(fig)

    function keypress(target, ev)
        switch ev.Key
            case 'return'
                switch target
                    case cancel_button
                        cancel
                    otherwise
                        ok
                end
        end
    end
    function buttonpress(varargin)
        returnvalue = varargin{3};
        ok
    end
    function ok(varargin)
        canceled = false;
        for p = 1:length(prompts)
            switch class(defaults{p})
                case {'char', 'cell'}
                    resp{p} = get(h(p),'String');
                case 'logical'
                    resp{p} = get(h(p),'Value') > 0;
%                case 'struct'
%                    resp{p}.setValue(defaults{p}.getValue);
            end
        end
        delete(fig)
    end
    function cancel(varargin)
        delete(fig)
    end
end

function pos = getpos(pos, fig_frac, pixel_offset)
    pos = pos([3 4 3 4]) .* fig_frac + pixel_offset;
end
