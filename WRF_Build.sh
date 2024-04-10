#!/bin/bash

echo "#---------------------------------------------------------------------------------------#"
echo "#                 Building   WRF-4.2.1                                                  #"
echo "#       Supported Compiler : AOCC                                                       #"
echo "#       Supported Parallelism : MPI                                                     #"
echo "#---------------------------------------------------------------------------------------#"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                COMPILER SETTINGS                                     #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Set compiler path and name
export COMPILER_NAME=aocc
export COMPILER_VERS=3.2.0

export COMPILERHOME=/mnt/share/users/manoj/aocc-compiler-4.0.0
export COMPILERBIN=${COMPILERHOME}/bin
export COMPILERNAME=${COMPILER_NAME}`echo ${COMPILER_VERS} | tr -dc "[:digit:]"`

#Setting up the compiler
export CC=clang
export CXX=clang++
export F90=flang
export F77=flang
export FC=flang

ARCH="-march=znver4"
OMP="-fopenmp"

#Setting up the compiler flags
export CFLAGS="-O3 ${ARCH} ${OMP} -fPIC"
export CXXFLAGS="-O3 ${ARCH} ${OMP} -fPIC"
export FCFLAGS="-O3 ${ARCH} ${OMP} -fPIC"
export FFLAGS="-O3 ${ARCH} ${OMP} -fPIC"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                MPI Settings                                          #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#Set MPI libray and version
export MPI_LIBRARY=openmpi
export MPI_VERS=4.1.1
export MPI_NAME=ompi`echo ${MPI_VERS} | tr -dc "[:digit:]"`

#MPI compiler setting
export MPICC=mpicc      #MPICC:     MPI C compiler command
export MPICXX=mpiCC     #MPICXX:    MPI C++ compiler command
export MPIFC=mpifort    #MPIFC:     MPI Fortran compiler command
export MPIF90=mpif90    #MPIF90:    MPI Fortran-90(F90) compiler command
export MPIF77=mpif77    #MPIF77:    MPI Fortran-77(F77) compiler command

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                Prerequiste Settings                                  #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

export WORK_DIR=$PWD/WRF_BUILD
mkdir -p $WORK_DIR
# Application specific builds, sources  and prerequisites installation paths etc
export PREFIX_PATH=${WORK_DIR}/apps

# Path for source directory where all archives are kept or will be downloaded
export SOURCES_DIR=${PREFIX_PATH}/sources

# Path for build directory where all compiler specific builds and logs are kept
export BUILD_DIR=${PREFIX_PATH}/build/${MPI_NAME}/${COMPILERNAME}

# Path for all prerequisites installations
export INSTALL_DIR=${PREFIX_PATH}

# Please provide MPI Library install directory, if installed already
export MPI_DIR=${INSTALL_DIR}/${MPI_LIBRARY}/${COMPILERNAME}/${MPI_VERS}

# JEMALLOC Setting
export JEMALLOC_VERS=5.2.1
export JEMALLOC_DIR=${INSTALL_DIR}/jemalloc/${JEMALLOC_VERS}

# AOCL Setting
export AOCL_LIB=/mnt/share/Amd_profiles/SOURCE_DIR/4.0/lib
# HDF5 Settings
export HDF5_VERS=1.10.8
export HDF5_DIR=${INSTALL_DIR}/hdf5/${MPI_NAME}/${COMPILERNAME}/${HDF5_VERS}

# PNETCDF Settings
export PNETCDF_VERS=1.11.2
export PNETCDF_DIR=${INSTALL_DIR}/pnetcdf/${MPI_NAME}/${COMPILERNAME}/${PNETCDF_VERS}

# NETCDF-C and NETCDF-FORTRAN Settings
# NETCDF-C Version
export NETCDFC_VERS=4.7.4

# NETCDF-FORTRAN Version
export NETCDFF_VERS=4.5.3

export NETCDF_DIR=${INSTALL_DIR}/netcdf/${MPI_NAME}/${COMPILERNAME}/${NETCDFC_VERS}

