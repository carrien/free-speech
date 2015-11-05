function [cellFromFile] = file2cell(filename)
%FILE2CELL  Make cell array from text file, one line per cell.

cellFromFile = {};

fid=fopen(filename);
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    cellFromFile{end+1} = tline;
end
fclose(fid);