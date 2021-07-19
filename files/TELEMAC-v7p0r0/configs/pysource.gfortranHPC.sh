# Path to telemac root dir
export HOMETEL=/usr/TELEMAC-v7p0r0
# Adding python scripts to PATH
export PATH=$HOMETEL/scripts/python3:.:$PATH
# Configuration file
export SYSTELCFG=$HOMETEL/configs/systel.cfg
# Name of the configuration to use
export USETELCFG=gfortranHPC
# Path to this file
export SOURCEFILE=$HOMETEL/configs/pysource.gfortranHPC.sh
### Python
# To force python to flush its output
export PYTHONUNBUFFERED='true'
### API
export PYTHONPATH=$HOMETEL/scripts/python3:$PYTHONPATH
export LD_LIBRARY_PATH=$HOMETEL/builds/$USETELCFG/wrap_api/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$HOMETEL/builds/$USETELCFG/wrap_api/lib:$PYTHONPATH
###
### EXTERNAL LIBRARIES -----------------------------------------------------------
###
### METIS -------------------------------------------------------------
export METISHOME=/usr/metis-5.1.0
