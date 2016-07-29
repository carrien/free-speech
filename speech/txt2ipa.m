function [ipa] = txt2ipa(txt)
%TXT2IPA   Converts text string to IPA equivalent.

if iscellstr(txt), txtcell = txt;
elseif ischar(txt), txtcell = {txt}; % if string, convert to cell array
else error('Input must be a text string or cell array of strings.')
end

vowels = {'a' 'ae' 'E' 'eI' 'I' 'i' 'o' 'u' 'er'};

a = ismember(txtcell,{'aa' 'ah'});
ae = ismember(txtcell,{'ae' 'add' 'ad' 'rad'});
E = ismember(txtcell,{'eh' 'Ed' 'head' 'red' 'glen' 'blend'});
eI = ismember(txtcell,{'grain'});
I = ismember(txtcell,{'ih' 'I' 'rid' 'grin'});
i = ismember(txtcell,{'ee' 'eat' 'reed' 'green' 'bleed'});
o = ismember(txtcell,{'oh' 'blow'});
u = ismember(txtcell,{'oo' 'rude' 'groom' 'blue'});
er = ismember(txtcell,{'er' 'blur'});

vowelinds = [a; ae; E; eI; I; i; o; u; er];
vowelinds = sum(vowelinds .* repmat([1:size(vowelinds,1)]',1,size(vowelinds,2)),1);
if any(~vowelinds)
    notfound = unique(txtcell(~vowelinds));
    error('Text ''%s'' not found in IPA conversion table. ',notfound{:});
end
ipa = vowels(vowelinds);

if ischar(txt), ipa = ipa{1}; end % if input was string, convert back
