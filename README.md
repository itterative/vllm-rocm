# vllm-rocm
just some personal changes to make vllm easier on RDNA 3 & 4

## Installation

### Requirements
* *git*
* *docker* or *podman*

### Building from wheels
Pre-built wheels are available in the [releases](https://github.com/itterative/vllm-rocm/releases). You can grab them from there and place them in `vllm/` directory inside the repo.

At minimum, you'll need:
* vllm
* amdsmi
* torch
* torchvision
* triton_kernels
* triton

Once downloaded, run the following:
```bash
# replace the name if you want to
export VLLM_IMAGE_NAME="itterative/vllm:v0.11.1"

# then build your image
podman build -t $VLLM_IMAGE_NAME -f vllm/docker/Dockerfile.rocm_prebuilt .

# copy the executables
cp hacks/bin/vllm ~/.local/bin/vllm
chmod +x ~/.local/bin/vllm

# finally, test your image
vllm --help
```

### Building from source
Building the vllm images will take around 1-2h to build and over 20GB of space.

Once you are done with building your image (and don't wish to rebuild it later on), you can run `podman image prune` in order to remove the intermediate build stage. This will free up some space. *This command will drop untagged images which are not used by any containers; you were warned.*

```bash
# replace the name if you want to
export VLLM_BASE_IMAGE_NAME="itterative/vllm:v0.11.1-base"
export VLLM_IMAGE_NAME="itterative/vllm:v0.11.1"
export VLLM_PATCH="patches/v0.11.1.patch"

# you might want to use your own gpu code here (mine is gfx1100, i.e. 7900 XTX)
# this will reduce the compilation times slightly
#
# note: you can use multiple (like this: ROCM_ARCH=gfx1100;gfx1101)
export ROCM_ARCH=gfx1100

# note: you can use either docker or podman (I use the latter)

# build the base image
podman build -t $VLLM_BASE_IMAGE_NAME --build-arg "PYTORCH_ROCM_ARCH=$ROCM_ARCH" --build-arg "AITER_ROCM_ARCH=$ROCM_ARCH" -f docker/Dockerfile.rocm_base .

# then build your image
podman build -t $VLLM_IMAGE_NAME --build-arg "BASE_IMAGE=$VLLM_BASE_IMAGE_NAME" -f docker/Dockerfile.rocm .

# copy the executables
cp hacks/bin/vllm ~/.local/bin/vllm
chmod +x ~/.local/bin/vllm

# finally, test your image
vllm --help
```

## Notes
The vllm executable from `hacks/bin/vllm` will create a folder in your home directory called `.vllm`.


### .env
One important file is `.vllm/.env` which can be used to pass environment variables to **vllm**. I use the following env:

```bash
# hugggingface token for grabbing models
export HF_TOKEN=...

# pytorch tunable options (not sure if they work properly with vllm)
export PYTORCH_TUNABLEOP_ENABLED=1
export PYTORCH_TUNABLEOP_TUNING=1
export PYTORCH_TUNABLEOP_FILENAME=/root/.vllm/pytorch_tunables.csv

# miopen settings for reducing start-up times (specifically useful if using multimodal models since the visual layers are retuned by default when the resolution changes)
export MIOPEN_FIND_MODE=FAST
export MIOPEN_FIND_ENFORCE=NONE
```

### configs
The folder `.vllm/configs` can be used to store your model configs. An example of what I use:

```yaml
# .vllm/configs/qwen3_vl_8b_instruct.yaml
model: Qwen/Qwen3-VL-8B-Instruct
host: 127.0.0.1
port: 5002
max_model_len: 8096
gpu_memory_utilization: 0.93
swap_space: 8
max_num_seqs: 2
skip_mm_profiling: true
limit_mm_per_prompt.video: 0

# usage: vllm serve --config qwen3_vl_8b_instruct.yaml
```

## Available patches
* patches/v0.11.1.patch - adds rocm's buildsandbytes to vllm (for quantization)
