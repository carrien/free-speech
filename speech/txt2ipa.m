function [ipa] = txt2ipa(txt)
%TXT2IPA   Converts text string to IPA equivalent.

if ~ischar(txt), error('Input must be a text string.')
elseif strcmp(txt,'ah'), ipa = 'a';
elseif sum(strcmp(txt,{'ae' 'add' 'ad' 'rad'})), ipa = 'ae';
elseif sum(strcmp(txt,{'eh' 'Ed' 'head' 'red' 'glen' 'blend'})), ipa = 'E';
elseif sum(strcmp(txt,{'grain'})), ipa = 'eI';
elseif sum(strcmp(txt,{'ih' 'I' 'rid' 'grin'})), ipa = 'I';
elseif sum(strcmp(txt,{'ee' 'eat' 'reed' 'green' 'bleed'})), ipa = 'i';
elseif sum(strcmp(txt,{'oh' 'blow'})), ipa = 'o';
elseif sum(strcmp(txt,{'oo' 'rude' 'groom' 'blue'})), ipa = 'u';
elseif sum(strcmp(txt,{'er' 'blur'})), ipa = 'er';
end