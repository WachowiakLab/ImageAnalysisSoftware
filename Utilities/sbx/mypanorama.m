
fn = 'xx0_500_000';

margin = 15;

lastimg = double(squeeze(sbxread(fn,1,1)));
lastt = [0 0];

panorama = padarray(lastimg,[margin margin],NaN);
N = double(~isnan(panorama));

for n=2:64
    img = squeeze(sbxread(fn,n,1));
    [u ,v] = fftalign(img,lastimg);
    t = [u v];
    t = t + lastt;
    warp = padarray(double(img),[margin margin],NaN);
    warp = circshift(warp,t);
    
    i0 = find(~isnan(panorama));
    j0 = find(~isnan(warp));
    idx = intersect(i0,j0);
    panorama(idx) = (panorama(idx).*N(idx)+warp(idx))./(N(idx)+1);
    N(idx) = N(idx)+1;
    
    idx = setdiff(j0,i0);
    N(idx) = 1;
    panorama(idx) = warp(idx);
    clf
    imagesc(panorama)
    truesize
    drawnow;
    n
end

    