function ephys = loadScanboxEphys(varargin)
%ephys = loadScanboxEphys(varargin)
%   varargin{1} = filename, e.g. 'tbt064_002_002.ephys'
%   varargin{2} = samprate, e.g. 150; (Hz, hardcoded in scanbox.config)
%   ephys is a struct w/fields: framenum, times, odor, trachea, sniff,
%       lick, puff, reward, valence

if ~nargin
    [filename,path] = uigetfile('*.ephys','Select ePhys File');
    filename=fullfile(path,filename);
else
    filename=varargin{1};
end
if nargin<2; samprate = input('Enter Ephys Sampling Rate:');
else; samprate = varargin{2};
end

fid=fopen(filename);
if fid==-1; ephys = []; return; end
A=fread(fid,'single');
% A=fread(fid);
fclose(fid);
B=reshape(A,[8 size(A,1)/8]);
ephys.framenum = B(1,:);
samprate = 150; % this value was set manually in the scanbox config file - change to match your data
ephys.times = (1:length(ephys.framenum))/samprate;
fprintf('Using %d Hz Sampling Rate for Ephys data.\n',samprate);
ephys.odor = B(2,:);
ephys.trachea = B(3,:);
ephys.sniff = B(4,:);
ephys.lick = B(5,:);
ephys.puff = B(6,:);
ephys.reward = B(7,:);
ephys.valence = B(8,:);

% figure; hold on;
% plotlabels = {'frame#','odor','trachea','sniff','lick','puff','reward','valence'};
% for i=1:8
%     tmp=(B(i,:));
%     tmp=(tmp-min(tmp(:)))./(max(tmp(:))-min(tmp(:)));
% %     tmp=normalize(tmp);
%     plot(tmp+2*i-1,'DisplayName',plotlabels{i});
% end
% tmp=axis;
% axis([tmp(1) tmp(2) tmp(3) tmp(4)+1]);