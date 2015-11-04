function [txt] = ipa2txt(ipa)
% IPA2TXT  Convert IPA string to pronounceable text equivalent.

if ~ischar(ipa), error('Input must be a text string.')
elseif strcmp(ipa,'a'), txt = 'ah';
elseif strcmp(ipa,'E'), txt = 'eh';
elseif strcmp(ipa,'i'), txt = 'ee';
elseif strcmp(ipa,'o'), txt = 'oh';
elseif strcmp(ipa,'u'), txt = 'oo';
elseif strcmp(ipa,'ih'), txt = 'ih';
elseif strcmp(ipa,'ae'), txt = 'ae';
end