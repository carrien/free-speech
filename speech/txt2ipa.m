function [ipa] = txt2ipa(txt)
%TXT2IPA   Converts text string to IPA equivalent.

if iscellstr(txt), txtcell = txt;
elseif ischar(txt), txtcell = {txt}; % if string, convert to cell array
else error('Input must be a text string or cell array of strings.')
end

vowels = {'aa' 'ae' 'ah' 'eh' 'ey' 'ih' 'iy' 'ow' 'uw' 'er' 'oe'};

aa = ismember(txtcell,{'aa' 'ah' 'a'}); % added 'a' because this was the original vowel name for this category. Possibly will need to change it if we ever use the indefinite article.
ae = ismember(txtcell,{'ae' 'add' 'ad' 'rad'});
ah = ismember(txtcell,{'above'});
eh = ismember(txtcell,{'eh' 'Ed' 'head' 'red' 'glen' 'blend' 'hais' 'eff' 'E' 'adept' 'meta'});
ey = ismember(txtcell,{'grain' 'eI' 'beta' 'abate'});
ih = ismember(txtcell,{'ih' 'I' 'rid' 'grin'});
iy = ismember(txtcell,{'ee' 'eat' 'reed' 'green' 'bleed' 'Yves' 'Eve'});
ow = ismember(txtcell,{'oh' 'blow' 'o'});
uw = ismember(txtcell,{'oo' 'rude' 'groom' 'blue' 'u'});
er = ismember(txtcell,{'er' 'blur'});
oe = ismember(txtcell,{'oeuf'});

vowelinds = [aa; ae; ah; eh; ey; ih; iy; ow; uw; er; oe];
vowelinds = sum(vowelinds .* repmat([1:size(vowelinds,1)]',1,size(vowelinds,2)),1);
if any(~vowelinds)
    notfound = unique(txtcell(~vowelinds));
    error('Text ''%s'' not found in IPA conversion table. ',notfound{:});
end
ipa = vowels(vowelinds);

if ischar(txt), ipa = ipa{1}; end % if input was string, convert back
