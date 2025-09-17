#####################################################################################
## Thermochimica Makefile (Fortran 95+ core, C/C++ API, tests & docs)
## - Auto source discovery (no manual lists)
## - Correct Fortran module ordering via stamp
## - FC normalization (no accidental f77)
## - macOS/Linux BLAS/LAPACK selection (overridable)
#####################################################################################

# ====== Toolchain (overridable) ====================================================
AR      ?= ar
RANLIB  ?= ranlib
FC      ?= gfortran
CXX     ?= g++
CC      ?= gcc

# --- Beat GNU Make's built-in FC=f77 default & any accidental f77 in env
ifeq ($(origin FC), default)
  override FC := gfortran
endif
ifneq (,$(findstring f77,$(notdir $(FC))))
  ifeq ($(ALLOW_F77),)
    $(info FC is '$(FC)'; forcing gfortran for .f90 sources. Set ALLOW_F77=1 to keep it.)
    override FC := gfortran
  endif
endif
override F77 := $(FC)
override F90 := $(FC)
override F95 := $(FC)

# ====== Layout =====================================================================
CURDIR    := $(shell pwd)
SRC_DIR   := src
EXE_DIR   := $(SRC_DIR)/exec
TST_DIR   := test
DTST_DIR  := $(TST_DIR)/daily
OBJ_DIR   := obj
BIN_DIR   := bin
LIB_DIR   := lib
DOC_DIR   := doc
TEX_DIR   := $(DOC_DIR)/latex

# ====== Config =====================================================================
DATA_DIR     ?= $(CURDIR)/data
FFPE_TRAPS   ?= zero
MODE         ?= release

COMMON_FCFLAGS  = -ffree-line-length-none -fno-automatic -fbounds-check -cpp \
                  -D DATA_DIRECTORY=\"$(DATA_DIR)\" -I$(OBJ_DIR) -J$(OBJ_DIR)
COMMON_CXXFLAGS = -std=gnu++17
COMMON_CFLAGS   =

ifeq ($(MODE),debug)
  FCFLAGS  ?= -Wall -O0 -g -ffpe-trap=$(FFPE_TRAPS) $(COMMON_FCFLAGS)
  CXXFLAGS ?= -O0 -g $(COMMON_CXXFLAGS)
  CFLAGS   ?= -O0 -g $(COMMON_CFLAGS)
else
  FCFLAGS  ?= -Wall -O2 -ffpe-trap=$(FFPE_TRAPS) $(COMMON_FCFLAGS)
  CXXFLAGS ?= -O2 $(COMMON_CXXFLAGS)
  CFLAGS   ?= -O2 $(COMMON_CFLAGS)
endif

# ====== BLAS/LAPACK & link flags ===================================================
UNAME_S := $(shell uname -s)

ifdef BLASLAPACK
  LDLIBS_BLAS := $(BLASLAPACK)
else
  HAVE_PKGCONF := $(shell sh -c 'command -v pkg-config >/dev/null 2>&1 && echo yes || echo no')
  ifeq ($(HAVE_PKGCONF),yes)
    LDLIBS_BLAS := $(shell pkg-config --libs lapack 2>/dev/null || true)
  endif
  ifeq ($(strip $(LDLIBS_BLAS)),)
    ifeq ($(UNAME_S),Darwin)
      LDLIBS_BLAS := -framework Accelerate
    else
      LDLIBS_BLAS := -llapack -lblas
    endif
  endif
endif

ifeq ($(UNAME_S),Darwin)
  LDFLAGS ?=
  LDLIBS  ?= $(LDLIBS_BLAS)
else
  LDFLAGS ?=
  LDLIBS  ?= $(LDLIBS_BLAS) -lgfortran
endif

# ====== Libraries ==================================================================
TC_LIB    := libthermochimica.a
TC_C_LIB  := libthermoc.a

# ====== Source discovery ===========================================================
# Core Fortran for the library (exclude executables & tests)
CORE_F90_SRCS := $(shell find $(SRC_DIR) -type f \
                  -not -path "$(EXE_DIR)/*" -not -path "$(TST_DIR)/*" \
                  \( -iname '*.f90' -o -iname '*.F90' \))

# Split modules vs non-modules (case-insensitive Module*.f90/F90)
MOD_SRCS  := $(filter %/Module%.f90 %/Module%.F90,$(CORE_F90_SRCS))
F90_NMOD  := $(filter-out $(MOD_SRCS),$(CORE_F90_SRCS))

# Map to obj/… and normalize extensions
F90_MOD_OBJS := $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/%,$(MOD_SRCS))
F90_MOD_OBJS := $(F90_MOD_OBJS:.f90=.o)
F90_MOD_OBJS := $(F90_MOD_OBJS:.F90=.o)

