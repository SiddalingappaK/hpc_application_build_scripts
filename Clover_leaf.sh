#!/bin/bash
main_dir=$PWD
flag=1
##################################################################################
if [[ -e ./aocc/bin/clang ]];
then
        echo "AOCC is installed skipping"
        source setenv_AOCC.sh
          export COMPILERROOT=$main_dir/aocc
else
        if [[ -e ./aocc-compiler-4.0.0.tar ]];
        then
                rm -rf aocc
                tar -xf aocc-compiler-4.0.0.tar -C $main_dir
                mv  aocc-compiler-4.0.0 aocc
                cd aocc
                ./install.sh
                cd ..
                source setenv_AOCC.sh
                export COMPILERROOT=$main_dir/aocc
                cd $main_dir
        else
        echo "Download aocc-compiler-4.0.0.tar and keep in in $main_dir"
        flag=0
    fi
fi
######################################################################################
cd $main_dir
if [[ $flag == 1 ]];
then
    echo ""
else
    exit
fi
#####################################################################################
if [ ! -e ${main_dir}/ompi/bin/mpirun ];
then
    echo "OpenMPI is not installed installing..."
    mkdir ompi
    rm -rf openmpi-4.1.4.tar.gz
    wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.4.tar.gz
    tar -xf openmpi-4.1.4.tar.gz
    cd openmpi-4.1.4
    if [[ -d /opt/mellanox/hcoll ]];
    then
        options="--with-hcoll=/opt/mellanox/hcoll"
    fi
    if [[ -d /opt/knem-1.1.4.90mlnx1 ]];
    then
        options="$options --with-knem=/opt/knem-1.1.4.90mlnx1"
    fi
    if [[ -d /home/software/ucc/1.2.0 ]];
    then
        options="$options --with-ucc=/home/software/ucc/1.2.0"
    fi
    if [[ -d /home/software/ucx/1.14.0_mt ]];
    then
        options="$options --with-ucx=/home/software/ucx/1.14.0_mt"
    fi
    if [[ -d /home/software/xpmem/2.3.0 ]];
    then
        options="$options --with-xpmem=/home/software/xpmem/2.3.0"
    fi
    if [[ -d /cm/shared/apps/slurm/20.02.6 ]];
    then
        options="$options --with-pmi=/cm/shared/apps/slurm/20.02.6"
    fi
    if [[ -d /home/software/hwloc/2.3.0s ]];
    then
        options="$options --with-hwloc=/home/software/hwloc/2.3.0s"
    fi
    export CC=clang
    export CXX=clang++
    export F90=flang
    export F77=flang
    export FC=flang
    ARCH="-march=znver4"
    OMP="-fopenmp"
    export CFLAGS="-O3 -ffast-math ${ARCH} ${OMP}"
    export CXXFLAGS="-O3 -ffast-math ${ARCH} ${OMP}"
    export FCFLAGS="-O3 -ffast-math ${ARCH} ${OMP}"
    export LDFLAGS="-L$COMPILERROOT/lib"

    ./configure --prefix=$main_dir/ompi CC="${CC}" CXX="${CXX}" FC="${FC}" CFLAGS="${CFLAGS}" \
    CXXFLAGS="${CXXFLAGS}" FCFLAGS="${FCFLAGS}" LDFLAGS="${LDFLAGS}" --enable-mpi-fortran --enable-shared=yes \
    --enable-mpi1-compatibility --enable-static=yes --enable-mpi-cxx --with-pmix --enable-mca-no-build=btl-uct \
    $options
    make -j $(nproc)
    make install
    if [[ -e ./ompi/bin/mpirun ]];
    then
        echo "Openmpi Installation successful"
    else
        echo "Openmpi installation failed"
        flag=0
    fi
else
        echo "ompi already exits.....so skipping "
fi

if [ ! -e ${main_dir}/openmpi_source_file.sh ];then
        echo "Creating openmpi_source_file"
        echo "export MPIROOT=${main_dir}/ompi" > ${main_dir}/openmpi_source_file.sh
        echo 'export PATH=${MPIROOT}/bin:$PATH
        export LD_LIBRARY_PATH=${MPIROOT}/lib:$LD_LIBRARY_PATH
        export LIBRARY_PATH=${MPIROOT}/lib:$LIBRARY_PATH
        export C_INCLUDE_PATH=${MPIROOT}/include:$C_INCLUDE_PATH
        export CPLUS_INCLUDE_PATH=${MPIROOT}/include:$CPLUS_INCLUDE_PATH
        export INCLUDE=${MPIROOT}/include:$INCLUDE
        export CPATH=${MPIROOT}/include:$CPATH
        export FPATH=${MPIROOT}/include:$FPATH
        export MANPATH=${MPIROOT}/share/man:$MANPATH
        export PKG_CONFIG_PATH=${MPIROOT}/lib/pkgconfig:$PKG_CONFIG_PATH
        ' >> ${main_dir}/openmpi_source_file.sh
        chmod +x ${main_dir}/openmpi_source_file.sh
else
        echo "source file for ompi already created...."
fi

source openmpi_source_file.sh
export MPIBIN=${MPIROOT}/bin
#################################################################################################################
cd $main_dir
if [[ $flag == 1 ]];
then
    echo ""
