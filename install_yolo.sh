#!/bin/bash

# Function to check for command success
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update
check_success "Failed to update package list"

sudo apt-get upgrade -y
check_success "Failed to upgrade packages"

# Install essential libraries and tools
echo "Installing essential libraries and tools..."
sudo apt-get install -y build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev zlib1g-dev openssl libffi-dev python3-dev python3-setuptools wget
check_success "Failed to install essential libraries and tools"

# Download and install Python 3.7
echo "Downloading and installing Python 3.7..."
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.7.12/Python-3.7.12.tgz
check_success "Failed to download Python 3.7"

sudo tar xzf Python-3.7.12.tgz
cd Python-3.7.12
sudo ./configure --enable-optimizations
sudo make altinstall
check_success "Failed to install Python 3.7"

# Verify Python 3.7 installation
python3.7 --version
check_success "Python 3.7 installation failed"

# Update alternatives to set Python 3.7 as default
sudo update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.7 1
sudo update-alternatives --config python3

# Upgrade pip for Python 3.7
echo "Upgrading pip for Python 3.7..."
wget https://bootstrap.pypa.io/get-pip.py
sudo python3.7 get-pip.py
check_success "Failed to upgrade pip for Python 3.7"

# Download and install TensorFlow
echo "Downloading and installing TensorFlow..."
wget https://developer.download.nvidia.com/compute/redist/jp/v46/tensorflow/tensorflow-2.5.0+nv21.7-cp36-cp36m-linux_aarch64.whl
check_success "Failed to download TensorFlow wheel"

sudo pip3.7 install tensorflow-2.5.0+nv21.7-cp36-cp36m-linux_aarch64.whl
check_success "Failed to install TensorFlow"

# Install NVIDIA Jetson Inference Library
echo "Cloning NVIDIA Jetson Inference Library..."
git clone --recursive https://github.com/dusty-nv/jetson-inference
check_success "Failed to clone NVIDIA Jetson Inference Library"

echo "Building NVIDIA Jetson Inference Library..."
cd jetson-inference
mkdir build
cd build
cmake ..
check_success "Failed to configure jetson-inference with cmake"

make -j$(nproc)
check_success "Failed to build jetson-inference"

sudo make install
check_success "Failed to install jetson-inference"

sudo ldconfig
check_success "Failed to update shared library cache"

# Install Darknet (YOLO Implementation)
echo "Cloning Darknet repository..."
git clone https://github.com/AlexeyAB/darknet
check_success "Failed to clone Darknet repository"

cd darknet

# Modify Makefile for Jetson Nano
echo "Modifying Makefile for Jetson Nano..."
sed -i 's/GPU=0/GPU=1/' Makefile
sed -i 's/CUDNN=0/CUDNN=1/' Makefile
sed -i 's/CUDNN_HALF=0/CUDNN_HALF=1/' Makefile
sed -i 's/OPENCV=0/OPENCV=1/' Makefile

# Build Darknet
echo "Building Darknet..."
make -j$(nproc)
check_success "Failed to build Darknet"

# Download YOLO weights
echo "Downloading YOLO weights..."
wget https://pjreddie.com/media/files/yolov3.weights
check_success "Failed to download YOLO weights"

# Optional: Install TensorRT for Optimized Inference
echo "Converting YOLO weights to TensorRT engine (optional)..."
./darknet2trt yolov3.cfg yolov3.weights yolov3.trt
check_success "Failed to convert YOLO weights to TensorRT engine"

# Create swap file to handle memory constraints
echo "Creating swap file..."
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
check_success "Failed to create swap file"

# Final message
echo "YOLO installation on Jetson Nano 2GB completed successfully!"

# Instructions for running YOLO
echo "To run YOLO on your Jetson Nano, use the following command:"
echo "./darknet detect cfg/yolov3.cfg yolov3.weights data/dog.jpg"
