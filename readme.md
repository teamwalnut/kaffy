# API

[![Coverage Status](https://coveralls.io/repos/github/teamwalnut/walnut_monorepo/badge.svg?branch=master&t=HM5q4D)](https://coveralls.io/github/teamwalnut/walnut_monorepo?branch=master)

## Startup guide

[Atlassian](https://teamwalnut.atlassian.net/wiki/spaces/RD/pages/65935/Install+Env+BE)

## Admin interface:

We use [Kaffy](https://aesmail.github.io/kaffy) to generate our admin.
You can access the Admin dashboard only if your User is set to is_admin(you can ask another admin to do so in Prod)
Admin is at: `/admin`

## Running tests:

- Either `mix test` or `mix test.watch --stale`
- Run `mix test.ci` before releasing a PR to make sure you pass the CI tests
- After running `mix test.ci` you can open `api/cover/excoveralls.html` to see where you can maximize test coverage
- In case you need to reset the tests DB only, run `MIX_ENV=test mix ecto.drop`

## Code readability:

We use Credo to safeguard against various code styling issues, use it by running `mix credo`

## Generating code coverage:

We use ExCoveralls to generate code coverage report run `mix coveralls.html`

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more:

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
