function [arpa] = txt2arpabet(txt)
%TXT2ARPABET  Convert text string to ARPABET equivalent.

if iscellstr(txt), txtcell = txt; %#ok<ISCLSTR>
elseif ischar(txt), txtcell = {txt}; % if string, convert to cell array
else, error('Input must be a text string or cell array of strings.')
end

vowels = {'aa' 'ae' 'ah' 'ay' 'eh' 'ey' 'ih' 'iy' 'ow' 'uw' 'er' 'oe' 'ou' 'uh' 'xx', 'os', 'uu'};

aa = ismember(txtcell,{'aa' 'ah' 'a' 'bod' 'sop' 'sock' 'sod' 'shop' 'shock' 'shot' 'shawl' 'saw' 'car' 'gar' 'czar' 'cod' 'god' 'odd' 'copper' 'shopper' 'carbonate'}); % added 'a' because this was the original vowel name for this category. Possibly will need to change it if we ever use the indefinite article.
ae = ismember(txtcell,{'ae' 'add' 'ad' 'bad' 'bat' 'dad' 'pat' 'rad' 'sad' 'sat' 'yallow' 'capper' 'gapper' 'sapper' 'tapper' 'zapper'});
ah = ismember(txtcell,{'ah' 'above' 'bud'});
ay = ismember(txtcell,{'ay' 'bide' 'idea' 'side' 'sigh' 'shy' });
eh = ismember(txtcell,{'eh' 'E' 'Ed' 'bed' 'bet' 'blend' 'dead' 'des' 'desk' 'debt' 'fed' 'head' 'ted' 'red' 'glen'  'hais' 'eff' 'fait' 'adept' 'meta' 'pet' 'sekt' 'set' 'said' 'shed' 'Ted' 'yellow' 'bedhead','pedestal','pedicure','pedigree'});
ey = ismember(txtcell,{'ey' 'eI' 'grain' 'beta' 'abate' 'bayed' 'shaper' 'caper' 'fei1' 'fei2' 'fei3' 'fei4' 'fei5'});
ih = ismember(txtcell,{'ih' 'I' 'bit' 'bid' 'bink' 'rid' 'grin' 'yillow' 'pink' 'pit' 'sip' 'sin' 'sit' 'shin' 'ship' 'tipper' 'sipper' 'zipper'});
iy = ismember(txtcell,{'iy' 'i' 'bead' 'ee' 'eat' 'reed' 'green' 'bleed' 'creed' 'kreen' 'Yves' 'Eve' 'see' 'seep' 'seat' 'sea' 'sheep' 'sheet' 'she' 'Sie' 'vee' 'vie' 'Wie' 'wie' 'Z' 'C' 'zee' 'ease'});
ow = ismember(txtcell,{'ow' 'o' 'oh' 'blow' 'bode' 'so' 'sore' 'show' 'shore'});
uw = ismember(txtcell,{'uw' 'u' 'booed' 'oo' 'rude' 'groom' 'blue' 'plume' 'plue' 'sue' 'suit' 'soon' 'shoe' 'shoot' 'shoes'});
er = ismember(txtcell,{'er' 'blur' 'bird'});
oe = ismember(txtcell,{'oe' 'oeuf' 'neuf' 'öde' 'oede' 'böse' 'boese'});
ou = ismember(txtcell,{'ceux'});
uh = ismember(txtcell,{'uh' 'good' 'hood'});
xx = ismember(txtcell,{'xx' '*' '**' '***'});
os = ismember(txtcell,{'os'});
uu = ismember(txtcell,{'uu'});

vowelinds = [aa; ae; ah; ay; eh; ey; ih; iy; ow; uw; er; oe; ou; uh; xx; os; uu;];
vowelinds = sum(vowelinds .* repmat([1:size(vowelinds,1)]',1,size(vowelinds,2)),1); %#ok<NBRAK>
if any(~vowelinds)
    notfound = unique(txtcell(~vowelinds));
    error('Text ''%s'' not found in Arpabet conversion table. ',notfound{:});
end
arpa = vowels(vowelinds);

if ischar(txt), arpa = arpa{1}; end % if input was string, convert back
