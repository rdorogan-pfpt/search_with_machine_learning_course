#!/bin/bash

#set -x

labelsFile="/workspace/datasets/fasttext/labeled_queries.txt"
shuffledLabelsFile="/workspace/datasets/fasttext/shuffled_labeled_queries.txt"
trainingFile="/workspace/datasets/fasttext/training_labeled_queries.txt"
testFile="/workspace/datasets/fasttext/test_labeled_queries.txt"

shuf --random-source=<(seq 999999) $labelsFile > $shuffledLabelsFile

# Create training & test files
head -10000 $shuffledLabelsFile > $trainingFile 
tail -10000 $shuffledLabelsFile > $testFile

# Create classifier file and test it
queryClassifierFile="/workspace/datasets/fasttext/query_classifier"
~/fastText-0.9.2/fasttext supervised -input $trainingFile  -output $queryClassifierFile -lr 0.5 #-epoch 25
~/fastText-0.9.2/fasttext test ${queryClassifierFile}.bin $testFile

