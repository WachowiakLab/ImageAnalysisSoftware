function gridrois = gridROIs(imsize,gridsize)
%imsize, e.g. [512 512] (rows, columns)
%gridsize, e.g. [16 16] (#rows/roi, #cols/roi), best to use an exact multiple of imsize

rowpix = floor(imsize(1)/gridsize(1));
colpix = floor(imsize(2)/gridsize(2));
gridrois.mask = zeros(imsize);
for col = 1:gridsize(2)
    for row = 1:gridsize(1)
        gridrois(row+gridsize(1)*(col-1)).mask=zeros(imsize);
        gridrois(row+gridsize(1)*(col-1)).mask((row-1)*rowpix+1:(row-1)*rowpix+rowpix,(col-1)*colpix+1:(col-1)*colpix+colpix) = 1;
    end
end

