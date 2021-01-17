<h1 align="center">
	Eye Tracking Utils
</h1>

[![Code Style: Blue][code-style-img]][code-style-url] [![Build Status](https://travis-ci.com/jakewilliami/EyeTrackingUtils.jl.svg?branch=master)](https://travis-ci.com/jakewilliami/EyeTrackingUtils.jl) ![Project Status](https://img.shields.io/badge/status-maturing-green)

## Note

**THIS PACKAGE IS IN PRE-ALPHA AND IS UNDER DEVELOPMENT!  IT IS NOT READY FOR USE**

Though we have hopes for this repository to be a registered package in the future, it is only for testing purposes, to be used in parallel to other tools, at this point in time.  This project is currently worked on by [Alexandros Tantos](https://github.com/atantos), [Jake Ireland](https://github.com/jakewilliami), and others.

## Introduction

This is a Julia implementation of a robust data-preparation and -analysis package using data from eye tracking experiments.  This package is designed modelling an R package called [`eyetrackingR`](https://github.com/jwdink/eyetrackingR).  This package is not to be confused with the "EyeTracking.jl" package (at time of writing; October, 2020), which [seems to be a GUI-style experimental interface](https://github.com/dandandai/EyeTracking.jl/) (at first glance, perhaps similar to [PyGaze](https://github.com/esdalmaijer/PyGaze)).

## Installation and Examples
```julia
julia> using EyeTrackingUtils
```

## How it works
This package has two main steps in the workflow, whose second step has three paths.  This workflow is drawn from [`eyetrackingR`](http://www.eyetracking-r.com/workflow).
 1. **Data cleaning** &mdash; obtain data and information about data from various eye-tracking sources (this step should be extremely robust), and puts data into a standardised format for analyses.
 2. **Analyses** &mdash;:
 
   &#9;&#9; a) *Overall Looking*; 
   
   &#9;&#9; b) *Onset-Contingent*;
   
   &#9;&#9; c) *Time-Course of Looking*.

## Obtaining Test Data
```bash
# PATH_TO_EYETRACKING="/some/path" # PLEASE FILL IN THIS LINE
$ cd /tmp/
$ wget https://raw.githubusercontent.com/jwdink/eyetrackingR/master/data/word_recognition.rda
$ Rscript -e 'load("word_recognition.rda"); write.csv(word_recognition, "word_recognition.csv")'
$ mv word_recognition.csv "$PATH_TO_EYETRACKING"/data/
$ curl https://raw.githubusercontent.com/jwdink/eyetrackingR/master/tests/testthat/tb_output_between_subj.txt > "$PATH_TO_EYETRACKING"/data/tb_output_between_subj.txt
$ curl https://raw.githubusercontent.com/jwdink/eyetrackingR/master/tests/testthat/tb_output_between_subj.txt > "$PATH_TO_EYETRACKING"/data/tb_output_between_subj.txt
$ curl https://raw.githubusercontent.com/jwdink/eyetrackingR/master/tests/testthat/tb_output_interaction.txt > "$PATH_TO_EYETRACKING"/data/tb_output_interaction.txt
$ curl https://raw.githubusercontent.com/jwdink/eyetrackingR/master/tests/testthat/tb_output_within_subj.txt > "$PATH_TO_EYETRACKING"/data/tb_output_within_subj.txt
$ curl https://raw.githubusercontent.com/jwdink/eyetrackingR/master/tests/testthat/tclust_tb_anal.txt > "$PATH_TO_EYETRACKING"/data/tclust_tb_anal.txt
```

## Timeline of Progression

 - [cdf151e](https://github.com/jakewilliami/EyeTracking.jl/commit/cdf151e) &mdash; Began working on the package.
 - [d6e0eec](https://github.com/jakewilliami/EyeTrackingUtils.jl/commit/d6e0eec) &mdash; [Registered package](https://github.com/JuliaRegistries/General/pull/23769) for pre-alpha. 

## To Do

 - Summarise ([Query.jl?](https://github.com/queryverse/Query.jl))
 - Read from [EDF](https://github.com/beacon-biosignals/EDF.jl) file.
    - Is this needed?  As long as we support dataframes, the rest is up to other pacakges.

## A Note on running on BSD:

The default JuliaPlots backend `GR` does not provide binaries for FreeBSD.  [Here's how you can build it from source.](https://github.com/jheinen/GR.jl/issues/268#issuecomment-584389111).


[code-style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[code-style-url]: https://github.com/invenia/BlueStyle
