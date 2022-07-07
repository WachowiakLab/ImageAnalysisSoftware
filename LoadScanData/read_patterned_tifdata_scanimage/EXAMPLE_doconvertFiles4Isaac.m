options.big = 'true';

[tmpim,tmp] = read_patterned_tifdata('D:/Trust/pcd309/old_pcd308_0_00001.tif');
fastsaveastiff(tmpim,'D:/Trust/pcd309/pcd308_0_00001.tif',options);
tmptif = Tiff('D:/Trust/pcd309/pcd308_0_00001.tif','r+');
setTag(tmptif,'ImageDescription',tmp.tifinfo.ImageDescription);
tmptif.close;
clear tmpim tmp tmptif;

[tmpim,tmp] = read_patterned_tifdata('D:/Trust/pcd309/old_pcd309_0_00001.tif');
fastsaveastiff(tmpim,'D:/Trust/pcd309/pcd309_0_00001.tif',options);
tmptif = Tiff('D:/Trust/pcd309/pcd309_0_00001.tif','r+');
setTag(tmptif,'ImageDescription',tmp.tifinfo.ImageDescription);
tmptif.close;
clear tmpim tmp tmptif;

[tmpim,tmp] = read_patterned_tifdata('D:/Trust/pcd309/old_pcd309_0_00002.tif');
fastsaveastiff(tmpim,'D:/Trust/pcd309/pcd309_0_00002.tif',options);
tmptif = Tiff('D:/Trust/pcd309/pcd309_0_00002.tif','r+');
setTag(tmptif,'ImageDescription',tmp.tifinfo.ImageDescription);
tmptif.close;
clear tmpim tmp tmptif;

clear options;