F90_OBJS := $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/%,$(F90_NMOD))
F90_OBJS := $(F90_OBJS:.f90=.o)
F90_OBJS := $(F90_OBJS:.F90=.o)

# C / C++ in src/ (exclude exec & tests) — used for the C/C++ API lib if present
C_SRCS    := $(shell find $(SRC_DIR) -type f -not -path "$(EXE_DIR)/*" -not -path "$(TST_DIR)/*" -iname '*.c')
CXX_SRCS  := $(shell find $(SRC_DIR) -type f -not -path "$(EXE_DIR)/*" -not -path "$(TST_DIR)/*" \
                \( -iname '*.C' -o -iname '*.cc' -o -iname '*.cpp' -o -iname '*.cxx' \))

C_OBJS    := $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/%,$(C_SRCS:.c=.o))
CXX_OBJS  := $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/%,$(CXX_SRCS))
CXX_OBJS  := $(CXX_OBJS:.C=.o)
CXX_OBJS  := $(CXX_OBJS:.cc=.o)
CXX_OBJS  := $(CXX_OBJS:.cpp=.o)
CXX_OBJS  := $(CXX_OBJS:.cxx=.o)

# Prefer the named C API files if present
C_API_SRCS := $(shell find $(SRC_DIR) -type f \( -iname 'Thermochimica-c.*' -o -iname 'Thermochimica-cxx.*' \))
ifeq ($(strip $(C_API_SRCS)),)
  C_API_OBJS := $(C_OBJS) $(CXX_OBJS)
else
  C_API_OBJS := $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/%,$(C_API_SRCS))
  C_API_OBJS := $(C_API_OBJS:.c=.o)
  C_API_OBJS := $(C_API_OBJS:.C=.o)
  C_API_OBJS := $(C_API_OBJS:.cc=.o)
  C_API_OBJS := $(C_API_OBJS:.cpp=.o)
  C_API_OBJS := $(C_API_OBJS:.cxx=.o)
endif

# Executable/test mains
EXEC_SRCS  := $(shell find $(EXE_DIR) -type f \( -iname '*.f90' -o -iname '*.F90' \))
TEST_SRCS  := $(shell find $(TST_DIR) -maxdepth 1 -type f \( -iname '*.f90' -o -iname '*.F90' \))
DTEST_SRCS := $(shell find $(DTST_DIR) -type f \( -iname '*.f90' -o -iname '*.F90' \))

EXEC_OBJS  := $(patsubst $(EXE_DIR)/%,$(OBJ_DIR)/%,$(EXEC_SRCS))
EXEC_OBJS  := $(EXEC_OBJS:.f90=.o)
EXEC_OBJS  := $(EXEC_OBJS:.F90=.o)

TEST_OBJS  := $(patsubst $(TST_DIR)/%,$(OBJ_DIR)/%,$(TEST_SRCS))
TEST_OBJS  := $(TEST_OBJS:.f90=.o)
TEST_OBJS  := $(TEST_OBJS:.F90=.o)

DTEST_OBJS := $(patsubst $(DTST_DIR)/%,$(OBJ_DIR)/%,$(DTEST_SRCS))
DTEST_OBJS := $(DTEST_OBJS:.f90=.o)
DTEST_OBJS := $(DTEST_OBJS:.F90=.o)

EXEC_BINS  := $(patsubst $(OBJ_DIR)/%.o,$(BIN_DIR)/%,$(EXEC_OBJS))
TEST_BINS  := $(patsubst $(OBJ_DIR)/%.o,$(BIN_DIR)/%,$(TEST_OBJS))
DTEST_BINS := $(patsubst $(OBJ_DIR)/%.o,$(BIN_DIR)/%,$(DTEST_OBJS))

# ====== Default targets ============================================================
.PHONY: all libs exe dailytest test debug release help
all: libs exe
libs: $(LIB_DIR)/$(TC_LIB) $(if $(C_API_OBJS),$(LIB_DIR)/$(TC_C_LIB),)
exe:  $(EXEC_BINS) $(TEST_BINS)
dailytest: $(DTEST_BINS)
test: all dailytest
debug: ; @$(MAKE) MODE=debug
release: ; @$(MAKE) MODE=release
help:
	@echo "Targets:"
	@echo "  all (default)  - build libs and executables"
	@echo "  libs           - build static libraries"
	@echo "  exe            - build executables in $(EXE_DIR) and $(TST_DIR)"
	@echo "  dailytest      - build executables in $(DTST_DIR)"
	@echo "  test           - all + dailytest"
	@echo "  debug/release  - switch build mode"
	@echo "  install        - install libs and .mod (PREFIX=$(PREFIX))"
	@echo "  doc            - Doxygen HTML + LaTeX"
	@echo "  clean/veryclean"

