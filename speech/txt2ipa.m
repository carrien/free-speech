function [ipa] = txt2ipa(txt)
%TXT2IPA   Converts text string to IPA equivalent.

if iscellstr(txt), txtcell = txt;
elseif ischar(txt), txtcell = {txt}; % if string, convert to cell array
else, error('Input must be a text string or cell array of strings.')
end

vowels = {'aa' 'ae' 'ah' 'ay' 'eh' 'ey' 'ih' 'iy' 'ow' 'uw' 'er' 'oe' 'ou' 'uh' 'xx', 'os', 'uu'};

aa = ismember(txtcell,{'aa' 'ah' 'a' 'bod' 'sop' 'sock' 'sod' 'shop' 'shock' 'shot' 'shawl' 'saw' 'car' 'gar' 'czar'}); % added 'a' because this was the original vowel name for this category. Possibly will need to change it if we ever use the indefinite article.
ae = ismember(txtcell,{'ae' 'add' 'ad' 'bad' 'bat' 'dad' 'pat' 'rad' 'sad' 'sat' 'yallow'});
ah = ismember(txtcell,{'ah' 'above' 'bud'});
ay = ismember(txtcell,{'ay' 'sigh' 'shy'});
eh = ismember(txtcell,{'eh' 'E' 'Ed' 'bed' 'bet' 'blend' 'dead' 'fed' 'head' 'ted' 'red' 'glen'  'hais' 'eff' 'fait' 'adept' 'meta' 'pet' 'set' 'said' 'yellow'});
ey = ismember(txtcell,{'ey' 'eI' 'grain' 'beta' 'abate'});
ih = ismember(txtcell,{'ih' 'I' 'bit' 'bid' 'bink' 'rid' 'grin' 'yillow' 'pink' 'pit' 'sip' 'sin' 'sit' 'shin' 'ship'});
iy = ismember(txtcell,{'iy' 'i' 'bead' 'ee' 'eat' 'reed' 'green' 'bleed' 'creed' 'kreen' 'Yves' 'Eve' 'see' 'seep' 'seat' 'sea' 'sheep' 'sheet' 'she' 'vee' 'vie'});
ow = ismember(txtcell,{'ow' 'o' 'oh' 'blow' 'bode' 'so' 'sore' 'show' 'shore'});
uw = ismember(txtcell,{'uw' 'u' 'booed' 'oo' 'rude' 'groom' 'blue' 'plume' 'plue' 'sue' 'suit' 'soon' 'shoe' 'shoot' 'shoes'});
er = ismember(txtcell,{'er' 'blur'});
oe = ismember(txtcell,{'oe' 'oeuf' 'neuf'});
ou = ismember(txtcell,{'ceux'});
uh = ismember(txtcell,{'uh' 'good'});
uu = ismember(txtcell,{'uu'});
xx = ismember(txtcell,{'xx' '*' '**' '***'});
os = ismember(txtcell,{'os'});
uu = ismember(txtcell,{'uu'});

vowelinds = [aa; ae; ah; ay; eh; ey; ih; iy; ow; uw; er; oe; ou; uh; xx; os; uu;];
vowelinds = sum(vowelinds .* repmat([1:size(vowelinds,1)]',1,size(vowelinds,2)),1);
if any(~vowelinds)
    notfound = unique(txtcell(~vowelinds));
    error('Text ''%s'' not found in IPA conversion table. ',notfound{:});
end
ipa = vowels(vowelinds);

if ischar(txt), ipa = ipa{1}; end % if input was string, convert back
