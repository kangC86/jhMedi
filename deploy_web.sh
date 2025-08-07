#!/bin/bash

flutter build web --base-href="/jhMedi/"
cp -r build/web/* deploy_temp/
cd deploy_temp
git init
git remote add origin https://github.com/kangC86/jhMedi.git
git checkout -b gh-pages
git add .
git commit -m "Deploy Flutter web"
git push -f origin gh-pages
