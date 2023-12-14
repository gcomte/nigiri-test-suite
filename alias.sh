#!/usr/bin/env bash

cln() {
    nigiri cln $@
}

cln2() {
    docker exec -it cln2 lightning-cli --regtest $@
}

