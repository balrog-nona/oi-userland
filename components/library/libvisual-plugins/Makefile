#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright 2015 Alexander Pyhalov
#
BUILD_BITS=32_and_64
include ../../../make-rules/shared-macros.mk

COMPONENT_NAME= libvisual-plugins
COMPONENT_VERSION= 0.4.0
COMPONENT_REVISION= 2
COMPONENT_SUMMARY= Visualization plugins for the Libvisual library
COMPONENT_SRC= $(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE= $(COMPONENT_SRC).tar.bz2
COMPONENT_ARCHIVE_HASH= \
  sha256:518eef40a8a41946a0c2c0d59ede40d53ba7c142873af71aa4d2d8f297396601
COMPONENT_ARCHIVE_URL= \
  http://downloads.sourceforge.net/libvisual/$(COMPONENT_ARCHIVE)
COMPONENT_PROJECT_URL = http://sourceforge.net/projects/libvisual/
COMPONENT_LICENSE_FILE = COPYING
COMPONENT_LICENSE = GPLv2
COMPONENT_FMRI = library/desktop/libvisual/plugins
COMPONENT_CLASSIFICATION = Desktop (GNOME)/Libraries

TEST_TARGET=$(NO_TESTS)
include $(WS_MAKE_RULES)/common.mk


CONFIGURE_OPTIONS += --sysconfdir=/etc
CONFIGURE_OPTIONS += --enable-shared=yes
CONFIGURE_OPTIONS += --enable-static=no
CONFIGURE_OPTIONS += --disable-corona
CONFIGURE_OPTIONS += --disable-gforce
CONFIGURE_OPTIONS += --disable-esd
# Only 0.8 supported
CONFIGURE_OPTIONS += --disable-gstreamer-plugin

# Auto-generated dependencies
REQUIRED_PACKAGES += library/desktop/gdk-pixbuf
REQUIRED_PACKAGES += library/desktop/libvisual
REQUIRED_PACKAGES += library/glib2
REQUIRED_PACKAGES += system/library
REQUIRED_PACKAGES += system/library/math
