#!/usr/bin/env python
"""@author Sebastien E. Bourban, Noemie Durand and Alain Weisgerber
"""
"""@note ... this work is based on a collaborative effort between
  .________.                                                          ,--.
  |        |                                                      .  (  (
  |,-.    /   HR Wallingford                EDF - LNHE           / \_ \_/ .--.
  /   \  /    Howbery Park,                 6, quai Watier       \   )   /_   )
   ,.  `'     Wallingford, Oxfordshire      78401 Cedex           `-'_  __ `--
  /  \   /    OX10 8BA, United Kingdom      Chatou, France        __/ \ \ `.
 /    `-'|    www.hrwallingford.com         innovation.edf.com   |    )  )  )
!________!                                                        `--'   `--
"""
"""@history 10/03/2011 -- Chris Cawthorn
      Amended to enable listing file in addition to output to stdout.
      Use of multi-threads.
"""
"""@history 04/04/2011 -- Sebastien E. Bourban
         Correction for POSTEL3D Use of key 'MULTI' for output file
         recollection.
"""
"""@history 05/04/2011 -- Sebastien E. Bourban
         Correction, adding an empty line at the end of all ASCII files
         (bug reported with CONFIG).
"""
"""@history 05/04/2011 -- Sebastien E. Bourban
         Amended to support reccursively coupled CAS Files, using
         "COUPLAGE AVEC".
"""
"""@history 28/04/2011 -- Sebastien E. Bourban
         Now supports SYSTELCFG as a directory (old Perl version, to which
         systel.cfg is added) or as a file.
"""
"""@history 30/04/2011 -- Sebastien E. Bourban
         Upgrade made to config parsing to include the option to reset
         the version and the root from the command line option:
         -v <version>, reset the version read in the config file with this
         -r <root>, reset the root path read in the config file with this
"""
"""@history 05/07/2011 -- Sebastien E. Bourban
         Python interpreter added for linux calls. This is a temporary
         solution as "/usr/bin/env" is not strickly portable cross
         operating systems
"""
"""@history 10/10/2011 -- Jan-Philip Gehrcke
         Correction made to the management of sortie files. (search JPG)
"""
"""@history 10/02/2012 -- Sebastien E. Bourban
         Addition of the fixed directory option, which is particulalry useful
         for parallel simulations.
"""
"""@history 20/02/2012 -- Sebastien E. Bourban
         Allowing PARTEL to run in parallel, having received the PARTEL
         source code from Charles (STFC-DL).
"""
"""@history 28/02/2012 -- Sebastien E. Bourban
         Allowing the python version of PARTEL_PARA to run in parallel, finding
         that PARTEL in PARALLEL did not solve our partitioning problem.
"""
"""@history 07/03/2012 -- Sebastien E. Bourban
         Allowing a launch of the main executable / script to run on an HPC queue
         Example given with BSUB to run on encore.ocf.co.uk
"""
"""@history 04/04/2012 -- Sebastien E. Bourban
         Three new options are now available toruncode:
         --split: only does the copying of files (and the split when in parallel)
         -x  : only does the compilation of the executable
         --run  : only does the running (by copying the CAS and the PRINCI
            again, for good measure)
         --merge: only does the re-collection and copy back of files,
            which is most useful when the simulation is put on an HPC queue.
"""
"""@history 12/04/2012 -- Sebastien E. Bourban
         Removed the dependency of the compilation of the PRINCI at run time
         from the configuration files (update or clean statements).
"""
"""@history 12/05/2012 -- Fabien Decung & Sebastien E. Bourban
         Modified checkConsistency so the behaviour is as follows :
          - if parallel not in module keys => ncsize should be 0 or stop
          - else ncsize should be 1 or more
         Also, forces the re-writing of the CAS file in the temporary directory
         so keywords can now be modified before running the CAS
"""
"""@history 18/06/2012 -- Sebastien E. Bourban & Fabien Decung
         Calls to sys.exit() and os.system() have been progressively captured
         into a try/except statement to better manage errors.
         This, however, assumes that all errors are anticipated.
"""
"""@history 29/08/2012 -- Sebastien E. Bourban
         Additonal option --nctile setting the number of cores per node.
         In the case of HPC use, the variable <ncsize> is replaced by ncsize,
            and now two other variables are available: <nctile> and <ncnode>.
         ncsize must be ncnode x nctile.
"""
"""@history 04/12/2012 -- Juliette Parisi and Sebastien E. Bourban
   Simplifying call to parseConfigFile, which now takes two arguments
      options.configFile, and options.configName and return one or more
      valid configurations in an array. Testing for validity is now done
      within config.py
"""
"""@history 15/04/2014 -- Sebastien E. Bourban
   FORTRAN file can now be refered to as directories, in which case, all files
      within it will be bundled together as one FORTRAn file.
"""
"""@history 23/09/2014 -- Sebastien E. Bourban and Yoann Audoin
   The content of the log files from GRETEL and PARTEL are now reported
   in the error report.
"""
"""@brief
         runcode is the execution launcher for all TELEMAC modules
"""

# _____          ___________________________________________________
# ____/ Imports /__________________________________________________/
#
# ~~> dependencies towards standard python
import sys
import shutil
import threading
from time import localtime, strftime
from subprocess import *
from os import path,walk,mkdir,chdir,remove,sep,environ,listdir,getcwd
# ~~> dependencies towards other modules
from config import OptionParser,parseConfigFile,parseConfig_RunningTELEMAC
# ~~> dependencies towards other pytel/modules
from utils.files import checkSymLink,symlinkFile,getFileContent,putFileContent,removeDirectories,isNewer
from utils.messages import MESSAGES,filterMessage
from parsers.parserKeywords import scanCAS,readCAS,rewriteCAS,scanDICO, getCASLang,getKeyWord,setKeyValue,getIOFilesSubmit
from parsers.parserSortie import getLatestSortieFiles

# _____                   __________________________________________
# ____/ Global Variables /_________________________________________/
#

# _____                  ___________________________________________
# ____/ General Toolbox /__________________________________________/
#
"""
   ncruns: allows a number of CAS files to be placed in the same
      queue and run in parallel as a single batch.
   ncnode: is the number of pysical ships or processors.
   nctile: is the number of core utilised per node
   ncsize: is the value of set in the CAS file, i.e. the total
      number of geometrical sub-domains.
   
   Note: ncsize = 0 is also supported.
   
   Logic:
      First, nctile is the one parameter we cannot modify, unless
         ncnode and ncsize are provided.
      If ncruns > 1, then ncsize and nctile will not be adjusted,
      but:
       - if ncnode is given by the user, there will be no
         adjustment, even if the resource allocated ncnode * nctile
         might be too much or too few.
       - if ncnode is not provided, the ncnode will be adjusted to
         best fit ncsize * ncruns with a constant nctile.
      If ncruns = 1, then normal adjustment will be done, 
      with:
       - if ncnode is given by the user then ...
          + if ncsize is given by the user, there will be a
            re-adjustment of nctile to accomodate
          + if nctile is given by the user, there will be a
            re-adjustment of ncsize to accomodate

"""

def checkParaTilling(onctile,oncnode,oncsize,ncruns,ncsize):

   # ~~ Default values ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ncnode = 1
   if oncnode != '': ncnode = max( 1,int(oncnode) )
   if oncsize != '': ncsize = int(oncsize)
   
   # ~~ Special case of nctile ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   nctile = 1
   if onctile != '': nctile = max( 1,int(onctile) )
   elif ncnode > 1:
      if ncsize > 1: nctile = int( ncsize / ncnode )
      elif ncruns > 1: nctile = int( ncruns / ncnode )

   # ~~ Special case of batching ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if oncnode == '':
      # ~~> temporary measure before doing each run in parallel of one another
      ncnode = int( max( 1,ncsize ) / nctile )
      if ncnode * nctile < max( 1,ncsize ): ncnode = ncnode + 1
      # ~~> valid for runs in parallel of one another
      #ncnode = int( max( 1,ncsize ) * ncruns / nctile )
      #if ncnode * nctile < max( 1,ncsize ) * ncruns: ncnode = ncnode + 1

   if ncruns == 1:
   # ~~ Standard cases ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # If the command line options.nctile and options.ncnode are fixed
      if onctile != '' and oncnode != '':
         ncsize = ncnode * nctile
   # If options.ncsize is set, it will have priority over the others
      elif oncsize != '':
         # ncnode is an integer of nctile and ncsize is re-ajusted
         if onctile != '':
            ncnode = int( max( 1,ncsize ) / nctile )
            while ncnode * nctile < max( 1,ncsize ): ncnode = ncnode + 1
         # nctile is an integer of ncnode and ncsize is re-ajusted
         if oncnode != '':
            nctile = int( max( 1,ncsize ) / ncnode )
            while ncnode * nctile < max( 1,ncsize ): nctile = nctile + 1
         # local processor with 1 node and many cores
         if onctile == '' and oncnode == '':
            ncnode = 1
            nctile = max( 1,ncsize )

   return nctile,ncnode,ncsize

   # ~~ check for openmi consistency ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
   return True

