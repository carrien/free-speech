function gender = get_height(heightResponse)
%get_gender -> get_height
%VTL increases with height over a large range of heights, 
%good to not put assuming a participants gender on individual running the experiment. 

if nargin < 1, heightResponse = []; end

if ~any(strcmp(heightResponse,{'y','n'}))
    heightResponse = input("Does the participant appear to be above the height 5' 8''? (y/n): ", 's');
    while ~any(strcmp(heightResponse,{'y','n'}))
        heightResponse = input('Invalid response. Please enter y/n: ','s');
    end
    
    if strcmp(heightResponse, 'y')
        gender = get_gender('male');
    elseif strcmp(heightResponse, 'n')
        gender = get_gender('female');
    end
    
end

end