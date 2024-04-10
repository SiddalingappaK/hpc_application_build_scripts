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
if [[ -e ./aocl/lib/libblis-mt.a ]];
then
    echo "AOCL is present skiping"
    source aocl_source_file.sh
else
    if [[ -e ./aocl-linux-aocc-4.0.tar.gz ]];
    then
        rm -rf aocl
        tar -xf aocl-linux-aocc-4.0.tar.gz
        cd aocl-linux-aocc-4.0
        ./install.sh -t $main_dir -i lp64
        mv $main_dir/4.0 $main_dir/aocl
        echo "export libhome=$main_dir/aocl" > $main_dir/aocl_source_file.sh
        echo 'export AOCLROOT=$libhome
        export MATHLIBROOT=$libhome
        export AOCL_PATH=$libhome:$AOCL_PATH
        export INCLUDE=$libhome/include:$INCLUDE
        export CPATH=$libhome/include:$CPATH
        export C_INCLUDE_PATH=$libhome/include:$C_INCLUDE_PATH
        export CPLUS_INCLUDE_PATH=$libhome/include:$CPLUS_INCLUDE_PATH
        export LIBRARY_PATH=$libhome/lib:$LIBRARY_PATH
        export LD_LIBRARY_PATH=$libhome/lib:$LD_LIBRARY_PATH
        ' >> $main_dir/aocl_source_file.sh
        chmod +x $main_dir/aocl_source_file.sh
        cd $main_dir
        source aocl_source_file.sh
    else
        echo "Download aocl-linux-aocc-4.0.tar.gz in $main_dir "
        flag=0
    fi
fi
#######################################################################################
cd $main_dir
if [[ $flag == 1 ]];
then
    echo ""
else
    exit
fi
#######################################################################################
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
####################################################################################
cd $main_dir
if [[ $flag == 1 ]];
then
    echo ""
else
    exit
fi
####################################################################################
cd $main_dir
if [[ -z $1 ]];
then
    export lammps_version=8Apr2021
else
    export lammps_version=$1
fi
if [ -e $PWD/lammps-${lammps_version}/src/lmp_clang++_openmpi ];
then
    echo "Lammps build is already exist. Exiting..."
    exit
else
    export FC=flang
    export CC=clang
    export CXX=clang++
    export F90=flang
    export F77=flang
    export CFLAGS="-O3 -fopenmp -march=znver4"
    export CXXFLAGS="-O3 -fopenmp -march=znver4"
    export FCFLAGS="-O3 -fopenmp -march=znver4"
    export LIB="-L\\\$(COMPILERROOT)\/lib\/ -lomp"
    export ARCHIVE=llvm-ar
    export LINKFLAGS="LINKFLAGS= -O"
    export FFTW_HOME=$AOCLROOT
    export FFT_INC="-DFFT_FFTW3 -I\\\$(FFTW_HOME)\/include"
    export FFT_PATH="\\\$(FFTW_HOME)\/lib\/libfftw3f_omp.so.3"
    export FFT_LIB="-L\\\$(FFTW_HOME)\/lib\/ -lfftw3f_omp -lfftw3"
    export MPICXX="mpicxx -std=c++11"
    rm -rf lammps*
    wget https://download.lammps.org/tars/lammps-${lammps_version}.tar.gz
    tar -xf lammps-${lammps_version}.tar.gz
    cd lammps-*/src
    if [ -e $PWD/MAKE/OPTIONS/Makefile.clang++_openmpi ];
    then
        echo "Makefile is present editing the same file"
    else
        echo "Makefile is not found copying g++_openmpi Makefile"
        cp MAKE/OPTIONS/Makefile.g++_openmpi MAKE/OPTIONS/Makefile.clang++_openmpi
    fi
    MKFILE=$PWD/MAKE/OPTIONS/Makefile.clang++_openmpi
    sed -i "s/-g//g" $MKFILE
    sed -i "s/mpicxx -std=c++11/$MPICXX/g" $MKFILE
    sed -i "s/OMPI_CXX = g++/OMPI_CXX = $CXX/" $MKFILE
    sed -i "s/-O3/$CFLAGS/g" $MKFILE
    sed -i "s/^LIB \=/LIB\=$LIB/g" $MKFILE
    sed -i "s/g++_openmpi/clang++_openmpi/" $MKFILE
    sed -i "s/GNU g++/AOCC clang++/" $MKFILE
    sed -i "s/ARCHIVE =\sar/ARCHIVE = $ARCHIVE/" $MKFILE
    sed -i "s/FFT\_INC \=/FFT\_INC\=$FFT_INC/g" $MKFILE
    sed -i "s/FFT\_PATH \=/FFT\_PATH\=$FFT_PATH/g" $MKFILE
    sed -i "s/FFT\_LIB \=/FFT\_LIB\=$FFT_LIB/g" $MKFILE
    sed -i "s/^LINKFLAGS.*/$LINKFLAGS/g" $MKFILE

    make yes-asphere yes-class2 yes-kspace yes-manybody yes-misc yes-molecule
    make yes-mpiio yes-opt yes-replica yes-rigid yes-granular

    make clang++_openmpi -j $(nproc)
    if [ -e ./lmp_clang++_openmpi ];
    then
        echo "Lammps build is Successful"
    else
        echo "Lammps build is failed"
    fi
fi
