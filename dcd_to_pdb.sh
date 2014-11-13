#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 [DCD_file] [PSF_file] [stride]"
    exit
fi

################################
#  Settings from command-line  #
################################

DCD_file=$1
PSF_file=$2
stride=$3

######################
#  Derived settings  #
######################

DCD_filename=$(basename "$DCD_file")
DCD_filename_noext="${DCD_file%.*}"

output_prefix=${DCD_filename_noext}"-"${stride}
PDB_traj=${output_prefix}".pdb"
temp=${output_prefix}".temp.pdb"

###########################
#  Check DCD file exists  #
###########################

if [ -f $DCD_file ]; then
    true
else
    echo "No such file $DCD_file. Exiting."
    exit
fi

###########################
#  Check file extensions  #
###########################

if [[ $DCD_filename != *.dcd ]]; then
    echo "DCD file should have .dcd extension."
    exit
fi

if [[ $PSF_file != *.psf ]]; then
    echo "PSF file should have .psf extension."
    exit
fi

#############################
#  Use catdcd to make PDBs  #
#############################

echo "Converting DCD file to PDB file."
echo catdcd -o ${PDB_traj} -otype pdb -stride ${stride} -stype psf -s ${PSF_file} ${DCD_file}
catdcd -o ${PDB_traj} -otype pdb -stride ${stride} -stype psf -s ${PSF_file} ${DCD_file}

############################
#  Fix up PDBs with regex  #
############################

echo "Using regex to fix the PDB trajectory file."
cat ${PDB_traj} | perl -pe 's{^[^A].*$}{$n=$n+1; "ENDMDL\nMODEL     $n"}e' | sed 1d | sed '$d' >$temp
cat $temp | perl -pe 's/(ATOM +\d+)    [41]/\1  N  /' | perl -pe 's/(ATOM +\d+)    2/\1  CA /' | perl -pe 's/(ATOM +\d+)    3/\1  C  /' | perl -pe 's/(ATOM +\d+) +\d+ +(\w)/\1  \2SC \2/' >${PDB_traj}
rm -f $temp
