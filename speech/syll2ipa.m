function [ipa] = syll2ipa(syll,type)
%SYLL2IPA  Convert text string to IPA equivalent.

if nargin < 2 || isempty(type), type = 'vowel'; end

if ~ischar(syll), error('Input must be a text string.'); end
syll = lower(syll); % convert to lowercase

switch type
    case 'vowel'
        if strcmp(syll(end-1:end),'aa'), ipa = 'a';
        elseif strcmp(syll(end-1:end),'ee'), ipa = 'i';
        elseif strcmp(syll(end-1:end),'oo'), ipa = 'u';
        else error('%s not found in IPA conversion table.',syll)
        end
    case 'consonant'
        if strcmp(syll(2),'h'), ipa = syll(1:2);
        else ipa = syll(1);
        end
    otherwise
        error('Type must be ''vowel'' or ''consonant''.')
end