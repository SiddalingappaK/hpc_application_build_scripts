#!/bin/bash
echo "Starting NAMD Build script"
###################################################
################## USER SECTIONS ###################
export SOURCES=$PWD
## Set the paths of AOCC ##
export COMPILERROOT=/mnt/share/Amd_profiles/sravan/namd/aocc-compiler-4.0.0
$COMPILERROOT/bin/clang -v &> /tmp/null
if [[ $? -ne 0 ]];
then
        echo "Error: '$COMPILERROOT/bin/clang -v' returns non-zero. Set the Path of AOCC in COMPILERROOT"
        exit 1
fi
 
export LD_LIBRARY_PATH=${COMPILERROOT}/lib:$LD_LIBRARY_PATH
export INCLUDE=${COMPILERROOT}/include:$INCLUDE
export PATH=${COMPILERROOT}/bin:$PATH
 
#### settings the paths for openmp
export OMPL=$COMPILERROOT/lib
export OMPI=$COMPILERROOT/include


 
export CC=clang
export CXX=clang++
export F90=flang
export F77=flang
export FC=flang
#export CC CXX F90 F77 FC
export AR=llvm-ar
export NM=llvm-nm
export RANLIB=llvm-ranlib
## Set the FLAGS ##
export CFLAGS="-O3 -ffast-math  -march=znver4  -fopenmp -I${OMPI}"
export CXXFLAGS="-O3 -ffast-math -march=znver4 -fopenmp -I${OMPI}"
export FCFLAGS="-O3 -ffast-math -march=znver4 -fopenmp -I${OMPI}"
export LDFLAGS="-fopenmp -L${OMPL}"
 
 
 
### Path to OpenMPI  ###
export OPENMPIROOT=/mnt/share/Amd_profiles/sravan/namd/openmpi-4.1.4/openmpi_installl
export PATH=$OPENMPIROOT/bin:$PATH
export LD_LIBRARY_PATH=$OPENMPIROOT/lib:$LD_LIBRARY_PATH
export INCLUDE=$OPENMPIROOT/include:$INCLUDE
 
### Path to FFTW ###
export FFTW_HOME=/mnt/share/Amd_profiles/sravan/namd/FFTW

 
### Path to NAMD ###
export NAMDROOT=$SOURCES/NAMD_2.14_Source
 
 
################# END OF USER SECTIONS  ###################
 
echo "###################################################################################"
echo "#                                 OpenMPI                                         #"
echo "###################################################################################"
if [ -e $OPENMPIROOT/bin/mpirun ];
then
        echo "OpenMPI - File exists"
else
        cd $SOURCES
        rm -rf openmpi-4.1.4  openmpi
        if [ -e "openmpi-4.1.4.tar.bz2" ]
        then
                break
        else
                echo "Downloading openMPI"
                wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.1.4.tar.bz2
        fi
 
        tar -xvf $SOURCES/openmpi-4.1.4.tar.bz2
 
        cd openmpi-4.1.4
        export OPENMPIROOT=$PWD

       ./configure --prefix=${OPENMPIROOT}/openmpi_installl  CC=${CC} CXX=${CXX} FC=${FC} CFLAGS="-O3 -ffast-math -march=znver4 " CXXFLAGS="-O3 -ffast-math -march=znver4 "  FCFLAGS="-O3 -ffast-math -march=znver4" --enable-mpi-fortran --enable-shared=yes --enable-static=yes  --enable-mpi1-compatibility --disable-hwloc-pci --enable-mpi-cxx --with-hcoll=/opt/mellanox/hcoll --with-knem=/opt/knem-1.1.4.90mlnx1 --with-pmix
        make clean
        make -j 2>&1|tee make.log
        make install 2>&1| tee make_install.log
 
        cd $OPENMPIROOT/bin
        if [ -e "mpicc" ]
                then
                echo "OPENMPI Build SUCCESSFUL"
        else
                echo "OPENMPI Build FAILED"
                exit 1
        fi
fi

export PATH=$OPENMPIROOT/bin:$PATH
export LD_LIBRARY_PATH=$OPENMPIROOT/lib:$LD_LIBRARY_PATH
export INCLUDE=$OPENMPIROOT/include:$INCLUDE
echo "###################################################################################"
echo "#                                 FFTW                                            #"
echo "###################################################################################"
if [ -e "$FFTW_HOME/lib/libfftw3f.so" ];
        then
        echo "FFTW -File exists"
