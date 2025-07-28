
fn = 'ms00_002_006';
marginh = 20;
marginv = 10;

vid = VideoWriter([fn '.avi'],'Grayscale AVI');
open(vid);

close all

figure

%h = fspecial('gauss',31,3);

lasttform =  affine2d;
lastimg = double(squeeze(sbxread(fn,0,1)));
lastimg = lastimg(marginv:end-marginv,marginh:end-marginh);

%lastimg = filter2(h,lastimg,'valid');

imageSize = size(lastimg);

height = 6000;
width = 6000;

% Initialize the "empty" panorama.
panorama = zeros([height width], 'like', lastimg);
blender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port');
panoramaView = imref2d([height width], [-height/2 height/2], [-width/2 width/2]);

global info
numImages = info.max_idx;

for n = 1:numImages
   
    img = double(squeeze(sbxread(fn,n,1)));
    img = img(marginv:end-marginv,marginh:end-marginh);
   % lastimg = filter2(h,lastimg,'valid');

    tform = imregcorr(img,lastimg,'translation','Window',true);

    tform.T
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
        h = imagesc(panorama);
        truesize
        colormap gray
        axis off
    else
        h.CData = panorama;
    end
    drawnow
    q = h.CData;
    q = uint8((q-min(q(:)))/(max(q(:))-min(q(:)))*255);
    writeVideo(vid,q);
end

close(vid)
