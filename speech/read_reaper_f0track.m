function [reaperdata] = read_reaper_f0track(filenamestr)
%READ_REAPER_F0TRACK  Import reaper f0 track.

fid = fopen(sprintf('%s.f0',filenamestr));
textscan(fid,'%*[^\n]',7); % toss out seven-line header
filedata = textscan(fid,'%f %f %f');
fclose(fid);
reaperdata.taxis = filedata{1};
reaperdata.bVoiced = logical(filedata{2});
reaperdata.f0 = filedata{3};