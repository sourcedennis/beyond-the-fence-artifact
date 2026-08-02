# "Beyond the Fence" Artifact

Artifact for our ASPLOS'27 paper "Beyond the Fence: Sound Compilation for GPU and Heterogeneous CPU+GPU Systems".

## Commands

Build the Docker image with:

```
docker build . --tag=beyond-the-fence
```

## Agda Proofs

The sources for the Agda proofs are included in [sourcedennis/ptx-proofs](https://github.com/sourcedennis/ptx-proofs), which the `Dockerfile` downloads together with its dependencies on the [Burrow](https://github.com/sourcedennis/agda-burrow) proof library.

Run the Agda proofs with:

```
docker run -it --rm beyond-the-fence agda src/Main.agda
```

## Alloy Litmus Tests

## License

BSD-3 -- See `LICENSE`