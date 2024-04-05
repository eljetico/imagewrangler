FROM imagewrangler-base

WORKDIR /apps/imagewrangler

COPY . /apps/imagewrangler

RUN gem update --system 3.2.3 && gem install bundler && bundle install -j4 --retry 3
