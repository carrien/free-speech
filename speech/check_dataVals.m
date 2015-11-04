function [ ] = check_dataVals(dataVals)
%CHECK_DATAVALS  Plot f0,f1,f2 traces from dataVals to check for errors.

colors = {'r' 'g' 'b'};

% plot f0
figure;
for i=1:length(dataVals)
    plot(dataVals(i).f0,colors{dataVals(i).cond});
    hold on;
end

% plot f1
figure;
for i=1:length(dataVals)
    plot(dataVals(i).f1,colors{dataVals(i).vowel});
    hold on;
end

% plot f2
figure;
for i=1:length(dataVals)
    plot(dataVals(i).f2,colors{dataVals(i).vowel});
    hold on;
end