def processCAS(casFiles,dico,frgb):

   # ~~ Aquire CAS Files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   cases = []; langs = []
   for casFile in casFiles:
      
      #/!\ to do: possible use of os.path.relpath() and comparison with os.getcwd()
      casFile = path.realpath(casFile)
      if not path.exists(casFile): raise Exception([{'name':'runCAS','msg':'inexistent CAS file: '+casFile+ \
            '    +> or you may have forgotten an option key in your command line'}])

      # ~~> extract keywords
      cas = readCAS(scanCAS(getFileContent(casFile)),dico,frgb)

      # ~~> extract language and set extra keywords
      lang = getCASLang(cas,frgb)
      if lang == 1:
         cas = setKeyValue('FICHIER DES PARAMETRES',cas,frgb,repr(path.basename(casFile)))
         cas = setKeyValue('DICTIONNAIRE',cas,frgb,repr(path.normpath(frgb['DICO'])))
      if lang == 2:
         cas = setKeyValue('STEERING FILE',cas,frgb,repr(path.basename(casFile)))
         cas = setKeyValue('DICTIONARY',cas,frgb,repr(path.normpath(frgb['DICO'])))

      # ~~> Store the CAS File
      cases.append( cas ); langs.append( lang )

   # ~~ Batching commonalities ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   lang = langs[0]
   ncsize = getNCSIZE(cases[0],dico,frgb)
   for cf,c,l in zip(casFiles,cases,langs):
      if ncsize != getNCSIZE(c,dico,frgb):
         raise Exception([{'name':'processCAS','msg':'batched CAS files should have same NCSIZE '+str(ncsize)+' != '+path.basename(cf)}])
      if lang != l:
         raise Exception([{'name':'processCAS','msg':'batched CAS files should have same LANGUAGE '+str(lang)+' != '+path.basename(cf)}])

   # ~~ For Information ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if lang == 1: print '    +> simulation en Francais'
   if lang == 2: print '    +> running in English'

   return cases,lang,ncsize

def processTMP(casFile):

   # ~~ TMP Directory ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   TMPDir = casFile + '_' + strftime("%Y-%m-%d-%Hh%Mmin%Ss", localtime())

   return TMPDir

def processLIT(cas,iFiles,TMPDir,ncsize,update,use_link):

   xcpt = []                            # try all files for full report
   section_name = ''
   zone_name    = ''
   # ~~ copy input files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   for k,v in zip(*cas[1]):
      if k in iFiles:
         cref = v[0].strip("'\"") 
         if not ( path.isfile(cref) or path.isdir(cref) ):
            xcpt.append({'name':'processLIT','msg':'file does not exist: '+path.basename(cref)})
            continue
         crun = path.join(TMPDir,iFiles[k].split(';')[1])
         if path.exists(crun) and update:
            if not isNewer(crun,cref) == 1:
               if iFiles[k].split(';')[5][0:7] == 'SELAFIN' or iFiles[k].split(';')[5][0:5] == 'PARAL':
                  # ~~> check if all files are there before skipping
                  found = True
                  for npsize in range(ncsize):
                     if not path.isfile(crun+'{0:05d}-{1:05d}'.format(ncsize-1,npsize)): found = False
                  # ~~> skip if all files are there
                  if found: iFiles[k] = iFiles[k].replace('SELAFIN','DONE').replace('PARAL','DONE')
               # special case for FORTRAN and CAS files in case of update
               if iFiles[k].split(';')[5][0:7] == 'FORTRAN':
                  if path.isdir(cref):
                     cdir = path.join(getcwd(),cref)
                     cfor = []
                     for file in listdir(cdir):
                        if path.isfile(path.join(cdir,file)): cfor.extend(getFileContent(path.join(cdir,file)))
                     print 're-bundling: ', path.basename(cref),crun
                     putFileContent(crun,cfor+[''])
                  else:
                     print ' re-copying: ', path.basename(cref),crun
                     putFileContent(crun,getFileContent(cref)+[''])
               elif iFiles[k].split(';')[5][0:3] == 'CAS':
                  #print ' re-writing: ', crun
                  #putFileContent(crun,rewriteCAS(cas))
                  print ' re-copying: ', crun
                  putFileContent(crun,cas[0])
               else:
                  print '   ignoring: ', path.basename(cref),crun
                  #putFileContent(crun,getFileContent(cref)+[''])
               continue
         if iFiles[k].split(';')[3] == 'ASC':
            if iFiles[k].split(';')[5][0:3] == 'CAS':
               #print ' re-writing: ', crun
               #putFileContent(crun,rewriteCAS(cas))
               print ' re-copying: ', crun
               putFileContent(crun,cas[0])
               # An input mesh may be a binary or an ascii file
               # It depends on the selected format (Selafin, Ideas, Med)
            elif iFiles[k].split(';')[5][0:12] == 'SELAFIN-GEOM':
               if use_link:
                  print '    linking: ', path.basename(cref),crun
                  symlinkFile(path.join(getcwd(),cref), crun)
               else:
                  print '    copying: ', path.basename(cref),crun
                  shutil.copy2(path.join(getcwd(),cref), crun)
            elif iFiles[k].split(';')[5][0:7] == 'SECTION':
               # Giving section name means that we have to give it to partel
               section_name = path.basename(crun)
               if use_link:
                  print '    linking: ', path.basename(cref),crun
                  symlinkFile(path.join(getcwd(),cref), crun)
               else:
                  print '    copying: ', path.basename(cref),crun
                  putFileContent(crun,getFileContent(cref)+[''])
            elif iFiles[k].split(';')[5][0:5] == 'ZONES':
               # Giving zone name means that we have to give it to partel
               zone_name = path.basename(crun)
               if use_link:
                  print '    linking: ', path.basename(cref),crun
                  symlinkFile(path.join(getcwd(),cref), crun)
               else:
                  print '    copying: ', path.basename(cref),crun
                  putFileContent(crun,getFileContent(cref)+[''])
            elif path.isdir(cref):
               cdir = path.join(getcwd(),cref)
               cfor = []
               for file in listdir(cdir):
                  if path.isfile(path.join(cdir,file)): cfor.extend(getFileContent(path.join(cdir,file)))
               print '   bundling: ', path.basename(cref),crun
               putFileContent(crun,cfor+[''])
            else:
               if use_link:
                  print '    linking: ', path.basename(cref),crun
                  symlinkFile(path.join(getcwd(),cref), crun)
               else:
                  print '    copying: ', path.basename(cref),crun
                  putFileContent(crun,getFileContent(cref)+[''])
         else:
            if use_link:
               print '    linking: ', path.basename(cref),crun
               symlinkFile(path.join(getcwd(),cref), crun)
            else:
               print '    copying: ', path.basename(cref),crun
               shutil.copy2(path.join(getcwd(),cref), crun)

   if xcpt != []: raise Exception(xcpt) # raise full report
   return section_name,zone_name

