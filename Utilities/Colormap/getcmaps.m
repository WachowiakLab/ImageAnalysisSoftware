function cmapstrings = getcmaps()
cmapstrings = {'gray'; 'gray_hilo'; 'parula'; 'hot'; 'cool'; 'bone'; 'jet';...
    'clut2b2'; 'green'; 'greenhot'; 'red'; 'redhot'; 'blue'; 'bluehot'; ...
   'nawhimar'; 'nawhimar_auto'; 'nawhimar_automax'; 'magenta'};
%'bluewhitered'; 'bluewhitered_auto'; 'azublare';'azublare_auto'};

%Note: When setting colormaps for >1 axes in the same figure, one should ...
%always specify an axes using e.g.... colormap(gca,map). This sets up a hidden
%axes property called "colorspace" that holds the colormap for each axes in
%the figure. To access this property, type cspace = get(gca,'ColorSpace');