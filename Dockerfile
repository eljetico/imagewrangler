FROM imagewrangler-base

WORKDIR /apps/imagewrangler

COPY . /apps/imagewrangler

RUN gem install bundler && bundle install -j4 --retry 3
