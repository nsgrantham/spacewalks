all: plot

plot: data
	Rscript visualize.R
	rm Rplots.pdf

data:
	Rscript process.R

clean:
	rm -f spacewalks.csv spacewalks.png
