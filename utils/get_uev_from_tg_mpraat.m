function [user_event_times, user_event_names] = get_uev_from_tg_mpraat(TextGrid)

% uses mpraat and DetectTextGridEncoding to generate event times and labels

[tier,~] = tgRead(TextGrid, 'auto');

ntiers = length(tier.tier);

for i = 1:ntiers
    if strcmp((tier.tier{1,i}.name),'phones')
        phonetier = tier.tier{1,i};
        user_event_times = phonetier.T1;
        labels = phonetier.Label;
        user_event_names = cell(1,length(labels));
        %labels(regexp(labels,'[0,1,2]'))=[]; % remove any stress info % strip stress
        for l = 1:length(labels)
            lab = labels{l};
            lab(regexp(lab,'[0,1,2]'))=[];
            user_event_names{l} = char(lab);
        end
    end
end
