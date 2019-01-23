FROM ruby:2.6 AS base
WORKDIR /app
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

FROM base AS service
WORKDIR /app
COPY . .
