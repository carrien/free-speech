function fadeVolumePTB(handle, newVol, fadeDur, numSteps)
% Lets you fade up or fade down the volume of a Psychtoolbox device over a
% specified number of seconds. Note that Psychtoolbox will keep MATLAB in a
% busy state for the duration of this fade; your main function will have to
% wait for the fade to finish to do other things.
%
% INPUT ARGUMENTS:
% Handle: [REQ] the handle variable for the Psychtoolbox device
% New volume: [REQ] What volume you want the device to go to. Normally 0 to 1.
%   Use command `PsychPortAudio Volume?` for more info about values. 
% Fade Duration: How long in seconds the fade should take from start to finish.
% Number of Steps: If you're doing a really long fade (>5 seconds) for
%   some reason, a higher value will smooth out the transition.
%
% CWN 2020-06

if nargin < 3 || isempty(fadeDur) || ~isnumeric(fadeDur)
    fadeDur = 0.3;
end
if nargin < 4 || isempty(numSteps)
    numSteps = 100;
end

oldVol = PsychPortAudio('Volume', handle);
if newVol == oldVol
    return;
elseif newVol > oldVol
    sign = 1;
else
    sign = -1;
end

distanceToTravel = abs(newVol - oldVol);

for vol = oldVol:(sign * (distanceToTravel / numSteps)):newVol
    PsychPortAudio('Volume', handle, vol);
    WaitSecs(fadeDur / numSteps);
end

end