###################################################################################################################################################3
mkdir -p $WORK_DIR
mkdir -p ${INSTALL_DIR} ${SOURCES_DIR} ${BUILD_DIR}

#Compiler
 export PATH=${COMPILERHOME}/bin:${PATH}
 export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+}:${COMPILERHOME}/lib:${COMPILERHOME}/lib32
 export INCLUDE=${INCLUDE:+}:${COMPILERHOME}/include

$COMPILERBIN/${CC} -v

if [[ $? -ne 0 ]];
then
        echo "Error: '$COMPILERHOME/bin/$CC} -v' returns non-zero. Set the Path of AOCC path"
        return
        exit 1
fi

#OpenMPI
 export PATH=${MPI_DIR}/bin:${PATH}
 export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MPI_DIR}/lib:${MPI_DIR}/lib64
 export INCLUDE=${INCLUDE}:${MPI_DIR}/include

#PNETCDF
 export PATH=${PNETCDF_DIR}/bin:${PATH}
 export LD_LIBRARY_PATH=${PNETCDF_DIR}/lib/:${LD_LIBRARY_PATH}
 export INCLUDE=${PNETCDF_DIR}/include:${INCLUDE}

 export PnetCDF_Fortran_LIBRARY=${PNETCDF_DIR}/lib
 export PnetCDF_Fortran_INCLUDE_DIR=${PNETCDF_DIR}/include

#HDF5
 export PATH=${HDF5_DIR}/bin:${PATH}
 export LD_LIBRARY_PATH=${HDF5_DIR}/lib:${HDF5_DIR}/lib64:${LD_LIBRARY_PATH}
 export INCLUDE=${HDF5_DIR}/include:${INCLUDE}

#NetCDF-C and NetCDF Fortran
 export PATH=${NETCDF_DIR}/bin:${PATH}
 export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${NETCDF_DIR}/lib64:${LD_LIBRARY_PATH}
 export INCLUDE=${NETCDF_DIR}/include:${INCLUDE}


echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
echo "#                                Building Jemalloc                                     #"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"


export build_packname=jemalloc-${JEMALLOC_VERS}
export jemalloc_packname=$build_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$jemalloc_packname.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux
        if [ -d "$JEMALLOC_DIR" ]  && { [ -e "$JEMALLOC_DIR/lib/libjemalloc.so" ] || [ -e "$JEMALLOC_DIR/lib64/libjemalloc.so" ]; }
        then
                echo " --- JEMALLOC is here : $JEMALLOC_DIR"
        else
                echo " --- JEMALLOC is not here : $JEMALLOC_DIR"
                echo " --- JEMALLOC build and install ... "

                jemalloc_vers=${JEMALLOC_VERS}.tar.gz
                jemalloc_archive=${jemalloc_packname}.tar.gz


                if [ ! -e ${SOURCES_DIR}/$jemalloc_archive ]
                then
                        cd  ${SOURCES_DIR}
                        echo --- $jemalloc_archive is not found in ${SOURCES_DIR}/ directory.
                        wget -P ${SOURCES_DIR} https://github.com/jemalloc/jemalloc/archive/refs/tags/${jemalloc_vers}
                        mv  ${jemalloc_vers} ${jemalloc_archive}
                fi

                cd $BUILD_DIR
                rm -rf ${jemalloc_packname}

                tar -xf ${SOURCES_DIR}/$jemalloc_archive

                cd ${jemalloc_packname}

                ./autogen.sh CC=gcc CFLAGS="-O3" CXX=g++ CXXFLAGS="-O3" --prefix=${JEMALLOC_DIR} |tee autoconf.log
                ./configure  CC=gcc CFLAGS="-O3" CXX=g++ CXXFLAGS="-O3" --prefix=${JEMALLOC_DIR} |tee configure.log

                make -j 2>&1|tee make.log

                make install 2>&1|tee make_install.log
        fi

        #Checking for installtion success
        if [ -e "$JEMALLOC_DIR/lib/libjemalloc.so" ] || [ -e "$JEMALLOC_DIR/lib64/libjemalloc.so" ];
        then
                echo "$jemalloc_packname built successfully."
        else
                echo "$jemalloc_packname failed."
                echo " --- Please check : ${BUILD_DIR}/$buildlog ---"
                cd ${WORK_DIR}
                exit 1
        fi

        export LD_LIBRARY_PATH=$JEMALLOC_DIR/lib:$JEMALLOC_DIR/li64:$LD_LIBRARY_PATH
        export C_INCLUDE_PATH=$JEMALLOC_DIR/include:$C_INCLUDE_PATH

} 2>&1 | tee $BUILD_DIR/$buildlog


