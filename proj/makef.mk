# makef.mk
#
# Copyrignt Potrepalov I.S.  potrepalov@list.ru
#
# This file included by Makefile
#
# Идея следующая
#
# В make-файле, из которого включается данный файл, определяется
# переменная SRCDIR как путь к каталогу с исходными файлами.  В этом
# каталоге размещается файл files.mk в котором определяются переменные
# C_SRC, CPP_SRC, AS_SRC как списки файлов с исходными текстами программы
# на языках Си, Си++, ассемблере соответственно.  Эти списки с помощью
# данного make-файла (makef.mk) добавляются к существующим спискам
# с добавлением к имени каждого файла с исходным текстом пути к каталогу
# из переменной SRCDIR.
#
# Также для каждого добавляемого к списку файла определяется переменная
# $(имя языка)_FLAGS_$(SRCDIR)_$(имя файла) с ключами компиляции,
# которые извлекаются из переменных:
# $(имя языка)FLAGS_$(SRCDIR) и $(имя файла)
#


EMPTY :=
LANGS := C CPP AS


####################################
# Start function section.
#

clear-name = $(strip $(1))

put =
# put = $(info $(1))

putvar = $(call put, $(strip $(1)) == '$($(strip $(1)))')
# putvar = $(call put, $(1) == '$($(1))')

# Condition put
cput = $(if $(strip $($(1))),$(call putvar,$(1)))

# Print flags
# pflags  lang, name
define pflags
$(eval $(call cput,$(1)FLAGS_$(2)))
$(eval $(call cput,$(2)))
$(eval $(call cput,$(2)_$(1)FLAGS))
endef


# Save_SRC  lang, dir
define Save_SRC
$(eval SAVE_$(1)_SRC_$(2) := $($(1)_SRC))
$(eval $(call cput,$(1)_SRC))
$(eval $(call cput,SAVE_$(1)_SRC_$(2)))
$(eval $(1)_SRC :=)
endef

# Save_SRCs  dir
Save_SRCs = $(foreach lang,$(LANGS), $(eval $(call Save_SRC,$(lang),$(1))))


# Restore_SRC  lang, dir
define Restore_SRC
$(eval $(1)_SRC := $(SAVE_$(1)_SRC_$(2)))
$(eval $(call cput,SAVE_$(1)_SRC_$(2)))
$(eval $(call cput,$(1)_SRC))
$(eval SAVE_$(1)_SRC_$(2) :=)
endef

# Restore_SRCs  dir
Restore_SRCs = $(foreach lang,$(LANGS), $(eval $(call Restore_SRC,$(lang),$(1))))



# Clear_Flags  lang, name
define Clear_Flags
$(eval $(1)FLAGS_$(2) :=)
$(eval $(2) :=)
$(eval $(2)_$(1)FLAGS :=)
endef

# Save_langFlags  lang, name, dir
define Save_langFlags
$(eval SAVE_LN_$(1)_$(2)_$(3) := $($(1)FLAGS_$(2)))
$(eval SAVE_NL_$(2)_$(1)_$(3) := $($(2)_$(1)FLAGS))
$(eval $(call cput,SAVE_LN_$(1)_$(2)_$(3)))
$(eval $(call cput,SAVE_NL_$(2)_$(1)_$(3)))
endef

# Restore_langFlags  lang, name, dir
define Restore_langFlags
$(eval $(1)FLAGS_$(2) := $(SAVE_LN_$(1)_$(2)_$(3)))
$(eval $(2)_$(1)FLAGS := $(SAVE_NL_$(2)_$(1)_$(3)))
$(eval $(call cput,$(1)FLAGS_$(2)))
$(eval $(call cput,$(2)_$(1)FLAGS))
$(eval SAVE_LN_$(1)_$(2)_$(3) :=)
$(eval SAVE_NL_$(2)_$(1)_$(3) :=)
endef

# Save_FilesFlags  dir
define Save_FilesFlags
$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), $(eval SAVE_N_$(name)_$(1) := $($(name))))))
$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), $(eval $(call cput,SAVE_N_$(name)_$(1))))))

$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call Save_langFlags,$(lang),$(name),$(1))))))

$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call Clear_Flags,$(lang),$(name),$(1))))))
endef

