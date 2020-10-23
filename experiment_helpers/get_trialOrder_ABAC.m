noShift = 3;
shiftUp = 4;
shiftDown = 5;
bankinds.noShift = find(condbank == noShift);
bankinds.shiftUp = find(condbank == shiftUp);
bankinds.shiftDown = find(condbank == shiftDown);

ntrials = length(condbank);
allConds = zeros(1,ntrials);
rp = zeros(1,ntrials);

nInsertions = length(bankinds.noShift) - length(bankinds.shiftUp) - length(bankinds.shiftDown);
insertionPoints = randperm(ntrials);
insertionPoints = insertionPoints(1:nInsertions);

counter = 0;
for t = 1:ntrials
    if ismember(t,insertionPoints)
        allConds(t) = noShift;
        rind = randi(length(bankinds.noShift));
        rp(t) = bankinds.noShift(rind);
        bankinds.noShift(rind) = [];
    else
        if any(counter == [0 2])
            % noShift
            allConds(t) = noShift;
            rind = randi(length(bankinds.noShift));
            rp(t) = bankinds.noShift(rind);
        elseif counter == 1
            % shiftUp
            allConds(t) = shiftUp;
            rind = randi(length(bankinds.shiftUp));
            rp(t) = bankinds.shiftUp(rind);
        elseif counter == 3
            % shiftDown
            allConds(t) = shiftDown;
            rind = randi(length(bankinds.shiftDown));
            rp(t) = bankinds.shiftDown(rind);
        end
        counter = mod(counter + 1,4);
    end
end