def processECR(cas,oFiles,CASDir,TMPDir,sortiefile,ncsize,bypass):

   xcpt = []                            # try all files for full report
   # ~~ copy output files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   for k,v in zip(*cas[1]):
      if  k in oFiles:
         if oFiles[k].split(';')[5] == 'MULTI':   # POSTEL3D
            npsize = 1
            while 1:                              # HORIZONTAL SECTION FILES
               cref = path.join(CASDir,v[0].strip("'\"")+'_{0:03d}'.format(npsize))
               if path.isfile(cref): shutil.move(cref,cref+'.old') #shutil.copy2(cref,cref+'.old')
               crun = oFiles[k].split(';')[1]+'_{0:03d}'.format(npsize)
               if not path.isfile(crun): break
               shutil.move(crun,cref) #shutil.copy2(crun,cref)
               print '  moving: ', path.basename(cref)
               npsize = npsize + 1
            npsize = 1
            while 1:                              # VERTICAL SECTION FILES
               nptime = 1
               if not path.isfile(oFiles[k].split(';')[1]+'_{0:03d}'.format(npsize)+'-{0:03d}'.format(nptime)): break
               while 1:
                  cref = path.join(CASDir,v[0].strip("'\"")+'_{0:03d}'.format(npsize)+'-{0:03d}'.format(nptime))
                  if path.isfile(cref): shutil.move(cref,cref+'.old') #shutil.copy2(cref,cref+'.old')
                  crun = oFiles[k].split(';')[1]+'_{0:03d}'.format(npsize)+'-{0:03d}'.format(nptime)
                  if not path.isfile(crun): break
                  shutil.move(crun,cref) #shutil.copy2(crun,cref)
                  print '  moving: ', path.basename(cref)
                  nptime = nptime + 1
               npsize = npsize + 1
         elif oFiles[k].split(';')[5] == 'PARAL' and ncsize > 1: # MAIN MODULE
            npsize = 0
            cb,ce = path.splitext(v[0].strip("'\""))
            while 1:
               cref = path.join(CASDir,cb+'{0:05d}-{1:05d}'.format(ncsize-1,npsize)+ce)
               if path.isfile(cref): shutil.move(cref,cref+'.old') #shutil.copy2(cref,cref+'.old')
               crun = oFiles[k].split(';')[1]+'{0:05d}-{1:05d}'.format(ncsize-1,npsize)
               if not path.isfile(crun): break
               shutil.move(crun,cref) #shutil.copy2(crun,cref)
               #print ' copying: ', path.basename(cref)
               print '  moving: ', path.basename(cref)
               npsize = npsize + 1
         elif oFiles[k].split(';')[5] == 'MULTI2':
            for crun in listdir('.') :
               if crun.count(oFiles[k].split(';')[1]) == 1:
                  cref = path.join(CASDir,crun.lower().replace(oFiles[k].split(';')[1].lower(),
                         v[0].strip("'\"").split('.')[0])) + '.' + v[0].strip("'\"").split('.')[1]
                  if path.isfile(cref): shutil.move(cref,cref+'.old') #shutil.copy2(cref,cref+'.old')
                  shutil.move(crun,cref)
                  print '  moving: ', path.basename(cref)
         else:
            cref = path.join(CASDir,v[0].strip("'\""))
            if path.isfile(cref): shutil.move(cref,cref+'.old') #shutil.copy2(cref,cref+'.old')
            crun = oFiles[k].split(';')[1]
            if not path.isfile(crun):
               xcpt.append({'name':'processECR','msg':'did not create outfile: '+path.basename(cref)+' ('+crun+')'})
               continue
            shutil.move(crun,cref) #shutil.copy2(crun,cref)
            print '  moving: ', path.basename(cref)

   # ~~~ copy the sortie file(s) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   sortiefiles = []
   if sortiefile != None:    # sortiefile.rstrip() != '':
      crun = path.basename(sortiefile)
      cref = path.join(CASDir,sortiefile)
      if not path.isfile(crun):
         xcpt.append({'name':'processECR','msg':'did not create listing file: '+path.basename(cref)+' ('+crun+')'})
         raise Exception(xcpt) # raise full report
      shutil.copy(crun,cref)
      print ' copying: ', path.basename(cref)
      sortiefiles.append(cref)

      # ~~~ If in parallel, also copy the slave log files     ~~~~~~
      # ~~~ called PEnnnnn_xxxxx.log for slave x of n         ~~~~~~
      # ~~~ Note that n=ncsize-1; output from the Master goes ~~~~~~
      # ~~~ directly in to the sortie file                    ~~~~~~
      if ncsize > 1:
         for i in range(ncsize-1):
            slavefile = 'PE{0:05d}-{1:05d}.LOG'.format(ncsize-1,i+1)
            bs,es = path.splitext(sortiefile) # (path.basename(sortiefile))
            slogfile  = bs+'_p'+'{0:05d}'.format(i+1)+es
            crun = slavefile
            cref = path.join(CASDir,slogfile)
            if not path.isfile(crun):
               xcpt.append({'name':'processECR','msg':'could not find the listing file: '+crun})
               raise Exception(xcpt) # raise full report
            shutil.copy(crun,cref)
            print ' copying: ',path.basename(cref)            
            sortiefiles.append(cref)
   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if xcpt != []: raise Exception(xcpt) # raise full report
   return sortiefiles

def processCONFIG(lang):

   # ~~ create CONFIG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   putFileContent('CONFIG',[repr(lang),'6',''])
   return True

def getNCSIZE(cas,dico,frgb):

   # ~~ check keyword ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   value,defaut = getKeyWord('PROCESSEURS PARALLELES',cas,dico,frgb)
   ncsize = 0
   if value != []: ncsize = value[0]
   elif defaut != []: ncsize = int(defaut[0])

   return ncsize

def getMPICommand(cfgMPI):
   # ~~> Executable
   mpiCmd = cfgMPI['EXEC']
   # ~~> host file
   hostfile = ''
   if 'HOSTFILE' in cfgMPI: hostfile = cfgMPI['HOSTFILE']
   mpiCmd = mpiCmd.replace('<hostfile>',hostfile)
   # ~~> stdin file
   infile = ''
   if 'INFILE' in cfgMPI: infile = cfgMPI['INFILE']
   mpiCmd = mpiCmd.replace('<mpi_infile>',infile)

   return mpiCmd

def getHPCCommand(cfgHPC):
   # ~~> Executable
   if cfgHPC.has_key('EXCODE'): hpcCmd = cfgHPC['EXCODE']
   elif cfgHPC.has_key('PYCODE'): hpcCmd = cfgHPC['PYCODE']
   # ~~> script
   if 'STDIN' in cfgHPC:
      hpc_stdin = cfgHPC['STDIN'][0]
      hpcCmd = hpcCmd.replace('<hpc_stdin>',hpc_stdin)

   return hpcCmd

def processExecutable(useName,objName,f90Name,objCmd,exeCmd,bypass):

   if path.exists(f90Name) and not path.exists(useName):
   # ~~ requires compilation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      objCmd = objCmd.replace('<f95name>',f90Name)
      mes = MESSAGES(size=10)
      try:
         tail,code = mes.runCmd(objCmd,bypass)
      except Exception as e:
         raise Exception([filterMessage({'name':'processExecutable','msg':'something went wrong for no reason. Please verify your compiler installation.'},e,bypass)])
      if code != 0: raise Exception([{'name':'processExecutable','msg':'could not compile your FORTRAN (runcode='+str(code)+').\n      '+tail}])
      exeCmd = exeCmd.replace('<objs>',objName)
      exeCmd = exeCmd.replace('<exename>',path.basename(useName))
      try:
         tail,code = mes.runCmd(exeCmd,bypass)
      except Exception as e:
         raise Exception([filterMessage({'name':'processExecutable','msg':'something went wrong for no reason. Please verify your external library installation.'},e,bypass)])
      if code != 0: raise Exception([{'name':'processExecutable','msg':'could not link your executable (runcode='+str(code)+').\n      '+tail}])
      print '    created: ',path.basename(useName)
   
   else:
   # ~~ default executable ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      shutil.copy2(useName,path.basename(useName))

   return True

def compilePRINCI(princiFile,codeName,cfgName,cfg,bypass):

   plib = cfg['MODULES'][codeName]['path'].replace(cfg['root']+sep+'sources',cfg['root']+sep+'builds'+sep+cfgName+sep+'lib')
   #pbin = cfg['root']+sep+'builds'+sep+cfgName+sep+'bin'
   objFile = path.join(plib,codeName+'.cmdo')
   exeFile = path.join(plib,codeName+'.cmdx')
   if not path.exists(objFile) or not path.exists(exeFile):
      raise Exception([{'name':'compilePRINCI','msg':'... could not find:' + exeFile + \
         '\n    ~~~> you may need to compile your system with the configuration: ' + cfgName }])
   # ~~> Make the keys portable (no full path)
   objCmd = getFileContent(objFile)[0]
   exeCmd = getFileContent(exeFile)[0]
   for k in cfg['TRACE']:
      objCmd = objCmd.replace('['+k+']',path.normpath(cfg['TRACE'][k]))
      exeCmd = exeCmd.replace('['+k+']',path.normpath(cfg['TRACE'][k]))
   # ~~<
   chdir(path.dirname(princiFile))
   princiFile = path.basename(princiFile)
   objFile = path.splitext(princiFile)[0] + cfg['SYSTEM']['sfx_obj']
   exeFile = path.splitext(princiFile)[0] + cfg['SYSTEM']['sfx_exe']
   if path.exists(exeFile): remove(exeFile)
   try:
      processExecutable(exeFile,objFile,princiFile,objCmd,exeCmd,bypass)
   except Exception as e:
      raise Exception([filterMessage({'name':'compilePRINCI','msg':'could not compile: ' + princiFile},e,bypass)])  # only one item here
   if path.exists(objFile): remove(objFile)

   return exeFile

def getCONLIM(cas,iFiles):

   # ~~ look for CONLIM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   CONLIM = ''
   for k in cas[1][0]:
      if k in iFiles:
         if iFiles[k].split(';')[5] == 'CONLIM': CONLIM = iFiles[k].split(';')[1]
   return CONLIM

