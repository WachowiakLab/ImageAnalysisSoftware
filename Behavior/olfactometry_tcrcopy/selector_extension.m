function selector_extension(interface)
    
    interface.add(trace_selector(interface.getBlankInitializer()))
    
    function init = trace_selector(init)
        init.uid = 'trace_selector';
        init.name = 'Selector';
        init.group = 'Views';
        init.prerequisites = {'default_view'};
        init.onDrawView = @drawView;
        init.onCheck = @load;
        init.onUncheck = @unload;

        patch_color = [.94 .65 .65];
        currentSelectionBox = [];
        currentTrial = 0;
        row = 0;
        starttime = 0;
        endtime = 0;
        active = false;
        
        function load
            interface.register_event_listener('mainaxes_click', @plot_click);
            interface.set('selection_row',[])
            interface.set('selection_range',[])
        end
        function unload
            interface.unregister_event_listener('mainaxes_click', @plot_click);
            interface.set('selection_row',[])
            interface.set('selection_range',[])
        end
        
        function drawView(drawaxes)
            t = interface.getCurrentTrial();
            if currentTrial ~= t
                interface.set('selection_row',[])
                interface.set('selection_range',[])
                row = 0; starttime = 0; endtime = 0;
                currentTrial = t;
            end
            currentSelectionBox = patch([starttime + [0 0] endtime + [0 0]], row + [-0.5 0.5 0.5 -0.5], patch_color,'EdgeColor','none','HitTest','off','Parent',drawaxes,'Userdata',-900);
            active = false;
        end

        function plot_click
            if active
                selection_drag_end
            else
                switch get(interface.fig,'SelectionType')
                    case 'normal'
                        set(interface.fig, 'WindowButtonMotionFcn', @selection_drag, 'WindowButtonUpFcn', @selection_drag_end);
                        pt = get(interface.mainaxes, 'CurrentPoint');
                        row = round(pt(3));
                        starttime = pt(1);
                        endtime = pt(1);
                        set(currentSelectionBox,'YData', row + [-0.5 0.5 0.5 -0.5], 'XData', [starttime + [0 0] endtime + [0 0]])
                        active = true;
                end
            end
        end
        
        function selection_drag(varargin)
            if active
                pt = get(interface.mainaxes, 'CurrentPoint');
                endtime = pt(1);
                set(currentSelectionBox,'YData', row + [-0.5 0.5 0.5 -0.5], 'XData', [starttime + [0 0] endtime + [0 0]])
            else
                selection_drag_end
            end
        end
        function selection_drag_end(varargin)
            active = false;
            set(interface.fig, 'WindowButtonMotionFcn', [], 'WindowButtonUpFcn', []);
            interface.set('selection_row',row)
            interface.set('selection_range',[min(starttime,endtime),max(starttime,endtime)])
        end
        
    end
    
    
end