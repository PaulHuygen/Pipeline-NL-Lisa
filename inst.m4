m4_define(m4_version, 0.0.0-01)m4_dnl
m4_define(m4_walltime, 30:00)m4_dnl                             Max duration of jobs
m4_define(m4_extens, naf)m4_dnl                                 Suffix of NAF filenames
m4_define(m4_projroot, m4_esyscmd(pwd))m4_dnl
m4_define(m4_piperoot, /home/phuijgen/nlp/nlpp)m4_dnl           Root of pipeline itself
m4_define(m4_pythonversion, `2.7.9')m4_dnl
m4_define(m4_pythonroot, /home/phuijgen/pythonpackages)m4_dnl
m4_define(m4_GB_per_process, 5)m4_dnl
m4_define(m4_KB_per_process, eval(m4_GB_per_process * 1000000))m4_dnl
m4_define(m4_spotlightmem_GB, 8)m4_dnl
m4_define(m4_stopospool, dppool)m4_dnl
m4_define(m4_min_outfilesize, 1000)m4_dnl                       Smaller outputfiles are considered failures.
m4_changequote(`<!',`!>')m4_dnl
