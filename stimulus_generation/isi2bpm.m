function [bpm] = isi2bpm(isi, bMs)
% Translates interstimulus intervals (ISIs) to bpms, assuming center-to-center or pulse-to-pulse 
% 
% isi: vector of interstimulus intervals
% bMs: if you're giving the intervals in milliseconds or not (not = seconds) 
% 
% Initiated RPK 2021-06-07

dbstop if error

%%

if nargin < 2 || isempty(bMs), bMs = 0; end

if bMs
    bpm = (60./(isi/1000)); 
else
    bpm = (60./isi); 
end




end
