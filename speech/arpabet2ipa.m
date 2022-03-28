function [ipa] = arpabet2ipa(arpabet,brackets)
%ARPABET2IPA  Convert ARPABET text string to IPA equivalent.

if nargin < 2, brackets = []; end

if iscellstr(arpabet), arpacell = arpabet; %#ok<ISCLSTR>
elseif ischar(arpabet), arpacell = {arpabet}; % if string, convert to cell array
else, error('Input must be a text string or cell array of strings.')
end

ipa = cell(1,length(arpacell));
for a = 1:length(arpacell)
    switch lower(arpacell{a})
        case 'aa'
            ipa{a} = char(593);
        case 'ae'
            ipa{a} = char(230);
        case 'ah'
            ipa{a} = char(652);
        case 'ao'
            ipa{a} = char(596);
        case 'aw'
            ipa{a} = sprintf('a%s',char(650));
        case 'ax'
            ipa{a} = char(601);
        case 'ay'
            ipa{a} = sprintf('a%s',char(618));
        case 'ey'
            ipa{a} = sprintf('e%s',char(618));
        case 'eh'
            ipa{a} = char(603);
        case 'ih'
            ipa{a} = char(618);
        case 'iy'
            ipa{a} = 'i';
        case 'ow'
            ipa{a} = sprintf('o%s',char(650));
        case 'uw'
            ipa{a} = 'u';
        case 'er'
            ipa{a} = char(602);
        case 'uh'
            ipa{a} = char(650);
        case 'xx'
            ipa{a} = '*';
        case 'os'
            ipa{a} = char(248);
        case 'uu'
            ipa{a} = char(623);
        otherwise
            warning('Input ''%s'' not found in ARPABET list.',arpacell{a});
            ipa{a} = '';
    end

    if brackets
        switch brackets
            case '/'
                ipa{a} = sprintf('/%s/',ipa{a});
            case {'[',']'}
                ipa{a} = sprintf('[%s]',ipa{a});
        end
    end

end

if ischar(arpabet), ipa = ipa{1}; end % if input was string, convert back
