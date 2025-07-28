function examples_data(olf_file,trial_name,rois)

olf=load(olf_file,'-mat');
o=olf.o;
trials=o.trials;

flows=trials(strcmp({trials.name},trial_name)).measurement.flowrate;
fits=trials(strcmp({trials.name},trial_name)).measurement.response_fits;
disp(flows);

    for i=1:length(rois)
        roi=rois(i);
        disp(roi)
        fits_amp=[fits([fits.roi_num]==roi).rise_amplitude]
        fits_time=[fits([fits.roi_num]==roi).stimtime]
        fits_flow=[fits([fits.roi_num]==roi).flowrate_mag]
    end
end