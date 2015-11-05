function [] = comp_cell(cell1,cell2,nlevels)

if nlevels < 1
    return
end

if nlevels == 3
    for i=1:length(cell1)
        for j=1:length(cell1{i})
            for k=1:length(cell1{i}{j})
                beq = isequal(cell1{i}{j}{k},cell2{i}{j}{k});
                if ~beq, fprintf('Arrays #%d,%d,%d are not equal:\n[%s]\nvs\n[%s]\n\n', ...
                        i,j,k,num2str(cell1{i}{j}{k}),num2str(cell2{i}{j}{k})),end
            end
        end
    end
    
elseif nlevels == 2
    for i=1:length(cell1)
        for j=1:length(cell1{i})
            beq = isequal(cell1{i}{j},cell2{i}{j});
            if ~beq, fprintf('Arrays #%d,%d are not equal:\n[%s]\nvs\n[%s]\n\n', ...
                    i,j,num2str(cell1{i}{j}),num2str(cell2{i}{j})),end
        end
    end
end