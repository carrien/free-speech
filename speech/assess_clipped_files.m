function [checks] = assess_clipped_files(data)
checks = [];
badsamplens = [];
for i = 1:length(data)
    y = data(i).signalIn;
    if any(y(:) < -1 | y(:) > +1)
        badsamps = 0;
        for z = 1:length(y)
            if (y(z) < -1 | y(z) > +1)
                badsamps = badsamps + 1;
            end
        end
%        sprintf('check trial %d',i)
        badsamplens = [badsamplens badsamps];
        if badsamps > 30
            checks = [checks i];
        end
    end
end

figure;
hist(badsamplens)
ylabel('Number of files')
xlabel('Number of bad samples')

