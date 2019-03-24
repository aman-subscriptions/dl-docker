FROM ubuntu:18.10

MAINTAINER Sai Soundararaj <saip@outlook.com>

ARG THEANO_VERSION=rel-0.8.2
ARG TENSORFLOW_VERSION=0.12.1 
ARG TENSORFLOW_ARCH=cpu
ARG KERAS_VERSION=1.2.0
ARG LASAGNE_VERSION=v0.1
ARG TORCH_VERSION=latest
ARG CAFFE_VERSION=master

#fix for ssl issue with older python
#https://github.com/opencoca/dl-docker/blob/de9050f4376964eb039a93c47aade0db7bcf5f8f/Dockerfile.gpu
ARG PYTHON_BASEDEPS="build-essential python-pip"
ARG PYTHON_BUILDDEPS="libbz2-dev \
  libc6-dev \
  libgdbm-dev \
  libncursesw5-dev \
  libreadline-gplv2-dev \
  libsqlite3-dev \
  libssl-dev \
  tk-dev"

# set noninteractive installation
RUN export DEBIAN_FRONTEND=noninteractive \ 
	echo "deb http://security.ubuntu.com/ubuntu xenial-security main" | tee -a /etc/apt/sources.list && \
	echo "deb http://nz.archive.ubuntu.com/ubuntu cosmic main universe" | tee -a /etc/apt/sources.list && \
	echo "deb http://mirror.launtel.net.au/ubuntu/ cosmic main universe" | tee -a /etc/apt/sources.list && \
	#sed -i'' 's/archive\.ubuntu\.com/us\.archive\.ubuntu\.com/' /etc/apt/sources.list && \
	apt-get update -y --fix-missing && \
	apt-get install -y tzdata && \
	ln -fs /usr/share/zoneinfo/posix/Australia/Melbourne /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata

# Install some dependencies
RUN apt-get install -y \
		bc \
		build-essential \
		cmake \
		curl \
		g++ \
		gfortran \
		git \	
		software-properties-common \
		unzip \
		vim \
		wget


RUN apt-get install -y \
		libffi-dev \
		libfreetype6-dev \
		libhdf5-dev \
		libjpeg-dev \
		liblcms2-dev \
		libopenblas-dev \
		liblapack-dev \
		libjpeg-dev \
		libpng-dev \
		libssl-dev \
		libtiff5-dev \
		libwebp-dev \
		libzmq3-dev \
		nano \
		pkg-config \
		python-dev

RUN apt-get install -y \
		zlib1g-dev \
		qt5-default \
		libvtk6-dev \
		zlib1g-dev \
		libjpeg-dev \
		libwebp-dev \
		libpng-dev \
		libtiff5-dev \
		libopenexr-dev \
		libgdal-dev \
		libdc1394-22-dev \
		libavcodec-dev \
		libavformat-dev \
		libswscale-dev \
		libtheora-dev \
		libvorbis-dev \
		libxvidcore-dev \
		libx264-dev \
		yasm \
		libopencore-amrnb-dev \
		libopencore-amrwb-dev \
		libv4l-dev \
		libxine2-dev \
		libtbb-dev \
		libeigen3-dev \
		python-dev \
		python-tk \
		python-numpy \
		python3-dev \
		python3-tk \
		python3-numpy \
		ant \
		default-jdk \
		doxygen

RUN	apt-get install -y \
		libicu-dev \
		libgdal-dev \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* 
# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
RUN	update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3

#aman - older python ssl version issue
#https://github.com/opencoca/dl-docker/blob/de9050f4376964eb039a93c47aade0db7bcf5f8f/Dockerfile.gpu
ARG PYTHON_TARFILE="Python-2.7.9.tgz"
ARG PYTHON_TARHOST="https://www.python.org/ftp/python/2.7.9"
ARG PYTHON_SRCDIR="Python-2.7.9"

RUN apt-get update
RUN apt-get install -y ${PYTHON_BASEDEPS} ${PYTHON_BUILDDEPS}

RUN wget "${PYTHON_TARHOST}/${PYTHON_TARFILE}"
RUN tar xvf ${PYTHON_TARFILE}

RUN cd ${PYTHON_SRCDIR} && \
  ./configure && \
  make && \
  make install

# Install pip
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
	python get-pip.py && \
	rm get-pip.py

# Add SNI support to Python
RUN pip --no-cache-dir install \
		pyopenssl \
		ndg-httpsclient \
		pyasn1

# Install useful Python packages using apt-get to avoid version incompatibilities with Tensorflow binary
# especially numpy, scipy, skimage and sklearn (see https://github.com/tensorflow/tensorflow/issues/2034)
RUN apt-get update && apt-get install -y \
		python-numpy \
		python-scipy \
		python-nose \
		python-h5py \
		python-skimage \
		python-matplotlib \
		python-pandas \
		python-sklearn \
		python-sympy \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

# Install other useful Python packages using pip
RUN pip --no-cache-dir install --upgrade ipython && \
	pip --no-cache-dir install \
		Cython \
		ipykernel \
		jupyter \
		path.py \
		Pillow \
		pygments \
		six \
		sphinx \
		wheel \
		zmq \
		&& \
	python -m ipykernel.kernelspec

