function [bPaused] = get_pauseState_ptb(pausekey)

pausekeyCode = KbName(pausekey); % convert pause string to pause keycode
[~,~,keyCodeLogical] = KbCheck;  % check for keypress
keyCode = find(keyCodeLogical);
bPaused = any(keyCode == pausekeyCode); % compare pressed keycodes with pause keycode

end
