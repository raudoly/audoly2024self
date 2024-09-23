# Self-employment and Labor Market Risks

This is the replication package for my paper "Self-employment and Labor Market Risks" published in the _International Economic Review_.

If you find this package helpful in your work, please consider citing the paper:

```
@article{audoly2024self,
  title={Self-employment and Labor Market Risks},
  author={Audoly, Richard},
  journal={International Economic Review},
  year={Forthcoming},
  publisher={Wiley Online Library}
}
```

The code was last run on:
* Stata 18 MP
* Matlab 2020a


## Step 1: Data analysis

The corresponding scripts are contained in the `data` folder.

### Extracting the SIPP data

`download_sipp.py` downloads the SIPP data from the NBER website for survey years 1996, 2001, 2004, and 2008. 
The script only works with Python 2 for some obscure reason. 
To get them into Stata format, navigate to the `1996` folder and run `1_make1996.do` 
Proceed similarly for survey years 2001, 2004, and 2008. 

### Main analysis

Set the data paths in `globals.do` to the SIPP data and run the do-files in the order suggested by the prefix:

`1_extract_variables.do` extracts  the main variables from the raw data.

`2_prep_panels.do` prepares monthly panels and defines wealth variables.

`3_prep_spells.do` constructs employment spells and assign status as paid- or self-employed

`4_prep_samples.do` prepare the analysis samples. 
This file calls the matlab script `clustering.m`, which groups workers using k-means. 
You will need to adjust the macro `matlab_command` in `globals.do` to run the script in one go. 
This script produces **Figure 2**.

`5_analysis.do` produces the plots and tables reported in the data section: **Figure 1** and **Tables 1-6**.

`6_model_inputs.do` computes and stores all inputs for the model.

`7_bootstrap.do` bootstraps the moment computations in `6_model_inputs.do` to get the standard errors for the targeted moments.

### Additional analysis

`A_macro_trends.do` benchmarks the macro trends in unemployment and self-employment derived from the SIPP to the CPS.

`B_additional_checks.do` performs a series of additional checks on the data requested during the revision process. 
Not all of them made it into the final manuscript.

The other do-files in the folder are called by the scripts previously described. 

## Step 2: Model analysis

The corresponding scripts are in the `model` folder.

`main.m` produces all model output: **Figures 3-5** and **Tables 7-9**.
Most of the heavy lifting is done by the matlab functions in the `lib` folder.

