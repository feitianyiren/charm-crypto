
CONFIG=config.mk
include ./${CONFIG}
export CONFIG_FILE=${CONFIG}

# user config options
setup1=$(shell mkdir -p /tmp/build-charm)
dest_build=/tmp/build-charm

# gmp source
gmp_version=gmp-5.0.2
gmp_url=http://ftp.gnu.org/gnu/gmp/${gmp_version}.tar.gz
gmp_options=CC="${CC}" CPP="${CPP}"

# pbc source
pbc_version=pbc-0.5.12
pbc_url=http://crypto.stanford.edu/pbc/files/${pbc_version}.tar.gz
pbc_options=CC="${CC}" CPP="${CPP}"
DESTDIR=${prefix}

# python packages
pyparse_version=pyparsing-1.5.5
pyparse_url=http://cheeseshop.python.org/packages/source/p/pyparsing/${pyparse_version}.tar.gz

all:
	@echo "make deps - Build the charm dependencies."
	@echo "make build - Build the charm framework and install dependencies."
	@echo "make source - Create source package."
	@echo "make install - Install on local system."
	@echo "make clean - Get rid of scratch and byte files."
	@echo "make test  - Run Unit Tests."
	@echo "make doc   - Compile documentation"

.PHONY: setup
setup:
	@echo "Setup build/staging directories"
	set -x
	${setup1}
	set +x

.PHONY: build-pyparse
build-pyparse:
	@echo "Build and install Pyparsing"
	set -x
	if test "${PYPARSING}" = "yes" ; then \
	   echo "Pyparsing installed already."; \
	elif [ ! -f ${pyparse_version}.tar.gz ]; then \
	   ${wget} ${pyparse_url}; \
	   tar -zxf ${pyparse_version}.tar.gz -C ${dest_build}; \
	   cd ${dest_build}/${pyparse_version}; \
	   ${PYTHON} setup.py install ${PYTHON-FLAGS}; \
	else \
	   tar -zxf ${pyparse_version}.tar.gz -C ${dest_build}; \
	   cd ${dest_build}/${pyparse_version}; \
	   ${PYTHON} setup.py install ${PYTHON-FLAGS}; \
	fi
	set +x
	sed "s/PYPARSING=no/PYPARSING=yes/g" ${CONFIG} > ${CONFIG}.new; mv ${CONFIG}.new ${CONFIG} 

.PHONY: build-gmp
build-gmp:
	@echo "Building the GMP library"
	set -x
	if test "${HAVE_LIBGMP}" = "yes" ; then \
           echo "GMP installed already."; \
	elif [ ! -f ${gmp_version}.tar.gz ]; then \
	   ${wget} ${gmp_url}; \
	   tar -zxf ${gmp_version}.tar.gz -C ${dest_build}; \
	   cd ${dest_build}/${gmp_version}; ./configure ${gmp_options} --prefix=${DESTDIR} ${OS-FLAGS}; \
	   ${MAKE} install; \
	   echo "GMP install: OK"; \
        else \
	   tar -zxf ${gmp_version}.tar.gz -C ${dest_build}; \
	   cd ${dest_build}/${gmp_version}; ./configure ${gmp_options} --prefix=${DESTDIR} ${OS-FLAGS}; \
	   ${MAKE} install; \
	   echo "GMP install: OK"; \
	fi
	set +x
	sed "s/HAVE_LIBGMP=no/HAVE_LIBGMP=yes/g" ${CONFIG} > ${CONFIG}.new; mv ${CONFIG}.new ${CONFIG} 

.PHONY: build-pbc
build-pbc:
	@echo "Building the PBC library"
	set -x
	if test "${HAVE_LIBPBC}" = "yes" ; then \
	   echo "PBC installed already."; \
	elif [ ! -f ${pbc_version}.tar.gz ]; then \
	   ${wget} ${pbc_url}; \
	   tar -zxf ${pbc_version}.tar.gz -C ${dest_build}; \
	   cd ${dest_build}/${pbc_version}; ./configure ${pbc_options} --prefix=${DESTDIR} ${OS-FLAGS}; \
	   ${MAKE} install; \
	   echo "PBC install: OK"; \
	else \
	   tar -zxf ${pbc_version}.tar.gz -C ${dest_build}; \
	   cd ${dest_build}/${pbc_version}; ./configure ${pbc_options} --prefix=${DESTDIR} ${OS-FLAGS}; \
	   ${MAKE} install; \
	   echo "PBC install: OK"; \
	fi
	set +x
	sed "s/HAVE_LIBPBC=no/HAVE_LIBPBC=yes/g" ${CONFIG} > ${CONFIG}.new; mv ${CONFIG}.new ${CONFIG} 
	
.PHONY: deps
deps: build-gmp build-pbc
	@echo "Dependencies build complete."

.PHONY: build
build: setup build-gmp build-pbc build-pyparse
	@echo "Building the Charm Framework"
	${PYTHON} setup.py build ${PYTHON-FLAGS}
	@echo "Complete"

.PHONY: source
source:
	$(PYTHON) setup.py sdist --formats=gztar,zip # --manifest-only

.PHONY: install
install:
	$(PYTHON) setup.py install
	
.PHONY: test
test:
	$(PYTHON) tests/all_tests.py
#	find . -name '*.pyc' -delete

.PHONY: doc
doc:
	if test "${BUILD_DOCS}" = "yes" ; then \
	${MAKE} -C doc html; \
	fi

# .PHONY: buildrpm
# buildrpm:
#        $(PYTHON) setup.py bdist_rpm # --post-install=rpm/postinstall --pre-uninstall=rpm/preuninstall

.PHONY: builddeb
builddeb:
        # build the source package in the parent directory
        # then rename it to project_version.orig.tar.gz
	$(PYTHON) setup.py sdist --dist-dir=../ --prune
	#rename -f 's/$(PROJECT)-(.*)\.tar\.gz/$(PROJECT)_$$1\.orig\.tar\.gz/' ../*
        # build the package
	#dpkg-buildpackage -i -I -rfakeroot

.PHONY: clean
clean:
	$(PYTHON) setup.py clean
#	cd doc; $(MAKE) clean
#        $(MAKE) -f $(CURDIR)/debian/rules clean
	rm -rf build/ dist/ ${dest_build} MANIFEST
	rm ${CONFIG}
	find . -name '*.pyc' -delete


