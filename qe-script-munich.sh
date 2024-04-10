#!/bin/bash

arch=znver4
export INSTALL_PATH=$PWD
#ml load aocc/4.0.0 aocl/aocc/4.0.0 openmpi/aocc40/4.1.4
module load aocc/4.0.0 aocl/aocl64 #cray-mpixlate/1.0.0.9
export SZIP_PATH=$INSTALL_PATH/szip
export HDF5_PATH=$INSTALL_PATH/hdf5
export ELPA_PATH=$INSTALL_PATH/elpa
export QE_PATH=$INSTALL_PATH/qe

if [[ $arch -eq "znver4" ]];then
	export CC=clang
	export CXX=clang++
	export FC=flang
	export F90=flang
	export F77=flang
	
	export CFLAGS="-O3 -ffast-math -march=${arch} -fopenmp -fPIC"
	export CXXFLAGS="-O3 -ffast-math -march=${arch} -fopenmp -fPIC"
	export FCFLAGS="-O3 -ffast-math -march=${arch} -fopenmp -fPIC"
	export FFLAGS="-O3 -ffast-math -march=${arch} -fopenmp -fPIC"

	export MPICC=mpicc
	export MPICXX=mpicxx
	export MPIFC=mpif90
	export MPIF77=mpif90
	export MPIF90=mpif90
fi 



if [[ ! -d $SZIP_PATH ]];then
	wget https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/szip-2.1.1.tar.gz
	tar -xvf szip*.tar.gz
	cd szip-2.1.1
	./configure --prefix=$SZIP_PATH CC=${CC} CFLAGS="-O3"
	make -j
	make install
	cd ..
	wget https://www.zlib.net/fossils/zlib-1.2.11.tar.gz
	tar -xvf zlib*.tar.gz
	cd zlib-1.2.11
	./configure --prefix=$SZIP_PATH
	make -j
	make install
	cd ..
fi	

#  module swap PrgEnv-cray PrgEnv-aocc #or you will get .f90 error

if [[ ! -d $HDF5_PATH ]];then
	wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.0/src/hdf5-1.12.0.tar.gz
    tar -xvf hdf5*.tar.gz
	cd hdf5-1.12.0
	# configure HDF5
	./configure --prefix=$HDF5_PATH --with-szlib=$SZIP_PATH --with-zlib=$SZIP_PATH --enable-parallel \
            --enable-fortran --enable-shared=yes --enable-hl --enable-cxx --enable-unsupported \
            --enable-symbols=yes CC=mpicc CXX=mpicxx FC=mpif90
	# in case of libtool issue
	sed -i 's/\\$wl-soname \\$wl\\$soname/-fuse-ld=ld -Wl,-soname,\\$soname/g' libtool
	make -j
	make install
	cd ..
fi

# export AOCL_PATH=/opt/AMD/aocl-aocc/4.0/aocl64


if [[ ! -d $ELPA_PATH ]];then
	# Obtain ELPA
	wget --no-check-certificate https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/2019.11.001/elpa-2019.11.001.tar.gz
	tar -xvf elpa-2019.11.001.tar.gz
	cd elpa-2019.11.001
 
	# configure ELPA
	./configure --prefix=$ELPA_PATH --disable-vsx --enable-sse --enable-avx --enable-avx2 --enable-avx512 \
            --disable-shared --enable-static --disable-gpu --enable-openmp CC=mpicc FC=mpif90 CXX=mpicxx \
            LDFLAGS="-L${AOCL_PATH}/lib" LIBS="-lflame -lblis-mt" \
            SCALAPACK_LDFLAGS="${AOCL_PATH}/lib/libscalapack.so" --disable-silent-rules
			
			#/opt/AMD/aocl-aocc/4.0//lib/libscalapack.a
			#/home/amdbench/vishal/QE/build/aocl-scalapack/build/lib/libscalapack.so
	
	make
	make install
	cd ..

fi

