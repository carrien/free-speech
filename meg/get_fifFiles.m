function [sfif] = get_fifFiles(exptName,sid)
%GET_FIFFILES : get list of .fif files

expDataPath = fullfile('/Volumes/smng/experiments/', exptName);
fifdir = fullfile(expDataPath, 'megdata',sid, 'tsss');

rows2rm = [];
d = dir(fullfile(fifdir,'*.fif'));
for i = 1:length(d)
    if strfind(d(i).name,'ER')
        rows2rm = [rows2rm i]
    end
end

d(rows2rm) = [];

z = d(end); d(end) = []; d = [z; d]; % reorder to put unsuffixed file first
sfif = fullfile(fifdir,{d.name});
