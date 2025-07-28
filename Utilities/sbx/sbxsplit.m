function sbxsplit(fn)

global info

% splits a volumetric optotune dataset into N different ones

load(fn);

type = 0;
if info.volscan == 0
    if isfield(info,'mesoscope')
        if info.mesoscope.enabled && length(info.mesoscope.galvo_a)>1
            type = 2;
        end
    else
        type = 3;
    end
else
    type = 1;   % volscan
end

switch type
    
    case 0        
        fprintf(2,'File is not a volumetric scan or mesoscope with #ROIs>1');

    case 1      % volscan
        
        disp ('Processing volumetric data');
        
        nslices = info.otparam(3);  % get the number of slices
        
        d = dir(sprintf('%s.sbx',fn));   % get the number of bytes in file
        nb = d(1).bytes;
        bytesperslice = nb/nslices;
        
        fid = fopen(d(1).name,'r');
        fids = zeros(1,nslices);
        sname = cell(1,nslices);
        
        for i = 1:nslices
            sname{i} = sprintf('%s_ot_%03d.sbx',fn,i-1);
            [~,~] = system(sprintf('fsutil file createnew %s %d',sname{i},bytesperslice));   %allocate space
            fids(i) = fopen(sname{i},'w');
        end
        
        z = sbxread(fn,0,1);
        
        % split file
        
        for n=0:info.max_idx
            s = mod(n,nslices); % which slice?
            buf = fread(fid,info.nsamples/2,'uint16=>uint16');
            fwrite(fids(s+1),buf,'uint16');
        end
        
        drawnow('update');
        
        % close files
        fclose(fid);
        
        for s = 1:nslices
            fclose(fids(s));
        end
        
        % create matlab files
        for i = 1:nslices
            matname{i} = sprintf('%s_ot_%03d.mat',fn,i-1);
            [~,~] = system(sprintf('copy %s %s',[fn '.mat'],matname{i}));
        end
        
    case 2  % mesoscope
        
        disp('Processing mesoscope data');
        
        nslices = length(info.mesoscope.galvo_a);  % get the number of ROIs
        
        d = dir(sprintf('%s.sbx',fn));   % get the number of bytes in file
        nb = d(1).bytes;
        bytesperslice = nb/nslices;
        
        fid = fopen(d(1).name,'r');
        fids = zeros(1,nslices);
        sname = cell(1,nslices);
                
        disp('Allocating space');
        for i = 1:nslices
            sname{i} = sprintf('%s_roi_%03d.sbx',fn,i-1);
            [~,~] = system(sprintf('fsutil file createnew %s %d',sname{i},bytesperslice));   %allocate space
            fids(i) = fopen(sname{i},'w');
        end
        
        z = sbxread(fn,0,1);
        
        % split file
        
        disp('Splitting data');

        for n=0:info.max_idx
            [n info.max_idx]
            s = mod(n,nslices); % which slice?
            buf = fread(fid,info.nsamples/2,'uint16=>uint16');
            fwrite(fids(s+1),buf,'uint16');
        end
        
        disp('Closing files');

        % close files
        fclose(fid);
        
        for s = 1:nslices
            fclose(fids(s));
        end
        
        disp('Creating associated Matlab files');

        % create matlab files
        for i = 1:nslices
            matname{i} = sprintf('%s_roi_%03d.mat',fn,i-1);
            [~,~] = system(sprintf('copy %s %s',[fn '.mat'],matname{i}));
        end
end


