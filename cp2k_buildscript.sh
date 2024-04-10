#!/bin/bash

echo "Set the AOCC Compiler Path? [y,n]"
#read input


read -p "Do you want to proceed? (yes/no) " yn

case $yn in
        yes ) echo ok, we will proceed;;
        no ) echo set the aocc and openmpi path and rerun,  exiting...;
                exit;;
        * ) echo invalid response;
                exit 1;;
esac

echo doing stuff...

#------------------------------------------------------------#
#                   COMPILER SETTINGS                        #
#------------------------------------------------------------#

export COMPILERHOME=/mnt/share/users/srapoola/cp2k_build/aocc-compiler-4.0.0
export COMPILERNAME=aocc40

export LD_LIBRARY_PATH=${COMPILERROOT}/lib:$LD_LIBRARY_PATH
export INCLUDE=${COMPILERROOT}/include:$INCLUDE
export PATH=${COMPILERROOT}/bin:$PATH

export FC=flang
export CC=clang
export CXX=clang++
export AR=llvm-ar

export CFLAGS="-g -O3 -march=znver4 -fPIC -fopenmp"
export CXXFLAGS="-g -O3 -march=znver4 -fPIC -fopenmp"
export FCFLAGS="-g -O3 -march=znver4 -fPIC -Mbackslash" # -flegacy-pass-manager"

echo "###############################################################################"
echo "#                                OpenMPI                                      #"
echo "###############################################################################"

export OPENMPIROOT=/mnt/share/users/srapoola/cp2k_build/openmpi-4.1.4


export MPI_VERS=4.1.4
export MPI_LIBRARY=openmpi
export OMPI=ompi411

export PATH=$OPENMPIROOT/bin:$PATH
export LD_LIBRARY_PATH=$OPENMPIROOT/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$OPENMPIROOT/include:$C_INCLUDE_PATH

#MPI compiler setting
export MPICC=mpicc      #MPICC:     MPI C compiler command
export MPICXX=mpiCC     #MPICXX:    MPI C++ compiler command
export MPIFC=mpifort    #MPIFC:     MPI Fortran compiler command
export MPIF90=mpif90    #MPIF90:    MPI Fortran-90(F90) compiler command
export MPIF77=mpif77    #MPIF77:    MPI Fortran-77(F77) compiler command

# CP2k Settings
export APP_NAME=cp2k

# Set CP2k version
export APP_VERS=7.1

# CP2K application Architecture file (Generates automatically)
export ARCH=Linux-x86-64-${COMPILERNAME}`echo $FCFLAGS | sed 's/ //g;s/march=//'`
export VERSION=psmp

# Submit sample job after compilation
export TEST_JOB=no      # yes or no

# Set your prerequisites installation path
export INSTALL_DIR=/mnt/share/users/srapoola/CP2Kbuild_cp2k_-g

export BUILD_DIR=${INSTALL_DIR}/build

# Please mention the path for Application installation.
export APP_PREFIX_PATH=${INSTALL_DIR}/${APP_NAME}
export CP2K_DIR=$INSTALL_DIR/${APP_NAME}_${APP_VERS}_${COMPILERNAME}

# Please mention path for directory where all archives are kept
export SOURCES_DIR=${INSTALL_DIR}/sources

# WORK_DIR is where your application scripts are
#export WORK_DIR=${PWD}

#------------------------------------------------------------#
#               LIBRARY SETTING                              #
#------------------------------------------------------------#

# User must provide full path for variables "LAPACK_LIBS", "BLAS_LIBS", "SCALAPACK_LIBS" and "FFTW_LIBS" with library details

# AOCL_VER = Please specify the AMD's AOCL vesrion
export AOCL_VER="4.0"
#"2.2"
#export AOCL_SUBVER="6"
#"0"

# AOCLDIR = Path for AMD's AOCL's root directory
export AOCL_DIR=/mnt/share/users/srapoola/amd/aocl/4.0


#-------------------------#
# AMD MATH Library (LibM) #
#-------------------------#

# AOCL_INTERNAL_RELEASE = Please specify the AOCL's internal release


export AOCL_INTERNAL_RELEASE_EDITION=may-2020
export AOCL_INTERNAL_RELEASE=aocl-linux-aocc-2005
export AOCL_INTERNAL_LIBM_RELEASE=aocl-libm-linux-aocc-3.6.0
export LIBM_INTERNAL_REL=$(echo "$AOCL_INTERNAL_RELEASE" | awk '{gsub("-"," "); print $NF}')


USE_LIBM=yes                            # yes to enalbe; no to disable compilation
#export LIBM_VERS=${AOCL_VER}.${AOCL_SUBVER}
export LIBM_VERS=${AOCL_VER}
#export AOCL_LIBM=${AOCL_DIR}/amdlibm/${COMPILERNAME}/${LIBM_VERS}
export AOCL_LIBM=${AOCL_DIR}

