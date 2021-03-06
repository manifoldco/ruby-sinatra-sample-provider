# Sample Manifold Provider (Ruby/Sinatra)

This repo contains a minimal provider using Sinatra and Ruby.
It provides digital cat bonnets as a service; fun!

# Testing the app with Grafton

[Grafton](https://github.com/manifoldco/grafton) is the test framework used to
verify your provider implementation is correct.

To use Grafton to verify this sample provider:

```bash
# create a test master key for grafton to use when acting as Manifold
# this file is written as masterkey.json
grafton generate

# Set environment variables to configure the test app
# MASTER_KEY is the public_key portion of masterkey.json
export MASTER_KEY="TtziSVE/9lnZ7fRYhWtGZpuXUKJ82FunK9rM0IkuP/0"
# CONNECTOR_URL is the url that Grafton will listen on. It corresponds to
# Grafton's --sso-port flag.
export CONNECTOR_URL=http://localhost:3001/v1

# Set fake OAuth 2.0 credentials. The format of these are specific, so you can
# reuse the values here.
export CLIENT_ID=21jtaatqj8y5t0kctb2ejr6jev5w8
export CLIENT_SECRET=3yTKSiJ6f5V5Bq-kWF0hmdrEUep3m3HKPTcPX7CdBZw

# install dependencies and run the sample app
bundle install
bundle exec ./app.rb

# In another shell, run grafton.
grafton test --product=bonnets --plan=small --region=aws::us-east-1 \
    --client-id=21jtaatqj8y5t0kctb2ejr6jev5w8 \
    --client-secret=3yTKSiJ6f5V5Bq-kWF0hmdrEUep3m3HKPTcPX7CdBZw \
    --connector-port=3001 \
    --new-plan=large \
    --resource-measures='{"feature-a": 0, "feature-b": 1000}' \
    http://localhost:4567

# If everything went well, you'll be greeted with plenty of green check marks!
```
