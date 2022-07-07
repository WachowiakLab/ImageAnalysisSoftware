function filtim = imfilter_suppressBrightPixels(im,pct)
%function filtim = filtBrightPixels(im,pct)
%   Applies a 5x5 pixel median filter to bright pixels
%   'pct' is the percentile of pixels above which to filter (e.g. percentile cutoff)
if isa(im,'uint16')
    filtim = uint16(zeros(size(im)));
else
    filtim = zeros(size(im));
end
frames = size(im,3);
if frames>=100; tmp = waitbar(0,'Filtering'); end
maxnum = qprctile(im(:),pct);
for i = 1:size(im,3)
    temp = squeeze(im(:,:,i));
    brightpixels = find(temp>maxnum);
    if ~isempty(brightpixels) 
        for j=1:size(brightpixels)
            [row,column]=ind2sub(size(temp),brightpixels(j));
            %get a local 5x5 pixel region w/brightpix in center, pad if necessary by replicating edge values
            if row > 2 && row < size(temp,1)-1 && column >2 && column < size(temp,2)-1
                tmp2filter = temp(row-2:row+2,column-2:column+2);
            else
                padtemp=padarray(temp,[2 2],'replicate');
                tmp2filter = padtemp(row:row+4,column:column+4);
            end
            temp(row,column)=median(tmp2filter(:)); %replace pixel with local median
            %tmpfilt=hmf(tmp2filter,5);temp(row,column)=tmpfilt(3,3); %see hmf.m
        end
    end
    if isa(im,'uint16')
        filtim(:,:, i) = uint16(temp);
    else
        filtim(:,:, i) = temp;
    end
    if exist('tmp','var'); waitbar(i/size(im,3)); end
end
if exist('tmp','var'); close(tmp); end
