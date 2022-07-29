function [answer] = askNChoiceQuestion(question,choices,bVisibleOptions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to get an input to a question that will match a (small) set of predetermined responses, e.g. y/n, 1/0, m/f, 1/2/3
% 
% Returns the answer after verifying that it belongs in the set of choices. 
% 
% Inputs: 
%       question                the question you would like to ask. Will also display the possible answers after. 
% 
%       choices                 an array of the possible choices, e.g. {'y' 'n'} [1 2 3]. Defaults to {'y' 'n'}  
% 
%       bVisibleOptions         a binary flag for if you want to show the possible answers in parentheses after. Defaults to 
%                               1 (yes), which is the original behavior. 
% 
%                               Do you want to continue? (y/n) 
%                               vs. 
%                               Do you want to continue?
% 
%                               This is simply for cleaner display of questions if they are formatted as something like "Do
%                               you want to redo or move on?" where the choices are in the question itself, or "Press 1 to
%                               redo, 0 to move on: " 
% 
% 
%
% Initiated 2020-02-28 RPK 
% Added bVisibleOptions flag RPK June 2022
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error

if nargin < 2 || isempty(choices), choices = {'y' 'n'}; end
if nargin < 3 || isempty(bVisibleOptions), bVisibleOptions = 1; end

if iscell(choices)
    choiceListText = [sprintf('%s/', choices{1:end-1}) choices{end}]; 
    if bVisibleOptions
        answer = strip(input([question ' (' choiceListText '): '], 's'));
    else
        answer = strip(input([question ' '], 's'));
    end
    while ~any(strcmp(answer,choices))
        answer = strip(input(['Invalid answer. Please enter ' choiceListText ': '],'s'));
    end
else
    choiceListText = [sprintf('%d/', choices(1:end-1)) num2str(choices(end))]; 
    if bVisibleOptions
        answer = input([question ' (' choiceListText '): ']); 
    else
        answer = input([question ' ']);
    end
    while isempty(answer) || ~any(answer == choices)
        answer = input(['Invalid answer. Please enter ' choiceListText ': ']);
    end
end


end