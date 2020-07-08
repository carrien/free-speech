function gender = get_gender(gender)

if nargin < 1, gender = []; end

if ~any(strcmp(gender,{'male','female'}))
    gender = input('Enter participant gender (m/f): ', 's');
    while ~any(strcmp(gender,{'m','f'}))
        gender = input('Invalid gender. Please enter m/f: ','s');
    end
    if strcmp(gender, 'm')
        gender = 'male';
    elseif strcmp(gender, 'f')
        gender = 'female';
    end
end