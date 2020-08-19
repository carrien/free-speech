function [keyCodeLogical] = KbWaitForKey(keys2wait4, timelimit, deviceNumber)
%KBWAITFORKEY  Wait for specific keypress.
%   KBWAITFORKEY(KEY2WAIT4,TIMELIMIT) waits until one of the keys defined
%   in KEYS2WAIT4 is pressed before continuing. If TIMELIMIT is defined,
%   the function will return after TIMELIMIT seconds even if no key has
%   been pressed.

if nargin < 1 || isempty(keys2wait4), keys2wait4 = [32 49 50 51 52]; end % spacebar, 1, 2, 3, 4
if nargin < 2 || isempty(timelimit), timelimit = inf; end
if nargin < 3 || isempty(deviceNumber), deviceNumber = []; end

tic;

wait = 1;
while wait && toc < timelimit
    [~,keyCodeLogical] = KbWait(deviceNumber);
    keyCode = find(keyCodeLogical);
    if any(keys2wait4 == keyCode(1))
        wait = 0;
    end
end