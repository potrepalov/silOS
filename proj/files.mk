# files.mk
#

C_SRC           := main.c
CPP_SRC         :=
AS_SRC          := timer.S

SRCDIR          := silOS
include makef.mk

# SRCDIR          := modbus
# include makef.mk

# SRCDIR          := crc
# crc             := -DCRC8_BY_TABLE -DMODBUS_CRC_BY_TABLE
# include makef.mk


#
# End of file  files.mk
