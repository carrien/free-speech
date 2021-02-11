function [arpabet] = txt2ipa(txt)
% txt2ipa no longer in use (deprecated). Forwards to txt2arpabet instead.

warning(['The txt2ipa function has been renamed txt2arpabet to more accurately reflect its behavior. ' ...
    'For long-term compatibility, replace your txt2ipa function calls with txt2arpabet.'])
arpabet = txt2arpabet(txt);

end