# Restore_FilesFlags  dir
define Restore_FilesFlags
$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC),$(eval $(name) := $(SAVE_N_$(name)_$(1))))))
$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC),$(eval SAVE_N_$(name)_$(1) :=))))
$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC),$(call cput,$(name)))))

$(eval $(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call Restore_langFlags,$(lang),$(name),$(1))))))

endef


# Save_DirFlags  dir, reldir
define Save_DirFlags
$(eval SAVE_DIR_$(1)_$(2) := $($(1)))
$(eval $(foreach lang,$(LANGS), \
    $(eval SAVE_$(lang)FLAGS_DIR_$(1)_$(2) := $($(lang)FLAGS_$(1)))))
$(eval $(foreach lang,$(LANGS), \
    $(eval SAVE_DIR_$(lang)FLAGS_$(1)_$(2) := $($(1)_$(lang)FLAGS))))

$(eval $(1) :=)
$(eval $(foreach lang,$(LANGS), $(eval $(lang)FLAGS_$(1) :=)))
$(eval $(foreach lang,$(LANGS), $(eval $(1)_$(lang)FLAGS :=)))

$(eval $(call cput,SAVE_DIR_$(1)_$(2)))
$(eval $(foreach lang,$(LANGS), \
    $(eval $(call cput,SAVE_$(lang)FLAGS_DIR_$(1)_$(2)))))
$(eval $(foreach lang,$(LANGS), \
    $(eval $(call cput,SAVE_DIR_$(lang)FLAGS_$(1)_$(2)))))
endef

# Restore_DirFlags  dir, reldir
define Restore_DirFlags
$(eval $(foreach lang,$(LANGS), \
    $(eval $(1)_$(lang)FLAGS := $(SAVE_DIR_$(lang)FLAGS_$(1)_$(2)))))
$(eval $(foreach lang,$(LANGS), \
    $(eval $(lang)FLAGS_$(1) := $(SAVE_$(lang)FLAGS_DIR_$(1)_$(2)))))
$(eval $(1) := $(SAVE_DIR_$(1)_$(2)))

$(eval $(call cput,$(1)))
$(eval $(foreach lang,$(LANGS), $(eval $(call cput,$(1)_$(lang)FLAGS))))
$(eval $(foreach lang,$(LANGS), $(eval $(call cput,$(lang)FLAGS_$(1)))))
endef


# Save_ExFiles  dir, reldir
define Save_ExFiles
$(eval SAVE_EXCLUDE_FILES_$(1)_$(2) := $(EXCLUDE_FILES))
$(eval SAVE_EXCLUDE_FILES :=)
$(eval $(call cput,SAVE_EXCLUDE_FILES_$(1)_$(2)))

$(eval $(foreach lang,$(LANGS), \
    $(eval SAVE_$(lang)_EXCLUDE_FILES_$(1)_$(2) := $($(lang)_EXCLUDE_FILES))))
$(eval $(foreach lang,$(LANGS), $(eval $(lang)_EXCULE_FILES :=)))
$(eval $(foreach lang,$(LANGS), \
    $(call cput,SAVE_$(lang)_EXCLUDE_FILES_$(1)_$(2))))
endef

# Restore_ExFiles  dir, reldir
define Restore_ExFiles
$(eval $(foreach lang,$(LANGS), \
    $(eval $(lang)_EXCLUDE_FILES := $(SAVE_$(lang)_EXCLUDE_FILES_$(1)_$(2)))))
$(eval $(foreach lang,$(LANGS), $(eval $(call cput,$(lang)_EXCLUDE_FILES))))

$(eval EXCULDE_FILES := $(SAVE_EXCLUDE_FILES_$(1)_$(2)))
$(eval $(call cput,EXCLUDE_FILES))
endef


#
# End function section.
####################################
# Start code.
#



$(call put)
$(call put, Start makef.mk)


