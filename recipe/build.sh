set -euxo pipefail

# Patch AmberTools/src/etc/setup.py to report correct version
# See https://github.com/conda-forge/ambertools-feedstock/issues/45
sed -i.bak "s/version='17.0',/version=\"$PKG_VERSION\",/" AmberTools/src/etc/setup.py

# Some Fortran binaries segfault because of this flag (addles, make_crd_hg... maybe sander?)
# See PR #24 -- this might be against CF conventions; might also disappear when we provide openmp/mpi
export FFLAGS=${FFLAGS//-fopenmp }
export FORTRANFLAGS=${FORTRANFLAGS//-fopenmp }
export DEBUG_FFLAGS=${DEBUG_FFLAGS//-fopenmp }

# memembed requires -pthread
# from: https://github.com/facebook/Surround360/issues/3
export CXXFLAGS="${CXXFLAGS} -pthread"

CMAKE_FLAGS=""
BUILD_GUI="FALSE"

export flibs_ml="-DMLCUDA -DHIGH_PREC -L ${PREFIX}/lib -Wl,--no-as-needed -lrt -ldeepmd_op -ldeepmd -ldeepmd_cc -ltensorflow_cc -ltensorflow_framework -lstdc++ -Wl,-rpath=${PREFIX}/lib"

# Build AmberTools with cmake
mkdir -p build
cd build
cmake ${SRC_DIR} ${CMAKE_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCOMPILER=MANUAL \
	-DBUILD_PYTHON=FALSE \
    -DBUILD_GUI=${BUILD_GUI} \
    -DCHECK_UPDATES=FALSE \
    -DTRUST_SYSTEM_LIBS=TRUE \
	-DDOWNLOAD_MINICONDA=FALSE \
	-DCMAKE_CXX_FLAGS="${CXXFLAGS} ${flibs_ml}"
    #-DPYTHON_EXECUTABLE=${PYTHON} \

make && make install

cmake ${SRC_DIR} ${CMAKE_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCOMPILER=MANUAL \
	-DBUILD_PYTHON=FALSE \
    -DBUILD_GUI=${BUILD_GUI} \
    -DCHECK_UPDATES=FALSE \
    -DTRUST_SYSTEM_LIBS=TRUE \
	-DCMAKE_CXX_FLAGS="${CXXFLAGS} ${flibs_ml}" \
	-DDOWNLOAD_MINICONDA=FALSE \
    -DMPI=TRUE
    #-DPYTHON_EXECUTABLE=${PYTHON} \

make && make install


# Export AMBERHOME automatically
mkdir -p ${PREFIX}/etc/conda/{activate,deactivate}.d
cp ${RECIPE_DIR}/activate.sh ${PREFIX}/etc/conda/activate.d/ambertools.sh
cp ${RECIPE_DIR}/activate.fish ${PREFIX}/etc/conda/activate.d/ambertools.fish
cp ${RECIPE_DIR}/deactivate.sh ${PREFIX}/etc/conda/deactivate.d/ambertools.sh
cp ${RECIPE_DIR}/deactivate.fish ${PREFIX}/etc/conda/deactivate.d/ambertools.fish


# Fix https://github.com/conda-forge/ambertools-feedstock/issues/35
#cp ${RECIPE_DIR}/patches/parmed_version.py ${SP_DIR}/parmed/_version.py
