# Copyright 2013-2020, Stephen Fryatt (info@stevefryatt.org.uk)
#
# This file is part of WinKeys:
#
#   http://www.stevefryatt.org.uk/software/
#
# Licensed under the EUPL, Version 1.2 only (the "Licence");
# You may not use this work except in compliance with the
# Licence.
#
# You may obtain a copy of the Licence at:
#
#   http://joinup.ec.europa.eu/software/page/eupl
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the Licence is
# distributed on an "AS IS" basis, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.
#
# See the Licence for the specific language governing
# permissions and limitations under the Licence.

# This file really needs to be run by GNUMake.
# It is intended for native compilation on Linux (for use in a GCCSDK
# environment) or cross-compilation under the GCCSDK.

# Set VERSION to build using a version number and not an SVN revision.

.PHONY: all clean application documentation release backup

# The build date.

BUILD_DATE := $(shell date "+%d %b %Y")
HELP_DATE := $(shell date "+%-d %B %Y")

# Construct version or revision information.

ifeq ($(VERSION),)
  RELEASE := $(shell svnversion --no-newline)
  VERSION := r$(RELEASE)
  RELEASE := $(subst :,-,$(RELEASE))
  HELP_VERSION := ----
else
  RELEASE := $(subst .,,$(VERSION))
  HELP_VERSION := $(VERSION)
endif

$(info Building with version $(VERSION) ($(RELEASE)) on date $(BUILD_DATE))

# The archive to assemble the release files in.  If $(RELEASE) is set, then the file can be given
# a standard version number suffix.

ZIPFILE := winkeys$(RELEASE).zip
SRCZIPFILE := winkeys$(RELEASE)src.zip
BUZIPFILE := winkeys$(shell date "+%Y%m%d").zip

# Build Tools

AS := $(wildcard $(GCCSDK_INSTALL_CROSSBIN)/*asasm)
STRIP := $(wildcard $(GCCSDK_INSTALL_CROSSBIN)/*strip)
CC := gcc

MKDIR := mkdir
RM := rm -rf
CP := cp

ZIP := $(GCCSDK_INSTALL_ENV)/bin/zip

LIBPATHS := BASIC:$(SFTOOLS_BASIC)/

MANTOOLS := $(SFTOOLS_BIN)/mantools
BINDHELP := $(SFTOOLS_BIN)/bindhelp
TEXTMERGE := $(SFTOOLS_BIN)/textmerge
MENUGEN := $(SFTOOLS_BIN)/menugen
TOKENIZE := $(SFTOOLS_BIN)/tokenize

# Build Flags

ASFLAGS :=
STRIPFLAGS := -O binary
ZIPFLAGS := -x "*/.svn/*" -r -, -9
SRCZIPFLAGS := -x "*/.svn/*" -r -9
BUZIPFLAGS := -x "*/.svn/*" -r -9
BINDHELPFLAGS := -f -r -v
TOKFLAGS := -verbose -crunch EIrW -warn pV -swi -swis $(GCCSDK_INSTALL_CROSSBIN)/../arm-unknown-riscos/include/swis.h -swis $(GCCSDK_INSTALL_ENV)/include/TokenizeSWIs.h

# Set up the various build directories.

SRCDIR := src
MANUAL := manual
OBJDIR := obj
OUTDIR := build


# Set up the named target files.

MODULE := WinKeys,ffa
README := ReadMe,fff
LICENCE := Licence,fff
CONFAPP := !WinKeys
RUNIMAGE := !RunImage,ffb


# Set up the source files.

MANSRC := Source
MANSPR := ManSprite
READMEHDR := Header
LICSRC ?= Licence

OBJS := WinKey.o

SRCS := Plugin.bbt

# Build everything, but don't package it for release.

all: application documentation


# Build the application and its supporting binary files.

application: $(OUTDIR)/$(MODULE) $(OUTDIR)/$(CONFAPP)/$(RUNIMAGE)

# Create the output folder if it doesn't exist.

$(OUTDIR):
	$(MKDIR) $(OUTDIR)

# Build the complete module from the object files.

OBJS := $(addprefix $(OBJDIR)/, $(OBJS))

$(OUTDIR)/$(MODULE): $(OBJS) $(OBJDIR) $(OUTDIR)
	$(STRIP) $(STRIPFLAGS) -o $(OUTDIR)/$(MODULE) $(OBJS)

# Build the configure plugin application from the source files.

SRCS := $(addprefix $(SRCDIR)/, $(SRCS))

$(OUTDIR)/$(CONFAPP)/$(RUNIMAGE): $(SRCS) $(OUTDIR)
	$(TOKENIZE) $(TOKFLAGS) $(firstword $(SRCS)) -link -out $(OUTDIR)/$(CONFAPP)/$(RUNIMAGE) -path $(LIBPATHS) -define 'build_date$$=$(BUILD_DATE)' -define 'build_version$$=$(VERSION)'

# Create a folder to hold the object files.

$(OBJDIR):
	$(MKDIR) $(OBJDIR)

# Build the object files, and identify their dependencies.

$(OBJDIR)/%.o: $(SRCDIR)/%.s $(OBJDIR)
	$(AS) $(ASFLAGS) -PreDefine 'Include SETS "$(GCCSDK_INSTALL_ENV)/include"' -PreDefine 'BuildDate SETS "\"$(BUILD_DATE)\""' -PreDefine 'BuildVersion SETS "\"$(VERSION)\""' -o $@ $<

# Build the documentation

documentation: $(OUTDIR)/$(README) $(OUTDIR)/$(LICENCE)

$(OUTDIR)/$(README): $(MANUAL)/$(MANSRC) $(OUTDIR)
	$(MANTOOLS) -MTEXT -I$(MANUAL)/$(MANSRC) -O$(OUTDIR)/$(README) -D'version=$(HELP_VERSION)' -D'date=$(HELP_DATE)'

$(OUTDIR)/$(LICENCE): $(LICSRC) $(OUTDIR)
	$(CP) $(LICSRC) $(OUTDIR)/$(LICENCE)


# Build the release Zip file.

release: clean all
	$(RM) ../$(ZIPFILE)
	(cd $(OUTDIR) ; $(ZIP) $(ZIPFLAGS) ../../$(ZIPFILE) $(CONFAPP) $(MODULE) $(README) $(LICENCE))
	$(RM) ../$(SRCZIPFILE)
	$(ZIP) $(SRCZIPFLAGS) ../$(SRCZIPFILE) $(OUTDIR) $(SRCDIR) $(MANUAL) Makefile


# Build a backup Zip file

backup:
	$(RM) ../$(BUZIPFILE)
	$(ZIP) $(BUZIPFLAGS) ../$(BUZIPFILE) *


# Clean targets

clean:
	$(RM) $(OBJDIR)/*
	$(RM) $(OUTDIR)/$(MODULE)
	$(RM) $(OUTDIR)/$(README)
	$(RM) $(OUTDIR)/$(LICENCE)
	$(RM) $(OUTDIR)/$(CONFAPP)/$(RUNIMAGE)

