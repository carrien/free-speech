function [answer] = askNChoiceQuestion(question,choices,bVisibleOptions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to get an input to a question that will match a (small) set of predetermined responses, e.g. y/n, 1/0, m/f, 1/2/3
% 
% Returns the answer after verifying that it belongs in the set of choices. 
%
% question: the question you would like to ask. Will also display the possible answers after. 
% choices: an array of the possible choices, e.g. {'y' 'n'} [1 0]. If empty, will be assumed to be y/n. 
%
% Initiated 2020-02-28 RPK 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error

if nargin < 2 || isempty(choices), choices = {'y' 'n'}; end
if nargin < 3 || isempty(bVisibleOptions), bVisibleOptions = 1; end

if iscell(choices)
    if bVisibleOptions
        answer = strip(input([question ' (' sprintf('%s/', choices{1:end-1}) choices{end} '): '], 's'));
    else
        answer = strip(input([question ' '], 's'));
    end
    while ~any(strcmp(answer,choices))
        answer = strip(input(['Invalid answer. Please enter ' sprintf('%s/', choices{1:end-1}) choices{end} ': '],'s'));
    end
else
    if bVisibleOptions
        answer = input([question ' (' sprintf('%d/', choices(1:end-1)) num2str(choices(end)) '): ']); 
    else
        answer = input([question ' ']);
    end
    while isempty(answer) || ~any(answer == choices)
        answer = input(['Invalid answer. Please enter ' sprintf('%d/', choices(1:end-1)) num2str(choices(end)) ': ']);
    end
end


end