# Install TensorFlow
RUN pip --no-cache-dir install \
	https://storage.googleapis.com/tensorflow/linux/${TENSORFLOW_ARCH}/tensorflow-${TENSORFLOW_VERSION}-cp27-none-linux_x86_64.whl

# Install dependencies for Caffe
RUN apt-get update && apt-get install -y \
		libboost-all-dev \
		libgflags-dev \
		libgoogle-glog-dev \
		libhdf5-serial-dev \
		libleveldb-dev \
		liblmdb-dev \
		libopencv-dev \
		libprotobuf-dev \
		libsnappy-dev \
		protobuf-compiler \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

# # Install Caffe
# RUN git clone -b ${CAFFE_VERSION} --depth 1 https://github.com/BVLC/caffe.git /root/caffe && \
# 	cd /root/caffe && \
# 	cat python/requirements.txt | xargs -n1 pip install && \
# 	mkdir build && cd build && \
# 	cmake -DCPU_ONLY=1 -fPIC -Wno-dev -DBLAS=Open .. && \
# 	make -j"$(nproc)" all 
# 	#&& \
# RUN	make install

# # Set up Caffe environment variables
# ENV CAFFE_ROOT=/root/caffe
# ENV PYCAFFE_ROOT=$CAFFE_ROOT/python
# ENV PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH \
# 	PATH=$CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH

# RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# Install Theano and set up Theano config (.theanorc) OpenBLAS
RUN pip --no-cache-dir install git+git://github.com/Theano/Theano.git@${THEANO_VERSION} && \
	\
	echo "[global]\ndevice=cpu\nfloatX=float32\nmode=FAST_RUN \
		\n[lib]\ncnmem=0.95 \
		\n[nvcc]\nfastmath=True \
		\n[blas]\nldflag = -L/usr/lib/openblas-base -lopenblas \
		\n[DebugMode]\ncheck_finite=1" \
	> /root/.theanorc


# Install Keras
RUN pip --no-cache-dir install git+git://github.com/fchollet/keras.git@${KERAS_VERSION}

# Install Lasagne
RUN pip --no-cache-dir install git+git://github.com/Lasagne/Lasagne.git@${LASAGNE_VERSION}

# Install Torch
RUN git clone https://github.com/torch/distro.git /root/torch --recursive && \
	cd /root/torch && \
	bash install-deps && \
	yes no | ./install.sh

# Export the LUA evironment variables manually
ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/root/torch/install/share/lua/5.1/?.lua;/root/torch/install/share/lua/5.1/?/init.lua;./?.lua;/root/torch/install/share/luajit-2.1.0-beta1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua' \
	LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/root/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so' \
	PATH=/root/torch/install/bin:$PATH \
	LD_LIBRARY_PATH=/root/torch/install/lib:$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=/root/torch/install/lib:$DYLD_LIBRARY_PATH
ENV LUA_CPATH='/root/torch/install/lib/?.so;'$LUA_CPATH

# Install the latest versions of nn, and iTorch
RUN luarocks install nn && \
    luarocks install loadcaffe && \
	\
	cd /root && git clone https://github.com/facebook/iTorch.git && \
	cd iTorch && \
	luarocks make

RUN cmake --version

# RUN add-apt-repository -y ppa:george-edison55/cmake-3.x && \
# 	apt-get update -y && \
# 	apt-get install cmake

#aman - install newer cmake
# RUN apt remove cmake -y && \
# 	cd ~ && \
# 	wget -q https://github.com/Kitware/CMake/releases/download/v3.14.0/cmake-3.14.0-Linux-x86_64.sh && \
# 	cp ~/cmake-3.14.0-Linux-x86_64.sh /opt/ && \
# 	bash /opt/cmake-3.14.0-Linux-x86_64.sh --skip-license --prefix=/usr/local/bin/ --exclude-subdir
# 	#ln -s /opt/cmake-3.14.0-Linux-x86_64/bin/* /usr/local/bin 

# COPY cmake-3.14.0-Linux-x86_64.sh ./opt/
# RUN bash /opt/cmake-3.14.0-Linux-x86_64.sh && \
# 	ln -s /opt/cmake-3.14.0-Linux-x86_64/bin/* /usr/local/bin

RUN cmake --version
# Install OpenCV
RUN git clone --depth 1 https://github.com/opencv/opencv.git /root/opencv && \
	cd /root/opencv && \
	mkdir build && \
	cd build && \
	cmake -DWITH_QT=ON -DWITH_OPENGL=ON -DFORCE_VTK=ON -DWITH_TBB=ON -DWITH_GDAL=ON -DWITH_XINE=ON -DBUILD_EXAMPLES=ON .. && \
	make -j"$(nproc)"  && \
	make install && \
	ldconfig && \
	echo 'ln /dev/null /dev/raw1394' >> ~/.bashrc


# Set up notebook config
COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly: https://github.com/ipython/ipython/issues/7062
COPY run_jupyter.sh /root/

# Expose Ports for TensorBoard (6006), Ipython (8888)
EXPOSE 6006 8888

WORKDIR "/root"
CMD ["/bin/bash"]