def getGLOGEO(cas,iFiles):

   # ~~ look for GLOBAL GEO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   GLOGEO = ''
   for k in cas[1][0]:
      if k in iFiles:
         if iFiles[k].split(';')[5][-4:] == 'GEOM': GLOGEO = iFiles[k].split(';')[1]
   return GLOGEO

def runPartition(partel,cas,conlim,iFiles,ncsize,bypass,section_name,zone_name,use_link):

   if ncsize < 2: return True
   # ~~ split input files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   for k in cas[1][0]:
      if k in iFiles:
         crun = iFiles[k].split(';')[1]
         if iFiles[k].split(';')[5][0:7] == 'SELAFIN':
            print ' partitioning: ', path.basename(crun)
            try:
               runPARTEL(partel,crun,conlim,ncsize,bypass,section_name,zone_name)
            except Exception as e:
               raise Exception([filterMessage({'name':'runPartition'},e,bypass)])
         elif iFiles[k].split(';')[5][0:5] == 'PARAL':
            if use_link:
               print 'duplilinking: ', path.basename(crun)
               for n in range(ncsize): symlinkFile(crun,crun+('00000'+str(ncsize-1))[-5:]+'-'+('00000'+str(n))[-5:])
            else:
               print ' duplicating: ', path.basename(crun)
               for n in range(ncsize): shutil.copy2(crun,crun+('00000'+str(ncsize-1))[-5:]+'-'+('00000'+str(n))[-5:])

   return True

def runPARTEL(partel,file,conlim,ncsize,bypass,section_name,zone_name):

   has_section = '0'
   if section_name != '': has_section = '1'
   has_zone = '0'
   if zone_name != '': has_zone = '1'
   putFileContent('PARTEL.PAR',[file,conlim,str(ncsize),str(1),has_section,section_name,has_zone,zone_name])
   parCmd = partel.replace('<partel.log>','partel_'+file+'.log').split(';')
   mes = MESSAGES(size=10)
   for p in parCmd:
      try:
         print '    +> ',p
         tail,code = mes.runCmd(p,bypass)
      except Exception as e:
         raise Exception([filterMessage({'name':'runPARTEL','msg':'something went wrong, I am not sure why. Here is the log:\n'+
            '\n'.join(getFileContent('partel_'+file+'.log'))},e,bypass)])
      if code != 0: raise Exception([{'name':'runPARTEL','msg':'Could not split your file '+file+' (runcode='+str(code)+') with the error as follows:'+
         '\n      '+tail+
         '\n      You may have forgotten to compile PARTEL with the appropriate compiler directive\n        (add -DHAVE_MPI to your cmd_obj in your configuration file).'+
         '\n\nHere is the log:\n'+'\n'.join(getFileContent('partel_'+file+'.log'))}])
   return

# ~~~ CCW: amended runCode to include optional listing file        ~~~
# ~~~      print_twice echos the listing output to the sortie file ~~~
def print_twice(pipe,ofile):

   # Utility subroutine to print listing data both to stdout 
   # and to the listing file, accessed via the ofile handle
   lastlineempty = False      # JPG addition here as opposed to argument
   for line in iter(pipe.readline,''):
      dat = line.rstrip()
      # This IF statement just avoid printing a lot of blank lines 
      # at the end of the run, before Python realises that the process
      # has stopped. 
      if (dat == ''):
         if not lastlineempty:
            print dat                   # Print to screen
            if ofile != None:
               ofile.write(dat+'\n')    # Write to sortiefile (if requested)
            lastlineempty = True        # Set to avoid printing multiple consecutive newlines
      else:
         lastlineempty = False
         print dat                      # Print to screen
         if ofile != None:
            ofile.write(dat+'\n')       # Write to sortiefile (if requested)

def runCode(exe,sortiefile):
   ofile = None
   # If sortiefile is required, open it
   if sortiefile != None: ofile = open(sortiefile,"w")
   # Start process with command 'exe', and direct standard output and
   # standard error into PIPE (part of the Popen object called proc)
   proc = Popen(exe,bufsize=1024,stdout=PIPE,stderr=PIPE,shell=True)
   # Define a thread, t1, that will execute the subroutine 'print_twice', with
   # the args given.
   t1 = threading.Thread(target=print_twice,args=(proc.stdout,ofile))
   # Start the print_twice thread. This continues until the stdout buffer is empty
   # (usually when the Telemac code has terminated)
   t1.start()
   # Wait for t1 to terminate before continuing
   t1.join()
   # Close the sortiefile, if used
   if ofile: ofile.close()
   # Wait to make sure that the Telemac code really has terminated
   # Note: this is probably unnecessary, but done to make sure that
   #       a zero return code is returned, indicating successful completion.
   proc.wait()
   if proc.returncode == 0: return True
   raise Exception({'name':'runCode','msg':'Fail to run\n'+exe+
      '\n~~~~~~~~~~~~~~~~~~\n'+str(proc.stderr.read().strip())+'\n~~~~~~~~~~~~~~~~~~'})
   return False

def runRecollection(gretel,cas,glogeo,oFiles,ncsize,bypass):

   if ncsize < 2: return True
   # ~~ aggregate output files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   for k in cas[1][0]:
      if  k in oFiles:
         crun = oFiles[k].split(';')[1]
         tpe = oFiles[k].split(';')[5]
         if tpe[0:7] == 'SELAFIN':
            print ' recollectioning: ', path.basename(crun)
            try:
               runGRETEL(gretel,crun,glogeo,ncsize,bypass)
            except Exception as e:
               raise Exception([filterMessage({'name':'runRecollection'},e,bypass)])
         if tpe[0:6] == 'DELWAQ':
            print ' recollectioning: ', path.basename(crun)
            try:
               runGREDEL(gretel,crun,glogeo,tpe[6:],ncsize,bypass)
            except Exception as e:
               raise Exception([filterMessage({'name':'runRecollection'},e,bypass)])
   return True

def runGRETEL(gretel,file,geom,ncsize,bypass):

   # ~~ Run GRETEL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   putFileContent('gretel_'+file+'.par',[geom,file,str(ncsize)])
   mes = MESSAGES(size=10)
   cmd = gretel+' < gretel_'+file+'.par >> gretel_'+file+'.log'
   try:
      tail,code = mes.runCmd(cmd,bypass)
   except Exception as e:
      raise Exception([filterMessage({'name':'runGRETEL','msg':'something went wrong, I am not sure why. Here is the log:\n'+'\n'.join(getFileContent('gretel_'+file+'.log'))},e,bypass)])
   if code != 0: raise Exception([{'name':'runGRETEL','msg':'Could not split your file '+file+' (runcode='+str(code)+') with the error as follows:'+'\n      '+tail+'\n\nHere is the log:\n'+'\n'.join(getFileContent('gretel_'+file+'.log'))}])
   return

def runGREDEL(gredel,file,geom,type,ncsize,bypass):

   # ~~ Change GRETEL into GREDEL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   pg = path.dirname(gredel)
   bg,eg = path.splitext(path.basename(gredel))
   gredel = path.join(pg,'gredel' + type.lower() + '_autop' + eg)
   # ~~ Run GREDEL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   putFileContent('gretel_'+file+'.par',[geom,file,str(ncsize)])
   mes = MESSAGES(size=10)
   cmd = gredel+' < gretel_'+file+'.par >> gretel_'+file+'.log'
   try:
      tail,code = mes.runCmd(cmd,bypass)
   except Exception as e:
      raise Exception([filterMessage({'name':'runGREDEL','msg':'something went wrong, I am not sure why. Please verify your compilation or the python script itself.'},e,bypass)])
   if code != 0: raise Exception([{'name':'runGREDEL','msg':'Could not split your file (runcode='+str(code)+').\n     '+file+'\n      '+tail}])
   return