if [[ ! -d QE_PATH ]];then
	
	export PATH=${ELPA_PATH}/bin:${HDF5_PATH}/bin:${PATH}
	export LIBRARY_PATH=${SZIP_PATH}/lib:${ELPA_PATH}/lib:${HDF5_PATH}/lib:${LIBRARY_PATH}
	
	export LD_LIBRARY_PATH=${SZIP_PATH}/lib:${ELPA_PATH}/lib:${HDF5_PATH}/lib:${LD_LIBRARY_PATH}
	
	export C_INCLUDE_PATH=${C_INCLUDE_PATH}:${SZIP_PATH}/include:${ELPA_PATH}/include:${HDF5_PATH}/include
	export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:${SZIP_PATH}/include:${ELPA_PATH}/include:${HDF5_PATH}/include
 
	# export MPI_PATH=/opt/cray/pe/mpich/8.1.24/ofi/cray/10.0
	# export MPI_PATH=
	
	# /home/amdbench/vishal/QE/build/build/64/lib/libscalapack.a 
 
	export MPI_LIBS="-L$MPI_PATH/lib -lmpi"
	export SCALAPACK_LIBS="${AOCL_PATH}/lib/libscalapack.so"
	export LAPACK_LIBS="-L${AOCL_PATH}/lib -lflame"
	export BLAS_LIBS="-L${AOCL_PATH}/lib -lblis-mt"
	export FFT_LIBS="-L${AOCL_PATH}/lib -lfftw3 -lfftw3_omp"
	export FFTW_INCLUDE="${AOCL_PATH}/include"
	export LIBDIRS="-L$SZIP_PATH/lib -lsz -lz"

	wget https://github.com/QEF/q-e/archive/refs/tags/qe-6.7.0.tar.gz
	tar -xvf qe-6.7.0.tar.gz
	cp configure_aocc00.patch q-e-qe-6.7.0/
	cd q-e-qe-6.7.0
 
	 #apply the given patch
	if [[ ! -d $PWD/configure_aocc00 ]];then echo "get the patch"; exit 1; fi
	cp ../configure_aocc00 ..
	patch -p1 < configure_aocc00.patch
 
	# configure and build QE
	./configure --prefix=$QE_PATH/6.7.1 --enable-parallel=yes --enable-openmp --with-scalapack=yes \
            --with-hdf5=$HDF5_PATH --with-elpa-lib=$ELPA_PATH/lib/libelpa_openmp.a \
            --with-elpa-include=$ELPA_PATH/include/elpa_openmp-2019.11.001/modules \
            --with-elpa-version=2019 CC=mpicc MPIF90=mpif90 F77=flang F90=flang 2>$1 | tee configure.log
 
	make -j all 2>&1 | tee make.log
	make install
	cd ..
fi


objdump -d ./pw.x | grep zmm





- mpi related library try to replace with cray mpi(mpich)
- install 7.0 in munich cluster with zhiyong zhu method
- install again 6.7 with cray mpi with disable-openmp option









 
export PATH="$HDF5_PATH/bin":$PATH
	export LIBRARY_PATH="$SZIP_PATH/lib:$HDF5_PATH/lib":$LIBRARY_PATH
	export LD_LIBRARY_PATH="$SZIP_PATH/lib:$HDF5_PATH/lib":$LD_LIBRARY_PATH
	export C_INCLUDE_PATH=$C_INCLUDE_PATH:"$SZIP_PATH/include:$HDF5_PATH/include"
	export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:"$SZIP_PATH/include:$HDF5_PATH/include"
	
	export MPI_LIBS="-L/opt/cray/pe/mpich/8.1.24/ofi/cray/10.0/lib -lmpi"
	
	export SCALAPACK_LIBS="/opt/AMD/aocl-aocc/4.0//lib/libscalapack.a"
	export LAPACK_LIBS="-L${AOCL_PATH} -lflame"
	export BLAS_LIBS="-L${AOCL_PATH} -lblis-mt"
	export FFT_LIBS="-L${AOCL_PATH} -lfftw3 -lfftw3_omp"
	export FFTW_INCLUDE="${AOCL_PATH}/include"
	export LIBDIRS="-L$SZIP_PATH/lib -lsz -lz"
	
	./configure --prefix=$QE_PATH/6.7.1 --enable-parallel=yes --disable-openmp --with-scalapack=yes \
            --with-hdf5=$HDF5_PATH \
           CC=mpicc MPIF90=mpif90 F77=flang F90=flang