ifeq ($(strip $(makef-nest-stack)),)
$(call put, Enter into  makef.mk  from project's  Makefile)
$(foreach lang,$(LANGS), $(eval REC_$(lang)_SRC :=))
$(foreach lang,$(LANGS), $(eval SAVE_$(lang)FLAGS := $($(lang)FLAGS)))
$(foreach lang,$(LANGS), $(eval $(lang)FLAGS :=))
LIST_MK_FILES := Makefile
else
$(call put, Recursive enter into  makef.mk  from  $(RELDIR)files.mk)
endif


last-nest-unit := $(lastword $(makef-nest-stack))
makef-nest-stack := $(makef-nest-stack) $(last-nest-unit)1
$(call putvar, makef-nest-stack)



ifeq ($(subst .,,$(strip $(SRCDIR))),)

$(call put, Process root project's directory)
SRCDIR :=
INCDIR :=
RELDIR :=

MK_DIRS := $(OBJDIR) $(MK_DIRS)

else

$(call put, Process submodule or subdirectory of submodule: SRCDIR == '$(SRCDIR)')
MK_DIRS := $(MK_DIRS) $(OBJDIR)/$(RELDIR)$(SRCDIR)

INCDIR := $(SRCDIR)/
RELDIR := $(RELDIR)$(INCDIR)

endif



$(call putvar, SRCDIR)
$(call putvar, INCDIR)
$(call putvar, RELDIR)

SAVE_RELDIR := $(SAVE_RELDIR) $(RELDIR)
$(call put, Save RELDIR: SAVE_RELDIR == '$(SAVE_RELDIR)')
SAVE_INCDIR_$(RELDIR) := $(INCDIR)
$(call put, Save INCDIR: SAVE_INCDIR_$(RELDIR) == '$(SAVE_INCDIR_$(RELDIR))')
SAVE_SRCDIR_$(RELDIR) := $(SRCDIR)
$(call put, Save SRCDIR: SAVE_SRCDIR_$(RELDIR) == '$(SAVE_SRCDIR_$(RELDIR))')

ifeq ($(strip $(SRCDIR)),)
DIRNAME := .
else
DIRNAME := $(SRCDIR)
endif

$(call put, Save dir's flags)
$(eval $(call Save_DirFlags,$(DIRNAME),$(RELDIR)))
$(eval $(call Save_ExFiles,$(DIRNAME),$(RELDIR)))

$(call put, )
$(call put, Save files' flags)
$(eval $(call Save_FilesFlags,$(RELDIR)))

$(call put, )
$(call put, Save SRCs)
$(eval $(call Save_SRCs,$(RELDIR)))
$(foreach lang,$(LANGS), $(eval $(call cput,REC_$(lang)_SRC)))

$(call put, )
$(call put, Save and record FLAGS)
$(foreach lang,$(LANGS), \
    $(eval SAVE_$(lang)RECFL_$(RELDIR) := $(REC_$(lang)FLAGS)))
$(foreach lang,$(LANGS), $(call cput,SAVE_$(lang)RECFL_$(RELDIR)))
$(foreach lang,$(LANGS), \
    $(eval REC_$(lang)FLAGS := $(REC_$(lang)FLAGS) $($(lang)FLAGS)))
$(foreach lang,$(LANGS), $(call cput,REC_$(lang)FLAGS))

$(call put, )
$(call put, Save FLAGS)
$(foreach lang,$(LANGS), $(eval SAVE_$(lang)FL_$(RELDIR) := $($(lang)FLAGS)))
$(foreach lang,$(LANGS), $(eval $(call cput,SAVE_$(lang)FL_$(RELDIR))))
$(foreach lang,$(LANGS), $(eval $(lang)FLAGS :=))



SAVE_LIST_MK_FILES_$(RELDIR) := $(LIST_MK_FILES)
LIST_MK_FILES := $(LIST_MK_FILES) $(RELDIR)files.mk





$(call put, )
$(call put, Process $(RELDIR)files.mk)
include $(RELDIR)files.mk




$(call put, Returned from  $(RELDIR)files.mk)
$(call put, )
$(call put, Restore SAVE_RELDIR)
SAVE_RELDIR := $(subst $(EMPTY) $(RELDIR),,$(SAVE_RELDIR))
$(call putvar, SAVE_RELDIR)
$(call putvar, RELDIR)
$(call putvar, SRCDIR)
$(call putvar, INCDIR)
INCDIR := $(SAVE_INCDIR_$(RELDIR))
$(call put, Restored INCDIR == '$(INCDIR)')

# Clear flags of proccessed directory
ifneq ($(strip $(SRCDIR)),)
$(SRCDIR) :=
endif

SRCDIR := $(SAVE_SRCDIR_$(RELDIR))
$(call put, Restored SRCDIR == '$(SRCDIR)')

$(foreach lang,$(LANGS), $(eval $(call cput,$(lang)FLAGS)))
$(call put, )
$(foreach lang,$(LANGS), $(eval $(call cput,$(lang)_SRC)))
$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call pflags,$(lang),$(name)))))


