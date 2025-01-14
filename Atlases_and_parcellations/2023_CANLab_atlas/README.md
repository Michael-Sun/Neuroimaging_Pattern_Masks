## Overview

This is a full brain atlas mashup. It draws from the following,
* Cortex: HCP Multimodal Parcellation (Glasser et al.)
* Thalamus: cytoarchitecture (Morel)
* Basal Ganglia: Functional gradients (Tian)
* Hippocampal formation: cytoarchitecture (Julitch)
* Cerebellum: Deidrichsen
* Brainstem: Multimodal gray matter parcellation (Bianciardi, Restricted)
* Brainstem: resting state gross parcellation (Shen)
* Additional subthalamic and brainstem nuclei: CIT168

There were two goals which motivated atlas construction. In order of priority
* Provide a probablistic spatial reference for functional localization in multiple references spaces
* Provide parcels for automated full brain parcelwise analysis
The first requires a higher level of spatial detail than the second, so a fine scale and coarse scale version of 
the atlas are provided to facilitate both goals. The coarse atlas is designed for applications that need some slack, 
and differs from the fine atlas in the following ways.
* fine thalamic parcels are merged into larger subdivisions in the coarse atlas
* basal ganglia are only subdivided up to the first "watershed" rather than fourth. The watersheds correspond to 
  peaks in functional gradients, and the first watersheds are more pronounced than subsequent nested levels.
* bianciardi atlas is coarse version rather than fine. Bianciardi offers a nested subdivision of the coarse atlas
  which includes subnuclei, while the coarse version does not take things as far. Aadditionally the coarse CANLab2023
  has bianciardi voxel probabilities increased to be given priority over surrounding (mostly white matter) Shen parcels. 
  This results in wider boundaries which are still informed by the original parcellation data.

These atlases are available in multiple spaces. The projection from one space to another differs depending on
the nature of the underlying data. See section below for details.
* MNI152NLin2009cAsym (fmriprep)
* MNI152NLin6Asym (fsl)
* LAS MNI152NLin2009cAsym (qsiprep)
* HCP Grayordinate


## SETUP

Due to the restrictive usage license put forth by the Bianciardi atlas (see usage restrictions below) CANLab2023 
cannot be distributed directly. Instead, we distribute a partial atlas which includes the entire atlas less the
bianciardi parcels and each user must assemble the remainder locally. In theory the abridged atlases could be used
too, but code to automate the construction process is provided.

Run setup.m to construct all the necessary files. You will need an internet connection. Your PC should also ideally
have at least 32G of memory and disk space, since the uncompressed probability maps are quite large. Once assembled,
the atlas files only take up a couple hundred MB. If you fail to do this it will also be done automatically when
you invoke load_atlas() to get the CanlabCore atlas object in matlab (see Usage below), but this script is the only
way to get the qsiprep and HCP grayordinate versions of the atlas.



## Usage

Most use is anticipated to be for analysis of functional data preprocessed by fmriprep data, in which case you
can load a useful version of the atlas like so,

canlab2023 = load_atlas('canlab2023_coarse_fmriprep20_2mm').threshold(0.2);

See "help load_atlas" in matlab for details (make sure CanlabCore is in your path).

### Bespoke applications

Although versions of this atlas have been provided that should be useful to most users most of the time if you have
exacting applications you may want generate atlases specific to your data and usage intentions. For localization purposes
probability maps are helpful, but if hard borders are desired probablistic thresholding and parcel defragmentation
may be desired. This can be accomplished using the atlas/threshold function. If you 
have specific data you intend to use this atlas with it may also make sense to resample it to your target space before 
thresholding. Presumably your data is already in alignment with the desired MNI template, but may be resampled to a 
different resolution, origin or orientation. You can potentially resample this atlas to a new space like so,

canlab = fmri_data(<path totemplate>)
canlab = load_atlas('canlab2023_coarse_fmriprep20'); % replace with desired parcellation and fsl6 version if appropriate
canlab = canlab.resample_space(template_2mm);
canlab = canlab.threshold(0.2); % adjust parameters as desired

Parcel defragmentation in particular may take some time. You may want to save the result for reuse. Saving and
reloading can be done like so,

save(<path>, 'canlab');
load(<path>, 'canlab');