echo "#################################################################################################################################"



echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
echo "#                                Building openmpi                                      #"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"

build_packname=${MPI_LIBRARY}-${MPI_VERS}
mpi_packname=${build_packname}

echo " --- MPIPACKNAME : ${mpi_packname}"
date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.${build_packname}.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        echo "Checking for PATH of OpenMPI... "

        if [ -d "$MPI_DIR" ] && [ -e "$MPI_DIR/bin/$MPICC" ]
        then
                echo
                echo " --- PATH for OpenMPI exists: $MPI_DIR"
                echo
        else
                echo
                echo " --- Path for OpenMPI not found."
                mpi_archive=${mpi_packname}.tar.bz2

                if [  -f "${SOURCES_DIR}/${mpi_archive}" ]
                then
                        echo "${mpi_packname} source file found in ${SOURCES_DIR}"
                else
                        echo "Downloading ${mpi_packname}"
                        wget -P ${SOURCES_DIR} https://download.open-mpi.org/release/open-mpi/v${MPI_VERS::-2}/${mpi_archive}
                fi

                cd ${BUILD_DIR}
                rm -rf ${mpi_packname}

                echo " Building ${mpi_packname} in $PWD "

                tar xvf ${SOURCES_DIR}/${mpi_archive}

                cd ${mpi_packname}
                #Configuring MPI library
                ./configure --prefix=${MPI_DIR} CC=${CC} CXX=${CXX} FC=${FC} \
                        CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" FCFLAGS="$FCFLAGS" \
                        --enable-mpi-fortran --enable-shared=yes --enable-static=yes  \
                        --enable-mpi1-compatibility --disable-hwloc-pci  \
                        --enable-builtin-atomics --enable-mpi-cxx --with-pmix --with-slurm --enable-mpi-cxx \
                        --with-hcoll=/opt/mellanox/hcoll \
                        --with-knem=/opt/knem-1.1.4.90mlnx1 \
#                       --with-xpmem=/home/software/xpmem/2.3.0 \
#                       --with-ucx=/home/software/ucx/1.11.0 \


                        2>&1 | tee  log.0

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make -j 2>&1| tee log.1

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make install -j 2>&1 | tee  log.2

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

        fi

        if [ -d "$MPI_DIR" ] && [ -e "$MPI_DIR/bin/$MPICC" ]
        then
                export PATH=${MPI_DIR}/bin:${PATH}
                export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MPI_DIR}/lib:${MPI_DIR}/lib64
                export INCLUDE=${INCLUDE}:${MPI_DIR}/include

                echo " --- ############################################## --- "
                echo " --- ###### ${mpi_packname} BUILT SUCCESSFULLY #### --- "
                echo " --- ############################################## --- "
                echo " MPI details : "
                which $MPICC
                ompi_info --version
                echo " --- ###################################### --- "
        else
                echo "${mpi_packname} installtion failed. Please reinstall ${mpi_packname} again".
                echo " --- Please check : ${BUILD_DIR}/$buildlog ---"
                echo " --- ### ${mpi_packname} BUILT FAILED ### --- "
                cd ${WORK_DIR}
                exit 1
        fi
                cd ${WORK_DIR}

} 2>&1 | tee ${BUILD_DIR}/$buildlog


###################################################################################################################################################################

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
echo "#                                Building HDF5                                         #"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"