$(eval $(call Restore_ExFiles,$(SRCDIR),$(RELDIR)))
$(eval $(foreach lang,$(LANGS), \
    $(eval $(lang)_SRC := $(filter-out $(EXCLUDE_FILES),$($(lang)_SRC)))))
$(eval $(foreach lang,$(LANGS), \
    $(eval $(lang)_SRC := $(filter-out $($(lang)_EXCLUDE_FILES),$($(lang)_SRC)))))
$(call put, After EXCLUDING FILES)    
$(eval $(foreach lang,$(LANGS),$(call cput,$(lang)_SRC)))

EXCLUDE_FILES :=
$(eval $(foreach lang,$(LANGS), $(eval $(lang)_EXCLUDE_FILES :=)))


$(foreach lang,$(LANGS), $(eval $(call cput,REC_$(lang)FLAGS)))
$(foreach lang,$(LANGS), $(eval $(call cput,$(lang)FLAGS)))

# Установка флагов для файла
ifeq ($(strip $(SRCDIR)),)

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(if $(strip $($(lang)_FLAGS_$(RELDIR)$(name))),, \
            $(eval $(lang)_FLAGS_$(RELDIR)$(name) := $(strip \
                $($(lang)FLAGS_$(name)) \
		$(REC_$(lang)FLAGS) \
                $($(lang)FLAGS) \
                $($(name)) \
                $($(name)_$(lang)FLAGS) \
 )))))

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(call put, Set flags for '$(name)' from: $(strip \
                $(lang)FLAGS_$(name) \
		REC_$(lang)FLAGS \
                $(lang)FLAGS \
                $(name) \
                $(name)_$(lang)FLAGS \
 ))))


else

$(call put, )
$(call put, Restore dir's flags)
$(eval $(call Restore_DirFlags,$(SRCDIR),$(RELDIR)))

ifeq "$(SRCDIR)/" "$(RELDIR)"

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(if $(strip $($(lang)_FLAGS_$(RELDIR)$(name))),, \
            $(eval $(lang)_FLAGS_$(RELDIR)$(name) := $(strip \
	        $($(lang)FLAGS_$(SRCDIR)) \
                $($(lang)FLAGS_$(name)) \
                $($(lang)FLAGS_$(SRCDIR)/$(name)) \
		$(REC_$(lang)FLAGS) \
                $($(lang)FLAGS) \
                $($(name)) \
		$($(SRCDIR)) \
                $($(SRCDIR)/$(name)) \
                $($(name)_$(lang)FLAGS) \
		$($(SRCDIR)_$(lang)FLAGS) \
                $($(SRCDIR)/$(name)_$(lang)FLAGS) \
 )))))

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call put, Set flags for '$(name)' from: $(strip \
	        $(lang)FLAGS_$(SRCDIR) \
                $(lang)FLAGS_$(name) \
                $(lang)FLAGS_$(SRCDIR)/$(name) \
		REC_$(lang)FLAGS \
                $(lang)FLAGS \
                $(name) \
		$(SRCDIR) \
                $(SRCDIR)/$(name) \
                $(name)_$(lang)FLAGS \
		$(SRCDIR)_$(lang)FLAGS \
                $(SRCDIR)/$(name)_$(lang)FLAGS \
 )))))

else

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(if $(strip $($(lang)_FLAGS_$(RELDIR)$(name))),, \
            $(eval $(lang)_FLAGS_$(RELDIR)$(name) := $(strip \
	        $($(lang)FLAGS_$(SRCDIR)) \
                $($(lang)FLAGS_$(name)) \
                $($(lang)FLAGS_$(SRCDIR)/$(name)) \
                $($(lang)FLAGS_$(RELDIR)$(name)) \
		$(REC_$(lang)FLAGS) \
                $($(lang)FLAGS) \
                $($(name)) \
		$($(SRCDIR)) \
                $($(RELDIR:%/=%)) \
                $($(SRCDIR)/$(name)) \
                $($(RELDIR)$(name)) \
                $($(name)_$(lang)FLAGS) \
		$($(SRCDIR)_$(lang)FLAGS) \
                $($(SRCDIR)/$(name)_$(lang)FLAGS) \
                $($(RELDIR)$(name)_$(lang)FLAGS) \
 )))))

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call put, Set flags for '$(name)' from: $(strip \
	        $(lang)FLAGS_$(SRCDIR) \
                $(lang)FLAGS_$(name) \
                $(lang)FLAGS_$(SRCDIR)/$(name) \
                $(lang)FLAGS_$(RELDIR)$(name) \
		REC_$(lang)FLAGS \
                $(lang)FLAGS \
                $(name) \
		$(SRCDIR) \
                $(RELDIR:%/=%) \
                $(SRCDIR)/$(name) \
                $(RELDIR)$(name) \
                $(name)_$(lang)FLAGS \
		$(SRCDIR)_$(lang)FLAGS \
                $(SRCDIR)/$(name)_$(lang)FLAGS \
                $(RELDIR)$(name)_$(lang)FLAGS \
 )))))

