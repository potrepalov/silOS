# share/avr/silOS/files.mk
#

# fixed order
AS_SRC := release.S occur.S unlock.S activate.S deblock.S
AS_SRC += scheduler.S get.S

# free order
AS_SRC += lock.S islocked.S init.S prepare.S
AS_SRC += _getsignal.S set.S set-1.S reset.S isset.S wait.S
AS_SRC += owner.S tryget.S
AS_SRC += state.S trydown.S down.S up.S
AS_SRC += kill.S sleep.S suspend.S
AS_SRC += occur-1.S watch.S

C_SRC := vars.c


SRCDIR := idle
include makef.mk

#
# End of file  files.mk
