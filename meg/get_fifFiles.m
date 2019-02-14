function [sfif] = get_fifFiles(exptName,sid)
%GET_FIFFILES : get list of .fif files

expDataPath = fullfile('/Volumes/smng/experiments/', exptName);
fifdir = fullfile(expDataPath, 'megdata',sid, 'tsss');

d = dir(fullfile(fifdir,'*.fif'));
z = d(end); d(end) = []; d = [z; d]; % reorder to put unsuffixed file first
sfif = fullfile(fifdir,{d.name});
