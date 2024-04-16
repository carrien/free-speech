function [event_times, user_event_names] = get_uev_from_tg(TextGrid)

% grabs PHONE TIER boundaries and labels from textgrids.

nonphon = {'"sil"','"sp"','""'}

% TODO: classify as long or short textgrid and be able to deal with both
% types



text = textread(TextGrid,'%s');

if ismember(text, 'short"') % must include the quotes
    type = 'short'
else
    type = 'long'
end


phonerow = find(ismember(text,'"phones"'));

% find all xmins between phonerow and the end of the tier
xminrows = find(ismember(text,'xmin'));
xminrows = (xminrows(xminrows>phonerow));
xminrows = xminrows(2:end); % first xmin just says where the file begins
start_vals = [str2num(char(text(xminrows + 2)))]';
textrows = find(ismember(text,'text'));
textrows = textrows(textrows>phonerow);
bound_labs = text(textrows+2);

if length(start_vals) ~= length(bound_labs)
    error('start values not equal to number of labels')
end

event_times = zeros(1, length(start_vals));
user_event_names = cell(1, length(bound_labs));

for i = 1:length(start_vals)
    event_times(i) = start_vals(i);
    name_base = [strip(bound_labs{i},'"') '_start'];
    name_base(regexp(name_base,'[0,1,2]'))=[]; % remove any stress info
    user_event_names{i} = name_base;
end



% find all labels between first xmin and end of the tier
