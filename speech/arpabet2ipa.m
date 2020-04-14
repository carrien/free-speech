function [ipa] = arpabet2ipa(arpabet,brackets)
%ARPABET2IPA  Convert arpabet to IPA.

if nargin < 2, brackets = []; end

switch arpabet
    case 'aa'
        ipa = char(593); %'a';
    case 'iy'
        ipa = 'i';
    case 'uw'
        ipa = 'u';
    case 'ae'
        ipa = 'æ';
end

if brackets
    switch brackets
        case '/'
            ipa = sprintf('/%s/',ipa);
        case {'[',']'}
            ipa = sprintf('[%s]',ipa);
    end
end
