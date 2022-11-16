function [event_params] = get_event_defaults()

    event_params = struct('event_names', [], ...
        'event_times', [], ...
        'user_event_name_prefix', 'uev',...
        'user_event_times', [],...
        'user_event_names', '',...
        'is_good_trial', 1); 
end