function [status,res] = gen_reaper_f0track(filenamestr,frange)
%GEN_REAPER_F0TRACK  Run reaper pitch tracker on a single wav file.
%   GEN_REAPER_F0TRACK(FILENAMESTR) takes runs the reaper pitch tracking
%   software on the wav file whose path is defined in FILENAMESTR. The
%   success or failure of the operation is returned in STATUS and any error
%   messages are returned in RES.

if nargin < 2 || isempty(frange)
    suffix = [];
else
    suffix = sprintf('-m %d -x %d',frange(1),frange(2));
end

[path,filename,ext] = fileparts(filenamestr);
if strcmp(ext,'.wav')
    filenamestr = [path filename];
end

if isempty(suffix)
    [status,res] = system(sprintf('reaper -i %s.wav -f %s.f0 -a',filenamestr,filenamestr));
else
    [status,res] = system(sprintf('reaper -i %s.wav -f %s.f0 %s -a',filenamestr,filenamestr,suffix));
end