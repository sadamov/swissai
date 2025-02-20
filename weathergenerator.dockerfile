FROM nvcr.io/nvidia/pytorch:25.01-py3

# setup
RUN apt-get update && apt-get install python3-pip python3-venv -y
RUN pip install --upgrade pip ninja wheel packaging setuptools

# update flash-attn
RUN MAX_JOBS=16 pip install --upgrade --no-build-isolation \
        flash-attn==2.7.4.post1 -v

# install the rest of dependencies
RUN pip install \
        astropy_healpix==1.0.3 \
        zarr==2.17.0 \
        anemoi-datasets==0.5.15 \
        six==1.16.0 \
        matplotlib==3.10.0 \
        packaging==24.2 \
        wheel==0.45.1

# replace pynvml with nvidia-ml-py
RUN pip uninstall -y pynvml && pip install nvidia-ml-py
