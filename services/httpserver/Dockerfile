FROM ruby:2.7-alpine

# RUN apt-get -qqy update && apt-get install -y --no-install-recommends apt-utils
RUN apk update \
  && apk upgrade \
  && apk add --update --no-cache \
  build-base \
  vim

WORKDIR /tmp

COPY Gemfile* ./
RUN bundle install --jobs 4

ENV APP_HOME /apps/httpserver

WORKDIR $APP_HOME

COPY . .

CMD ["rackup", "-p", "80", "-o", "0.0.0.0"]
