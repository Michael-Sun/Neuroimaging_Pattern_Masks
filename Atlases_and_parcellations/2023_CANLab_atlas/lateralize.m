function atlas = lateralize(atlas)
    % takes an atlas and reassigns regions to be left or right lateralized 
    % instead of bilateral
    % Assumes all areas are bilateral
    % Assuming R=x+ orientation

    atlas = atlas.replace_empty();

    % make values lateralized
    xyz = atlas.volInfo.mat*[atlas.volInfo.xyzlist'; ones(1,length(atlas.volInfo.xyzlist))];
    atlas.dat(xyz(1,:)' > 0 & atlas.dat ~= 0) = atlas.dat(xyz(1,:)' > 0 & atlas.dat ~= 0) + length(atlas.labels);
    if ~isempty(atlas.probability_maps)
        pmap = atlas.probability_maps;
        pmap(xyz(1,:)' < 0 & atlas.dat ~= 0,:) = 0;
        atlas.probability_maps(xyz(1,:)' > 0 & atlas.dat ~= 0,:) = 0;
        atlas.probability_maps = [atlas.probability_maps, pmap];
    end
    atlas = atlas.remove_empty();
    
    n_labels = length(atlas.labels);
    for i = 1:length(atlas.labels)
        atlas.labels{i + n_labels} = [atlas.labels{i}, '_R'];
        atlas.labels{i} = [atlas.labels{i}, '_L'];
    end 
    fnames = {'label_descriptions','labels_2','labels_3','labels_4','labels_5'};
    for j = 1:length(fnames)
        if ~all(cellfun(@isempty, atlas.(fnames{j})))
            for i = 1:length(atlas.(fnames{j}))
                atlas.(fnames{j}){i + n_labels} = [atlas.(fnames{j}){i}, ' (right)'];
                atlas.(fnames{j}){i} = [atlas.(fnames{j}){i}, ' (left)'];
            end 
        end
    end
end