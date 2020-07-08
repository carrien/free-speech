function [unusedDirs] = get_unusedDirs(parentdir,dirs)
%GET_UNUSEDDIRS  Compares list to dir structure and returns nonexistent dirs

d = dir(parentdir);
dirnames = {d.name};
unusedDirs = setdiff(dirs,dirnames);