Small regions will be severely affected by partial volume effects during resampling. In particular the brainstem. Your
best bet is to regenerate brainstem nuclei from source using the scripts in the 2023_Bianciardi* sister folder to this
directory and incorporate you target space into a custom apply_spm_warps.m script, similar to the existing one in the
templates/transforms/code folder. The idea is to accomplish all transformations, including your own resampling, in a
single step to avoid compounding partial volume erors across interpolations. This will probably require some substantial
engineering on your part to achieve, but to put these into perspective, this atlas took 3-4 weeks of dedicated work to 
assemble. It is likely worthwhile to build off of it rather than starting from scratch even if it takes a day or two of 
work.

### Grayordinates

The CIFTI files are not designed for use with CANLab tools, which as of this time does not support CIFTI formated
data. They can be used with connectome workbench or other toolboxes though. Run the setup scripts to generate them 
(see SETUP section above).

### QSIPrep

QSIprep is to DWI analysis what fMRIPrep is to fMRI analysis and some. Whereas fMRIprep only performs preprocessing, QSIPrep also performs what might be a the DWI analog of a first level analysis in the sense that its qsirecon workflows automated common aspects of post-preprocessing analysis. In the case of tractography, the question of interest is what regions are connected to what other regions. The regions are defined by atlas files. Several default atlases are provided with qsiprep, but none are more detailed or exhaustive than the CANLab atlas. Thankfully qsiprep allows for use of custom atlases if appropriately formatted and accompanied by the necessary metadata (specified in a json file). To use the CANLab 2023 atlas with qsiprep you need to pass a path to a directory containing the atlas and its atlas_config.json file in during the QSIprep run. If running qsiprep in a singularity container you do this by mounting this folder at a particular location within the virtual environment by using the --bind <full_atlas_directory_path>:/atlas/qsirecon_atlases. For use without a singularity container refer to the QSIprep docs,
https://qsiprep.readthedocs.io/en/latest/reconstruction.html

For the most basic usage (e.g. you only want to use the CANLab 2023 atlas in your qsirecon pipelines, and no other atlases) you can simply mount this directory in your singularity container after running the setup script (see SETUP above). You will only need to manually configure anything if you want to use your own custom atlases or use custom atlases in combination with qsiprep stock atlases. This will require merging the atlas_config.json with the stock atlas_config.json file to combine multiple atlases into a single reconstruction workflow. You will need the stock qsiprep atlases' files. They're linked to in the qsiprep docs, but for your convenience they can be found here,
https://upenn.box.com/shared/static/8k17yt2rfeqm3emzol5sa0j9fh3dhs0i.xz

### Usage Restrictions

The bianciardi atlas used for brain stem nuclear parcels is covered by a restrictive usage license. Specifically,
we are not allowed to redistribute it or any other derivative of this atlas. Consequently, we cannot distibute
the full CANLab2023 either. Instead we download the necessary bianciardi atlas files from their authorized
distributor on demand and assemble requested derivative atlases automatically. There is also a .gitignore file
in the relevant folders to prevent reupload of derivative files. The load_atlas() command will automatically
start this process for whichever atlas you try to load first, but qsiprep and HCP grayordinate atlases do not
have a matlab interface, so instead follow the instructions in the SETUP section.


## Mappings between spaces

Source parcellations are generally in idiosyncratic spaces and most needed to be projected into a new space for
any particlar space of interest. The following projections were used:

Registration fusion using fmriprep output to project labels from fsaverage space into MNI space.
* Glasser parcelation. See README in 2016_Glasser* sister folder of this one for details

Nonlinear registrations of MNI152NLin6Asym to MNI152NLin2009cAsym using ANTs SyN. Inverse transform was estimated and 
used for the MNI152NLin2009cAsym to MNI152NLin6Asym alignment. Some of the source atlases exclusively contained
subcortical structures, in which case a subcortical weighting mask was used when transformations were computed. Full
brain alignments were estimated using fmriprep 20.2.3 with cortical reconstruction enabled. Subcortically weighted
alignments were run using a similar ANTs parameterization as fmriprep's, but with a subcortical mask for the cost 
function. The details of this alignment are documented in templates/transforms/code/subctx_alignment.sh.
* Hippocampal formation (full brain) Julithc atlas
* Basal Ganglia (subcortically weighted alignment)
* Thalamus (subcortically weighted alignment)
* Bianciardi brainstem parcels (subcortically weighted alignment)
* HCP grayordinate volumetric mask (subcortically weighted alignment)

