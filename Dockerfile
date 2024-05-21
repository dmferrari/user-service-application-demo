FROM ruby:3.3.0

RUN apt-get update -qq \
  && apt-get install -y build-essential libpq-dev nodejs \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV RAILS_LOG_TO_STDOUT=true

RUN mkdir /app

COPY Gemfile Gemfile.lock /app/
WORKDIR /app
RUN bundle install

COPY . /app

CMD ["bundle", "exec", "rails", "s", "-p", "3005", "-b", "0.0.0.0"]

