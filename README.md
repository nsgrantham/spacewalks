# Spacewalks

Raw data downloaded from [NASA's Data Portal: Extra-vehicular Activity (EVA) - US and Russia](https://data.nasa.gov/Raw-Data/Extra-vehicular-Activity-EVA-US-and-Russia/9kcy-zwvn). However, these data do not include China's first EVA in 2008, nor do they include EVAs from US or Russia since August 2013; see `additions.csv`.

The complete[^1] EVA dataset is `spacewalks.csv` produced by `process.R`. This `csv` file is recent as of October 2, 2015.

Additionally, `visualize.R` uses `ggplot2` and `gridExtra` to build a visualization titled **Spacewalks: A Fifty-Year History** and saved as `spacewalks.png`.

Producing the processed data and visualization is easy with [Make](https://www.gnu.org/software/make/). In the command line, navigate to this directory and enter
```
make
```

If you simply want the processed data and do not care to build the visualization, enter
```
make data
```

Finally, to remove `spacewalks.csv` and `spacewalks.png` from your directory, enter
```
make clean
```

Of course, you don't have to use Make and can simply run `process.R` and `visualize.R` from within [RStudio](https://www.rstudio.com), so long as the working directory is set to `spacewalks`. 

[^1]: To the best of my knowledge. If not, please submit a pull request with corrections!