if [ "$AOCL_VER" = "2.2" ] && [ "${LIBM_INTERNAL_REL/*-}" -le "2005" ]; then
        #export MATH_LIBS=${AOCL_LIBM}/${AOCL_INTERNAL_RELEASE/*-}/libs/libamdlibm.so
        export MATH_LIBS=${AOCL_LIBM}/${AOCL_INTERNAL_LIBM_RELEASE/*-}/lib/libamdlibm.so
else
        export MATH_LIBS=${AOCL_LIBM}/lib/libamdlibm.so
fi

#--------------------------#
# LAPACK/libflame library  #
#--------------------------#

USE_LAPACK=yes                          # yes to enalbe; no to disable compilation
#export LAPACK_VERS=${AOCL_VER}.${AOCL_SUBVER}
export LAPACK_VERS=${AOCL_VER}
#export AOCL_LAPACK=${AOCL_DIR}/libflame/${COMPILERNAME}/${LAPACK_VERS}
export AOCL_LAPACK=${AOCL_DIR}
export LAPACK_LIBS=${AOCL_LAPACK}/lib/libflame.a

#--------------------------#
# BLAS/blis library        #
#--------------------------#

USE_BLAS=yes # yes to enalbe; no to disable compilation

#export BLAS_VERS=${AOCL_VER}.${AOCL_SUBVER}
export BLAS_VERS=${AOCL_VER}

# Set "AMD BLIS" options
#export BLIS_THREADING_MODE="no"                # Modes   : openmp, pthread or no. "no" will disable multi-threading and generates libblis.a
#export BLIS_CONFNAME="amd64"           # "amd64" enables optimization for all AMD architectures;  "auto" enables host CPU architecture. This feature is enabled from AOCL 2.1 version onwards
#export BLAS_LIB_NAME=blis              # blis : disables multi-thread; blis-mt : enables multi-thread (use openmp/pthread as BLIS_THREADING_MODE)

# Recommend for RHEL and Cent OS for any AOCL version
#export AOCL_BLAS=${AOCL_DIR}/blis/${COMPILERNAME}/${BLAS_VERS}
export AOCL_BLAS=${AOCL_DIR}
export BLAS_LIBS=${AOCL_BLAS}/lib/libblis.a


#--------------------------#
# ScaLAPACK library        #
#--------------------------#

USE_SCALAPACK=yes                       # yes to enalbe; no to disable compilation

#export SCALAPACK_VERS=${AOCL_VER}.${AOCL_SUBVER}
export SCALAPACK_VERS=${AOCL_VER}

#export AOCL_SCALAPACK=${AOCL_DIR}/scalapack/${OMPI}/${COMPILERNAME}/${SCALAPACK_VERS}
#export AOCL_SCALAPACK=${INSTALL_DIR}/scalapack/${OMPI}/${COMPILERNAME}/${SCALAPACK_VERS}
export AOCL_SCALAPACK=${AOCL_DIR}
export SCALAPACK_LIBS=${AOCL_SCALAPACK}/lib/libscalapack.a
#export SCALAPACK_LIBS="/home/hpcadm/apps/aocl/scalapack/ompi403/aocc220/2.2.0/lib"
#export SCALAPACK_LIBS=""


#--------------------------#
# FFTW libray              #
#--------------------------#

USE_FFTW=yes                            # yes to enalbe; no to disable compilation

#export FFTW_VERS=${AOCL_VER}.${AOCL_SUBVER}
export FFTW_VERS=${AOCL_VER}


#Precision for FFTW libary

#For Double Precision :
FFTW_PRECISION="dp"             # Default is "dp"
FFTW_LIB_NAME="libfftw3"

#For Single/float Precision :
#FFTW_PRECISION="sp"
#FFTW_LIB_NAME="libfftw3f"

#For Long Double Precision :
#FFTW_PRECISION="ldp"
#FFTW_LIB_NAME="libfftw3l"

# Recommend for RHEL and Cent OS for any AOCL versions
#export FFTW_DIR=${AOCL_DIR}/fftw/${OMPI}/${COMPILERNAME}/${FFTW_VERS}
#export FFTW_DIR=${AOCL_DIR}/fftw/${OMPI}/aocc30b78/3.0.5
export AOCL_FFTW=${AOCL_DIR}
export FFTW_LIBS=${AOCL_FFTW}/lib/${FFTW_LIB_NAME}.a


#------------------------------------------------------------#
#        Application Pre-requisite library settings          #
#------------------------------------------------------------#

#--------------------------#
# LIBINT library           #
#--------------------------#

USE_LIBINT=yes                  # yes to enalbe; no to disable compilation
export LIBINT_VERS=v2.6.0-cp2k-lmax-6
#1.1.6
export LIBINT_DIR=${INSTALL_DIR}/libint/${LIBINT_VERS}/${COMPILERNAME}

#--------------------------#
# LIBXSMM library          #
#--------------------------#

#LIBXSMM is a library for specialized dense and sparse matrix operations.
#The "MM" stands for Matrix Multiplication, and the "S" clarifies the working domain i.e., Small Matrix Multiplication.

USE_LIBXSMM=yes         # yes to enalbe; no to disable compilation
export LIBXSMM_VERS=1.15
export LIBXSMM_DIR=${INSTALL_DIR}/libxsmm/${LIBXSMM_VERS}/${COMPILERNAME}

#--------------------------#
# LIBXC library            #
#--------------------------#
#Libxc is a library of exchange-correlation functionals for density-functional theory.

USE_LIBXC=yes                   # yes to enalbe; no to disable compilation
export LIBXC_VERS=4.2.3
#export LIBXC_VERS=5.2.0
export LIBXC_DIR=${INSTALL_DIR}/libxc/${LIBXC_VERS}/${COMPILERNAME}

#--------------------------#
# ELPA library             #
#--------------------------#
#"ELPA_VER": ELPA ( Eigenvalue soLvers for Petaflop-Applications) library version

USE_ELPA=yes                    # yes to enalbe; no to disable compilation
export ELPA_VERS=2019.11.001    #CP2K 7.1
#2017.05.001    #CP2K 6.1
export ELPA_DIR=${INSTALL_DIR}/elpa/${ELPA_VERS}/${COMPILERNAME}
#/home/hpcadm/apps/elpa/ompi403/aocc220/2019.05.001
export ELPA_LIB=${ELPA_DIR}/lib
export ELPA_TAG=`echo ${ELPA_VERS%.*} | sed 's/\.//g'`



source $PWD/ #cp2k_aocc_configure.sh

set -exu

mkdir -p ${INSTALL_DIR} ${SOURCES_DIR} ${BUILD_DIR} ${APP_PREFIX_PATH}

#Checking for $COMPILERHOME variable

if [ -z "$COMPILERHOME" ]; then
        echo
        echo "Please set COMPILERHOME ..." 1>&2
        echo
        return
fi

if [ -e "$COMPILERHOME/bin/$CC" ] && [ -e "$COMPILERHOME/bin/$FC" ]; then
        export PATH=$COMPILERHOME/bin:$PATH
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+}:$COMPILERHOME/lib:$COMPILERHOME/lib32:$COMPILERHOME/lib64
        export LIBRARY_PATH=${LIBRARY_PATH:+}:$COMPILERHOME/lib
        export C_INCLUDE_PATH=${C_INCLUDE_PATH:+}:$COMPILERHOME/include
        export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH:+}:$COMPILERHOME/include
else
        echo " C and/or FORTRAN compilers are not found in "$COMPILERHOME/bin" "
        echo
        return
fi

#MPI
if [ -e "$OPENMPIROOT/bin/$MPICC" ] && [ -e "$OPENMPIROOT/bin/$MPIFC" ]; then
        export PATH=$OPENMPIROOT/bin:$PATH
        export LD_LIBRARY_PATH=$OPENMPIROOT/lib:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$OPENMPIROOT/lib
        export C_INCLUDE_PATH=$OPENMPIROOT/include:$C_INCLUDE_PATH
fi

#amdlibm
if [ "$USE_LIBM" = yes ]; then
export MATH_LIBS=$MATH_LIBS
        export LD_LIBRARY_PATH=$AOCL_LIBM/lib:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$AOCL_LIBM/lib
fi

#lapack
if [ "$USE_LAPACK" = yes ]; then
        export LAPACK_LIBS=$LAPACK_LIBS
        export LD_LIBRARY_PATH=$AOCL_LAPACK/lib:$AOCL_LAPACK/lib64:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$AOCL_LAPACK/lib:$AOCL_LAPACK/lib64
        export C_INCLUDE_PATH=$AOCL_LAPACK/include:$C_INCLUDE_PATH
        export LAPACKLIB_PATH=$AOCL_LAPACK/lib
fi

#blas
if [ "$USE_BLAS" = yes ]; then
        export BLAS_LIBS=$BLAS_LIBS
        export LD_LIBRARY_PATH=$AOCL_BLAS/lib:$AOCL_BLAS/lib64:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$AOCL_BLAS/lib:$AOCL_BLAS/lib64
        export C_INCLUDE_PATH=$AOCL_BLAS/include:$C_INCLUDE_PATH
fi

#scalapack
if [ "$USE_SCALAPACK" = yes ]; then
        export SCALAPACK_LIBS=${SCALAPACK_LIBS}
        export LD_LIBRARY_PATH=$AOCL_SCALAPACK/lib:$LD_LIBRARY_PATH
fi

#fftw
if [ "$USE_FFTW" = yes ]; then
        export PATH=$AOCL_FFTW/bin:$PATH
        export FFTW_INC=$AOCL_FFTW/include
        export FFTW_LIB=$AOCL_FFTW/lib
        export LD_LIBRARY_PATH=$AOCL_FFTW/lib:$AOCL_FFTW/lib64:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$AOCL_FFTW/lib:$AOCL_FFTW/lib64
        export C_INCLUDE_PATH=$FFTW_INC:$C_INCLUDE_PATH
        export CPLUS_INCLUDE_PATH=$FFTW_INC:$CPLUS_INCLUDE_PATH
fi

#libxsmm
if [ "$USE_LIBXSMM" = yes ]; then
        export PATH=$LIBXSMM_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$LIBXSMM_DIR/lib:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$LIBXSMM_DIR/lib
        export C_INCLUDE_PATH=$LIBXSMM_DIR/include:$C_INCLUDE_PATH
fi

#libint
if [ "$USE_LIBINT" = yes ]; then
        export PATH=$LIBINT_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$LIBINT_DIR/lib:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$LIBINT_DIR/lib
        export C_INCLUDE_PATH=$LIBINT_DIR/include:$C_INCLUDE_PATH
fi

#libxc
if [ "$USE_LIBXC" = yes ]; then
        export PATH=$LIBXC_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$LIBXC_DIR/lib:$LD_LIBRARY_PATH
        export LD_RUN_PATH=${LD_RUN_PATH:+}$LIBXC_DIR/lib
        export C_INCLUDE_PATH=$LIBXC_DIR/include:$C_INCLUDE_PATH
fi

#elpa
if [ "$USE_ELPA" = yes ]; then
        export PATH=$ELPA_DIR/bin:$PATH
        export ELPA_LIBS=$ELPA_DIR/lib
        export LD_LIBRARY_PATH=$ELPA_LIBS:$LD_LIBRARY_PATH
fi

#cp2k
ARCH_FILE=$ARCH.$VERSION
export PATH=$CP2K_DIR/exe/${ARCH}:$PATH

ENV_FILE=setEnv-${APP_NAME}-${APP_VERS}-${ARCH_FILE}-${MPI_LIBRARY}_${MPI_VERS}_${COMPILERNAME}.sh

echo "export CP2K_DIR=$CP2K_DIR" >$ENV_FILE
echo "export PATH=$PATH:\$PATH" >>$ENV_FILE
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:\$LD_LIBRARY_PATH" >>$ENV_FILE
echo "export LD_RUN_PATH=$LD_RUN_PATH" >>$ENV_FILE
echo "export C_INCLUDE_PATH=$C_INCLUDE_PATH:$C_INCLUDE_PATH" >>$ENV_FILE
echo "export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$CPLUS_INCLUDE_PATH" >>$ENV_FILE

if [ "$USE_LIBM" = yes ]; then
        echo "export AOCL_LIBM=$AOCL_LIBM" >>$ENV_FILE
        echo "export MATH_LIBS=$MATH_LIBS" >>$ENV_FILE
fi

if [ "$USE_LAPACK" = yes ]; then
        echo "export AOCL_LAPACK=${AOCL_LAPACK}" >>$ENV_FILE
        echo "export LAPACK_LIBS=${LAPACK_LIBS}" >>$ENV_FILE

fi

if [ "$USE_BLAS" = yes ]; then
        echo "export AOCL_BLAS=${AOCL_BLAS}" >>$ENV_FILE
        echo "export BLAS_LIBS=${BLAS_LIBS}" >>$ENV_FILE
fi

if [ "$USE_SCALAPACK" = yes ]; then
        echo "export AOCL_SCALAPACK=${AOCL_SCALAPACK}" >>$ENV_FILE
        echo "export SCALAPACK_LIBS=${SCALAPACK_LIBS}" >>$ENV_FILE
fi

#. $ENV_FILE





# Build all

#Configure and Environment set-up
#. cp2k_aocc_configure.sh
#. cp2k_aocc_env_setup.sh


#OpenMPI
#. openmpi_aocc_build.sh


#AMD Optimizing CPU Libraries (AOCL)
#https://developer.amd.com/amd-aocl/
#if [ "$USE_LIBM" = yes ]; then
#        . aocl_libm_build.sh
#fi

#if [ "$USE_LAPACK" = yes ]; then
#        . aocl_lapack_build.sh
#fi

#if [ "$USE_BLAS" = yes ]; then
#        . aocl_blas_build.sh
#fi

#if [ "$USE_SCALAPACK" = yes ]; then
#        . aocl_scalapack_build.sh
#fi
#
#if [ "$USE_FFTW" = yes ]; then
#        . aocl_fftw_build.sh
#fi

#A library for matrix operations and deep learning primitives:
#https://github.com/hfp/libxsmm/.
#if [ "$USE_LIBXSMM" = yes ]; then
#        . libxsmm_aocc_build.sh
#else
#        libxsmm_succ=no
#fi

#LIBINT
# Enables methods including HF exchange
#if [ "$USE_LIBINT" = yes ]; then
#        . libint_aocc_build.sh
#else
#        libint_succ=no
#fi

#LIBXC
#Wider choice of xc functionals
#if [ "$USE_LIBXC" = yes ]; then
#        . libxc_aocc_build.sh
#else
#        libxc_succ=no
#fi

#ELPA :
# Library ELPA for the solution of the eigenvalue problem
# http://elpa.rzg.mpg.de/software.
#if [ "$USE_ELPA" = yes ]; then
#        . elpa_aocc_build.sh
#else
#        elpa_succ=no
#fi

#CP2K
#. cp2k_aocc_build.sh

#!/bin/sh
#amdlibm
# MATH Library
# https://developer.amd.com/amd-aocl/amd-math-library-libm/
#-----------------------------------------------------------------------------------------

export build_packname=amdlibm.${AOCL_VER}

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.${build_packname}.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        echo " --- Checking for PATH of MATH library :  ... "

        if [ -e "${MATH_LIBS}" ]; then
                echo
                echo " --- MATH Library exists: "
                echo "${MATH_LIBS}"
                echo
        else

                echo
                echo " --- Path for MATH libraries not found."
                echo " --- Installing AMD LibM library using binary package.... "
                echo

                libmsourcename=amd-libm
                aocl_edition=${AOCL_INTERNAL_RELEASE_EDITION}
                aocl_archive=${AOCL_INTERNAL_RELEASE}.tar.gz

                if [ ! -e $SOURCES_DIR/${aocl_archive} ]; then
                        echo --- ${aocl_archive} is not found in directory.
                        echo --- Downloading ${aocl_archive} from http://aocl.amd.com/data/${aocl_edition}/${aocl_archive}

                        wget -P $SOURCES_DIR http://aocl.amd.com/data/${aocl_edition}/${aocl_archive}
                fi
                cd ${BUILD_DIR}

                tar -xzf ${SOURCES_DIR}/${aocl_archive}
                cd ${AOCL_INTERNAL_RELEASE}
                ./install.sh -l libm -t ${AOCL_LIBM}

                export MATH_LIB_DIR=$(echo "${MATH_LIBS}" | sed 's|\(.*\)/.*|\1|')

                cd $WORK_DIR
        fi
} 2>&1 | tee ${BUILD_DIR}/$buildlog

if [ -e "${MATH_LIBS}" ]; then
        export AOCL_MATH_LIB=$(echo "${MATH_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export AOCL_LIBM=$(echo "${AOCL_MATH_LIB}" | sed 's|\(.*\)/.*|\1|')
        export LD_LIBRARY_PATH=$AOCL_MATH_LIB:$LD_LIBRARY_PATH
        export libm_succ=yes
        echo " Math Library is set to ${MATH_LIBS}"
else
        export AOCL_MATH_LIB=$(echo "${MATH_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export libm_succ=no
        echo " Math library not found in $AOCL_MATH_LIB"
        echo " Please check $BUILD_DIR/$buildlog file "
        return
fi


##libflame
#-----------------------------------------------------------------------------------------
# Numerical, and linear algebra libraries.
# https://developer.amd.com/amd-aocl/
#-----------------------------------------------------------------------------------------
echo " --- Checking for PATH of Linear Algebra Package (LAPACK)/libFLAME library :  ... "

export build_packname=libflame-$AOCL_VER
export libflame_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$libflame_packname.$USER.$(hostname -s).$(hostname -d).$date.txt
{
        set -eux

        if [ -e "$LAPACK_LIBS" ]; then
                echo
                echo " --- Linear Algebra Package (LAPACK)/libFLAME exists : "
                echo "LAPACK is set to $LAPACK_LIBS"
                echo
        else
                echo
                echo " --- Path for LAPACK/libFLAME library is not found."
                echo " --- Installing "libFLAME" library.... "
                echo

                libflame_archive=${libflame_packname}.tar.gz

                if [ ! -e ${SOURCES_DIR}/${libflame_archive} ]; then
                        echo --- ${libflame_archive} in $SOURCES_DIR directory.
                        wget https://github.com/amd/libflame/archive/${AOCL_VER}.tar.gz -O ${SOURCES_DIR}/$libflame_archive

                fi

                cd $BUILD_DIR
                rm -rf $libflame_packname

                tar -xzf ${SOURCES_DIR}/$libflame_archive
                cd $libflame_packname

                export CC=$CC
                export CXX=$CXX
                export FC=$FC
                export F77=$FC
                export FLIBS="-lflang"
                export CFLAGS="-march=znver4 -fopenmp"

                ./configure --prefix=${AOCL_LAPACK} \
                        --enable-lapack2flame --enable-external-lapack-interfaces \
                        --enable-dynamic-build --enable-max-arg-list-hack

                #Compile
                make -j 8 CFLAGS="$CFLAGS" 2>&1 | tee make_${libflame_packname}.log
                make install 2>&1 | tee make_install_${libflame_packname}.log

                cd $WORK_DIR
        fi
} 2>&1 | tee $BUILD_DIR/$buildlog

#Checking for installtion success
if [ -e "${LAPACK_LIBS}" ]; then
        export AOCL_LAPACK_LIB=$(echo "${LAPACK_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export AOCL_LAPACK=$(echo "${AOCL_LAPACK_LIB}" | sed 's|\(.*\)/.*|\1|')
        export LD_LIBRARY_PATH=${AOCL_LAPACK_LIB}:$LD_LIBRARY_PATH
        export lapack_succ=yes
        echo " Lapack library is set to ${LAPACK_LIBS}"
else
        export AOCL_LAPACK_LIB=$(echo "${LAPACK_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export lapack_succ=no
        echo " LAPACK libraries are not found in $AOCL_LAPACK_LIB ."
        echo " Please check directory $BUILD_DIR/$buildlog file"
        return
fi

#blas
#-----------------------------------------------------------------------------------------
# BLIS/BLAS, Basic linear algebra libraries.
# https://developer.amd.com/amd-aocl/
#-----------------------------------------------------------------------------------------
echo " --- Checking for PATH of Basic linear algebra libraries (BLIS/BLAS) library :  ... "

export build_packname=blis-$AOCL_VER
export blis_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$blis_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        if [ -e "$BLAS_LIBS" ]; then
                echo
                echo " --- Basic Linear Algebra Package exists (BLIS/BLAS): "
                echo "$BLAS_LIBS"
                echo
        else
                echo
                echo " --- Path for BLAS/BLIS libraries not found."
                echo " --- Installing BLIS library  .... "

                blis_archive=${blis_packname}.tar.gz

                if [ ! -e ${SOURCES_DIR}/${blis_archive} ]; then
                        echo --- ${blis_archive} in $SOURCES_DIR directory.
                        wget https://github.com/amd/blis/archive/${AOCL_VER}.tar.gz -O ${SOURCES_DIR}/${blis_archive}
                fi

                cd $BUILD_DIR
                rm -rf $blis_packname

                tar -xzf ${SOURCES_DIR}/$blis_archive

                cd $blis_packname
                make distclean

                echo " --- Configuring $blis_packname....."
                echo " --- Threading mode : $BLIS_THREADING_MODE "
                echo " --- Buld configuration based on the target CPU architecture : $BLIS_CONFNAME"
                echo " --- ./configure --enable-cblas --disable-sup-handling --enablethreading=$BLIS_THREADING_MODE --prefix=$AOCL_BLAS CC=$CC CXX=$CXX $BLIS_CONFNAME"

                ./configure --prefix=$AOCL_BLAS \
                        --enable-cblas --disable-sup-handling \
                        --enable-threading=$BLIS_THREADING_MODE \
                        CC=$CC CXX=$CXX CFLAGS="-DF2C -DAOCL_F2C" $BLIS_CONFNAME

                #Compile
                make -j 16 2>&1 | tee make_${blis_packname}.log

                #Test
                #make -j 8 check
                #Install
                make -j install 2>&1 | tee make_install_${blis_packname}.log

                cd $WORK_DIR
        fi
} 2>&1 | tee $BUILD_DIR/$buildlog

#Checking for installtion success
if [ -e "${BLAS_LIBS}" ]; then
        export AOCL_BLAS_LIB=$(echo "${BLAS_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export AOCL_BLAS=$(echo "${AOCL_BLAS_LIB}" | sed 's|\(.*\)/.*|\1|')
        export LD_LIBRARY_PATH=$AOCL_BLAS_LIB:$LD_LIBRARY_PATH
        export blas_succ=yes
        echo " BLAS Library is set to ${BLAS_LIBS}"
else
        export AOCL_BLAS_LIB=$(echo "${BLAS_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export blas_succ=no
        echo " BLAS not found in $AOCL_BLAS_LIB"
        echo " Please check $BUILD_DIR/$buildlog file "
        return
fi



#scalapack
# ScaLAPACK(v2.0.2) Library Build and Installation
#http://www.netlib.org/scalapack/scalapack.tgz
#----------------------------------------------------------------------------
echo " --- Building ScaLAPACK Library with ${COMPILERNAME}... "

export build_packname=scalapack-$AOCL_VER
export scalapack_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$scalapack_packname.$USER.$(hostname -s).$(hostname -d).$date.txt
{
        set -eux

        if [ -e "${SCALAPACK_LIBS}" ]; then

                echo
                echo " --- PATH for ScaLAPACK library exists: $AOCL_SCALAPACK"
                echo

        else

                echo
                echo " --- Path for ScaLAPACK library not found."
                echo " --- Building and Installing ScaLAPACK library, using $COMPILERNAME."
                echo

                export scalapack_archive=$build_packname.tar.gz

                if [ ! -e ${SOURCES_DIR}/${scalapack_archive} ]; then
                        echo " Downloading ${scalapack_archive} in ${SOURCES_DIR} directory."
                        wget -P ${SOURCES_DIR} https://github.com/amd/scalapack/archive/refs/tags/${AOCL_VER}.tar.gz  -O ${SOURCES_DIR}/${scalapack_archive}
                fi
                echo "${scalapack_archive} found in ${SOURCES_DIR} directory."
                echo

 echo "${scalapack_archive} found in ${SOURCES_DIR} directory."

                #Extracting the archive
                cd $BUILD_DIR

                tar -xf ${SOURCES_DIR}/${scalapack_archive}
                cd $BUILD_DIR/$scalapack_packname
                rm -rf build_${COMPILERNAME}

                mkdir build_${COMPILERNAME}
                cd build_${COMPILERNAME}

                #To avoid following Warning messages:
                #Warning: ieee_inexact is signaling FORTRAN STOP)

                export NO_STOP_MESSAGE=1

                cmake ../ -DCMAKE_C_COMPILER=${MPICC} -DCMAKE_Fortran_COMPILER=${MPIF90} \
                        -DCMAKE_C_FLAGS="${CFLAGS} -DF2C_COMPLEX -fPIC" -DCMAKE_Fortran_FLAGS="${FCFLAGS} -fPIC" \
                        -DLAPACK_LIBRARIES=${LAPACK_LIBS} -DBLAS_LIBRARIES=${BLAS_LIBS} \
                        -DUSE_OPTIMIZED_LAPACK_BLAS=OFF -DUSE_F2C=ON -DUSE_DOTC_WRAPPER=ON \
                        -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=${AOCL_SCALAPACK}

                make -j 32 lib 2>&1 | tee make_${COMPILERNAME}.log
                make install

        fi

        cd $WORK_DIR

} 2>&1 | tee $BUILD_DIR/$buildlog

#Checking for installation success
if [ -e "${SCALAPACK_LIBS}" ]; then
        export AOCL_SCALAPACK_LIB=$(echo "${SCALAPACK_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export AOCL_SCALAPACK=$(echo "${AOCL_SCALAPACK_LIB}" | sed 's|\(.*\)/.*|\1|')
        export LD_LIBRARY_PATH=$AOCL_SCALAPACK_LIB:$LD_LIBRARY_PATH
        export scalapack_succ=yes
        echo " ScaLapack is set to ${SCALAPACK_LIBS} "
else
        export AOCL_SCALAPACK_LIB=$(echo "${SCALAPACK_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export scalapack_succ=no
        echo " ScaLAPACK library are not found in ${AOCL_SCALAPACK_LIBS}"
        echo " Check cmake  BUILD_SHARED_LIBS option is ON/OFF"
        echo " Please check $BUILD_DIR/$buildlog file"
        return
fi



#-----------------------------------------------------------------------------------------
# FFTW (Fast Fourier Transform in the West) Library Build and Installation
# Building and Installing FFTW libraries
#----------------------------------------------------------------------------
echo " --- Checking for PATH of FFTW library (AOCL_FFTW) ... "

export build_packname=amd-fftw-$AOCL_VER
export fftw_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$fftw_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        if [ -e "${FFTW_LIBS}" ]; then

                echo
                echo " FFTW is set to $AOCL_FFTW"
                echo
        else
                echo
                echo " --- Path for FFTW library not found."
                echo " --- Building and Installing AMD FFTW libraries."
                echo

                export fftw_archive=${fftw_packname}.tar.gz

                if [ ! -e ${SOURCES_DIR}/${fftw_archive} ]; then
                        echo --- ${fftw_archive} in $SOURCES_DIR directory.
                        wget https://github.com/amd/amd-fftw/archive/${AOCL_VER}.tar.gz -O ${SOURCES_DIR}/$fftw_archive
                fi

                cd $BUILD_DIR
                rm -rf $fftw_packname

                tar -xzf ${SOURCES_DIR}/$fftw_archive
                cd $fftw_packname

                # Compile FFTW libary using Double/Single/Long Double :
                # Precision for FFTW libary
                if [ "$FFTW_PRECISION" = "dp" ]; then
                        #For Double Precision :
                        FFTW_LIB_NAME="libfftw3.a"
                        FFTW_PREC_FLAG=""
                elif [ "$FFTW_PRECISION" = "sp" ]; then
                        #For Single/float Precision :
                        FFTW_LIB_NAME="libfftw3f.a"
                        FFTW_PREC_FLAG="--enable-single"
                else
                        #For Long Double Precision :
                        #FFTW_PRECISION="ldp"
                        FFTW_LIB_NAME="libfftw3l.a"
                        FFTW_PREC_FLAG="--enable-long-double"
                fi

                echo " --- Configuring FFTW ${FFTW_PRECISION} libraries"

                ./configure \
                        --enable-mpi --enable-openmp --enable-shared \
                        --enable-amd-opt --enable-threads --enable-amd-mpifft \
                        --enable-sse2 --enable-avx --enable-avx2 ${FFTW_PREC_FLAG} \
                        CC=$CC F77=$FC MPICC=$MPICC \
                        LDFLAGS="-no-pie" --prefix=$AOCL_FFTW
                #Test
                #make -j 8 check

                #Compile
                make -j 2>&1 | tee make_${fftw_packname}_${FFTW_PRECISION}.log

                #Install
                make install 2>&1 | tee make_install_${fftw_packname}_${FFTW_PRECISION}.log

                cd $WORK_DIR

        fi

} 2>&1 | tee $BUILD_DIR/$buildlog

#Checking for libraries
if [ -e "${FFTW_LIBS}" ]; then
        export AOCL_FFTW_LIB=$(echo "${FFTW_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export AOCL_FFTW=$(echo "${AOCL_FFTW_LIB}" | sed 's|\(.*\)/.*|\1|')
        export LD_LIBRARY_PATH=${AOCL_FFTW_LIB}:$LD_LIBRARY_PATH
        export fftw_succ=yes
        echo " FFTW is set to ${FFTW_LIBS}"
else
        export AOCL_FFTW_LIB=$(echo "${FFTW_LIBS}" | sed 's|\(.*\)/.*|\1|')
        export fftw_succ=no
        echo " FFTW libraries are not found in $AOCL_FFTW_LIB"
        echo " Please check directory $BUILD_DIR/$buildlog file"
        return
fi



#----------------------------------------------------------------------------
# LIBXSMM Library Build and Installation
# (optional, improved performance for matrix multiplication)
# Building and Installing LIBXSMM library
# https://github.com/hfp/libxsmm/
# Preferred download site : https://www.cp2k.org/static/downloads/
#----------------------------------------------------------------------------
echo " --- Checking for PATH of LIBXSMM library (LIBXSMM_DIR) ... "

export build_packname=libxsmm-$LIBXSMM_VERS
export libxsmm_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$libxsmm_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        if [ -d "$LIBXSMM_DIR" ] && { [ -e "$LIBXSMM_DIR/lib/libxsmm.a" ] || [ -e "$LIBXSMM_DIR/lib64/libxsmm.a" ]; }; then

                echo
                echo " --- PATH for LIBXSMM library exists: $LIBXSMM_DIR"
                echo

        else

                echo
                echo " --- Path for LIBXSMM library not found."
                echo " --- Building and Installing LIBXSMM libraries, using ${COMPILERNAME}."
                echo

                libxsmm_archive=${libxsmm_packname}.tar.gz

                if [ ! -e ${SOURCES_DIR}/${libxsmm_archive} ]; then
                        echo --- ${libxsmm_archive} in ${SOURCES_DIR} directory.
                        wget -P $SOURCES_DIR https://www.cp2k.org/static/downloads/${libxsmm_archive}
                fi

                cd $BUILD_DIR
                rm -rf $libxsmm_packname

                tar -xzf ${SOURCES_DIR}/$libxsmm_archive

                cd $libxsmm_packname

                #Compile & Install
                #AVX=2; Intrinsics settings: Without setting AVX can reduce performance of certain code paths.
                LDFLAGS+="-Wl,-z,muldefs"
                make CC=${CC} FC=${FC}  CFLAGS="${CFLAGS}" FCFLAGS="${FCFLAGS}" LDFLAGS+="-Wl,-z,muldefs" PREFIX=$LIBXSMM_DIR -j 4 install 2>&1 | tee make_${libxsmm_packname}_${COMPILERNAME}.log
                #make CC=${CC} CXX=${CXX} FC=${FC} GNU=1 AVX=2 INTEL=0 MIC=0 CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS} " FCFLAGS="${FCFLAGS}" PREFIX=$LIBXSMM_DIR install 2>&1 | tee make_${libxsmm_packname}_${COMPILERNAME}.log
                #Test
                #make test

                cd $WORK_DIR
        fi
} 2>&1 | tee $BUILD_DIR/$buildlog
#Checking for installtion success

if [ -e "$LIBXSMM_DIR/lib/libxsmm.a" ] && [ -e "$LIBXSMM_DIR/lib/libxsmmf.a" ]; then
        export libxsmm_succ=yes
        export LIBXSMM_DIR=$LIBXSMM_DIR
        echo " LIBXSMM is set to $LIBXSMM_DIR"
else
        export libxsmm_succ=no
        echo " LIBXSMM libraries are not found in $LIBXSMM_DIR"
        echo " Please check $BUILD_DIR/$buildlog file "
        return
fi


#----------------------------------------------------------------------------
# LIBINT Library Build and Installation
# Optional, enables methods including HF exchange
# High-performance library for computing Gaussian integrals in quantum mechanics
# It is a library for the evaluation of molecular integrals of many-body operators over Gaussian functions
# Building and Installing LIBINT library
# Preferred download site : https://www.cp2k.org/static/downloads/
#----------------------------------------------------------------------------
echo " --- Checking for PATH of LIBINT library (LIBINT_DIR) ... "
export build_packname=libint-$LIBINT_VERS
export libint_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$libint_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        if [ -d "$LIBINT_DIR" ] && { [ -e "$LIBINT_DIR/lib/libint.a" ] || [ -e "$LIBINT_DIR/lib/libint2.a" ]; }; then

                echo
                echo " --- PATH for LIBINT library exists: $LIBINT_DIR"
                echo
        else
                echo
                echo " --- Path for LIBINT library not found."
                echo " --- Building and Installing LIBINT libraries, using ${COMPILERNAME}."
                echo



                if [ "${LIBINT_VERS%.*}" == "v2.6" ]; then

                        libint_packname=libint-v2.6.0-cp2k-lmax-6
                        libint_archive=$libint_packname.tgz

                        if [ ! -e ${SOURCES_DIR}/${libint_archive} ]; then
                                echo --- Downloading ${libint_archive} in ${SOURCES_DIR} directory.
                                wget -P $SOURCES_DIR https://github.com/cp2k/libint-cp2k/releases/download/v2.6.0/${libint_archive}
                        fi
                else

                        libint_packname=libint-${LIBINT_VERS}
                        libint_archive=$libint_packname.tar.gz

                        if [ ! -e ${SOURCES_DIR}/${libint_archive} ]; then
                                echo --- Downloading ${libint_archive} in ${SOURCES_DIR} directory.
                                wget -P $SOURCES_DIR https://github.com/cp2k/libint-cp2k/releases/download/v2.6.0/$libint_archive
                        fi
                fi

                cd $BUILD_DIR
#               rm -rf $libint_packname

                tar -xzf ${SOURCES_DIR}/$libint_archive
                cd $libint_packname

                #Configure with desired options:
                if [ "${LIBINT_VERS%.*}" == "v2.6" ]; then
                        ./configure --prefix=$LIBINT_DIR \
                                CC=$MPICC CXX=$MPICXX FC=$MPIF90 \
                                CFLAGS="$CFLAGS" --enable-fortran
                        #LDFLAGS="-L${GMP_DIR}/lib" --with-boost-libdir=${BOOST_DIR}/lib
                        # -I${GMP_DIR}/include " CXXFLAGS="$CXXFLAGS -I${GMP_DIR}/include " FCFLAGS="$FCFLAGS -I${GMP_DIR}/include " \
                else
                        ./configure --prefix=$LIBINT_DIR \
                                --with-cc=${CC} --with-cxx=${CXX} \
                                --with-cc-optflags="${CFLAGS}" \
                                --with-cxx-optflags="${CXXFLAGS}" \
                                --with-libint-max-am=6 --with-libderiv-max-am1=5
                fi

                #Compile
                make -j 16
                make install

                cd $WORK_DIR

        fi

}       2>&1 | tee $BUILD_DIR/$buildlog

#Checking for installtion success
if [ -e "$LIBINT_DIR/lib/libint.a" ] || [ -e "$LIBINT_DIR/lib/libint2.a" ]; then
        echo
        export libint_succ=yes
        export LIBINT_DIR=$LIBINT_DIR
        echo " --- LIBINT_DIR is set to $LIBINT_DIR ."
        echo
else
        echo
        export libint_succ=no
        echo "  LIBINT libraries are not found in $LIBINT_DIR."
        echo "  Please check $BUILD_DIR/$buildlog log  "
        echo
        return
fi




# LIBXC Library Build and Installation
# (optional, optional, wider choice of xc functionals)
# Building and Installing LIBXC library
# http://www.tddft.org/programs/octopus/wiki/index.php/Libxc
# Preferred download site : https://www.cp2k.org/static/downloads/
#----------------------------------------------------------------------------
echo " --- Checking for PATH of LIBXC library (LIBXC_DIR) ... "
export build_packname=libxc-${LIBXC_VERS}
export libxc_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$libxc_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        if [ -d "$LIBXC_DIR" ] && { [ -e "$LIBXC_DIR/lib/libxc.a" ] || [ -e "$LIBXC_DIR/lib64/libxc.a" ]; }; then

                echo
                echo " --- PATH for LIBXC library exists: $LIBXC_DIR"
                echo

        else

                echo
                echo " --- Path for LIBXC library not found."
                echo " --- Building and Installing LIBXC libraries, using ${COMPILERNAME}."
                echo

                libxc_archive=${libxc_packname}.tar.gz

                #       export LIBXC_DIR=$PWD/install-$libxcpackname-${COMPILERNAME}

                if [ ! -e ${SOURCES_DIR}/${libxc_archive} ]; then
                        echo --- ${libxc_archive} in ${SOURCES_DIR} directory.
                        #wget -P ${SOURCES_DIR} http://www.tddft.org/programs/libxc/down.php?file=${LIBXC_VERS}/${libxc_archive} -O ${SOURCES_DIR}/${libxc_archive}
                        #https://www.cp2k.org/static/downloads/libxc-4.3.4.tar.gz
                        wget -P $SOURCES_DIR https://www.cp2k.org/static/downloads/$libxc_archive
                fi
                cd $BUILD_DIR
                rm -rf $libxc_packname

                tar -xzf ${SOURCES_DIR}/$libxc_archive
                cd $libxc_packname

                #Configure
                ./configure CC=${CC} CXX=${CXX} FC=${FC} --prefix=$LIBXC_DIR CFLAGS="${CFLAGS}" FCFLAGS="${FCFLAGS} -fPIC" --enable-shared
                #sed -i 's/\\$wl-soname \\$wl\\$soname/-fuse-ld=ld -Wl,-soname,\\$soname/g' libtool
                sed -i 's/\\$wl-soname \\$wl\\$soname/-Wl,-soname,\\$soname/g' libtool

                #Compile & Install
                make -j
                make install

                cd $WORK_DIR
        fi

}       2>&1 | tee $BUILD_DIR/$buildlog

#Checking for installtion success
if [ -e "$LIBXC_DIR/lib/libxc.a" ] || [ -e "$LIBXC_DIR/lib64/libxc.a" ]; then
        export libxc_succ=yes
        export LIBXC_DIR=$LIBXC_DIR
        echo " LIBXC is set to $LIBXC_DIR"
else
        export libxc_succ=no
        echo " LIBXC libraries are not found in $LIBXC_DIR."
        echo " Please check $BUILD_DIR/$buildlog file "
        return
fi




## ELPA: Eigenvalue soLvers for Petaflop-Applications
## https://elpa.mpcdf.mpg.de/
##-----------------------------------------------------------------------------------------
#echo " --- Checking for PATH for ELPA :  ... "
#

export build_packname=elpa-$ELPA_VERS
export elpa_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$elpa_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        if [ -d "$ELPA_DIR" ] && { [ -e "$ELPA_DIR/lib/libelpa_openmp.a" ] || [ -e "$ELPA_DIR/lib64/libelpa_openmp.a" ]; }; then
                echo
                echo " --- ELPA : Eigenvalue soLvers for Petaflop-Applications is found in : "
                echo "$ELPA_DIR"
                echo "$ELPA_DIR/lib/libelpa_openmp.a"

                ELPA_VERSION_PC=$(ls -1 $ELPA_DIR/lib/pkgconfig/)
                export ELPA_VERSION=$(echo "${ELPA_VERSION_PC%.*}")
                export PATH=$ELPA_DIR/bin:$PATH
                export ELPA_LIBS=$ELPA_DIR/lib
                export LD_LIBRARY_PATH=$ELPA_LIBS:$LD_LIBRARY_PATH
                export ELPA_C_INCLUDE=$ELPA_DIR/include/elpa_openmp-$ELPA_VERSION/elpa
                export ELPA_FORTRAN_INCLUDE=$ELPA_DIR/include/elpa_openmp-$ELPA_VERSION/modules
                echo
        else
                export elpa_archive=elpa-${ELPA_VERS}.tar.gz

                echo
                echo " --- Path for ELPA libraries not found."
                echo " --- Installing ELPA libraries .... "
                echo

                if [ ! -e ${SOURCES_DIR}/${elpa_archive} ]; then
                        echo --- ${elpa_archive} in $SOURCES_DIR directory.
                        wget -P ${SOURCES_DIR} https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2019.11.001/elpa-2019.11.001.tar.gz
                fi
                cd $BUILD_DIR
                rm -rf $elpa_packname

                tar -xzf ${SOURCES_DIR}/$elpa_archive

                cd elpa-$ELPA_VERS

                # Configure with desired options;

                #export FCLIBS="-L$MPI_DIR/lib -L$MPI_DIR/lib64 -L${COMPILERHOME}/lib -L${COMPILERHOME}/lib64 -lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi -lflangmain -lflang -lflangrti -lpgmath -lomp -lm -lrt -lpthread $LAPACK_LIBS $BLAS_LIBS $SCALAPACK_LIBS"
                export FCLIBS=" -lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi $SCALAPACK_LIBS $LAPACK_LIBS $BLAS_LIBS"
                LDFLAGS+="-Wl,-z,muldefs"
        #       ./configure --prefix="$ELPA_DIR" \
        #               --enable-openmp --with-mpi=yes --enable-shared=no --disable-avx512 \
        #               CC=${MPICC} FC=${MPIFC} FCFLAGS="-O3 -march=znver4 -ffast-math -fopenmp -mno-lwp -fPIC" CFLAGS="-O3 -march=znver4 -ffast-math -fopenmp" \
        #                       LIBS="-lflang -lflangrti -lpgmath $SCALAPACK_LIBS $LAPACK_LIBS $BLAS_LIBS $MATH_LIBS -lm -lpthread"

                ./configure --prefix="$ELPA_DIR" \
                        --enable-openmp --with-mpi=yes --enable-shared=no --enable-avx512 \
                        CC=${MPICC} FC=${MPIFC} FCFLAGS="-O3 -march=znver4 -ffast-math -fopenmp -mno-lwp -fPIC" CFLAGS="-O3 -march=znver4 -ffast-math -fopenmp" \
                        LIBS="-lflang -lflangrti -lpgmath $SCALAPACK_LIBS $LAPACK_LIBS $BLAS_LIBS $MATH_LIBS -lm -lpthread"
                sed -i 's/\\$wl-soname \\$wl\\$soname/-fuse-ld=ld -Wl,-soname,\\$soname/g' libtool
                sed -i 's/\\$wl--whole-archive\\$convenience \\$wl--no-whole-archive//g' libtool

                # Compile
                make clean
                make -j 1 2>&1 | tee make_elpa-${ELPA_VERS}.log

                # Install
                make install 2>&1 | tee make_install_elpa-${ELPA_VERS}.log

                cd $WORK_DIR

        fi

}       2>&1 | tee $BUILD_DIR/$buildlog

# Checking for installation success
if [ -e "$ELPA_DIR/lib/libelpa_openmp.a" ] || [ -e "$ELPA_DIR/lib64/libelpa_openmp.a" ]; then
        export ELPA_VERSION_PC=$(ls -1 $ELPA_DIR/lib/pkgconfig/)
        export ELPA_VERSION=$(echo "${ELPA_VERSION_PC%.*}")
        export ELPA_C_INCLUDE=$ELPA_DIR/include/elpa_openmp-$ELPA_VERSION/elpa
        export ELPA_FORTRAN_INCLUDE=$ELPA_DIR/include/elpa_openmp-$ELPA_VERSION/modules
        export elpa_succ=yes
        echo " ELPA_DIR set to $ELPA_DIR and ELPA_VERSION=$ELPA_VERSION"
else
        export elpa_succ=no
        echo " No ELPA found in $ELPA_DIR"
        echo " Please check $BUILD_DIR/$buildlog file"
        return
fi

#----------------------------------------------------------------------------
#CP2K building
#https://www.cp2k.org/
#----------------------------------------------------------------------------
echo " --- Building CP2K with ${COMPILERNAME}... "

export cp2k_packname=cp2k-$APP_VERS
export cp2k_sourcename=cp2k-$APP_VERS
date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$cp2k_packname.$USER.$(hostname -s).$(hostname -d).$date.txt
{
        set -eux
        if [ -e "$CP2K_DIR/exe/${ARCH}/cp2k.{VERSION}" ]; then
                echo "CP2K exits"
        else
                cp2k_archive=cp2k-${APP_VERS}.tar.bz2

                if [ ! -e ${SOURCES_DIR}/${cp2k_archive} ]; then
                        echo " --- Downloading ${cp2k_archive} in ${SOURCES_DIR} directory."

                        wget -P ${SOURCES_DIR} https://github.com/cp2k/cp2k/releases/download/v${APP_VERS}.0/${cp2k_archive}
                fi
                echo " --- ${cp2k_archive} found in ${SOURCES_DIR} directory."

                cd $BUILD_DIR

                tar -xjf ${SOURCES_DIR}/$cp2k_archive

                if [ -d "$CP2K_DIR/exe/${ARCH}" ]; then
                        echo " --- Install directory :$CP2K_DIR"
                        echo " --- Exists .... "

                else
                        echo " --- Compiling ${ARCH}"
                        cp -Trf $cp2k_sourcename $CP2K_DIR
                fi

                #cd $cp2ksourcename

                ARCH_FILE=${ARCH}.${VERSION}

                echo " --- FFTW_HOME=$AOCL_DIR"

                cd $CP2K_DIR/arch

                if [ -e "$CP2K_DIR/arch/${ARCH_FILE}" ]; then
                        mv ${ARCH_FILE} ${ARCH_FILE}.bak
                fi
                echo "--- Entering in $PWD"
#                . $WORK_DIR/$ENV_FILE
                echo "CC       = ${MPICC} " >${ARCH_FILE}
                echo "CPP      = " >>${ARCH_FILE}
                echo "FC       = ${MPIF90} " >>${ARCH_FILE}
                echo "AR       = llvm-ar -rc" >>${ARCH_FILE}
                echo "RANLIB   = llvm-ranlib" >>${ARCH_FILE}
                echo "" >>${ARCH_FILE}
                echo "LD       = ${MPIF90}" >>${ARCH_FILE}
                echo "" >>${ARCH_FILE}
                echo "#Pre-requisite paths: " >>${ARCH_FILE}
                echo "" >>${ARCH_FILE}
                echo "FFTW_INC    = ${AOCL_DIR}/include" >>${ARCH_FILE}
                echo "FFTW_LIB    = ${AOCL_DIR}/lib" >>${ARCH_FILE}
                echo "LIBINT_INC  = ${LIBINT_DIR}/include" >>${ARCH_FILE}
                echo "LIBINT_LIB  = ${LIBINT_DIR}/lib" >>${ARCH_FILE}
                echo "LIBXC_INC   = ${LIBXC_DIR}/include" >>${ARCH_FILE}
                echo "LIBXC_LIB   = ${LIBXC_DIR}/lib" >>${ARCH_FILE}
                echo "LIBXSMM_INC = ${LIBXSMM_DIR}/include" >>${ARCH_FILE}
                echo "LIBXSMM_LIB = ${LIBXSMM_DIR}/lib" >>${ARCH_FILE}

                if [ "$elpa_succ" = yes ]; then
                        echo "ELPA_INC    = ${ELPA_DIR}/include/${ELPA_VERSION}" >>${ARCH_FILE}
                        echo "ELPA_LIB    = ${ELPA_DIR}/lib" >>${ARCH_FILE}
                fi

                echo "" >>${ARCH_FILE}
                echo "" >>${ARCH_FILE}
                #echo "DFLAGS       = -D__F2008 -D__FFTW3 -D__MPI_VERSION=3 " >>${ARCH_FILE}
                echo "DFLAGS       =  -D__F2008 -D__FFTW3 -D__MPI_VERSION=3 " >>${ARCH_FILE}
                echo "DFLAGS      += -D__parallel -D__SCALAPACK" >>${ARCH_FILE}

                if [ "$libint_succ" = yes ]; then
                        echo "DFLAGS      +=  -D__LIBINT -D__LIBINT_MAX_AM=6 -D__LIBDERIV_MAX_AM1=5 -D__MAX_CONTR=4" >>${ARCH_FILE}
                fi

                if [ "$libxsmm_succ" = yes ]; then
                        echo "DFLAGS      += -D__LIBXSMM " >>${ARCH_FILE}
                fi

                if [ "$libxc_succ" = yes ]; then
                        echo "DFLAGS      += -D__LIBXC" >>${ARCH_FILE}
                fi

                if [ "$elpa_succ" = yes ]; then
                        echo "DFLAGS      += -D__ELPA=$ELPA_TAG" >>${ARCH_FILE}
                fi

                echo "" >>${ARCH_FILE}


                echo "CFLAGS       = \$(DFLAGS)-g -O3 -march=znver4 -fopenmp" >>${ARCH_FILE}
                echo "FCFLAGS       = \$(DFLAGS)-g -O3 -march=znver4 -fopenmp -Mbackslash" >>${ARCH_FILE}
#               echo "FCFLAGS       += -ffp-contract=fast"  >>${ARCH_FILE}
#               echo "FCFLAGS       += -g" >>${ARCH_FILE}
                #echo "FCFLAGS      += -fexperimental-new-constant-interpreter ">>${ARCH_FILE}
                #echo "FCFLAGS      += -fremap-arrays  ">>${ARCH_FILE}
                #echo "FCFLAGS      += -flto -fremap-arrays -mllvm -vector-library=LIBMVEC -Hx,47,0x10000008 ">>${ARCH_FILE}
                #echo "FCFLAGS      += -ffree-form -ffast-math -std=2008 -funroll-loops " >>${ARCH_FILE}
                echo "FCFLAGS      += -I\${FFTW_INC} -I\${LIBINT_INC}" >>${ARCH_FILE}
                echo "FCFLAGS      += -I\${LIBXC_INC} -I\${LIBXSMM_INC}" >>${ARCH_FILE}

                if [ "$elpa_succ" = yes ]; then
                        echo "FCFLAGS      += -I\${ELPA_INC}/elpa" >>${ARCH_FILE}
                        echo "FCFLAGS      += -I\${ELPA_INC}/modules" >>${ARCH_FILE}
                fi

                echo "" >>${ARCH_FILE}
                echo "LDFLAGS      = \${FCFLAGS} -Wl,-z,muldefs" >>${ARCH_FILE}
                echo "" >>${ARCH_FILE}
                echo "" >>${ARCH_FILE}
                echo "LIBS         = ${SCALAPACK_LIBS}" >>${ARCH_FILE}
                echo "LIBS        += ${LAPACK_LIBS}" >>${ARCH_FILE}
                echo "LIBS        += ${BLAS_LIBS}" >>${ARCH_FILE}
                echo "LIBS        += \${FFTW_LIB}/${FFTW_LIB_NAME}_mpi.a" >>${ARCH_FILE}
                echo "LIBS        += \${FFTW_LIB}/${FFTW_LIB_NAME}_omp.a" >>${ARCH_FILE}
                echo "LIBS        += \${FFTW_LIB}/${FFTW_LIB_NAME}.a" >>${ARCH_FILE}

                if [ "$libxc_succ" = yes ]; then
                        echo "LIBS        += \${LIBXC_LIB}/libxcf03.a" >>${ARCH_FILE}
                        #echo "LIBS        += -lxcf03" >>${ARCH_FILE}
                        echo "LIBS        += \${LIBXC_LIB}/libxc.a" >>${ARCH_FILE}
                        #echo "LIBS        += -lxc" >>${ARCH_FILE}
                fi

                if [ "$libint_succ" = yes ]; then
                        #echo "LIBS        += \${LIBINT_LIB}/libderiv.a" >>${ARCH_FILE}
                        echo "LIBS        += \${LIBINT_LIB}/libint2.a" >>${ARCH_FILE}
                fi

                if [ "$libxsmm_succ" = yes ]; then
                        echo "LIBS        += \${LIBXSMM_LIB}/libxsmmf.a" >>${ARCH_FILE}
                        echo "LIBS        += \${LIBXSMM_LIB}/libxsmm.a" >>${ARCH_FILE}
                fi
                if [ "$elpa_succ" = yes ]; then
                        echo "LIBS        += \${ELPA_LIB}/libelpa_openmp.a" >>${ARCH_FILE}
                fi

                echo "LIBS        += -lpthread -lstdc++ -ldl" >>${ARCH_FILE}

                #echo "# Required due to memory leak that occurs if high optimisations are used" >>${ARCH_FILE}
                #echo "mp2_optimize_ri_basis.o: mp2_optimize_ri_basis.F" >>${ARCH_FILE}
                #echo "                 ${MPIF90} -c \$(subst O2,O0,\$(FCFLAGS)) $<" >>${ARCH_FILE}
                #echo "# Required to disable escape function of character \ within quotes" >>${ARCH_FILE}
                #echo "cp2k.o: cp2k.F" >>${ARCH_FILE}
                #echo "                         ${MPIF90} -c \$(subst fopenmp,Mbackslash,\$(FCFLAGS)) $<" >>${ARCH_FILE}

                if [ "$APP_VERS" = "6.1" ]; then
                        cd $CP2K_DIR/makefiles
                elif [ "$APP_VERS" = "7.1" ]; then
                        cd $CP2K_DIR
                fi

                echo "--- Entering in $PWD"

                #Compiling :
                #Syntax :make -j N ARCH=architecture VERSION=version

                make ARCH=${ARCH} VERSION=${VERSION} clean
                time make -j ARCH=${ARCH} VERSION=${VERSION} 2>&1 | tee make.${ARCH_FILE}.log

                if [ -e "$CP2K_DIR/exe/${ARCH}/cp2k.${VERSION}" ]; then
                        echo
                        echo " --- CP2K release $cp2k_packname BUILD using ${ARCH_FILE} SUCCESSFUL with ${COMPILERNAME}."
                        echo " --- Binary exiectuables can be found in : $CP2K_DIR/exe/${ARCH}"
                        export PATH=$CP2K_DIR/exe/${ARCH}:$PATH
                        echo " --- Environment file : $WORK_DIR/$ENV_FILE ."

                        if [ "$elpa_succ" = yes ]; then
                                echo "export ELPA_FORTRAN_INCLUDE=$ELPA_FORTRAN_INCLUDE:\$ELPA_FORTRAN_INCLUDE" >>$WORK_DIR/$ENV_FILE
                                echo "export ELPA_C_INCLUDE=$ELPA_C_INCLUDE:\$ELPA_C_INCLUDE" >>$WORK_DIR/$ENV_FILE
                        fi
                        chmod a+x $WORK_DIR/$ENV_FILE
                        echo
                else
                        echo " --- CP2K release $cp2k_sourcename BUILD using ${ARCH_FILE} is NOT SUCCESSFUL with ${COMPILERNAME}."
                        echo

                        cd $WORK_DIR
                        return
                fi

                if [ "$TEST_JOB" = yes ]; then

                        #####################################################################################
                        #
                        # Check the SMP executables with H2O-32 benchmark input
                        # Ref : https://www.cp2k.org/dev:release_checklist
                        #
                        ######################################################################################
                        echo " --- Testing and validation of PSMP executables with "H2O-32 benchmark inputs"."
                        echo " --- Ref : https://www.cp2k.org/dev:release_checklist."
                        echo " --- This tests suite take a few tens of minutes to complete."
                        echo " --- Starting tests ............"

                        cwd=$PWD

                        cp -rf $CP2K_DIR/tests/QS/benchmark $CP2K_DIR/tests/QS/benchmark-${COMPILERNAME}

                        cd $CP2K_DIR/tests/QS/benchmark-${COMPILERNAME}
                        #
                        $CP2K_DIR/tools/clean_cwd.sh

                        export OMP_NUM_THREADS=1
                        mpiexec -np 8 ../../../exe/${ARCH}/cp2k.${VERSION} H2O-32.inp >${cwd}/H2O-32-${VERSION}-8-1.out
                        #
                        $CP2K_DIR/tools/clean_cwd.sh
                        export OMP_NUM_THREADS=2
                        mpiexec -np 4 ../../../exe/${ARCH}/cp2k.${VERSION} H2O-32.inp >${cwd}/H2O-32-${VERSION}-4-2.out
                        #
                        $CP2K_DIR/tools/clean_cwd.sh
                        export OMP_NUM_THREADS=4
                        mpiexec -np 2 ../../../exe/${ARCH}/cp2k.${VERSION} H2O-32.inp >${cwd}/H2O-32-${VERSION}-2-4.out
                        #
                        $CP2K_DIR/tools/clean_cwd.sh
                        #

                        cd ${cwd}

                        for f in H2O-32-${VERSION}-*.out; do
                                echo -n $f
                                grep "ENERGY| Total FORCE_EVAL" $f | tail -1 | awk '{printf "%20.12f\n",$NF}'
                        done

                        echo " --- The final energies of all MD runs should agree by 10^-10. "
                fi
        fi

} 2>&1 | tee ${BUILD_DIR}/$buildlog

