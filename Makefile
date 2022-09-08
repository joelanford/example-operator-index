
OPERATOR_NAME = example-operator
OPERATOR_CATALOG_DIR = catalog/$(OPERATOR_NAME)
OPERATOR_CATALOG_CONTRIBUTION = $(OPERATOR_CATALOG_DIR)/catalog.yaml
STEP_PASS = \033[0;32m
STEP_FAIL = \033[0;31m
NO_COLOR = \033[0m


# the catalog contribution target will enforce that the user selected an FBC build approach and generated the catalog
$(OPERATOR_CATALOG_CONTRIBUTION):
	@echo "$(OPERATOR_CATALOG_CONTRIBUTION) does not exist"; \
         echo ">>> you must first execute 'make basic' or 'make semver' to generate the catalog contribution"; \
         false;


# framework target provides two pieces that are helpful for any veneer approach:  
#  - an OWNERS file to provide default contribution control
#  - an .indexignore file to illustrate how to add content to the FBC contribution which should be 
#    excluded from validation via `opm validate`
.PHONY: framework
framework: CATALOG_OWNERS
	cp CATALOG_OWNERS $(OPERATOR_CATALOG_DIR)/OWNERS && \
         echo "OWNERS" > $(OPERATOR_CATALOG_DIR)/.indexignore


# basic target provides an example FBC generation from a `basic` veneer type.  
# this example takes a single file as input and generates a well-formed FBC operator contribution as an output
# the 'sanity' target should be used next to validate the output
.PHONY: basic
basic: bin/opm basic-veneer.yaml clean
	mkdir -p $(OPERATOR_CATALOG_DIR) && bin/opm alpha render-veneer basic -o yaml basic-veneer.yaml > $(OPERATOR_CATALOG_CONTRIBUTION)


# semver target provides an example FBC generation from a `semver` veneer type.  
# this example takes a single file as input and generates a well-formed FBC operator contribution as an output
# the 'sanity' target should be used next to validate the output
.PHONY: semver
semver: bin/opm semver-veneer.yaml clean
	mkdir -p $(OPERATOR_CATALOG_DIR) && bin/opm alpha render-veneer semver -o yaml semver-veneer.yaml > $(OPERATOR_CATALOG_CONTRIBUTION)


# sanity target illustrates FBC validation
# all FBC must pass opm validation in order to be able to be used in a catalog
.PHONY: sanity
sanity: bin/opm $(OPERATOR_CATALOG_CONTRIBUTION) preverify
	@bin/opm validate catalog; \
	 if [ $$? -ne 0 ] ; then \
             echo "opm validate catalog                                        $(STEP_FAIL)[FAIL]$(NO_COLOR)\n"; \
         else \
             echo "opm validate catalog                                        $(STEP_PASS)[PASS]$(NO_COLOR)\n"; \
         fi

# preverify target ensures that the operator name is consistent between the destination directory and the generated catalog
# since the veneer will be modified outside the build process but needs to be consistent with the directory name
.PHONY: preverify
preverify: $(OPERATOR_CATALOG_CONTRIBUTION)
	@./sanity.sh -q -n $(OPERATOR_NAME) -f $(OPERATOR_CATALOG_CONTRIBUTION); \
	 if [ $$? -ne 0 ] ; then \
	     echo "operator name MISMATCH in catalog contribution and Makefile $(STEP_FAIL)[FAIL]$(NO_COLOR)"; \
	     false; \
	 else \
	     echo "operator name matches in catalog contribution and Makefile  $(STEP_PASS)[PASS]$(NO_COLOR)"; \
	 fi


.PHONY: clean
clean:
	rm -rf catalog

OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(shell uname -m | sed 's/x86_64/amd64/')
OPM_VERSION ?= v1.26.1
bin/opm:
	mkdir -p bin
	curl -sLO https://github.com/operator-framework/operator-registry/releases/download/$(OPM_VERSION)/$(OS)-$(ARCH)-opm && chmod +x $(OS)-$(ARCH)-opm && mv $(OS)-$(ARCH)-opm bin/opm

YQ_VERSION=v4.22.1
YQ_BINARY=yq_$(OS)_$(ARCH)
bin/yq:
	if [ ! -e bin ] ; then mkdir -p bin; fi
	wget  https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O bin/${YQ_BINARY} && mv -f bin/${YQ_BINARY} bin/yq && chmod +x bin/yq
