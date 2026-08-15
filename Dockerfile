# syntax=docker/dockerfile:1

# Rails 8 app — Ruby 3.2.0, Postgres, Solid Queue/Cache/Cable, cssbundling-rails
# (sass/postcss), wkhtmltopdf-binary + ImageMagick for PDF/image processing.

ARG RUBY_VERSION=3.2.0
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# ---- build stage -----------------------------------------------------------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git pkg-config curl libpq-dev libyaml-dev ca-certificates gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN bundle exec bootsnap precompile app/ lib/
RUN npm run build:css

RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---- final stage ------------------------------------------------------------
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libpq5 libjemalloc2 imagemagick \
      libxrender1 libxext6 libfontconfig1 fontconfig fonts-dejavu-core libjpeg62-turbo && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV LD_PRELOAD="libjemalloc.so.2"

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log storage tmp && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]
