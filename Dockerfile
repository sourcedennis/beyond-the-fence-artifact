# alpine:3.20 variant
FROM sourcedennis/agda-mini:2.8.0 AS download

USER root

RUN apk upgrade --no-cache &&\
    apk add --no-cache git openssh ca-certificates &&\
    update-ca-certificates

USER proof

# Download and unpack the Agda standard library
RUN wget -O agda-stdlib.tar.gz https://github.com/agda/agda-stdlib/archive/v2.3.tar.gz &&\
    tar -zxvf agda-stdlib.tar.gz &&\
    rm agda-stdlib.tar.gz

RUN git clone --depth 1 https://github.com/sourcedennis/agda-dodo &&\
    cd agda-dodo &&\
    rm -rf .git*

RUN git clone --depth 1 https://github.com/sourcedennis/agda-burrow &&\
    cd agda-burrow &&\
    rm -rf .git*

RUN git clone --depth 1 https://github.com/sourcedennis/ptx-proofs &&\
    cd ptx-proofs &&\
    rm -rf .git*


FROM sourcedennis/agda-mini:2.8.0

RUN mkdir -p /home/proof/.config/agda/ &&\
    echo "/home/proof/agda-stdlib-2.3/standard-library.agda-lib" >> /home/proof/.config/agda/libraries &&\
    echo "/home/proof/agda-dodo/dodo.agda-lib" >> /home/proof/.config/agda/libraries &&\
    echo "/home/proof/agda-burrow/burrow.agda-lib" >> /home/proof/.config/agda/libraries

COPY --from=download --chown=proof:proof /home/proof/agda-stdlib-2.3 /home/proof/agda-stdlib-2.3
COPY --from=download --chown=proof:proof /home/proof/agda-dodo /home/proof/agda-dodo
COPY --from=download --chown=proof:proof /home/proof/agda-burrow /home/proof/agda-burrow
COPY --from=download --chown=proof:proof /home/proof/ptx-proofs /home/proof/ptx-proofs

WORKDIR /home/proof/ptx-proofs