endif

# Очистка флагов файлов
$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call Clear_Flags,$(lang),$(SRCDIR)/$(name)))))

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call Clear_Flags,$(lang),$(RELDIR)$(name)))))

endif


$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call putvar,$(lang)_FLAGS_$(RELDIR)$(name)))))

# Очистка флагов файлов
$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call Clear_Flags,$(lang),$(name)))))

# Добавление пути к именам файлов
$(foreach lang,$(LANGS), $(eval $(lang)_SRC := $($(lang)_SRC:%=$(RELDIR)%)))
$(foreach lang,$(LANGS), $(eval $(call cput,$(lang)_SRC)))


$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(lang)_MK_FILES_$(name) := $(LIST_MK_FILES))))

$(foreach lang,$(LANGS), \
    $(foreach name,$($(lang)_SRC), \
        $(eval $(call putvar,$(lang)_MK_FILES_$(name)))))

LIST_MK_FILES := $(SAVE_LIST_MK_FILES_$(RELDIR))


# Формирование сборного списка (новые файлы в конец списка)
$(foreach lang,$(LANGS), \
    $(eval REC_$(lang)_SRC := $(strip $(REC_$(lang)_SRC) $($(lang)_SRC) )))
$(foreach lang,$(LANGS), $(eval $(call cput,REC_$(lang)_SRC)))


$(call put, )
$(call put, Restore FLAGS)
$(foreach lang,$(LANGS), $(eval $(lang)FLAGS := $(SAVE_$(lang)FL_$(RELDIR))))
$(foreach lang,$(LANGS), $(eval $(call cput,$(lang)FLAGS)))
$(foreach lang,$(LANGS), $(eval SAVE_$(lang)FL_$(RELDIR) :=))


$(call put, )
$(call put, Restore recorded FLAGS)
$(foreach lang,$(LANGS), \
    $(eval REC_$(lang)FLAGS := $(SAVE_$(lang)RECFL_$(RELDIR))))
$(foreach lang,$(LANGS), $(call cput,REC_$(lang)FLAGS))    



$(call put, )
$(call put, Restore SRCs)
$(eval $(call Restore_SRCs,$(RELDIR)))


$(call put, Restore files' flags)
$(eval $(call Restore_FilesFlags,$(RELDIR)))




$(call put, )
$(call put, Restore RELDIR)
RELDIR := $(lastword $(SAVE_RELDIR))
$(call putvar, RELDIR)



$(call put, )

last-nest-unit := $(lastword $(makef-nest-stack))
makef-nest-stack := $(strip $(subst $(last-nest-unit),,$(makef-nest-stack)))

ifeq ($(strip $(makef-nest-stack)),)

#$(call put, Prepare to return to Makefile)

ifeq ($(subst .,,$(strip $(SRCDIR))),)
$(foreach lang,$(LANGS), \
    $(eval $(lang)_SRC := $(strip $($(lang)_SRC) $(REC_$(lang)_SRC) )))
else
$(foreach lang,$(LANGS), \
    $(eval $(lang)_SRC := $(strip $(REC_$(lang)_SRC) $($(lang)_SRC) )))
endif
$(foreach lang,$(LANGS), $(eval $(lang)FLAGS := $(SAVE_$(lang)FLAGS)))
$(foreach lang,$(LANGS), $(eval SAVE_$(lang)FLAGS :=))
$(call put, Exit from  makef.mk  to  Makefile)
else
$(call put, Exit from  makef.mk  to  $(RELDIR)files.mk)
endif


#
# End of file  makef.mk
