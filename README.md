<h1 align="center">
	Eye Tracking
</h1>

[![Code Style: Blue][code-style-img]][code-style-url]

## Note

Though we have hopes for this repository to be a registered package in the future, it is only for testing purposes, to be used in parallel to other tools, at this point in time.  This project is currently worked on by [Jake Ireland](https://github.com/jakewilliami) and [Alexandros Tantos](https://github.com/atantos).

It is preferrable that you have `coreutils` (or something similar, giving you access to `realpath`) installed for the project path to be interpretted by the shebang correctly.

## Introduction

This is a Julia implementation of a robust data-preparation and -analysis package using data from eye tracking experiments.  This package is designed modelling an R package called [`eyetrackingR`](https://github.com/jwdink/eyetrackingR).  This package is not to be confused with the other "EyeTracking.jl" package (at time of writing; October, 2020), which [seems to be a GUI-style experimental interface](https://github.com/dandandai/EyeTracking.jl/) (at first glance, perhaps similar to [PyGaze](https://github.com/esdalmaijer/PyGaze)).

## Installation and Set Up
Ensure you `cd` into the `EyeTracking.jl` directory after `clone`ing it, and run
```bash
julia -E 'import Pkg; et_home = dirname(@__FILE__); Pkg.activate(fd_home), Pkg.instantiate()'
```
To obtain any dependencies.  This step will not be necessary once this package is registered.

## How it works
This package has two main steps in the workflow, whose second step has three paths.  This workflow is drawn from [`eyetrackingR`](http://www.eyetracking-r.com/workflow).
 1. *Data cleaning* &mdash; obtain data and information about data from various eye-tracking sources (this step should be extremely robust), and puts data into a standardised format for analyses.
 2. *Analyses* &mdash;:
  a) **Overall Looking**; 
  b) **Onset-Contingent**;
  c) **Time-Course of Looking**.

## Timeline of Progression

 - [](https://github.com/jakewilliami/EyeTracking.jl/commit/) &mdash; Began working on the package.

## To Do

 - Summarise ([Query.jl?](https://github.com/queryverse/Query.jl))
 - Read from edf file.

## A Note on running on BSD:

The default JuliaPlots backend `GR` does not provide binaries for FreeBSD.  [Here's how you can build it from source.](https://github.com/jheinen/GR.jl/issues/268#issuecomment-584389111).  That said, `StatsPlots` is only a dependency for an example, and not for the main package.


[code-style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[code-style-url]: https://github.com/invenia/BlueStyle