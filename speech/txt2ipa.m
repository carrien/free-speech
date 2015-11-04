function [ipa] = txt2ipa(txt)
%TXT2IPA   Converts text string to IPA equivalent.

if ~ischar(txt), error('Input must be a text string.')
elseif strcmp(txt,'ah'), ipa = 'a';
elseif strcmp(txt,'eh'), ipa = 'E';
elseif strcmp(txt,'Ed'), ipa = 'E';
elseif strcmp(txt,'head'), ipa = 'E';
elseif strcmp(txt,'ee'), ipa = 'i';
elseif strcmp(txt,'eat'), ipa = 'i';
elseif strcmp(txt,'oh'), ipa = 'o';
elseif strcmp(txt,'oo'), ipa = 'u';
elseif strcmp(txt,'ih'), ipa = 'ih';
elseif strcmp(txt,'ae'), ipa = 'ae';
elseif strcmp(txt,'add'), ipa = 'ae';
end