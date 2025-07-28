function sbxsuite2sbx(smat,fn)

% Convert a suite2p segmentation to Scanbox format

% z = sbxread(fn,0,1);
% z = squeeze(z(1,:,:));
% sz = size(z);

sz = [512 796];
mask = zeros(sz);

s2p=load(smat);

k = 1;
spks = [];
sig = [];
np = [];

for i=1:length(s2p.stat)
    if(s2p.iscell(i,1))
        mask(sub2ind(sz,s2p.stat{i}.ypix,s2p.stat{i}.xpix)) = k;
        spks(:,k) = s2p.spks(i,:)';
        sig(:,k)  = s2p.F(i,:);
        np(:,k)   = s2p.Fneu(i,:)';
        k = k+1;
    end
end

save([fn '.segment'],'mask');
save([fn '.signals'],'spks');


