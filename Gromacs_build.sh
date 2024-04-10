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
    export LAPACKROOT=$MATHLIBROOT
    export BLISROOT=$MATHLIBROOT
    export FFTWROOT=$MATHLIBROOT
else
    if [[ -e ./aocl-linux-aocc-4.0.tar.gz ]];
    then
        rm -rf aocl
        tar -xf aocl-linux-aocc-4.0.tar.gz
        cd aocl-linux-aocc-4.0
        ./install.sh -t $main_dir -i lp64
        mv $main_dir/4.0 $main_dir/aocl
        export libhome=$main_dir/aocl
        echo "export libhome=$main_dir/aocl
        export AOCLROOT=$libhome
        export MATHLIBROOT=$libhome
        export AOCL_PATH=$libhome:$AOCL_PATH
        export INCLUDE=$libhome/include:$INCLUDE
        export CPATH=$libhome/include:$CPATH
        export C_INCLUDE_PATH=$libhome/include:$C_INCLUDE_PATH
        export CPLUS_INCLUDE_PATH=$libhome/include:$CPLUS_INCLUDE_PATH
        export LIBRARY_PATH=$libhome/lib:$LIBRARY_PATH
        export LD_LIBRARY_PATH=$libhome/lib:$LD_LIBRARY_PATH
        " > $main_dir/aocl_source_file.sh
        chmod +x $main_dir/aocl_source_file.sh
        cd $main_dir
        source aocl_source_file.sh
        export LAPACKROOT=$MATHLIBROOT
        export BLISROOT=$MATHLIBROOT
        export FFTWROOT=$MATHLIBROOT
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
if [[ -e ./ompi/bin/mpirun ]];
then
    echo "Openmpi is present. Skipping.."
    source openmpi_source_file.sh
    export MPIBIN=$MPIROOT/bin
else
    rm -rf ompi
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
    if [[ -e $main_dir/ompi/bin/mpirun ]];
    then
        echo "Openmpi installation is done"
        export MPIROOT=$main_dir/ompi
        echo "export MPIROOT=$main_dir/ompi
        export PATH=$MPIROOT/bin:$PATH
        export LD_LIBRARY_PATH=$MPIROOT/lib:$LD_LIBRARY_PATH
        export LIBRARY_PATH=$MPIROOT/lib:$LIBRARY_PATH
        export C_INCLUDE_PATH=$MPIROOT/include:$C_INCLUDE_PATH
        export CPLUS_INCLUDE_PATH=$MPIROOT/include:$CPLUS_INCLUDE_PATH
        export INCLUDE=$MPIROOT/include:$INCLUDE
        export CPATH=$MPIROOT/include:$CPATH
        export FPATH=$MPIROOT/include:$FPATH
        export MANPATH=$MPIROOT/share/man:$MANPATH
        export PKG_CONFIG_PATH=$MPIROOT/lib/pkgconfig:$PKG_CONFIG_PATH
        " > $main_dir/openmpi_source_file.sh
        chmod +x $main_dir/openmpi_source_file.sh
        cd $main_dir
        source openmpi_source_file.sh
        export MPIBIN=$MPIROOT/bin
    else
        echo "Openmpi installation failed"
        flag=0
    fi
fi
####################################################################################
cd $main_dir
if [[ $flag == 1 ]];
then
    echo ""
else
    exit
fi
####################################################################################
if [[ -e ./gmx/bin/gmx_mpi ]];
then
    echo "Already Gromacs is installed in this dir"
else
    export CC=clang
    export CXX=clang++
    export CFLAGS="-O3 -march=znver4 -flto -ffast-math -mllvm -unroll-threshold=8 -flv-function-specialization "
    export CXXFLAGS="-O3 -march=znver4 -flto -ffast-math -mllvm -unroll-threshold=8 -flv-function-specialization"
    export FCFLAGS="-O3 -march=znver4 -flto"
    export LDFLAGS="-O3 -march=znver4 -flto -lblis-mt -lm -Wl,-mllvm -Wl,-x86-use-vzeroupper=false"
    export RANLIB=llvm-ranlib
    export ARCHIVER=llvm-ar
    export OMPL=$COMPILERROOT/lib
    rm -rf gmx
    mkdir gmx
    rm -rf gromacs-2021.2*
    wget ftp://ftp.gromacs.org/gromacs/gromacs-2021.2.tar.gz
    tar -xf gromacs-2021.2.tar.gz
    cd gromacs-2021.2
    mkdir build_dir
    cd build_dir
    if [[ -z $(which cmake) ]];
    then
        echo "Cmake not found"
    else
        echo "cmake found"
    fi
    cmake $main_dir/gromacs-2021.2 \
                -DGMX_SIMD=AVX_512 \
                -DGMXAPI=OFF \
                -DOpenMP_C_FLAGS="-fopenmp=libomp -L$OMPL -lomp" \
                -DOpenMP_CXX_FLAGS="-fopenmp=libomp -L$OMPL -lomp" \
                -DGMX_OPENMP=on  \
                -DGMX_MPI=on \
                -DGMX_FFT_LIBRARY=FFTW3 \
                -DFFTWF_INCLUDE_DIR=$FFTWROOT/include \
                -DFFTWF_LIBRARY="$FFTWROOT/lib/libfftw3f_omp.so.3;$FFTWROOT/lib/libfftw3f.so.3" \
                -DCMAKE_INCLUDE_PATH=$FFTWROOT/include \
                -DCMAKE_C_COMPILER=$CC \
                -DCMAKE_CXX_COMPILER=$CXX \
                -DCMAKE_C_FLAGS="$CFLAGS" \
                -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
                -DMPI_C_COMPILER:FILEPATH=$MPIBIN/mpicc \
                -DMPI_CXX_COMPILER:FILEPATH=$MPIBIN/mpic++ \
                -DCMAKE_INSTALL_PREFIX=$main_dir/gmx \
                -DCMAKE_CXX_COMPILER_RANLIB=$RANLIB \
                -DCMAKE_C_COMPILER_RANLIB=$RANLIB \
                -DCMAKE_CXX_COMPILER_AR=$ARCHIVER \
                -DCMAKE_C_COMPILER_AR=$ARCHIVER \
                -DCMAKE_EXE_LINKER_FLAGS_MINSIZE="$LDFLAGS"
    make -j $(nproc)
    make install
    if [[ -e $main_dir/gmx/bin/gmx_mpi ]];
    then
        echo "Gromacs installation Done"
    else
        echo "Gromacs installation failed"
    fi
fi
