function sample_extension(interface)
%rename this file to sample_extension.m to make it work

    interface.add(sample_script(interface.getBlankInitializer()))
    interface.add(sample_view(interface.getBlankInitializer()))

    function init = sample_script(init)
        init.uid = 'sample_script';
        init.name = 'Sample1';
        init.group = 'Scripts';
        init.type = 'script';
        init.onExecute = @doStuff;
        
        function doStuff
            disp 'replace me with something that does something!'
        end
    end
    
    function init = sample_view(init)
        init.uid = 'sample_view';
        init.name = 'Sample2';
        init.group = 'Views';
        %init.prerequisites = {'default_view'};
        init.onDrawView = @drawView;
        
        function drawView(drawaxes)
            
            o = interface.getOlfact();
            t = interface.getCurrentTrial();

            %do complicated processing...
            
            text(0.5,0.5,o.trials(t).name,'Parent',drawaxes)
            
        end
    end

end