## 'input.py', the data input template.  
## This file is a part of the StrAuto-0.3.1 Python program 
## For further information, contact the author
## Vikram Chhatre [crypticlineage (at) tamu.edu]

##Please fill out following information.
## Do not make any changes to the information already existent in this file.
## Simply add information about your data set and the analysis.


##########                         ##########
##########  Questions begin below  ##########
##########                         ##########

## 1. How many populations are you assuming? [Integers]
maxpops = 4

## 2. How many burnin you wish to do before collecting data [Integers]
burnin = 100000

## 3. How long do you wish to collect the data after burnin [Integers]
mcmc = 100000

## 4. Name of your dataset.  Don't remove quotes. No spaces allowed. Exclude the '.str' extension.  
##    e.g. dataset = "sim" if your datafile is called 'sim.str'
dataset = "populations.structure"

## 5. How many runs of Structure do you wish to do for every assumed cluster K? [Integers]
kruns =5

## 6. Number of individuals [Integers]
numind = 106

## 7. Number of loci [Integers]
numloci = 6923

## 8. What is the ploidy [Integers 1 through n]
ploidy = 2

## 9. How is the missing data coded? Write inside quotes. e.g. missing = "-9"
missing = "0"

## 10. Does the data file contain every individual on 2 lines (0) or 1 line (1). [Boolean]
onerowperind = 0 

## 11. Do the individuals have labels in the data file?  [Boolean]
label = True

## 12. Are populations identified in the data file? [Boolean]
popdata =  True

## 13. Do you wish to set the popflag parameter? [Boolean]
popflag = False

## 14. Does the data file contain location identifiers (Not the same as population identifier) [Boolean]
locdata = False

## 15. Does the data file contain phenotypic information? [Boolean]
pheno = False

## 16. Does the data file contain any extra columns before the genotype data begins? [Boolean]
extracols = False

## 17. Does the data file contain a row of marker names at the top? [Boolean]
markers = True

## 18. Are you using dominant markers such as AFLP? [Boolean]
dominant = False

## 19. Does the data file contain information on map locations for individual markers? [Boolean]
mapdist = False

## 20. Is the data in correct phase? [Boolean]
phase = False

## 21. Is the phase information provided in the data? [Boolean]
phaseinfo = False

## 22. Does the phase follow markov chain? [Boolean]
markov = False

## 23. Do you have access to multiple cores? [Boolean]
##     TO USE THIS YOU MUST HAVE GNU Parallel installed
parallel = True

## 24. What percentage of the cores would you like to use [Integer]: eg. 90
##     Used only if parallel = True
percentCores = 65

########## End of questions ##########
########## Please do not write any other information in this file ###########