export build_packname=hdf5-${HDF5_VERS}
export hdf5_packname=${build_packname}

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.${hdf5_packname}.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux
        if [ -d "${HDF5_DIR}" ] && { [ -e "${HDF5_DIR}/lib/libhdf5.a" ] || [ -e "${HDF5_DIR}/lib64/libhdf5.a" ]; }
        then
                echo
                echo "Path for HDF5 exist"
        else

                export CXXFLAGS=-I${MPI_DIR}/include
                export LDFLAGS="-L${MPI_DIR}/lib -L${MPI_DIR}/lib64 "

                echo
                echo "Path for HDF5 not found"

                hdf5_archive=${hdf5_packname}.tar.gz

                if [  -f "${SOURCES_DIR}/$hdf5_archive" ]
                then
                        echo "${hdf5_packname} source file found in ${SOURCES_DIR}"
                else
                        cd ${SOURCES_DIR}
                        echo "Downloading ${hdf5_packname}"
                        wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERS::-2}/${hdf5_packname}/src/$hdf5_archive
                fi

                cd ${BUILD_DIR}
                rm -rf ${hdf5_packname}

                echo " Building ${hdf5_packname}"

                tar xf ${SOURCES_DIR}/$hdf5_archive
                cd ${hdf5_packname}

                export FC=$MPIF90
                export CC=$MPICC
                export CXX=$MPICXX
                #export FCFLAGS="-mllvm --max-speculation-depth=0 -Mextend -ffree-form $FCFLAGS"

                ./configure  --prefix=${HDF5_DIR} CFLAGS="$CFLAGS" FCFLAGS="$FCFLAGS" --enable-fortran --enable-parallel --enable-hl --enable-shared 2>&1 | tee configure.log

                sed -i -e 's#wl=""#wl="-Wl,"#g' libtool
                sed -i -e 's#pic_flag=""#pic_flag=" -fPIC -DPIC"#g' libtool


                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make -j  2>&1 | tee make.log

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make install 2>&1 | tee make-install.log

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make clean
        fi

        if  [ -f ${HDF5_DIR}/lib/libhdf5.a ] || [ -e "${HDF5_DIR}/lib64/libhdf5.a" ] ;
        then
                echo " --- ############################################## --- "
                echo " --- ## Building ${hdf5_packname} is SUCCESSFUL  ## --- "
                echo " --- ############################################## --- "
                export PATH=${HDF5_DIR}/bin:${PATH}
                export LD_LIBRARY_PATH=${HDF5_DIR}/lib:${HDF5_DIR}/lib64:${LD_LIBRARY_PATH}
                export INCLUDE=${HDF5_DIR}/include:${INCLUDE}

                export LDFLAGS+="-L${HDF5_DIR}/lib -L${HDF5_DIR}/lib64"
                export CFLAGS+="-I${HDF5_DIR}/include"
        else
                echo " Building ${hdf5_packname} is UNSUCCESSFUL "
                echo " --- Please check : ${BUILD_DIR}/$buildlog ---"
                cd ${WORK_DIR}
                exit 1
        fi

        cd $WORK_DIR

} 2>&1 | tee $BUILD_DIR/$buildlog
########################################################################################################################################################3

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
echo "#                                Building Pnetcdf                                      #"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"

build_packname=pnetcdf-${PNETCDF_VERS}
pnc_packname=${build_packname}

echo " --- PNCPACKNAME : ${pnc_packname}"
date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.${build_packname}.$USER.$(hostname -s).$(hostname -d).$date.txt