"""
   runCAS now takes in an array of casFiles, and if possible,
      run these in parallel of one another and as one job on a queue
      where the mpi_exec command do the parallelisation
   Notes:
      - casdir is where the CAS files are.
      - The hpccmd is unique. The mpicmd is not (unfortunately).
"""
def runCAS(cfgName,cfg,codeName,casNames,options):

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~~~ Read the main DICO File ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   dicoFile = path.join(cfg['MODULES'][codeName]['path'],codeName+'.dico')
   if not path.exists(dicoFile): raise Exception([{'name':'runCAS','msg':'could not find the DICO file: '+dicoFile}])
   print '\n... reading the main module dictionary'
   frgb,dico = scanDICO(dicoFile)
   iFS,oFS = getIOFilesSubmit(frgb,dico)
   #> MODFiles avoids duplication of dico parsing
   MODFiles = { codeName:{ 'frgb':frgb,'iFS':iFS,'oFS':oFS,'dico':dico } }
   pbin = cfg['root']+sep+'builds'+sep+cfgName+sep+'bin'

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~~~ Acquiring all CAS file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, to copy the correct CAS files and get the LIT files
   #    - if options.run, to get to the FORTRAN FILE for compilation
   #    - if options.compileonly, same as options.run
   #    - if options.merge, to get the ECR files and associated ncsize
   print '\n... processing the main CAS file(s)'
   try:
      cases,lang,ncsize = processCAS(casNames,MODFiles[codeName]['dico'],MODFiles[codeName]['frgb'])
   except Exception as e:
      raise Exception([filterMessage({'name':'runCAS'},e,options.bypass)])
   CASFiles = {}
   # ~~ Find a common root to all CAS files ~~~~~~~~~~~~~~~~~~~~~
   # /!\ in case of multiple CAS files, all CAS files have to leave at the same address
   casdir = ''
   for cas,casName in zip(cases,casNames):
      name = path.basename(casName)
      if casdir == '': casdir = path.dirname(path.realpath(casName))
      elif casdir != path.dirname(path.realpath(casName)):
         raise Exception([{'name':'runCAS','msg':'Location of more than one CAS file is not common to all:' \
            '    +> you should have all your CAS files within the same directory'}])
      CASFiles.update({ name:{ 'code':codeName, 'cas':cas, 'dir':casdir } })
   ncruns = len(CASFiles)

   # /!\ options.mpi is True only if you are in your second call, within the HPC queue; you have already used up your HPC credits
   if options.mpi and cfg.has_key('HPC'): cfg['HPC'] = {}
   # /!\ hpcpass is True only if you are in your first call and you intend to do a second call with the same configuration
   hpcpass = False
   if cfg['HPC'] != {}: hpcpass = ( cfg['HPC'].has_key('PYCODE') )

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Common behaviours for all CAS files ~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, to copy the correct CAS files once ncsize updated
   #    - if options.run, to re-copy the correct CAS file
   #    - if options.merge, to get ncsize but no need to copy correct CAS file anymore
   # Outputs ...
   #    > nctile, ncnode, ncsize
   #    > lang, casdir
   print '\n... checking parallelisation'
   nctile,ncnode,ncsize = checkParaTilling(options.nctile,options.ncnode,options.ncsize,ncruns,ncsize)
   if cfg['MPI'] != {}: ncsize = max( 1, ncsize )
   elif ncsize > 1:
      raise Exception([{'name':'runCAS','msg':'parallel inconsistency: ' \
         '\n    +> you may be using an inappropriate configuration: '+cfgName+ \
         '\n    +> or may be wishing for scalar mode while setting to '+str(ncsize)+' processors'}])
   if cfg['MPI'] == {}: ncsize = 0      #TODO: check if this is still useful
   # ~~ Forces keyword if parallel ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # /!\ in case of multiple CAS files, you have to have the same ncsize
   if lang == 1:
      for name in CASFiles: CASFiles[name]['cas'] = \
         setKeyValue('PROCESSEURS PARALLELES',CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['frgb'],ncsize)
   elif lang == 2:
      for name in CASFiles: CASFiles[name]['cas'] = \
         setKeyValue('PARALLEL PROCESSORS',CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['frgb'],ncsize)

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling Directories ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, to know where to copy the LIT files into
   #    - if options.run, to run
   #    - if options.compileonly, same as options.run
   #    - if options.merge, to know where to copy the ECR file from
   # Outputs ...
   #    > the full name of the sortie file without extension, in CASFiles[name]['sortie']
   #    > wdir same as above but would be reset with -w option
   #    > CASFiles[name]['wir'] and CASFiles[name]['wrt']
   #    > CASFiles[name]['dir'] is where the CAS file is from
   print '\n... handling temporary directories'
   for name in CASFiles:
      TMPDir = processTMP(CASFiles[name]['dir']+sep+name)    #/!\ includes date/time in the name
      wdir = TMPDir
      CASFiles[name].update({ 'wir':wdir, 'wrt':True, 'sortie':TMPDir })
      if options.wDir != '':
         if ncruns == 1: wdir = path.join(CASFiles[name]['dir'],options.wDir)
         else: wdir = path.join(CASFiles[name]['dir'],path.basename(options.wDir)+'_'+name)
         CASFiles[name]['wir'] = wdir
      if not path.exists(wdir):
         mkdir(wdir)
         CASFiles[name]['wrt'] = False

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Read the included CAS File ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, to include coupling code files in LIT
   #    - if options.run, to run in coupled mode ?? may not need to know that ??
   #    - if options.compileonly, to aggregate FORTRAN FILEs
   #    - if options.merge, to include coupling code files in ECR
   print '\n... checking coupling between codes'
   for name in CASFiles:
      cplages,defaut = getKeyWord('COUPLING WITH',CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['dico'],MODFiles[CASFiles[name]['code']]['frgb'])
      CASFiles[name].update({ 'with':{} })

      #/!\ having done the loop this way it will not check for DELWAQ
      for cplage in cplages:
         for mod in cfg['MODULES']:
            if mod in cplage.lower():

               # ~~~~ Extract the CAS File name ~~~~~~~~~~~~~~~~~~~~~~~
               casNamePlage,defaut = getKeyWord(mod.upper()+' STEERING FILE',CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['dico'],MODFiles[CASFiles[name]['code']]['frgb'])
               if casNamePlage == []: casNamePlage = defaut[0]
               else: casNamePlage = casNamePlage[0].strip("'\"")
               casNamePlage = path.join(CASFiles[name]['dir'],casNamePlage)
               if not path.isfile(casNamePlage): raise Exception([{'name':'runCAS','msg':'missing coupling CAS file for '+mod+': '+casNamePlage}])

               # ~~~~ Read the DICO File ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
               if mod not in MODFiles:
                  dicoFilePlage = path.join(cfg['MODULES'][mod]['path'],mod+'.dico')
                  if not path.exists(dicoFilePlage): raise Exception([{'name':'getDICO','msg':'could not find the DICO file: '+dicoFilePlage}])
                  frgbPlage,dicoPlage = scanDICO(dicoFilePlage)
                  iFSPlage,oFSPlage = getIOFilesSubmit(frgbPlage,dicoPlage)
                  MODFiles.update({ mod:{ 'frgb':frgbPlage,'iFS':iFSPlage,'oFS':oFSPlage,'dico':dicoPlage } })

               # ~~ Read the coupled CAS File ~~~~~~~~~~~~~~~~~~~~~~~~~
               casPlage,l,n = processCAS([casNamePlage],MODFiles[mod]['dico'],MODFiles[mod]['frgb'])
               CASFiles[name]['with'].update({ casNamePlage:{ 'code':mod, 'cas':casPlage[0] } })

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling all input files (PART I) ~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, obvisouly this is PART I of the main file pre-processing
   #    - if options.compileonly, you also need to copy the FORTRAN FILE
   section_name = ''
   zone_name = ''
   if not options.merge and not options.run and not hpcpass:
      print '\n... first pass at copying all input files'
      for name in CASFiles:
         # >>> Placing yourself where the CAS File is
         chdir(CASFiles[name]['dir'])
         # >>> Copy INPUT files into wdir
         try:
            section_name,zone_name = processLIT(CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['iFS'],
                       CASFiles[name]['wir'],ncsize,CASFiles[name]['wrt'],options.use_link)
         except Exception as e:
            raise Exception([filterMessage({'name':'runCAS'},e,options.bypass)])  # only one item here
         for cplage in CASFiles[name]['with']:
            try:
               section_name,zone_name = processLIT(CASFiles[name]['with'][cplage]['cas'],MODFiles[CASFiles[name]['with'][cplage]['code']]['iFS'],
                          CASFiles[name]['wir'],ncsize,CASFiles[name]['wrt'],options.use_link)
            except Exception as e:
               raise Exception([filterMessage({'name':'runCAS'},e,options.bypass)])  # only one item here
         # >>> Placing yourself into the wdir
         chdir(CASFiles[name]['wir'])
         # >>> Creating LNG file
         processCONFIG(lang)

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling the executables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.run, obvisouly this is the main executable to run
   #    - if options.compileonly, obvisouly this is the main executable to create
   #    - if you are in your first pass of two of the HPC configuration, as you may need to update the name in the STDIN script
   if not options.merge and not options.split and not hpcpass:
      print '\n... checking the executable'
      for name in CASFiles:
         chdir(CASFiles[name]['wir'])
         # >>> Names for the executable set
            #> names within wdir
         f90File = MODFiles[CASFiles[name]['code']]['iFS']['FICHIER FORTRAN'].split(';')[1]
            #> aggregation of PRINCI files
         for cplage in CASFiles[name]['with']:
            f90FilePlage = MODFiles[CASFiles[name]['with'][cplage]['code']]['iFS']['FICHIER FORTRAN'].split(';')[1]
            if path.isfile(f90FilePlage):
               putFileContent(f90File,getFileContent(f90File)+['']+getFileContent(f90FilePlage))
               remove(f90FilePlage)
         plib = cfg['MODULES'][CASFiles[name]['code']]['path'].replace(cfg['root']+sep+'sources',cfg['root']+sep+'builds'+sep+cfgName+sep+'lib')
         objFile = path.splitext(f90File)[0] + cfg['SYSTEM']['sfx_obj']
            #> default executable name
         exeFile = path.join(pbin,CASFiles[name]['code']+cfg['SYSTEM']['sfx_exe'])
            #> user defined executable name
         useFile = exeFile
         value,defaut = getKeyWord('FICHIER FORTRAN',CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['dico'],MODFiles[CASFiles[name]['code']]['frgb'])
         # ~~ check if compileTELEMAC.py has been called since
         if value != []:
            useFort = path.join(CASFiles[name]['dir'],value[0].strip("'\""))
            useFile = path.join(CASFiles[name]['dir'],path.splitext(value[0].strip("'\""))[0]+cfg['SYSTEM']['sfx_exe'])
            # /!\ removing dependency over cfg['REBUILD']:
            if path.exists(useFile):
               if cfg['REBUILD'] == 1: remove(useFile)
               elif isNewer(useFile,exeFile) == 1: remove(useFile)
               elif isNewer(useFile,useFort) == 1: remove(useFile)
            #> default command line compilation and linkage
         if not path.exists(path.join(plib,CASFiles[name]['code']+'.cmdo')):
            raise Exception([{'name':'runCAS','msg': \
               '\nNot able to find your OBJECT command line: ' + path.join(plib,CASFiles[name]['code']+'.cmdo') + '\n' + \
               '\n ... you have to compile this module at least: '+CASFiles[name]['code']}])
         objCmd = getFileContent(path.join(plib,CASFiles[name]['code']+'.cmdo'))[0]
         if not path.exists(path.join(plib,CASFiles[name]['code']+'.cmdx')):
            raise Exception([{'name':'runCAS','msg': \
               '\nNot able to find your OBJECT command line: ' + path.join(plib,CASFiles[name]['code']+'.cmdx') + '\n' + \
               '\n ... you have to compile this module at least: '+CASFiles[name]['code']}])
         exeCmd = getFileContent(path.join(plib,CASFiles[name]['code']+'.cmdx'))[0]
         # ~~> Make the keys portable (no full path)
         for k in cfg['TRACE']:
            objCmd = objCmd.replace('['+k+']',path.normpath(cfg['TRACE'][k]))
            exeCmd = exeCmd.replace('['+k+']',path.normpath(cfg['TRACE'][k]))
         # >>> Compiling the executable if required
         exename = path.join(CASFiles[name]['wir'],'out_'+path.basename(useFile))
         CASFiles[name].update({ 'run':exename, 'exe':exename })
         try:
            processExecutable(useFile,objFile,f90File,objCmd,exeCmd,options.bypass)
         except Exception as e:
            raise Exception([filterMessage({'name':'runCAS','msg':'could not compile: ' + path.basename(useFile)},e,options.bypass)])  # only one item here
         print ' re-copying: ',path.basename(useFile),exename
         shutil.copy2(path.basename(useFile),path.join(CASFiles[name]['dir'],path.basename(useFile)))
         shutil.move(path.basename(useFile),exename) # rename executable because of firewall issues
   
   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling the MPI command ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, for PARTEL that could be used in parallel
   #    - if options.run, obvisouly this is the main executable to run
   # Note: the mpicmd is unique and run once
   if not options.merge and not hpcpass:
      if cfg['MPI'] != {}:
         print '\n... modifying run command to MPI instruction'
         # ~~> MPI host file provided through the command line
         if options.hosts != '':
            if 'HOSTS' in cfg['MPI']: cfg['MPI']['HOSTS'] = options.hosts.replace(':',' ')
            else: cfg['MPI'].update( {'HOSTS':options.hosts.replace(':',' ')} )
         # ~~> MPI host file ( may be re-written by the HPC INFILE script )
         hostfile = cfg['MPI']['HOSTFILE']
         hosts = []; n = 0
         while n < ncsize:
            for i in cfg['MPI']['HOSTS'].split():
               hosts.append(i); n += 1
               if n == ncsize: break
         # ~~> MPI Command line and options ( except <exename> )
         mpicmd = getMPICommand(cfg['MPI']) # /!\ cfg['MPI'] is also modified
         # mpi_exec supports: -n <ncsize> -wdir <wdir> <exename>
         mpicmd = mpicmd.replace('<ncsize>',str(ncsize))
         for name in CASFiles:
            # >>> Parallel execution configuration
            chdir(CASFiles[name]['wir'])
            mpi = mpicmd
            # ~~> filling in the blanks
            mpi = mpi.replace('<wdir>',CASFiles[name]['wir'])
            CASFiles[name]['mpi'] = mpi
            if not options.split:
               CASFiles[name]['run'] = mpi.replace('<exename>',CASFiles[name]['exe']) #path.basename(CASFiles[name]['exe']))
            # ~~> no file handling necessary if hpcpass
            if hpcpass: continue
            # ~~> Creating the HOST file
            putFileContent(hostfile,hosts)
            # ~~> Creating the PARA file
            putFileContent('PARAL',[str(ncsize),str(len(CASFiles[name]['wir']+sep)),CASFiles[name]['wir']+sep,''])

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Getting out if compile only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if options.compileonly and not hpcpass:
      print '\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
      print '... Your simulation is ready for launch and you can now :\n'
      print '    +> re-run without option -x (--compileonly) or with option --run\n'
      if cfg['MPI'] == {}:
         print '    +> or run the following command within each local subdirectory:'
         for name in CASFiles:
            print '       -> in <'+CASFiles[name]['wir'].replace(CASFiles[name]['dir'],'.')+sep+'>',
            print ' run with EXE:\n                 ',path.basename(CASFiles[name]['exe'])
      else:
         print '    +> or run with MPI: '
         for name in CASFiles: print '                 '+CASFiles[name]['run']
      return []

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling the PARTEL command and partitioning ~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.split, to execute PARTEL if ncsize > 0
   #    - options.compileonly is out already
   if not options.merge and not options.run and ncsize > 0 and not hpcpass:
      print '\n... modifying run command to PARTEL instruction'
      for name in CASFiles:
         chdir(CASFiles[name]['wir'])
         # ~~> Path
         PARDir = pbin
         if cfg['PARTEL'] != {}:
            if cfg['PARTEL'].has_key('PATH'): PARDir = cfg['PARTEL']['PATH'].replace('<root>',cfg['root']).replace('<config>',pbin)
         # ~~> Call to PARTEL
         parcmd = path.join(pbin+sep+'partel'+cfg['SYSTEM']['sfx_exe']+' < PARTEL.PAR >> <partel.log>')
         if cfg['PARTEL'] != {}:
            if cfg['PARTEL'].has_key('EXEC'): parcmd = cfg['PARTEL']['EXEC']
         # <mpi_cmdexec> and <exename> should be known by now
         if cfg['MPI'] != {}:
            parcmd = parcmd.replace('<mpi_cmdexec>',CASFiles[name]['mpi']).replace('<exename>','')
         parcmd = parcmd.replace('<root>',cfg['root']).replace('<config>',PARDir)
         # >>> Add running command
         CASFiles[name].update({ 'par':parcmd })

         # ~~> Run PARTEL
         CONLIM = getCONLIM(CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['iFS'])    # Global CONLIM file
         try:
            runPartition(parcmd,CASFiles[name]['cas'],CONLIM,MODFiles[CASFiles[name]['code']]['iFS'],
                         ncsize,options.bypass,section_name,zone_name,options.use_link)
         except Exception as e:
            raise Exception([filterMessage({'name':'runCAS','msg':'Partioning primary input files of the CAS file: '+name},e,options.bypass)])
         for cplage in CASFiles[name]['with']:
            CONLIM = getCONLIM(CASFiles[name]['with'][cplage]['cas'],MODFiles[CASFiles[name]['with'][cplage]['code']]['iFS'])
            try:
               runPartition(parcmd,CASFiles[name]['with'][cplage]['cas'],CONLIM,MODFiles[CASFiles[name]['with'][cplage]['code']]['iFS'],
                            ncsize,options.bypass,section_name,zone_name,options.use_link)
            except Exception as e:
               raise Exception([filterMessage({'name':'runCAS','msg':'Partioning coupling input files'},e,options.bypass)])
   
   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Getting out if split only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if options.split and not hpcpass:
      print '\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
      print '... Your simulation is almost ready for launch. You need to compile your executable with the option -x (--compileonly)\n'
      return []          # Split only: do not proceed any further

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling sortie file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Outputs ...
   #    > CASFiles.values()[0]['sortie']
   print '\n... handling sortie file(s)'
   if not options.sortieFile:
      for name in CASFiles: CASFiles[name]['sortie'] = None
   else:
      if options.merge:
         # try re-using existing/latest sortie file with same root name
         for name in CASFiles: CASFiles[name]['sortie'] = path.basename(getLatestSortieFiles(path.join(CASFiles[name]['wir'],path.basename(name)))[0])
      else:
         # define the filename (basename) of the sortie file
         for name in CASFiles: CASFiles[name]['sortie'] = path.basename(CASFiles[name]['sortie'])+'.sortie'

   if not options.merge:
      print '\n\nRunning your simulation(s) :\n\
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Running the Executable ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - options.split is out already
   #    - options.compileonly is out already
   #    - if options.run, obvisouly this is the main run of the executable
   # Inputs ...
   #    - runcmd if options.hpc
   #    - CASFiles[name]['run'] and CASFiles[name]['sortie'] otherwise
      if cfg['HPC'] == {}:
         for name in CASFiles:  # /!\ This should be done in parallel when multiple CASFiles
            chdir(CASFiles[name]['wir'])
            print '\n\n'+CASFiles[name]['run']+'\n\n'
            # ~~> here you go run
            if not runCode(CASFiles[name]['run'],CASFiles[name]['sortie']):
               raise Exception([filterMessage({'name':'runCAS','msg':'Did not seem to catch that error...'})])

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling the HPC before running ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # You need to do this if ...
   #    - if options.run, obvisouly this is the main executable to run
   # Inputs ...
   #    - ncsize, nctilem ncnode, wdir, casdir, options, codeName
   #    - cfg['HPC']['STDIN'] and cfg['MPI']['HOSTS']
   #    - CASFiles.values()[0]['sortie'] and CASFiles.values()[0]['exe']
   #    - CASFiles[name]['run']
   # Outputs ...
   #    > runcmd and putFileContent(stdinfile,)
      elif not cfg['HPC'].has_key('STDIN'):
         raise Exception([{'name':'runCAS','msg':'\nI would need the key hpc_stdin in you configuration so I can launch your simulation on the HPC queue.'}])
      else:
         for name in CASFiles:  # /!\ This is being done in parallel when multiple CASFiles
            chdir(CASFiles[name]['wir'])
            print '\n... modifying run command to HPC instruction'
            # ~~> HPC Command line launching runcode
            hpccmd = getHPCCommand(cfg['HPC'])
            if not hpcpass: hpccmd = hpccmd.replace('<wdir>',CASFiles[name]['wir'])
            else: hpccmd = hpccmd.replace('<wdir>',CASFiles[name]['dir'])
            # ~~> HPC queueing script
            stdinfile = cfg['HPC']['STDIN'][0]   # only one key for now
            stdin = cfg['HPC']['STDIN'][1]
            if cfg['MPI'] != {}: stdin = stdin.replace('<hosts>',cfg['MPI']['HOSTS'])
            stdin = stdin.replace('<ncsize>',str(ncsize))
            stdin = stdin.replace('<nctile>',str(nctile))
            stdin = stdin.replace('<ncnode>',str(ncnode))
            stdin = stdin.replace('<email>',options.email)
            if ncruns == 1: stdin = stdin.replace('<jobname>',options.jobname)
            else: stdin = stdin.replace('<jobname>',name)
            stdin = stdin.replace('<time>',strftime("%Y-%m-%d-%Hh%Mmin%Ss", localtime()))
            stdin = stdin.replace('<queue>',options.hpc_queue)
            stdin = stdin.replace('<walltime>',options.walltime)
            stdin = stdin.replace('<codename>',codeName)
            stdin = stdin.replace('\n ','\n')
            if not hpcpass: stdin = stdin.replace('<wdir>',CASFiles[name]['wir'])      # /!\ HPC_STDIN in the TMP directory
            else: stdin = stdin.replace('<wdir>',CASFiles[name]['dir'])
            sortie = 'hpc-job.sortie'
            if options.sortieFile: sortie = CASFiles[name]['sortie']
            stdin = stdin.replace('<sortiefile>',sortie)
            # ~~> Recreate the <mpi_exec> (option --hpc)
            if not hpcpass:
               if 'exe' in CASFiles[name]: stdin = stdin.replace('<exename>',path.basename(CASFiles[name]['exe']))
               else: stdin = stdin.replace('<exename>',CASFiles[name]['run'])
               stdin = stdin.replace('<mpi_cmdexec>',CASFiles[name]['run'])   # /!\ serial mode
            # ~~> Recreate the runcode.py command 
            else:
               stdin = stdin.replace('<exename>',name)
               runcmd = 'runcode.py ' + codeName + ' --mpi '
               if options.configName != '': runcmd = runcmd + ' -c ' + options.configName
               if options.configFile != '': runcmd = runcmd + ' -f ' + options.configFile
               if options.rootDir != '': runcmd = runcmd + ' -r ' + options.rootDir
               if options.version != '': runcmd = runcmd + ' -v ' + options.version
               runcmd = runcmd + ' -s '
               if options.tmpdirectory: runcmd = runcmd + ' -t '
               runcmd = runcmd + ' -w ' + CASFiles[name]['wir']
               runcmd = runcmd + ' --nctile ' + str(nctile)
               runcmd = runcmd + ' --ncnode ' + str(ncnode)
               runcmd = runcmd + ' --ncsize ' + str(ncsize)
               if options.split: runcmd = runcmd + ' --split '
               if options.compileonly: runcmd = runcmd + ' -x '
               if options.merge: runcmd = runcmd + ' --merge '
               if options.run: runcmd = runcmd + ' --run '
               runcmd = runcmd + ' ' + name
               stdin = stdin.replace('<py_runcode>',runcmd)
            # ~~> Write to HPC_STDIN
            chdir(CASFiles[name]['wir'])
            putFileContent(stdinfile,stdin.split('\n'))

            # ~~> here you go run
            if not runCode(hpccmd,sortie):
               raise Exception([filterMessage({'name':'runCAS','msg':'Did not seem to catch that error...'})])
            print '... Your simulation ('+name+') has been launched through the queue.\n'
            if hpcpass: print '   +> You need to wait for completion before checking on results.\n'
            else: print '   +> You need to wait for completion before re-collecting files using the option --merge\n'
         return []

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Getting out if run only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #    - options.split and options.compileonly are out already
   if options.run:
      print '\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
      print '... Your simulation has been completed but you need to re-collect files using the option --merge\n'
      return []          # Run only: do not proceed any further

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling the recollection ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #    - options.split and options.compileonly and options run are out already
   if ncsize > 0:
      print '\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
      print '... merging separated result files\n'
      # ~~> Path
      PARDir = pbin
      if cfg['PARTEL'] != {}:
         if cfg['PARTEL'].has_key('PATH'): PARDir = cfg['PARTEL']['PATH'].replace('<root>',cfg['root']).replace('<config>',pbin)
      # ~~> GRETEL Executable
      execmd = path.join(PARDir,'gretel_autop'+cfg['SYSTEM']['sfx_exe'])
      # ~~> Run GRETEL
      for name in CASFiles:
         print '    +> ',name
         chdir(CASFiles[name]['wir'])
         GLOGEO = getGLOGEO(CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['iFS'])    # Global GEO file
         runRecollection(execmd,CASFiles[name]['cas'],GLOGEO,MODFiles[CASFiles[name]['code']]['oFS'],ncsize,options.bypass)
         for cplage in CASFiles[name]['with']:
            GLOGEO = getGLOGEO(CASFiles[name]['with'][cplage]['cas'],MODFiles[CASFiles[name]['with'][cplage]['code']]['iFS'])
            runRecollection(execmd,CASFiles[name]['with'][cplage]['cas'],GLOGEO,MODFiles[CASFiles[name]['with'][cplage]['code']]['oFS'],ncsize,options.bypass)

   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # ~~ Handling all output files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   print '\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
   print '... handling result files\n'
   sortiefiles = []
   for name in CASFiles:
      print '    +> ',name
      chdir(CASFiles[name]['wir'])
      files = processECR(CASFiles[name]['cas'],MODFiles[CASFiles[name]['code']]['oFS'],CASFiles[name]['dir'],CASFiles[name]['wir'],CASFiles[name]['sortie'],ncsize,options.bypass)
      sortiefiles.extend(files)
      for cplage in CASFiles[name]['with']:
         files = processECR(CASFiles[name]['with'][cplage]['cas'],MODFiles[CASFiles[name]['with'][cplage]['code']]['oFS'],CASFiles[name]['dir'],CASFiles[name]['wir'],None,ncsize,options.bypass)
         sortiefiles.extend(files)
   #except Exception as e:
   #   raise Exception([filterMessage({'name':'runCAS','msg':'I could not copy the output files back from the temporary directory:\n      '+wdir},e,options.bypass)])  # only one item here

   # ~~ Handling Directories ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if options.tmpdirectory:
      chdir(casdir)
      for name in CASFiles:
         try:
            removeDirectories(CASFiles[name]['wir'])
         except Exception as e:
            print '\n\nWarning: Your operating system does not allow me to remove a directory\n\n'

   return sortiefiles