else
        cd $SOURCES
        if [ -e "aocl-linux-gcc-3.0.6.tar.gz" ]
        then
                echo "AOCL tar file already present"
                break
        else
                echo "Downloading AOCL"
                wget http://aocl.amd.com/data/aocl-3.0/aocl-linux-aocc-3.0-6.tar.gz
        fi
 
        cd aocl-linux-aocc-3.0-6
        ./install.sh -t $FFTW_HOME
 
        echo "FFTW installation completed in  $FFTW_HOME"
        export FFTW_HOME=$FFTW_HOME/3.0-6/
        cd $FFTW_HOME/lib
        if [ -e "libfftw3f.so"  ]
                then
                echo "FFTW Downloaded SUCCESSFUL"
        else
                echo "FFTW Download FAILED"
                exit 1
        fi
fi
 
export PATH=$FFTW_HOME/amd-fftw/bin/:$PATH
export LD_LIBRARY_PATH=$FFTW_HOME/lib:$LD_LIBRARY_PATH
export INCLUDE=$FFTW_HOME/include:$INCLUDE
 
echo "###################################################################################"
echo "#                                 NAMD                                            #"
echo "###################################################################################"
 
if [ -e "$NAMDROOT/Linux-x86_64-g++/namd" ];
then
        echo "NAMD - File exists"
else
        cd $SOURCES
        if [ -e "NAMD_2.14_Source.tar.gz" ]
        then
                break
        else
                echo "Downloading NAMD"
                wget --no-check-certificate https://www.ks.uiuc.edu/Research/namd/2.14/download/946183/NAMD_2.14_Source.tar.gz
        fi
        rm -rf NAMD_2.14_Source
        tar xvf NAMD_2.14_Source.tar.gz
        cd NAMD_2.14_Source
        #Unpack charm
        #tar xvf charm-6.10.2.tar.gz
 
        #cat arch/Linux-x86_64-g++.arch
        # Addinig flags -O3 -march=znver2 -ffast-math
        # Addinig flags -O3 -march=znver2 -ffast-math
        find ./ -type f -exec sed -i 's/-O3/-O3/g' {} \;
        find ./ -type f -exec sed -i 's/-O1/-O3/g' {} \;
        find ./ -type f -exec sed -i "s|-O3|$CFLAGS|g" {} \;
 
        ## TCL libraries:
 
        wget http://www.ks.uiuc.edu/Research/namd/libraries/tcl8.5.9-linux-x86_64.tar.gz
        wget http://www.ks.uiuc.edu/Research/namd/libraries/tcl8.5.9-linux-x86_64-threaded.tar.gz
        tar xzf tcl8.5.9-linux-x86_64.tar.gz
        tar xzf tcl8.5.9-linux-x86_64-threaded.tar.gz
        mv tcl8.5.9-linux-x86_64 tcl
        cd tcl
        sed -i "s/TCL_CC.*/TCL_CC=clang/g" lib/tclConfig.sh
        cd ..
        mv tcl8.5.9-linux-x86_64-threaded tcl-threaded
        cd tcl-threaded
        sed -i "s/TCL_CC.*/TCL_CC=${TCL_CC}/g" lib/tclConfig.sh
        cd ..
 
        #Build and test the Charm++/Converse library (MPI version):
 
        rm -rf charm-6.10.2.tar
        wget http://charm.cs.illinois.edu/distrib/charm-6.10.2.tar.gz
        tar xvf charm-6.10.2.tar.gz
        mv charm-v6.10.2 charm-6.10.2
        cd charm-6.10.2
        ./build charm++ mpi-linux-x86_64 mpicxx -j16 --with-production "$CFLAGS" 2>&1| tee log_charm_build
        cd mpi-linux-x86_64-mpicxx/tests/charm++/megatest
        make -j 32 pgm
        mpiexec -n 4 ./pgm  # (run as any other MPI program on your machine )
 
 
        cd $NAMDROOT
 
 
        cat > arch/Linux-x86_64-clang.arch << EOF
NAMD_ARCH=Linux-x86_64
CHARMARCH=mpi-linux-x86_64 mpicxx
CXX=clang++ -m64 -std=c++0x
CXXOPTS=-O3 -march=znver4 -ffp-contract=fast
CC=clang -m64
COPTS=-O3 -march=znver4 -ffp-contract=fast
 
EOF
 
        cat arch/Linux-x86_64-clang.arch
        rm -rf Linux-x86_64-clang
        export CHARMBASE=$NAMD_ROOT/charm-6.10.2
        #Set up MPI build directory and compile:
        ./config Linux-x86_64-${CC} --charm-arch mpi-linux-x86_64-mpicxx --with-tcl --tcl-prefix $NAMDROOT/tcl --with-fftw3 --fftw-prefix $FFTW_HOME
 
        
        cd Linux-x86_64-clang
        time make -j 16 2>&1 | tee make.log
        if [ -e "namd2" ]
        then
                echo "NAMD BUILD SUCCESSFUL"
        else
                echo "NAMD BUILD Failed"
        fi
fi