# ====== Module ordering: build modules once, then everything else ==================
$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

# Build all module objects before any non-module or main program compiles
$(OBJ_DIR)/.mods.stamp: $(F90_MOD_OBJS) | $(OBJ_DIR)
	@touch $@

# Core non-module Fortran objects must wait for modules
$(F90_OBJS): | $(OBJ_DIR)/.mods.stamp
# Executable/test objects must also wait for modules
$(EXEC_OBJS): | $(OBJ_DIR)/.mods.stamp
$(TEST_OBJS): | $(OBJ_DIR)/.mods.stamp
$(DTEST_OBJS): | $(OBJ_DIR)/.mods.stamp

# ====== Archives ===================================================================
$(LIB_DIR)/$(TC_LIB): $(F90_MOD_OBJS) $(F90_OBJS)
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $@ $^
	@$(RANLIB) $@ || true

$(LIB_DIR)/$(TC_C_LIB): $(C_API_OBJS)
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $@ $^
	@$(RANLIB) $@ || true

# ====== Link executables ===========================================================
$(BIN_DIR)/%: $(OBJ_DIR)/%.o $(LIB_DIR)/$(TC_LIB)
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) $(LDFLAGS) -o $@ $< $(LIB_DIR)/$(TC_LIB) $(LDLIBS)

# ====== Compile rules (core sources) ==============================================
# Fortran core
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.f90
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.F90
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) -c $< -o $@

# C / C++
DEPFLAGS = -MMD -MP
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(DEPFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.C
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cc
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cxx
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@

# ====== Compile rules (exec/tests — depend on modules) ============================
$(OBJ_DIR)/%.o: $(EXE_DIR)/%.f90 | $(OBJ_DIR)/.mods.stamp
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(EXE_DIR)/%.F90 | $(OBJ_DIR)/.mods.stamp
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(TST_DIR)/%.f90 | $(OBJ_DIR)/.mods.stamp
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(TST_DIR)/%.F90 | $(OBJ_DIR)/.mods.stamp
	@mkdir -p $(@D)
	$(FC) $(FCFLAGS) -c $< -o $@

# ====== Cleaning ===================================================================
.PHONY: clean veryclean
clean:
	-@rm -f $(OBJ_DIR)/**/*.o $(OBJ_DIR)/**/*.d 2>/dev/null || true
	-@rm -f $(OBJ_DIR)/*.o $(OBJ_DIR)/*.d $(OBJ_DIR)/.mods.stamp 2>/dev/null || true
	-@find $(BIN_DIR) -name '*.dSYM' -exec rm -rf {} \; >/dev/null 2>&1 || true
	-@rm -f $(BIN_DIR)/* 2>/dev/null || true

veryclean: clean cleandoc
	-@rm -rf $(OBJ_DIR) $(BIN_DIR) $(LIB_DIR)
	-@rm -f *.mod

# ====== Install ====================================================================
PREFIX ?= /usr/local

.PHONY: install c-thermo libraries
install: $(LIB_DIR)/$(TC_LIB)
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m 644 $(LIB_DIR)/$(TC_LIB) $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/include
	@find $(OBJ_DIR) -name '*.mod' -exec install -m 644 {} $(DESTDIR)$(PREFIX)/include/ \;

c-thermo: $(LIB_DIR)/$(TC_C_LIB)
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m 644 $(LIB_DIR)/$(TC_C_LIB) $(DESTDIR)$(PREFIX)/lib/

libraries: install c-thermo

# ====== Documentation ==============================================================
.PHONY: doc dochtml doclatex doctest cleandoc
doc: dochtml doclatex

dochtml:
	doxygen Doxyfile

doclatex: dochtml
	$$(cd $(TEX_DIR) && $(MAKE))

doctest:
	$$(cd $(TST_DIR) && doxygen Doxyfile && cd $(TEX_DIR) && $(MAKE) && cd ../.. && mv $(DOC_DIR) ../$(DOC_DIR)/$(TST_DIR))

cleandoc:
	-@rm -rf $(DOC_DIR)/html $(TEX_DIR) $(TST_DIR)/$(DOC_DIR)/html $(TST_DIR)/$(TEX_DIR) $(DOC_DIR)/$(TST_DIR)

# ====== Diagnostics (optional) =====================================================
.PHONY: print-scan
print-scan:
	@echo "CORE_F90_SRCS: $(words $(CORE_F90_SRCS))"
	@echo "F90_MOD_OBJS : $(words $(F90_MOD_OBJS))"
	@echo "F90_OBJS     : $(words $(F90_OBJS))"
	@echo "EXEC_BINS    : $(words $(EXEC_BINS))"
	@echo "TEST_BINS    : $(words $(TEST_BINS))"
	@echo "DTEST_BINS   : $(words $(DTEST_BINS))"
