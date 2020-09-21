run('localPathDefinition.m')
%-----------------------------------------------------------------------
% Job saved on 27-Jul-2020 11:47:13 by cfg_util (rev $Rev: 6460 $)
% spm SPM - SPM12 (6470)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.source = {'PATH_TO_SUMMED_PERFUSION_PET,1'};
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
%%
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.resample = {
                                                           LIST_OUTPUT_FILES
                                                           };
%%
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.template = {[perfusionPETTemplate ',1']};
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 8;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smoref = 0;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.bb = [-78 -112 -70
                                                         78 76 85];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.vox = [2 2 2];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.interp = 4;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w';
