[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/sadamov/swissai/main?filepath=verification_climllama.ipynb)
[![nbviewer](https://img.shields.io/badge/view-nbviewer-orange)](https://nbviewer.jupyter.org/github/sadamov/swissai/blob/main/verification_climllama.ipynb)

## SwissAI Helper Tools

### Overview

This repository contains helper tools for the SwissAI project:

1. **Verification Tools**: Compare SwissAI model outputs with ground truth (ERA5) data through plots and statistics, focusing on reconstructions.

2. **CMIP6 Data Processing**: Scripts to split multi-year CMIP6 NetCDF files into yearly chunks for more efficient processing.

### Installation

#### For Verification

Install the required Python dependencies using:

```bash
pip install -r requirements.txt
```

If you are working inside containers you can use the Dockerfile provided in the repository.
As usual custom container can be created using podman and squashed with enroot.
Afterwards adjust the path `swissai_container.toml` to match your container's location.

#### For CMIP6 Processing

The CMIP6 splitting tool requires CDO (Climate Data Operators). You can either:

- Use the provided Dockerfile to build a container
- Install CDO directly: `apt-get install cdo`

### Usage

#### Verification Notebook

There are two base notebooks, one defaults to the ClimLLama model and the other to the ESFM model.
To run the verification notebook:

1. Open 'verification_*.ipynb' in Jupyter
2. Configure parameters in the first cell
3. Run **Chapter One** first (required for initialization)
4. Execute other chapters as needed

CSCS offers jupyter notebooks on compute nodes here: <https://jupyter-santis.cscs.ch/>

Or if you are sure that all settings in parameters are correct you can also
run the notebook directly from the CLI, here an example for Aurora:

```bash
jupyter nbconvert --to notebook --execute verification_aurora.ipynb \
    --output executed_notebook.ipynb \
    --ExecutePreprocessor.kernel_name=python3 \
    --ExecutePreprocessor.extra_arguments='["/iopsstor/scratch/cscs/sadamov/pyprojects_data/swissai/preds_20250219/aurora.zarr"]'
```

Note: The notebook is optimized for dark mode. Especially ClimLLama is very heavy,
please don't run it on the login node.

#### CMIP6 File Splitting

1. Set environment variables:
   - `CMIP6_PATH`: Path to CMIP6 data
   - `OUT_PATH`: Output directory for split files

2. Run directly or via SLURM:

   ```bash
   # Direct execution
   ./split_cmip6.sh
   
   # Via SLURM
   sbatch launchscript.sh
   ```

### License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