{
        set -eux

        export FC=$MPIF90
        export CC=$MPICC
        export CXX=$MPICXX

        echo "Checking for PATH of PNETCDF... "

        if [ -d "${PNETCDF_DIR}" ] && [ -e "${PNETCDF_DIR}/lib/libpnetcdf.so" ]
        then
                echo
                echo " --- PATH for PNETCDF exists: ${PNETCDF_DIR}"
                echo
        else
                echo
                echo " --- Path for PNETCDF not found."
                pnc_archive=${pnc_packname}.tar.gz

                if [  -f "${SOURCES_DIR}/${pnc_archive}" ]
                then
                        echo "${pnc_packname} source file found in ${SOURCES_DIR}"
                else
                        echo "Downloading ${pnc_packname}"
                        wget -P ${SOURCES_DIR} https://parallel-netcdf.github.io/Release/$pnc_archive
                fi

                cd ${BUILD_DIR}
                rm -rf ${pnc_packname}

                echo " Building ${pnc_packname} in $PWD "

                tar xvf ${SOURCES_DIR}/${pnc_archive}

                cd ${pnc_packname}
                #Configuring PNETCDF library

                        ./configure --disable-cxx --enable-fortran=yes --enable-shared --prefix=${PNETCDF_DIR} 2>&1 | tee  log.0

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make -j 16 2>&1| tee log.1

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

                make install -j 16 2>&1 | tee  log.2

                rc=${PIPESTATUS[0]}
                [[ $rc -eq 0 ]] || exit $rc

        fi

        if [ -d "${PNETCDF_DIR}" ] && [ -e "${PNETCDF_DIR}/lib/libpnetcdf.a" ]
        then
                export PATH=${PNETCDF_DIR}/bin:${PATH}
                export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${PNETCDF_DIR}/lib
                export INCLUDE=${INCLUDE}:${PNETCDF_DIR}/include

                echo " --- ###################################### --- "
                echo " --- ## PNETCDF installation Successfull ## --- "
                echo " --- ###################################### --- "
        else
                echo "${pnc_packname} installtion failed. Please reinstall ${pnc_packname} again".
                echo " --- Please check : ${BUILD_DIR}/$buildlog ---"
                cd ${WORK_DIR}
                exit 1
        fi
                cd ${WORK_DIR}

} 2>&1 | tee ${BUILD_DIR}/$buildlog
 #########################################################################################################################################################


echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
echo "#                                Building netcdf                                       #"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"

export build_netcdfc_packname=netcdf-c-$NETCDFC_VERS
export build_netcdff_packname=netcdf-fortran-$NETCDFF_VERS

export netcdfc_packname=$build_netcdfc_packname
export netcdff_packname=$build_netcdff_packname

date=$(date | perl -pe 's/\s+/_/g;s/_$//;s/://g')

