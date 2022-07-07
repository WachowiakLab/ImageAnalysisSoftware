function Neuroplex2TIF(imfile)
%function Neuroplex2TIF(imfile)
%   reads neuroplex (.da) file, writes to .tif

%see: http://www.redshirtimaging.com/support/dfo.html for info on Neuroplex
sizeA = 2560; % # of integers of header info
fid = fopen(imfile);
header = fread(fid, sizeA, 'int16');
dat = fread(fid, inf, 'int16');
fclose(fid);
frames = header(5);
xpix = header(385);
ypix = header(386);
im = zeros(ypix,xpix,frames);
im = uint16(im);
cnt = 1;
for i = 1:ypix
    for j = 1:xpix 
        im(i,j,1:frames) = uint16(dat(cnt:cnt+frames-1));
        cnt = cnt+frames;
    end
end

%write as a tiff
t = Tiff([imfile(1:end-3) '.tif'], 'w');
for i = 1:frames   
    a.ImageWidth      = xpix;
    a.ImageLength     = ypix;
    a.Photometric     = 1;
    a.BitsPerSample   = 16;
    a.SamplesPerPixel = 1;
    a.PlanarConfiguration = 1;
    a.XResolution     = 72;
    a.YResolution     = 72;
    a.ResolutionUnit  = 2;
    a.Compression     = Tiff.Compression.None;
    a.Orientation     = 1;
    t.setTag(a);
    t.write(im(:,:,i));
    if i<frames
        t.writeDirectory();
    end
end
t.close();
