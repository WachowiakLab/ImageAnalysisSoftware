function display(o)
	%DISPLAY Olfactometry class
    if isequal(get(0,'FormatSpacing'),'compact')
        disp([inputname(1) ' =']);
    else
        disp(' ')
        disp([inputname(1) ' =']);
        disp(' ');
    end
    if length(o) == 1
        disp(['    Olfactometry object: ' int2str(length(o.trials)) ' trials, ' int2str(length(o.rois)) ' rois'])
    else
        siz = sprintf('x%d',size(o));
        disp(['    [' siz(2:end) ' olfact]'])
    end
end
