% MCC adapted from Aladin's "DAT file structure info.m" 2008-06-18
% reads a single map file (i.e. .dat) and returns the resting lights,
% signal, and mask. All I did was to remove the references to the "handles" pointer

function [rlis, signal, mask] = read_dat(filename)

  [fid, message]=fopen(filename, 'r', 'b');   %big-endian format
 % fseek(fid, 243, 'bof');
 % odor(n) = cellstr(char((fread(fid,24,'char'))'));
                
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
    
               
  fclose(fid);
                
                
end