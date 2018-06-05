function [meter] = txt2mtr(txt)
%TXT2IPA   Converts text string to IPA equivalent.

if iscellstr(txt), txtcell = txt;
elseif ischar(txt), txtcell = {txt}; % if string, convert to cell array
else, error('Input must be a text string or cell array of strings.')
end

feet = {'trochee' 'iamb'};

trochee = ismember(txtcell,{'meta' 'beta'}); % added 'a' because this was the original vowel name for this category. Possibly will need to change it if we ever use the indefinite article.
iamb = ismember(txtcell,{'above' 'adept' 'abate'});

stressinds = [trochee; iamb];
stressinds = sum(stressinds .* repmat([1:size(stressinds,1)]',1,size(stressinds,2)),1);
if any(~stressinds)
    notfound = unique(txtcell(~stressinds));
    error('Text ''%s'' not found in stress table. ',notfound{:});
end
meter = feet(stressinds);

if ischar(txt), meter = meter{1}; end % if input was string, convert back
