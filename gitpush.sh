#! /bin/bash

git add .
git commit
git push

speedy=false
if [ $1=='-s' ]; then
    speedy=true;
fi
echo $1
echo $speedy
