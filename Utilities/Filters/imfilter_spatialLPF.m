function [im] = imfilter_spatialLPF(im,sigma)
% Apply gaussian low pass filter to image stack (width,height,frames)

%spatial filter
hsize = round(sigma*5);
if mod(hsize,2)==0
    hsize = hsize+1;
end
%could use matlab functions here: e.g.   filt = fspecial('gaussian',size,sigma) - where you can input both
%size and sigma, then filtIm = imfilter(origIm, filt,'replicate');
gaus2 = fspecial('gaussian',hsize,sigma);  
frames = size(im,3);
if frames>=100; tmp = waitbar(0,'Filtering'); end
for i = 1:size(im,3)
    im(:,:,i) = imfilter(im(:,:,i), gaus2, 'replicate');
    if exist('tmp','var'); waitbar(i/size(im,3)); end
end
if exist('tmp','var'); close(tmp); end
% old code using convolution method (tcr changed 03/28/2019-filtim was argout)
% gaus2 = zeros(hsize,hsize);
% midx = (hsize+1)/2;
% midy = midx;
% for x = 1:hsize
%     for y = 1:hsize
%         gaus2(x,y) = exp(-((x-midx)^2+(y-midy)^2)/(2*sigma^2));
%     end
% end
% gaus2 = gaus2./sum(sum(gaus2));   
% frames = size(im,3);
% if frames>=100; tmp = waitbar(0,'Filtering'); end
% for i = 1:size(im,3)
%     tmpim = conv2(single(im(:,:,i)), single(gaus2), 'same');
%     if isa(im,'uint16')
%         filtim(:,:,i) = uint16(tmpim);
%     else
%         filtim(:,:,i) = tmpim;
%     end
%     if exist('tmp','var'); waitbar(i/size(im,3)); end
% end
% if exist('tmp','var'); close(tmp); end