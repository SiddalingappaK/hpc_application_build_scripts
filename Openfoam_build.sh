#! /bin/bash

##### Set the Paths for Working Directory ###
export SOURCES=$PWD
##Set the paths of AOCC ##
export COMPILERROOT=/mnt/share/users/manoj/aocc-compiler-4.0.0
$COMPILERROOT/bin/clang -v
if [[ $? -ne 0 ]];
then
        echo "Error: '$COMPILERROOT/bin/clang -v' returns non-zero. Set the Path of AOCC in COMPILERROOT"
       exit 1
fi
export OPENMP_ROOT=$COMPILERROOT

## Set the Paths for OpenMPI ##
export OPENMPIROOT=/mnt/share/users/manoj/OpenFoam/Debug_openfoam/openmpi_installl
export OPENFOAMROOT=$PWD

#### exporting the env ####
export LD_LIBRARY_PATH=${COMPILERROOT}/lib:$LD_LIBRARY_PATH
export INCLUDE=${COMPILERROOT}/include:$INCLUDE
export PATH=${COMPILERROOT}/bin:$PATH

#Compiler/tool names
## Set the AOCC compiler and FLAGS  ##
export CC=clang
export CXX=clang++
export F90=flang
export F77=flang
export FC=flang
export AR=llvm-ar
export RANLIB=llvm-ranlib
export arch="-march=znver4 -mprefer-vector-width=512"
## Set the FLAGS for ROME znver2, for Milan znver3 ##
export OMPI_CC=clang
export OMPI_CXX=clang++
export OMPI_FC=flang
export CFLAGS="-O3 ${arch} -fPIC -fopenmp"
export CXXFLAGS="-O3 ${arch} -fPIC -fopenmp"
export FCFLAGS="-O3 ${arch} -fPIC -fopenmp"
export LDFLAGS=" -lz -lm -lrt -Wl,-z,notext"


echo "###############################################################################"
echo "#                                OpenMPI                                      #"
echo "###############################################################################"

### Installing Openmpi ####

if [ -e "$OPENMPIROOT/bin/mpicc" ]; # -d $OPENMPIROOT ];
then
        echo "OpenMPI File Exists "
else
        rm -rf openmpi-4.1.1  openmpi
        if [ ! -e "openmpi-4.1.1.tar.bz2" ]
        then
                echo "Downloading openMPI"
                wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.1.tar.bz2
        fi
        tar -xvf openmpi-4.1.1.tar.bz2
        cd openmpi-4.1.1
        ./configure --prefix=/mnt/share/users/manoj/openmpi_install  CC=${CC} CXX=${CXX} FC=${FC} CFLAGS="-O3 -ffast-math -march=znver4 " CXXFLAGS="-O3 -ffast-math -march=znver4 "  FCFLAGS="-O3 -ffast-math -march=znver4" --enable-mpi-fortran --enable-shared=yes --enable-static=yes  --enable-mpi1-compatibility --disable-hwloc-pci
        make -j 32 2>&1|tee make.log
        make install -j 8 2>&1| tee make_install.log
        cd $OPENMPIROOT/bin
        if [ -e "mpicc" ]
                then
                echo "OPENMPI BUILD SUCCESSFUL"
        else
                echo "OPENMPI BUILD FAILED"
                exit 1
        fi
fi
export PATH=$OPENMPIROOT/bin:$PATH
export LD_LIBRARY_PATH=$OPENMPIROOT/lib:$LD_LIBRARY_PATH
export INCLUDE=$OPENMPIROOT/include:$INCLUDE

echo "###################################################################################"
echo "#                                 OpenFOAM                                        #"
echo "###################################################################################"
if [ -d $OPENFOAMROOT/OpenFOAM-v2212 ];
then
        echo "OpenFOAM 2112 - File exists"
else
        cd $OPENFOAMROOT
        version=v2212
	if [ ! -e "OpenFOAM-v2212.tgz" ] && [ ! -e "ThirdParty-v2212.tgz" ]
        then
                echo "Downloading Openfoam-${version}"
		wget --no-check-certificate https://sourceforge.net/projects/openfoam/files/$version/OpenFOAM-$version.tgz
		wget --no-check-certificate https://sourceforge.net/projects/openfoam/files/$version/ThirdParty-$version.tgz

        fi


        tar -xzf OpenFOAM-v2212.tgz
        tar -xzf ThirdParty-v2212.tgz
        cd $OPENFOAMROOT
        export WM_CXXFLAGS="$CFLAGS"
        export WM_CFLAGS="$CXXFLAGS"
	  export FOAM_EXTRA_CFLAGS="-march=znver4" FOAM_EXTRA_CXXFLAGS="-march=znver4" FOAM_EXTRA_LDFLAGS="-march=znver4"
        sed -i 's/WM_COMPILER=Gcc/WM_COMPILER=Amd/' $OPENFOAMROOT/OpenFOAM-v2212/etc/bashrc
        sed -i 's/Wl,--as-needed/Wl,--as-needed -lregionFaModels/' $OPENFOAMROOT/OpenFOAM-v2212/wmake/rules/General/Amd/link-c++
        sed -i 's/-O3/-O3 -march=znver4 -mprefer-vector-width=256/' $OPENFOAMROOT/OpenFOAM-v2212/wmake/rules/linux64Amd/cOpt
        sed -i 's/-O3/-O3 -march=znver4 -mprefer-vector-width=256/' $OPENFOAMROOT/OpenFOAM-v2212/wmake/rules/linux64Amd/c++Opt
        #sed -i 's/WM_COMPILE_OPTION=Opt/WM_COMPILE_OPTION=Debug/' $OPENFOAMROOT/OpenFOAM-v2212/etc/bashrc
        source $OPENFOAMROOT/OpenFOAM-v2212/etc/bashrc
        echo $WM_PROJECT_DIR
        echo " Building in progress "
        # Build OpenFOAM-v2212
        cd $OPENFOAMROOT/OpenFOAM-v2212

        time ./Allwmake -j  64 all -k 2>&1 |tee  OpenFOAM_AOCC_install.log
        source $OPENFOAMROOT/OpenFOAM-v2212/etc/bashrc
        cd $OPENFOAMROOT/OpenFOAM-v2212/platforms/linux64AmdDPInt32Opt/bin/
        if [ -e "simpleFoam" ] && [ -e "blockMesh" ] && [ -e "snappyHexMesh" ] && [ -e "decomposePar" ];
        then
                echo "OPENFOAM BUILD SUCCESSFUL"
        else
                echo "OPENFOAM BUILD Failed"
        fi
fi

