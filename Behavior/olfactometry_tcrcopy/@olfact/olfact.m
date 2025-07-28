function o = olfact(varargin)
    %OLFACT Olfactometry class constructor
    %   o = olfact creates an empty olfactometry object

    switch nargin
        case 0
            o = struct('trials', struct('name',{},'timestamp',{},'numtrialavg',{},'trial_length',{},'rois',{},'other',{},'measurement',{},'measurement_param',{},'detail',{},'import',{}),...
                       'rois', struct('name',{},'source',{},'index',{},'points',{},'position',{},'measurement',{},'measurement_param',{},'detail',{}));
            o = class(o,'olfact');
        case 1
            if isa(varargin{1},'olfact')
                o = varargin{1};
            end
    end
end