# _____             ________________________________________________
# ____/ MAIN CALL  /_______________________________________________/
#

__author__="Sebastien E. Bourban; Noemie Durand"
__date__ ="$19-Jul-2010 08:51:29$"

def main(module=None):
   debug = False

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Reads config file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   print '\n\nLoading Options and Configurations\n\
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
   USETELCFG = ''
   if 'USETELCFG' in environ: USETELCFG = environ['USETELCFG']
   PWD = path.dirname(path.dirname(path.dirname(sys.argv[0])))
   SYSTELCFG = path.join(PWD,'configs')
   if 'SYSTELCFG' in environ: SYSTELCFG = environ['SYSTELCFG']
   if path.isdir(SYSTELCFG): SYSTELCFG = path.join(SYSTELCFG,'systel.cfg')
   parser = OptionParser("usage: %prog [options] \nuse -h for more help.")
   # ~~> Environment
   parser.add_option("-c", "--configname",type="string",dest="configName",default=USETELCFG,
      help="specify configuration name, default is randomly found in the configuration file" )
   parser.add_option("-f", "--configfile",type="string",dest="configFile",default=SYSTELCFG,
      help="specify configuration file, default is systel.cfg" )
   parser.add_option("-r", "--rootdir",type="string",dest="rootDir",default='',
      help="specify the root, default is taken from config file" )
   parser.add_option("-v", "--version",type="string",dest="version",default='',
      help="specify the version number, default is taken from config file" )
   parser.add_option("-s", "--sortiefile",action="store_true",dest="sortieFile",default=False,
      help="specify whether there is a sortie file, default is no" )
   parser.add_option("-t", "--tmpdirectory",action="store_false",dest="tmpdirectory",default=True,
      help="specify whether the temporary directory is removed, default is yes" )
   parser.add_option("-x", "--compileonly",action="store_true",dest="compileonly",default=False,
      help="specify whether to only create an executable but not run, default is no" )
   parser.add_option("-w", "--workdirectory",type="string",dest="wDir",default='',
      help="specify whether to re-run within a defined subdirectory" )
   # ~~> HPC / parallel
   if module is None: parser.add_option("--jobname",type="string",dest="jobname",default=path.basename(sys.argv[0]),
      help="specify a jobname for HPC queue tracking" )
   else: parser.add_option("--jobname",type="string",dest="jobname",default=module,
      help="specify a jobname for HPC queue tracking" )
   parser.add_option("--queue",type="string",dest="hpc_queue",default='',
      help="specify a queue for HPC queue tracking" )
   parser.add_option("--walltime",type="string",dest="walltime",default='01:00:00',
      help="specify a walltime for HPC queue tracking" )
   parser.add_option("--email",type="string",dest="email",default='s.bourban@hrwallingford.com',
      help="specify an e-mail adress to warn when HPC job is finished" )
   parser.add_option("--hosts",type="string",dest="hosts",default='',
      help="specify the list of hosts available for parallel mode, ';' delimited" )
   parser.add_option("--ncsize",type="string",dest="ncsize",default='',
      help="the number of processors forced in parallel mode" )
   parser.add_option("--nctile",type="string",dest="nctile",default='0',
      help="the number of core per node. ncsize/nctile is the number of compute nodes" )
   parser.add_option("--ncnode",type="string",dest="ncnode",default='',
      help="the number of of nodes. ncsize = ncnode*nctile is the total number of compute nodes" )
   parser.add_option("--mpi",action="store_true",dest="mpi",default=False,
      help="make sure the mpi command is executed, ignoring any hpc command" )
   parser.add_option("--split",action="store_true",dest="split",default=False,
      help="will only do the trace (and the split in parallel) if option there" )
   parser.add_option("--merge",action="store_true",dest="merge",default=False,
      help="will only do the output copying (and recollection in parallel) if option there" )
   parser.add_option("--run",action="store_true",dest="run",default=False,
      help="will only run the simulation if option there" )
   # ~~> Other
   parser.add_option("--use-link",action="store_true",dest="use_link",default=False,
      help="Will use link instead of copy in the temporary folder (Unix system only)" )
   options, args = parser.parse_args()
   # If module is given add it as first argument
   if not module is None:
       args.insert(0,module)
   if not path.isfile(options.configFile):
      print '\nNot able to get to the configuration file: ' + options.configFile + '\n'
      dircfg = path.abspath(path.dirname(options.configFile))
      if path.isdir(dircfg) :
         print ' ... in directory: ' + dircfg + '\n ... use instead: '
         _, _, filenames = walk(dircfg).next()
         for ffile in filenames :
            head,tail = path.splitext(ffile)
            if tail == '.cfg' : print '    +> ',ffile
      sys.exit(1)
   if len(args) < 2:
      print '\nThe name of the module to run and one CAS file at least are required\n'
      parser.print_help()
      sys.exit(1)
   # Checking if symlink is available
   if (options.use_link and not checkSymLink(options.use_link)):
      print '\nThe symlink option is only available on Linux systems. Remove the option and try again'
      sys.exit(1)

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Reads command line arguments ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   codeName = args[0]
   casFiles = args[1:]

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Works for only one configuration ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   cfgs = parseConfigFile(options.configFile,options.configName)
   cfgname = cfgs.iterkeys().next()

   # still in lower case
   if options.rootDir != '': cfgs[cfgname]['root'] = path.abspath(options.rootDir)
   if options.version != '': cfgs[cfgname]['version'] = options.version
   # recognised keys in the config
   if options.ncsize == '' and cfgs[cfgname].has_key('ncsize'): options.ncsize = cfgs[cfgname]['ncsize']
   if options.nctile == '' and cfgs[cfgname].has_key('nctile'): options.nctile = cfgs[cfgname]['nctile']
   if options.ncnode == '' and cfgs[cfgname].has_key('ncnode'): options.ncnode = cfgs[cfgname]['ncnode']

   # bypass errors and carries on
   options.bypass = False
   if options.split or options.merge or options.run:
      if options.wDir == '':
         print '\nPlease use option -w (--workdirectory) with either of the options --split, --run or --merge\n'
         sys.exit(1)
   if (options.split and options.merge) or (options.split and options.run) or (options.split and options.compileonly) or \
      (options.merge and options.run) or (options.merge and options.compileonly) or \
      (options.run and options.compileonly):
      print '\nOnly one of the options --split, --run, --merge or --compileonly (-x) can be used at a time'
      sys.exit(1)
   # parsing for proper naming
   cfg = parseConfig_RunningTELEMAC(cfgs[cfgname])
   
   print '\n\nRunning your CAS file for:\n\
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
   print '    +> configuration: ' +  cfgname
   if 'brief' in cfgs[cfgname]: print '    +> '+'\n    |  '.join(cfgs[cfgname]['brief'].split('\n'))
   print '    +> root:          ' +  cfgs[cfgname]['root']
   print '    +> version        ' +  cfgs[cfgname]['version']
   if options.wDir != '':
      print '    +> directory      ' +  options.wDir
      options.tmpdirectory = False
   print '\n\n\
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'

# >>> Check wether the config has been compiled for the runcode
   if options.compileonly: cfg['REBUILD'] = 1
   if codeName not in cfg['MODULES']:
      print '\nThe code requested is not installed on this system : ' + codeName + '\n'
      sys.exit(1)

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Reporting errors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   xcpts = MESSAGES()

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Run the Code from the CAS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   try: 
      runCAS(cfgname,cfg,codeName,casFiles,options)
   except Exception as e:
      xcpts.addMessages(filterMessage({'name':'_____________\nruncode::main:\n'},e,options.bypass))

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Reporting errors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if xcpts.notEmpty():
      print '\n\nHummm ... I could not complete my work.\n\
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n' \
      + xcpts.exceptMessages()

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Jenkins' success message ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   print '\n\nMy work is done\n\n'

   sys.exit(0)

if __name__ == "__main__":
   main(None)
