function [isi] = bpm2isi(bpm, bMs)
% Converts tempos in bpm (beats per minute) to the ISI (interstimulus interval). 
% 
% Inputs: 
% 
%       bpm             The bpm you would like to convert. Can also take a vector of bpms. 
% 
%       bMs             Whether you want your result in milliseconds or not (seconds) 
% 
% Outputs: 
% 
%       isi             The corresponding ISI values. 
% 
% Initiated RPK 2021-06-07

dbstop if error 

%% 
if nargin < 2 || isempty(bMs), bMs = 0; end    

if bMs
    isi = (1 ./ (bpm/60)) * 1000; 
else
    isi = 1./(bpm/60);
end


end