buildlog=buildlog.$netcdfc_packname.$netcdff_packname.$USER.$(hostname -s).$(hostname -d).$date.txt
{
        set -eux

        export FC=$MPIF90
        export CC=$MPICC
        export CXX=$MPICXX

        export CFLAGS="$CFLAGS -I${MPI_DIR}/include -I${HDF5_DIR}/include -I${PNETCDF_DIR}/include -I${NETCDF_DIR}/include"
        export CPPFLAGS="$CXXFLAGS -I${MPI_DIR}/include -I${HDF5_DIR}/include -I${PNETCDF_DIR}/include -I${NETCDF_DIR}/include"
        export LDFLAGS="-L${MPI_DIR}/lib -L${MPI_DIR}/lib64 -L${HDF5_DIR}/lib -L${HDF5_DIR}/lib64 -L${PNETCDF_DIR}/lib -L${PNETCDF_DIR}/lib64 -L${NETCDF_DIR}/lib -L${NETCDF_DIR}/lib64 "

        if [ -d "${NETCDF_DIR}" ] && { [ -e "${NETCDF_DIR}/lib/libnetcdf.a" ] || [ -e "${NETCDF_DIR}/lib64/libnetcdf.a" ] || [ -e "${NETCDF_DIR}/lib64/libnetcdf.so" ]; }
        then
                echo
                echo "Netcdf Fortran $NETCDFF_VERS already installed"
        else
                netcdfc_archive=$netcdfc_packname.tar.gz

                if [  -f "${SOURCES_DIR}/$netcdfc_archive" ]
                then
                        echo "$netcdfc_packname source file found in ${SOURCES_DIR}"
                else
                        cd ${SOURCES_DIR}
                        echo "Downloading $netcdfc_packname"
                        wget https://github.com/Unidata/netcdf-c/archive/v$NETCDFC_VERS.tar.gz -O $netcdfc_archive
                fi

                cd ${BUILD_DIR}
                rm -rf $netcdfc_packname

                tar xf ${SOURCES_DIR}/$netcdfc_archive
                echo " Building $netcdfc_packname"

                cd $netcdfc_packname

                ./configure --with-hdf5=${HDF5_DIR} --enable-dynamic-loading --enable-netcdf-4 --enable-shared --enable-pnetcdf --disable-dap --prefix=${NETCDF_DIR} 2>&1 | tee configure.log
                make -j 16 2>&1 | tee make.log

                make install -j 16 2>&1 | tee make-install.log

                make clean
        fi

        if  [ -f ${NETCDF_DIR}/lib/libnetcdf.a ] || [ -e "${NETCDF_DIR}/lib64/libnetcdf.a" ];
        then
                echo " Building $netcdfc_packname is SUCCESSFUL "
        else
                echo " Building $netcdfc_packname is UNSUCCESSFUL "
                echo " --- Please check : ${BUILD_DIR}/$buildlog ---"
                cd ${WORK_DIR}
                exit 1
        fi


        if [ -d "${NETCDF_DIR}" ] && { [ -e "${NETCDF_DIR}/lib/libnetcdff.so" ] || [ -e "${NETCDF_DIR}/lib64/libnetcdff.so" ] || [ -e "${NETCDF_DIR}/lib64/libnetcdff.so" ]; }
        then
                echo
                echo "Netcdf Fortran $NETCDFF_VERS already installed"

                export PATH=${NETCDF_DIR}/bin:${PATH}
                export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${NETCDF_DIR}/lib64:${LD_LIBRARY_PATH}
                export INCLUDE=${NETCDF_DIR}/include:${INCLUDE}
        else
                netcdff_archive=$netcdff_packname.tar.gz

                if [  -f "${SOURCES_DIR}/$netcdff_archive" ]
                then
                        echo "$netcdff_packname source file found in ${SOURCES_DIR}"
                else
                        cd ${SOURCES_DIR}
                        echo "Downloading netcdff_packname"
                        wget https://github.com/Unidata/netcdf-fortran/archive/v$NETCDFF_VERS.tar.gz -O $netcdff_archive
                fi

                cd ${BUILD_DIR}
                rm -rf $netcdff_packname

                tar xf ${SOURCES_DIR}/$netcdff_archive
                echo " Building $netcdff_packname"

                cd $netcdff_packname

                ./configure --prefix=${NETCDF_DIR} --enable-shared 2>&1 | tee configure.log
                sed -i -e 's#wl=""#wl="-Wl,"#g' libtool
                sed -i -e 's#pic_flag=""#pic_flag=" -fPIC -DPIC"#g' libtool

                make 2>&1 | tee make.log

                make install 2>&1 | tee make-install.log

                make clean
        fi

        if  [ -f ${NETCDF_DIR}/lib/libnetcdff.a ] || [ -e "${NETCDF_DIR}/lib64/libnetcdff.so" ];
        then 
                echo " --- ###################################### --- "
                echo " -- Building $netcdff_packname is SUCCESSFUL -- "
                echo " --- ###################################### --- "
        else
                echo " Building $netcdff_packname is UNSUCCESSFUL "
                echo " --- Please check : ${BUILD_DIR}/$buildlog ---"
                cd ${WORK_DIR}
                exit 1
        fi

        export PATH=${NETCDF_DIR}/bin:${PATH}
        export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${NETCDF_DIR}/lib64:${LD_LIBRARY_PATH}
        export INCLUDE=${NETCDF_DIR}/include:${INCLUDE}

} 2>&1 | tee $BUILD_DIR/$buildlog

#################################################################################################################################

export ENV_FILE=${WORK_DIR}/setEnv_prereq_${MPI_NAME}_${COMPILERNAME}.sh

