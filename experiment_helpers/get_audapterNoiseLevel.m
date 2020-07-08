function noiseLevel = get_audapterNoiseLevel(outputDB)
%set Audapter noise level based on desired outputDB for UW SMNG. 
%input argument outputDB should be a number. Currently only 60 and 80 outputDB noise
%levels are available.
if outputDB == 60
    noiseLevel = 0.03;
elseif outputDB == 80
    noiseLevel = 0.3;
else
    warning('No noise level available for %d outputDB. Setting level to 60 outputDB',outputDB)
    noiseLevel = 0.03;
end