function [out, info] = LoadBehavData(fn)

endian = 'b';
fid = fopen(fn);
%read header
NumChan = 1;
Pts = 224;
comment = fread(fid,[NumChan,Pts], '*char');
Pts = 2;
timestr = fread(fid, [NumChan, Pts], '*char');
while (~strcmp(timestr(end-1:end), 'AM') && ~strcmp(timestr(end-1:end), 'PM'))
    Pts = 1;
    timestr(end+1) = fread(fid, [NumChan, Pts], '*char');
    if numel(timestr)>50
        disp('Header parsing error');
        return;
    end
end
type = 'int16';
Pts = 1;
ScaleFact = fread(fid, [NumChan, Pts], type, 0, endian);
type = 'uint8';
Pts = 1;
channels = fread(fid, [NumChan, Pts], type, 0, endian);
type = 'uint8';
Pts = 1;
bytes = fread(fid, [NumChan, Pts], type, 0, endian);
type = 'int16';
Pts = 1;
Fs = fread(fid, [NumChan, Pts], type, 0, endian);
type = 'uint32';
Pts = 1;
points = fread(fid, [NumChan, Pts], type, 0, endian);
if channels~=8
    disp('Something is wrong with data loading');
    return;
end
%read data
SamplesPerLine = 10;
reads = floor(points./SamplesPerLine);
data = zeros(points, channels);
cnt = 1;
for j = 1:reads
    %read 2 blocks of data: 5channels x 10samples,then 3 x 10
    type = 'int16';
    Pts = SamplesPerLine;
    NumChan = 5;
    a = fread(fid, [NumChan, Pts], type, 0, endian);
    a = a';
    data(cnt:cnt+SamplesPerLine-1, 1:5) = a./ScaleFact;

    Pts = SamplesPerLine;
    NumChan = 3;
    a = fread(fid, [NumChan, Pts], type, 0, endian);
    a = a';
    data(cnt:cnt+SamplesPerLine-1, 6:8) = a;        
    cnt = cnt+SamplesPerLine;
end
fclose(fid);

%write to output variable
dt = 1/Fs;
time = dt.*(1:size(data,1));
time = time';

info.comment = comment;
info.timestr = timestr;
info.ScaleFact = ScaleFact;
info.channels = channels;
info.bytes = bytes;
info.Fs = Fs;
info.points = points;

out.time = time;
out.lick = data(:,1);
out.Xvel = data(:,2);
out.Yvel = data(:,3);
out.sniff = data(:,4);
out.odor = data(:,5);

out.scanTrig = data(:,6);
out.labTrig = data(:,7);
out.licked = data(:,8);
