
close all
numImages = 100;
figure
load clown

xc = size(X,2)/2;
yc = size(X,1)/2;

x = xc + 50 * cos(2*pi*1/31);
y = yc + 50 * sin(2*pi*1/27);
x = round(x); y = round(y);

lasttform =  affine2d;
lastimg = X(y-35:y+35,x-35:x+35);

imageSize = size(lastimg);


height = 300;
width = 300;
% Initialize the "empty" panorama.
panorama = zeros([height width], 'like', img);
blender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port');

panoramaView = imref2d([height width], [-height/2 height/2], [-width/2 width/2]);

for n = 1:numImages
    
    x = xc + 50 * cos(2*pi*n/31);
    y = yc + 60 * sin(2*pi*n/27);
    x = round(x); y = round(y);
    img = X(y-35:y+35,x-35:x+35);

    tform = imregcorr(img,lastimg,'translation');
    tform.T = tform.T * lasttform.T;
    lastimg = img;
    lasttform = tform;
    
    % Transform I into the panorama.
    warpedImage = imwarp(img, tform, 'OutputView', panoramaView);
    
    % Generate a binary mask.
    mask = imwarp(true(size(img,1),size(img,2)), tform, 'OutputView', panoramaView);
    
    % Overlay the warpedImage onto the panorama.
    panorama = step(blender, panorama, warpedImage, mask);
    if(n==1)
    h = imagesc(medfilt2(panorama,[3 3]));
    truesize
    colormap gray
    axis off
    else
        h.CData = medfilt2(panorama,[3 3]);
    end
    drawnow
end