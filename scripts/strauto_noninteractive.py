#!/usr/bin/env python
#########################################################
##              StrAuto Version 0.3.1                  ##
##     A Python program to aid in the automation of    ##
##       STRUCTURE Program (Pritchard et al)           ##
##              Vikram E. Chhatre                      ##  
##             Texas A&M University                    ##  
##         crypticlineage (at) gmail.com               ##   
#########################################################

## Import libraries we will need.  List subject to update
import os, sys, stat, time, textwrap

## Clear screen function
def cls():
    if os.name == "nt":
        os.system("cls")
    else:
        os.system("clear")

cls()

## Function kfolders to print correct number of folders in the shell script.
def kfoldersf():
  mystr = ''.join("mkdir k{}\n".format(x) for x in xrange(1, maxpops+1))
  return mystr

## Function to print names of folders to be moved around through shell script.
def mvfolders():
  mvfold = ''.join("k{} ".format(y) for y in xrange(1, maxpops+1))
  return mvfold 

## Import all the variables from the input.py file
from input import *

## Opening the file named mainparams
target = open("mainparams", 'w')

## Writing to mainparams
### First the basic parameters
target.write("Basic program parameters\n")
target.write("#define MAXPOPS \t %d\n" % maxpops)
target.write("#define BURNIN  \t %d\n" % burnin)
target.write("#define NUMREPS \t %d\n\n" % mcmc)

### Input file info
target.write("Input file\n")
target.write("#define INFILE \t %s" % dataset +".str\n\n")

### Data information
target.write("Data file format\n")
target.write("#define NUMINDS \t %d\n" % numind)
target.write("#define NUMLOCI \t %d\n" % numloci)
target.write("#define PLOIDY  \t %d\n" % ploidy)
target.write("#define MISSING \t %s\n" % missing)
target.write("#define ONEROWPERIND \t %d\n\n" % onerowperind)
target.write("#define LABEL   \t %d\n" % label)
target.write("#define POPDATA \t %d\n" % popdata)
target.write("#define POPFLAG \t %d\n" % popflag)
target.write("#define LOCDATA \t %d\n" % locdata)
target.write("#define PHENOTYPE \t %d\n" % pheno)
target.write("#define EXTRACOLS \t %d\n" % extracols)
target.write("#define MARKERNAMES \t %d\n" % markers)
target.write("#define RECESSIVEALLELES \t %d\n" % dominant)
target.write("#define MAPDISTANCES \t %d\n\n" % mapdist)

target.write("Advanced data file options\n")
target.write("#define PHASED    \t %d\n" % phase) 
target.write("#define MARKOVPHASE \t %d\n" % markov)
target.write("#define NOTAMBIGUOUS \t -999 \n\n")

## Close the file 'mainparams'
target.close()

### Now working with the 'runstructure' shell script
## Create runstructure script and call it 'runstr'
runstr = open("runstructure", 'w')

## Print info about the script
runstr.write("#!/bin/sh \n")

## Create directory structure
runstr.write("mkdir results_f log harvester\n") 
runstr.write(kfoldersf())
runstr.write("\n")
runstr.write("cd log\n")
runstr.write(kfoldersf())
runstr.write("\n")
runstr.write("cd ..\n\n")

######
###### Code added and modified by Kevin Emerson 14 Mar 2013
######

# This bit will run strauto as previously implemented (all commands in one bash script)
# if parallel = False.  If parallel = True, a new file called structureCommands will be 
# created with only those indidividual calls to the structure program included.  The bash
# script runstructure will then read all of those individual commands and pass them through
# GNU parallel (which needs to be installed for this to work).  This may not be the most efficient
# or pretty code, but it gets the job done.  Runnings jobs like this through parallel seems to be 
# a quite efficient way to run parallel jobs.

# For this to work, two new variables were defined in input.py (parallel - boolean, percentCores-Integer)
# which are used below.  If parallel = False, the value of percentCores is ignored.

if parallel:
    runstr.write("cat structureCommands | parallel -j {}%\n\n".format(percentCores))

    structureCommands = open('structureCommands', 'w')
    for myK in xrange(1, maxpops+1):
        for run in xrange(1, kruns+1):
            structureCommands.write("structure -K %d -m mainparams -o k%d/%s_k%d_run%d 2>&1 | tee log/k%d/%s_k%d_run%d.log" % (myK, myK, dataset, myK, run, myK, dataset, myK, run))
            structureCommands.write("\n")
    structureCommands.close()
else:
## For loop to iteratively write for all K's and all runs for each K
    for myK in xrange(1, maxpops+1):
        for run in xrange(1, kruns+1):
            runstr.write("structure -K %d -m mainparams -o k%d/%s_k%d_run%d 2>&1 | tee log/k%d/%s_k%d_run%d.log" % (myK, myK, dataset, myK, run, myK, dataset, myK, run))
            runstr.write("\n")

## This code is used to move files/folders around after STRUCTURE analysis finishes
runstr.write("mv %s results_f/\n" %mvfolders())
runstr.write("cd results_f/\n")
runstr.write("cp k*/*_f . && zip %s_Harvester-Upload.zip *_f && rm *_f\n" %dataset)
runstr.write("mv %s_Harvester-Upload.zip ../harvester/\n" %dataset)
runstr.write("cd ..\n")
runstr.write("echo 'Your structure run has finished.'\n")
runstr.write("echo 'Zip archive: %s_Harvester-Upload.zip is ready.'\n" %dataset)

## Close 'runstructure' script and assign rwx permissions to it                
runstr.close()
os.chmod("runstructure", 0755)

exit(0)
