function [arpa] = txt2arpabet(txt)
%TXT2ARPABET  Convert text string to ARPABET equivalent.
% 
% Note: words are in alphabetical order, with the arpabet vowel as the first member. Please try to maintain this structure
% for organization's sake! RK 2022-07

if iscellstr(txt), txtcell = txt; %#ok<ISCLSTR>
elseif ischar(txt), txtcell = {txt}; % if string, convert to cell array
else, error('Input must be a text string or cell array of strings.')
end

vowels = {'aa' 'ae' 'ah' 'ay' 'eh' 'ey' 'ih' 'iy' 'ow' 'uw' 'er' 'oe' 'ou' 'uh' 'xx', 'os', 'uu'};


aa = ismember(txtcell,{'aa', ...
    'ah' 'a' 'ba' 'bah' 'Bobby' 'bod' 'bot' 'boss' 'buyBobby' 'car' 'carbonate' 'cod' 'copper' 'czar' 'dock' 'gar' 'god' 'ka' 'llama', ...
    'odd' 'pa' 'pot' 'saw' 'shawl' 'shock' 'shop' 'shopper' 'shot' 'sock' 'sod' 'sop' 'ta' 'top'}); % added 'a' because this was the original vowel name for this category. Possibly will need to change it if we ever use the indefinite article.
ae = ismember(txtcell,{'ae',...
    'add', 'ad', 'bad', 'ban', 'bat', 'batA', 'batB', 'black', 'capper', 'cat', 'dad', 'gapper',...
    'pat', 'rad', 'sad', 'sapper', 'sat', 'tapper', 'yallow', 'zapper'});
ah = ismember(txtcell,{'ah', 'above', 'bud', 'buddy', 'buffed', 'bun', 'bus', 'busk', 'bust', 'buyDougie', 'Dougie', 'Duggie', 'muffins', 'musk', 'must', 'puppy',...
    'somebun'});
ay = ismember(txtcell,{'ay', 'bide', 'buy', 'buyYogurt', 'guide', 'idea', 'side', 'sigh', 'shy', 'thigh', 'time', 'thyme'});
eh = ismember(txtcell, {'eh', ... 
    'adept','bed','bedhead', 'bedspread', 'best','bet', 'betty', 'blend', 'breastfed', 'cent','dead','debt','deficit','definite', ...
    'deathbed',  'den', 'des','desk','E','Ed','eff',...
    'fait','fed','get','getBetty','glen','guest','hais','head','headH','headL','headM', 'headrest', 'hen', 'level','meta',...
    'pedestal','pedicure','pedigree','pen','pen a ten','pen-a-ten','pen_a_ten','penitentiary','pet','red', 'redhead', ...
    'said','scent','sekt','sent','set','seven','sever','shed','Ted','ted','ten','yellow'}); 
ey = ismember(txtcell,{'ey' 'abate' 'bayed' 'beta' 'caper' 'eI' 'fei1' 'fei2' 'fei3' 'fei4' 'fei5' 'grain' 'Mary' 'shaper'});
ih = ismember(txtcell,{'ih' 'I' 'bid' 'bin' 'bink' 'bit'  'rid' 'grin' 'yillow' 'pink' 'pit' 'sin' 'sip' 'sipper' 'sit' 'shin' 'ship' 'tipper' 'zipper' 'lion', ...
    'BLACKzipper' 'BLACKsipper' 'BLUEzipper' 'BLUEsipper' 'BIGzipper' 'BIGsipper'});
iy = ismember(txtcell,{'iy', ...
    'bead','bean','bee','bleed','C','creed','deer', 'dear','deal','deem','ease','eat','ee','eep','Eve','green','i','kreen','pea',...
    'reed','scene','sea','seat','see','seep','she','sheep','sheet','Sie','somebean','teal','tear','teem', 'team', 'tier','vee','vie','wie','Wie',...
    'yi1', 'yi2', 'yi12 ding4', 'Yves','zee','Z'});
ow = ismember(txtcell,{'ow' 'o' 'oh' 'blow' 'bode' 'show' 'shore' 'so' 'sore'});
uw = ismember(txtcell,{'uw' 'blue' 'booed' 'boon' 'dude' 'food' 'groom' 'oo' 'plume' 'plue' 'rude' 'sue' 'suit' 'soon' 'shoe' 'shoot' 'shoes' 'u'});
er = ismember(txtcell,{'er' 'bird' 'blur'});
oe = ismember(txtcell,{'oe' 'boese' 'böse' 'neuf' 'oeuf' 'oede' 'öde'});
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
