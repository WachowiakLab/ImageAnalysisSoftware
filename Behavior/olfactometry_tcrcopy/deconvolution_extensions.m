function deconvolution_extensions(interface)

    interface.add(deconvolved_view(interface.getBlankInitializer()))

    %initializer for default_view
    function init = deconvolved_view(init)
        init.uid = 'deconvolved_view';
        init.name = 'Deconvolved';
        init.group = 'Views';
        init.prerequisites = {'default_view'};
        init.onDrawView = @drawView;
        init.onRightClick = @rightClick;
        init.onUncheck = @savePrefs;

        colorwheel = ([1 0 0; 0 .7 0; 0 0 1; 1 .5 0; .5 1 0; .7 0 .7; 0 .5 .5] + 1) / 2;
        
        tau = 0.248;
        butter_Wn = 7.5; %Hz

        function drawView(drawaxes)
            o = interface.getOlfact();
            t = interface.getCurrentTrial();
            trial = o.trials(t);
            ri = interface.getCurrentRois();
            scale = interface.get('real_scale_factor');
            [butter_b,butter_a] = butter(4,butter_Wn/(trial.rois.samplingrate/2));

            kernellength=round(2*tau*trial.rois.samplingrate)-1;
            kernelpad = zeros(1,kernellength);
            kernel=exp((0:-1:-kernellength)/(tau*trial.rois.samplingrate));
            
            time = (1:trial.rois.datasize(1))./trial.rois.samplingrate;
            tr_all = bsxfun(@ldivide,trial.rois.RLIs,trial.rois.traces);
            
            for rii = 1:length(ri)
                r = ri(rii);
                tr = tr_all(r,:);
                filt_tr = filtfilt(butter_b,butter_a,tr);
                deconv_tr = deconv([filt_tr kernelpad], kernel);
                meantr = mean(deconv_tr);
                plot(time,((deconv_tr - meantr).*scale*10)-rii,'Parent',drawaxes,'Color',colorwheel(mod(r-1,length(colorwheel))+1,:),'Userdata',-100)
            end

        end

        function rightClick(menu)
            uimenu(menu, 'Label', 'About', 'Callback', @show_about);
            set(menu,'Visible','on')
            
            function show_about(varargin)
                msgbox({'This adds deconvolved roi traces to the default view.','','RMC','13 September 2007'}, 'Deconvolved view')
            end
        end
        
        function savePrefs
            
        end
        
    end
end