ARG RUBY_VERSION=3.2.3
FROM ruby:$RUBY_VERSION-slim as base

# Set environment variable for production
ENV RACK_ENV=production

# Rack app lives here
WORKDIR /app

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev libpq5
# added libpq-dev

# Install application gems
COPY Gemfile* .
RUN bundle install --without development test

# Final stage for app image
FROM base

# Install libpq5 in the final image to ensure the required library is available
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Run and own the application files as a non-root user for security
RUN useradd ruby --home /app --shell /bin/bash
USER ruby:ruby
# to try: RUN useradd -ms /bin/bash ruby
# to try: RUN ruby

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=ruby:ruby /app /app

# Copy application code
COPY --chown=ruby:ruby . .

# Start the server
EXPOSE 8080
CMD ["bundle", "exec", "puma", "-t", "5:5", "--port", "8080"]
