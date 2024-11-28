## README

### Overview

This repository contains the code for the verification of the SwissAI project.
The verification is done by comparing the output of the SwissAI model with some
_ground_truth_ (usually ERA5) data. It is done in the form of plots and
statistics currently focussing on reconstructions (i.e. reproducing essential
features of input data).

### Installation

To set up the verification environment, install the required dependencies using
the following command:

```bash
conda env create -f environment.yml
```
This will create a new conda environment called swissai with all the necessary
packages.

### Usage

Open the verification.ipynb notebook in your Jupyter environment. In the very
first cell of the verification.ipynb notebook, you can set all required
parameters for the verification of your dataset. Always run **Chapter One**
first. This chapter initializes necessary variables and has a strict return API
(dims and sizes). After running **Chapter One**, you can execute any of the
following chapters directly.