% MCC adapted from Aladin's "DAT file structure info.m" 2009-04-15
% so that it also returns the odor name
function [rlis, signal, mask, odor] = read_dat2(filename)

  [fid, message]=fopen(filename, 'r', 'b');   %big-endian format
  fseek(fid, 243, 'bof');
  odor = cellstr(char((fread(fid,24,'char'))'));
                
  fseek(fid, 501, 'bof');
  pixels = fread(fid, 1, 'uint8');
                %x = handles.var.pixels(n)
  if pixels == 0 || pixels > 255 || pixels == 1
    fseek(fid,501,'bof');
    pixels = fread(fid,1,'int16');
                    %y = handles.var.pixels(n)
  else
  end
                
  fseek(fid, 512, 'bof');
  rlis=(fread(fid, [pixels, pixels], 'float32'))';
  signal=(fread(fid, [pixels, pixels], 'float32'))';
  mask=(fread(fid, [pixels, pixels], 'float32'))';
   
%  assignin('base','rlis',rlis);
%  assignin('base', 'signal', signal);
%  assignin('base','mask',mask);
%  assignin('base','odor',odor);
               
  fclose(fid);
                
                
end