% this script is meant to be invoked by create_CANLab2023_unrestricted.m
% it's only saved separately for readability purposes

switch SCALE
    case 'fine'
        bg = load_atlas(sprintf('tian_3t_s4_%s',ALIAS));
    case 'coarse'
        bg = load_atlas(sprintf('tian_3t_s1_%s',ALIAS));
    otherwise
        error('Unknown scale %s\n', SCALE);
end
bg = bg.resample_space(ref,'nearest');
bg.labels_5 = repmat({'Tian'},1,num_regions(bg));

%% incorporate BST_SLEA into BG and make it lateralized
% we include parts that overlap with acumbens, GP and caudate, but not
% putamen because it's a trivial segment (4vxls) and not worth the mess,
% and not GP because it's a small segment and fragments the ROI which is
% mostly in caudate.

citfile = which(sprintf('CIT168_%s_subcortical_v1.1.0_atlas_object.mat',SPACE));
atlas_obj = load(citfile); atlas_obj = atlas_obj.atlas_obj.resample_space(ref);

BST = atlas_obj.select_atlas_subset(find(contains(atlas_obj.labels,{'BST_SLEA'}))).replace_empty();
BST = lateralize(BST);
BST.labels_5 = repmat({'CIT168'},1,num_regions(BST));

%% Caudate
% some of V_Striatum is in the CIFTI accumben (13%), but most is in the
% CIFTI caudate mask (45.9%). This is a 70-30 split, and it's hard to
% assign it to one over the other like with entorhinal cortex below. We'll
% give it to both.
% We could also include 'Cau' here, but it's very sparse within the CIFTI
% mask regions and is more likely to cause problems down the line than not
% (e.g. selecting it as an ROI for seed based analysis or alignment results
% in a nonsensical fragmented region of caudate), so we drop it.
caud = bg.select_atlas_subset(find(contains(bg.labels,{'CAU'}))).remove_empty();

cifti_mask = fmri_mask_image(cifti_atlas.select_atlas_subset(find(contains(cifti_atlas.labels,'caudate'))));
cifti_mask = cifti_mask.replace_empty();

tic
caud_dil = dilate(caud, cifti_mask);
caud_dil = bg.select_atlas_subset('NAc').apply_mask(cifti_mask).merge_atlases(caud_dil,'noreplace');
caud_dil = BST.apply_mask(cifti_mask).merge_atlases(caud_dil,'noreplace');
toc

%% Putamen
% It's not clear why Caudate_Ca overlaps with the putamen ROI, but it's
% a major hunk, so we include it here.
put = bg.select_atlas_subset(find(contains(bg.labels,{'PUT'}))).remove_empty();
%put = bg.select_atlas_subset(find(contains(bg.labels,{'V_Striatum','Putamen','VeP', 'BST_SLEA'}))).remove_empty();

cifti_mask = fmri_mask_image(cifti_atlas.select_atlas_subset(find(contains(cifti_atlas.labels,'putamen'))));
cifti_mask = cifti_mask.replace_empty();

tic
put_dil = dilate(put, cifti_mask);
toc

% trim dilated left and right margins of putamen to avoid bleedover into insula
for i = 1:5
    put_xyz = put_dil.volInfo.xyzlist;
    trim_x = [min(put_xyz(put_dil.dat > 0,1)), max(put_xyz(put_dil.dat > 0,1))];
    trim_ind = ismember(put_xyz(:,1), trim_x);
    put_dil.probability_maps(trim_ind,:) = 0;
    put_dil = put_dil.probability_maps_to_region_index();
end
% let side looks like it needs more trimming than the right
for i = 1:2
    put_xyz = put_dil.volInfo.xyzlist;
    trim_x = min(put_xyz(put_dil.dat > 0,1));
    trim_ind = ismember(put_xyz(:,1), trim_x);
    put_dil.probability_maps(trim_ind,:) = 0;
    put_dil = put_dil.probability_maps_to_region_index();
end

% add back in any original voxels we'd removed (we only want to trim from
% the newly dilated voxels)
put = put.replace_empty;
put_dil.probability_maps(put.dat > 0,:) = put.probability_maps(put.dat > 0,:);

put_dil = bg.select_atlas_subset('NAc').apply_mask(cifti_mask).merge_atlases(put_dil,'noreplace');
%% Pallidum
pal = bg.select_atlas_subset(find(contains(bg.labels,{'GP'}))).remove_empty();

cifti_mask = fmri_mask_image(cifti_atlas.select_atlas_subset(find(contains(cifti_atlas.labels,'pallidum'))));
cifti_mask = cifti_mask.replace_empty();

tic
pal_dil = dilate(pal, cifti_mask);
toc

%% Accumbens
% We're dropping VeP because it's split across multiple structures (Putamen
% and NAc) and neither has much of it.
accumbens = bg.select_atlas_subset(find(contains(bg.labels,{'NAc'}))).remove_empty();

cifti_mask = fmri_mask_image(cifti_atlas.select_atlas_subset(find(contains(cifti_atlas.labels,'accumbens'))));
cifti_mask = cifti_mask.replace_empty();

tic
accumbens_dil = dilate(accumbens, cifti_mask);
accumbens_dil = BST.apply_mask(cifti_mask).merge_atlases(accumbens_dil,'noreplace');
toc

%% bg atlas
bg_dil = caud_dil.merge_atlases(put_dil).merge_atlases(pal_dil).merge_atlases(accumbens_dil);
% deal with redundant labels
n_labels = length(bg_dil.labels);
uniq_labels = unique(bg_dil.labels);
remove = [];
for i = 1:length(uniq_labels)
    this_lbl = uniq_labels(i);
    this_ind = find(contains(bg_dil.labels, this_lbl));
    for j = 2:length(this_ind)
        bg_dil.dat(bg_dil.dat == this_ind(j)) = this_ind(1);
        remove(end+1) = this_ind(j);
        bg_dil.probability_maps(:,this_ind(1)) = max(bg_dil.probability_maps(:,this_ind),[],2);
    end
end
[~,~,dat] = unique(bg_dil.dat);
bg_dil.dat = dat - 1;
fnames = {'labels','label_descriptions','labels_2','labels_3','labels_4','labels_5'};
for i = 1:length(fnames)
    if length(bg_dil.(fnames{i})) == n_labels
        bg_dil.(fnames{i})(remove) = [];
    end
end
bg_dil.probability_maps(:,remove) = [];
bg_dil.labels_2 = {};
bg_dil.labels_3 = {};
bg_dil.labels_4 = {};