else
    exit
fi
#################################################################################################################
#########################ENVIRONMENT##################################################
export COMPILERHOME=$COMPILERROOT
export CCOMPILERBIN=$COMPILERROOT/bin
export COMPILERNAME=LLVM

export CCOMPILER=clang
export CXXCOMPILER=clang++
export FORTCOMPILER=flang
export ARCMD=ar
export NMCMD=nm
export ASCMD=as
export RAINLIBCMD=ranlib

export MPICC=mpicc
export MPIFC=mpif90

export CFLAGS="-O3 -fPIC -march=native"
export CXXFLAGS="-O3 -fPIC -march=native"
export FCFLAGS="-O3 -fPIC -march=native"
#######################################################################################
cd $main_dir
rm -rf clover_l
mkdir clover_l
cd clover_l
wget https://github.com/UK-MAC/CloverLeaf_ref/archive/v1.3.tar.gz
tar -xf v1.3.tar.gz
mv CloverLeaf_ref-1.3 CloverLeaf_ref-1.3_aocc
cd CloverLeaf_ref-1.3_aocc
make clean
export OPTIONS="$CFLAGS"
export C_OPTIONS="$CFLAGS"


################################################Creating Patch file#############################################
echo '--- CloverLeaf_ref-1.3/Makefile   2015-10-28 08:39:46.000000000 +0000
+++ Makefile    2019-09-19 14:36:21.655835809 +0000
@@ -30,6 +30,7 @@
 #  compilers.
 # To select a OpenMP compiler option, do this in the shell before typing make:-
 #
+#  export COMPILER=LLVM        # to select the LLVM flags
 #  export COMPILER=INTEL       # to select the Intel flags
 #  export COMPILER=SUN         # to select the Sun flags
 #  export COMPILER=GNU         # to select the Gnu flags
@@ -40,6 +41,7 @@

 # or this works as well:-
 #
+# make COMPILER=LLVM
 # make COMPILER=INTEL
 # make COMPILER=SUN
 # make COMPILER=GNU
@@ -62,6 +64,7 @@
   MESSAGE=select a compiler to compile in OpenMP, e.g. make COMPILER=INTEL
 endif

+OMP_LLVM      = -fopenmp
 OMP_INTEL     = -openmp
 OMP_SUN       = -xopenmp=parallel -vpara
 OMP_GNU       = -fopenmp
@@ -71,6 +74,7 @@
 OMP_XL        = -qsmp=omp -qthreaded
 OMP=$(OMP_$(COMPILER))

+FLAGS_LLVM      = -O3 -funroll-loops
 FLAGS_INTEL     = -O3 -no-prec-div
 FLAGS_SUN       = -fast -xipo=2 -Xlistv4
 FLAGS_GNU       = -O3 -march=native -funroll-loops
@@ -88,6 +92,7 @@
 CFLAGS_          = -O3

 ifdef DEBUG
+  FLAGS_LLVM      = -O0 -g -O -Wall -Wextra -fsanitize=address
   FLAGS_INTEL     = -O0 -g -debug all -check all -traceback -check noarg_temp_created
   FLAGS_SUN       = -g -xopenmp=noopt -stackvar -u -fpover=yes -C -ftrap=common
   FLAGS_GNU       = -O0 -g -O -Wall -Wextra -fbounds-check
@@ -96,6 +101,7 @@
   FLAGS_PATHSCALE = -O0 -g
   FLAGS_XL       = -O0 -g -qfullpath -qcheck -qflttrap=ov:zero:invalid:en -qsource -qinitauto=FF -qmaxmem=-1 -qinit=f90ptr -qsigtrap -qextname=flush:ideal_gas_kernel_c:viscosity_kernel_c:pdv_kernel_c:revert_kernel_c:accelerate_kernel_c:flux_calc_kernel_c:advec_cell_kernel_c:advec_mom_kernel_c:reset_field_kernel_c:timer_c:unpack_top_bottom_buffers_c:pack_top_bottom_buffers_c:unpack_left_right_buffers_c:pack_left_right_buffers_c:field_summary_kernel_c:update_halo_kernel_c:generate_chunk_kernel_c:initialise_chunk_kernel_c:calc_dt_kernel_c
   FLAGS_          = -O0 -g
+  CFLAGS_LLVM     = -O0 -g -Wall -Wextra -fsanitize=address
   CFLAGS_INTEL    = -O0 -g -debug all -traceback
   CFLAGS_SUN      = -g -O0 -xopenmp=noopt -stackvar -u -fpover=yes -C -ftrap=common
   CFLAGS_GNU       = -O0 -g -O -Wall -Wextra -fbounds-check
@@ -106,6 +112,7 @@
 endif

 ifdef IEEE
+  I3E_LLVM      = -ffast-math
   I3E_INTEL     = -fp-model strict -fp-model source -prec-div -prec-sqrt
   I3E_SUN       = -fsimple=0 -fns=no
   I3E_GNU       = -ffloat-store
' > llvm.patch
###############################################################################################################################################
patch -b Makefile ./llvm.patch

make COMPILER=LLVM MPI_COMPILER=${MPIFC} C_MPI_COMPILER=${MPICC} IEEE=1
