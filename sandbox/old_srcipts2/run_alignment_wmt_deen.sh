#!/bin/bash

# suffix of source language files
SRC=de

# suffix of target language files
TRG=en

# number of merge operations. Network vocabulary should be slightly larger (to include characters),
# or smaller if the operations are learned on the joint vocabulary
bpe_operations=37000
tools=../tools
data=/media/data/data/wmt16-deen

# path to fastalign
fastalign=./fast_align

# convert the data into fast_align format --->

train_set='train.tok.bpe.decode'
dev_set='newstest2013.tok.bpe.decode.dev'

paste \
    $data/${train_set}.src.b1 \
    $data/${train_set}.trg.b1 \
    | sed "s/$(printf '\t')/ ||| /g" > $data/${train_set}.real.fastalign2
l1=$(wc -l < "$data/${train_set}.real.fastalign2")

paste \
    $data/${train_set}.src.b1 \
    $data/${train_set}.dec.b1 \
    | sed "s/$(printf '\t')/ ||| /g" > $data/${train_set}.fake.fastalign2
l2=$(wc -l < "$data/${train_set}.fake.fastalign2")


l3=$(($l1 + 1))
l4=$(($l1 + $l2))

echo $l1 $l2 $l3 $l4
cat $data/${train_set}.real.fastalign2 \
    $data/${train_set}.fake.fastalign2 > $data/${train_set}.full.fastalign2

$fastalign \
     -i $data/${train_set}.full.fastalign2 \
     -v -p $data/${train_set}.full.fastlign2.cond \
     -N -d -o \
     > $data/${train_set}.full.fastlign2.aligned

sort -k1,1 -k3,3gr $data/${train_set}.full.fastlign2.cond \
        | sort -k1,1 -u \
        > $data/${train_set}.full.fastlign2.dict

sed -n "1, ${l1}p"   $data/${train_set}.full.fastlign2.aligned > $data/${train_set}.real.aligned
sed -n "$l3, ${l4}p" $data/${train_set}.full.fastlign2.aligned > $data/${train_set}.fake.aligned

# force-alignment
paste \
    $data/${dev_set}.src.b1 \
    $data/${dev_set}.trg.b1 \
    | sed "s/$(printf '\t')/ ||| /g" > $data/${dev_set}.real.fastalign2

$fastalign \
    -i $data/${dev_set}.real.fastalign2 \
    -v -f $data/${train_set}.full.fastlign2.cond \
    -N -d -o \
    > $data/${dev_set}.real.aligned_t
python remove.py < $data/${dev_set}.real.aligned_t > $data/${dev_set}.real.aligned

paste \
    $data/${dev_set}.src.b1 \
    $data/${dev_set}.dec.b1 \
    | sed "s/$(printf '\t')/ ||| /g" > $data/${dev_set}.fake.fastalign2

$fastalign \
    -i $data/${dev_set}.fake.fastalign2 \
    -v -f $data/${train_set}.full.fastlign2.cond \
    -N -d -o \
    > $data/${dev_set}.fake.aligned_t
python remove.py < $data/${dev_set}.fake.aligned_t > $data/${dev_set}.fake.aligned

# generate fertility
python generate_fertility.py < $data/${train_set}.real.aligned > $data/${train_set}.real.fer
python generate_fertility.py < $data/${train_set}.fake.aligned > $data/${train_set}.fake.fer
python generate_fertility.py < $data/${dev_set}.real.aligned > $data/${dev_set}.real.fer
python generate_fertility.py < $data/${dev_set}.fake.aligned > $data/${dev_set}.fake.fer
