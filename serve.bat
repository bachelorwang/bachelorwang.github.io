docker run --rm -d --volume="%cd%:/srv/jekyll" --name jekyll_server -p 80:4000 gh-jekyll jekyll serve --force_polling