Nonlinear registration of MNIColin27v1998 to MNI152NLin2009cAsym and MNI152NLin6Asym using ANTs SyN and implemented
by fmriprep with surface reconstruction enabled.
* Shen

CIT was already available in all desired spaces and was not transformed.

Alignments used linear interpolation of probability maps when available, or nearest neighbor interpolation otherwise.

For details regarding any particular regions transformation you should refer to the README file in that atlases 
directory in this repo. All transformations used are in the templates/transforms folder. They are available in
multiple formats for use with ANTs, FSL and SPM but were all computed using ANTs.


## Parcel Probabilities

Fine atlas:
* Cortex: likelihood a voxel will be circumscribed by a label in surface space, based on registration fusion
* Basal Ganglia: No likelihoods. These exist, but the authors have not shared them. They're not opposed, but busy. 
May be worth trying to bug them about it periodically. Values given (0.8 I think) were asigned arbitrarily by me for the
time being.
* MTL, Brainstem nuclei, CIT regions and cerebellum: Probablistic likelihoods that a labeled region was found in a participant 
at a particular voxel after alignment to standard space. Sample sizes are small, so don't expect them to be well
calibrated.
* Thalamus: bogus values I assigned since there weren't any natively
* Brainstem background regions (shen parcels): bogus values I asigned to be 0.35 to provide minimal constraints on nuclear
parcel boundaries. 

Coarse atlas:
Same as the above except that brainstem nuclei had probabilities scaled to range from 0.351 to 1, so that they would
receive their maximal boundary extent instead of being outcompeted by the background Shen regions.


## CANLab2018 Comparison

This atlas was created as a drop in replacement for CANLab2018. Taken individually the differences are relatively 
minor but extensive, and all together represent a substantial change. Differences are as follows
* Internally consistent grayordinate and volume formated versions available in register with multiple standard templates
* Probablistic cortical parcels obtained through registration fusion
* Removal of redundant Glasser cortical hippocampal segmentation. It doesn't comprehensively cover the hippocampal volume and intersects comprehensive cytoarchitectonic atlases.
* Different basal ganglia segmentation which better respects gross anatomical subdivisions
* New brainstem nuclear segmentation that is substantially more accurate and probablistic
* Correction of misalignments of MTL (severe), thalamus (severe), brainstem and cerebellum.
* (mostly) Probablistic (exceptions: basal ganglia, thalamus and some brainstem regions)
* no RVM or trigeminal analog. The canlab2018 areas were not credible when compared against Duvernoy's Atlas (which is the
authoritative reference), so they were not carried over. Most other brainstem regions have analogs here, although potentially
under a different name (for instance the dorsal motor nucleus of the vagus, or DMNX, is not the viscero-sensory-motor nuclei,
or VSM).

## Methods


## Parcel Discussion

Many of the parcels available here are quite small. In many cases you shouldn't consider their localization authoritative.
Take small brianstem nuclei or thalamic parcels for instance. It would be inappropriate to conclude involvement of a structure
based solely on whether or not your data overlaps said structure in this atlas. Even taking the probability maps into account 
you may want to take localization with a grain of salt and use multiple methods to establish the identity of a region. This atlas is best used in a blind and dumb fashion at coarse scale, or alternatively at a fine grained level as a rough guide 
indicating possible structural associations rather than definitive ones. Despite substantial effort devoted to alignment the
templates used by the source datasets for generating many of these atlases are intrinsically limited. For instance, the
MNI152NLin6Asym template used by the bianciardi atlas natively is exclusively a T1 template, but many of the structures
in question have minimal to no T1w contrast. This leaves few landmarks for ANTs to exploit when computing mappings between
structures. Additionally, the parcellation provided here, particularly for the brainstem, is incomplete. Other regions
not yet included may be involved, which if involved might have a much more probable boundary for a region than any yet
included here. For instance, we don't have an RVM or a trigeminal nucleus in this parcellation, but they certainly exist. 


## References
