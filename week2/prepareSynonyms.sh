#!/bin/bash

#set -x

prefix="500plus"
productFile="/workspace/datasets/fasttext/labeled_products.txt"
labelsFile="/workspace/datasets/fasttext/${prefix}_products_label.txt"
newProductFile="/workspace/datasets/fasttext/${prefix}_shuffled_labeled_products.txt"
newTrainingile="/workspace/datasets/fasttext/${prefix}_training_labeled_products.txt"
newTestFile="/workspace/datasets/fasttext/${prefix}_test_labeled_products.txt"

# Find labels with more than 500 products
cat $productFile | \
   sed -e "s/\([.\!?,'/()]\)/ \1 /g" | tr "[:upper:]" "[:lower:]" | sed "s/[^[:alnum:]_]/ /g" | tr -s ' ' | \
   sed 's/\W.*//g' | sort | uniq -c | awk 'int($1) >= 500' | awk '{print $2}' > $labelsFile

# Find the products for above identied labels
grep -f $labelsFile $productFile | shuf --random-source=<(seq 99999) > $newProductFile

# Create training & test files
head -10000 $newProductFile > $newTrainingile 
tail -10000 $newProductFile > $newTestFile

# Create classifier file and test it
productClassifierFile="/workspace/datasets/fasttext/${prefix}_product_classifier"
~/fastText-0.9.2/fasttext supervised -input $newTrainingile  -output $productClassifierFile -lr 1.0 -epoch 25
~/fastText-0.9.2/fasttext test ${productClassifierFile}.bin $newTestFile

# Create titles
titlesFile="/workspace/datasets/fasttext/${prefix}_titles.txt"
cut -d' ' -f2- $newProductFile | \
  sed -e "s/\([.\!?,'/()]\)/ \1 /g" | tr "[:upper:]" "[:lower:]" | sed "s/[^[:alnum:]]/ /g" | tr -s ' ' > $titlesFile

titlesModelFile="/workspace/datasets/fasttext/${prefix}_titles_model"
~/fastText-0.9.2/fasttext skipgram -input $titlesFile -output $titlesModelFile

# Find top 1000 words
topWordsFile="/workspace/datasets/fasttext/${prefix}_top_words.txt"
cat $titlesFile | tr " " "\n" | grep "...." | sort | uniq -c | sort -nr | head -1000 | grep -oE '[^ ]+$' > $topWordsFile

# Create synonym file
synonymsFile="/workspace/datasets/fasttext/synonyms.csv"
while read data; do
   echo $data | ~/fastText-0.9.2/fasttext nn ${titlesModelFile}.bin | sed 's/Query word. //g' | sort -k2 -nr | awk '$2 > 0.8' | awk '{print $1}' | paste -s -d , | awk -v orig=$data '{print orig","$0}'
done < $topWordsFile > $synonymsFile 
