FROM jekyll/jekyll

COPY Gemfile Gemfile.lock /srv/jekyll/
RUN bundle install
