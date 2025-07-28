function K = sbxhough(fname)

% analyze sparse noise experiment

% edit Luis 1/10/17. Allow rigid and nonrigid .signals files as input..
    % -----
    if contains(fname,'rigid') % search for rigid in filename
        si = strfind(fname,'_'); 
        fnamelog = fname( 1:si(end)-1); % remove it
    else 
        fnamelog = fname;
    end
    % -----

%%
log = sbxreadhoughlog(fnamelog); % read log
log = log{1};       % assumes only 1 trial

load([fname, '.signals'],'-mat');    % load signals
if(ndims(spks)>2)
    spks = squeeze(spks(1,:,:));
    sig =  squeeze(sig(1,:,:));
end

dsig = spks;

bad = find(isnan(sum(spks))); % some bad ROIs?
dsig(:,bad) = abs(randn(size(spks,1),length(bad))); % replace with white noise

ncell = size(dsig,2);
nstim = size(log,1);
ntau = 20;

r = zeros(ntau,ncell);

for(i=1:nstim)
        r = r + dsig(log.sbxframe(i)-2:log.sbxframe(i)+ntau-3,:);
end

%% Darios test code
% ntau = 20;
% for i = 1:ncell
%     err = zeros(1,ntau);
%     p = cell(1,ntau);
%     for tau = 1:20
%         y = dsig(t.sbxframe+tau-3,i);
%         [p{tau},err(tau)] = sbxhoughret(t.angle,t.dist,y);
%     end
% end

% [xx,yy] = meshgrid(-1920:1920,-540:540);
% P = [xx(:) yy(:)];
% kern = zeros(size(xx));
% km = zeros(size(kern));
% K = cell(1,12);
% 
% 
% for tau = 1:12
%     y = dsig(t.sbxframe+tau-2,i);
%     kern = zeros(size(xx));
%     km = zeros(size(kern));
%     for m=1:nstim
%         [tau m]
%         z = abs(P * [cos(t.angle(m)) sin(t.angle(m))]' - t.dist(m)) < 90;
%         km = reshape(z,size(km));
%         kern = kern+y(m)*km;
%     end
%     K{tau} = kern;
% end

%%

fprintf('\nProcessing...\n%s\n', fname)        

%%
[xx,yy] = meshgrid(-1920:1920,-540:540);
P = [xx(:) yy(:)];

K = cell(ntau, ncell);

for i = 1:ncell
    tStart = tic;
    fprintf('\nProcessing roi # %d/%d\n \ttau(elapsedTime):', i,ncell)        
    for tau = 1:ntau
        fprintf(' %d(%.1f)', tau, toc(tStart))        
        
        y = dsig(log.sbxframe+tau-2,i);
        kern = zeros(size(xx));
        km = zeros(size(kern));
        for m=1:nstim
            z = abs(P * [cos(log.angle(m)) sin(log.angle(m))]' - log.dist(m)) < 90;
            km = reshape(z,size(km));
            kern = kern+y(m)*km;
        end
        K{tau, i} = kern;
    end
end


disp('Saving...');
extention = '.houghkernels';
save([fname extention],'K', '-v7.3');
fprintf('\nSaved as...\n%s\n', [fname extention])        
disp('Done!');

end