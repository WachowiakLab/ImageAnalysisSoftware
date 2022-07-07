function [filtim] = imfilter_temporalLPF(im,framerate,cutoff)
% Apply 1st order butterworth low pass filter to image stack (width,height,frames)
% framerate is sampling frequency of image, cutoff is cutoff frequency

filtim = zeros(size(im));

%temporal filter
Wn = cutoff/(0.5*framerate); % Wn = Normalized Cutoff Frequency
while (Wn <= 0 || Wn >= 1)
    answer = inputdlg(sprintf('Enter Valid Filter Value (between 0.0 and %4.4f Hz )',framerate/2),...
        'Temporal Filter Error',1,{num2str(framerate/10)});
    if isempty(answer)
        newfreq = 0.0;
    else
        newfreq = str2double(answer);
    end
    Wn = newfreq/(0.5*framerate); % Wn = CutOff Frequency
end
N = 1; % 1st order butterworth filter tcrtcrtcr - should have this as input!
[b,a] = butter(N,Wn); %
tmp = waitbar(0,'Filtering');
for i = 1:size(im,1);
    for j = 1:size(im,2);
        filtim(i,j,:) = filtfilt(b,a,double(im(i,j,:))); %filtfilt uses zero-phase digital filtering
    end
    waitbar(i/size(im,1));
end
close(tmp);