#export PATH=${NETCDF}/bin:${PNETCDF}/bin:${HDF5}/bin:${PATH}
#export LD_LIBRARY_PATH=${NETCDF}/lib:${PNETCDF}/lib:${HDF5}/lib:${JEMALLOC}/lib:${LD_LIBRARY_PATH}
#export INCLUDE=${NETCDF}/include:${PNETCDF}/include:${HDF5}/include:${JEMALLOC}/include:${INCLUDE}
echo " --- ENVIRONMENT VARIABLE FILE : $ENV_FILE----------"
echo -e "#This file can be used to set up the environment required for application execution \n

export COMPILER=${COMPILERNAME}
export MPI=${MPI_NAME}

export HDF5=${HDF5_DIR}
export PNETCDF=${PNETCDF_DIR}
export NETCDF=${NETCDF_DIR}
export NETCDFC_DIR=${NETCDF_DIR}
export NETCDFF_DIR=${NETCDF_DIR}
export PNETCDF_DIR=${PNETCDF_DIR}
export HDF5_DIR=${HDF5_DIR}
export MPI_DIR=${MPI_DIR}
export JEMALLOC_DIR=${JEMALLOC_DIR}
export JEMALLOC=${JEMALLOC_DIR}


export PATH=${PATH}:\${PATH}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:\${LD_LIBRARY_PATH}
export INCLUDE=${INCLUDE}:\${INCLUDE}
" >$ENV_FILE

chmod a+x ${ENV_FILE}

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
echo "#                                Building WRF-4.2.1                                    #"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"



export WRFWORKDIR=$WORK_DIR
export SOURCE_DIR=/mnt/share/Amd_profiles/SOURCE_DIR/WRF
cd $WRFWORKDIR
rm -rvf WRF-4.2.1
if [ -d $WRFWORKDIR/WRF-4.2.1 ];
then
       echo "file exists WRF"
else
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1

    export FC=flang
    export CC=clang
    export CXX=clang++
    export AR=llvm-ar
    export NM=llvm-nm
    export RANLIB=llvm-ranlib

    export CFLAGS="-g -O3 march=zver4 -fopenmp -fPIC"
    export CXXFLAGS="-g -O3 march=zver4 -fopenmp -fPIC"
    export FCFLAGS="-g -O3 march=zver4 -fopenmp -fPIC"
    export FFLAGS="-g -O3 march=zver4 -fopenmp -fPIC"
    echo "Building WRF"

    export MATHFLAGS="-lamdlibm -L$AOCL_LIB/amdlibm -lm"
    export OPT_CFLAGS="-m64 -Ofast -ffast-math -march=znver4 -mllvm -vector-library=LIBMVEC  -freciprocal-math -ffp-contract=fast -mavx2 -funroll-loops -finline-aggressive"
    export OPT_LDFLAGS="-m64 -Ofast $MATHFLAGS "
    export OPT_FCFLAGS="-m64 -Ofast -march=znver4 -Mbyteswapio -freciprocal-math -ffp-contract=fast -mavx2 -funroll-loops -ffast-math -finline-aggressive "


    source $ENV_FILE

    cd $WRFWORKDIR
    wget https://github.com/wrf-model/WRF/archive/refs/tags/v4.2.1.tar.gz
    tar -xvf v4.2.1.tar.gz
    cd $WRFWORKDIR/WRF-4.2.1
################ AMD Optimised Configure file ##################################
    wget https://raw.githubusercontent.com/Manojmp2000/WRF_configure_fiel/main/configure.wrf
    chmod +x configure.wrf
    echo "compiling wrf"
    ./compile -j 64 em_real 2>&1 | tee logem_real
    cd $WRFWORKDIR/WRF-4.2.1/main
    if [ -e "wrf.exe" ] && [ -e "ndown.exe" ] && [ -e "real.exe" ] && [ -e "tc.exe" ];
    then
            echo " --- ###################################### --- "
            echo " --- ##### WRF-4.2.1 BUILD SUCCESSFUL ##### --- "
            echo " --- ###################################### --- "
    else
            echo " --- ###################################### --- "
            echo " --- ####### WRF-4.2.1 BUILD Failed ####### --- "
            echo " --- ###################################### --- "
            
    fi


fi




