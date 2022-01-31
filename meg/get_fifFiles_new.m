%\\wcs-cifs.waisman.wisc.edu\wc

function [sfif] = get_fifFiles_new(exptName,sid,visit)
%GET_FIFFILES : get list of .fif files

expDataPath = fullfile('\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\', exptName);
fifdir = fullfile(expDataPath, 'megdata',sid,visit,'tsss');%'tsss''first_tsss_noevents'

rows2rm = [];
d = dir(fullfile(fifdir,'*.fif'));%,'*.fif'
for i = 1:length(d)
    if strfind(d(i).name,'ER')
        rows2rm = [rows2rm i]
    end
end

d(rows2rm) = [];

z = d(end); d(end) = []; d = [z; d]; % reorder to put unsuffixed file first
sfif = fullfile(fifdir,{d.name});
