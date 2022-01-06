alias Api.Accounts.User
alias Api.Companies.Member
alias Api.Storylines.Demos.Demo
alias Api.Storylines.Storyline

defimpl AccessPolicy, for: Demo do
  def preloads(_resource), do: [storyline: AccessPolicy.preloads(%Storyline{})]

  # for a super admin allow all
  def authorize(_, %Member{user: %User{is_admin: true}}, _), do: :ok

  def authorize(%Demo{is_shared: true}, _, :viewer), do: :ok
  def authorize(%Demo{is_shared: false}, nil, :viewer), do: {:error, :unauthorized}

  def authorize(%Demo{is_shared: false} = demo, %Member{} = actor, :viewer) do
    AccessPolicy.authorize(demo.storyline, actor, :viewer)
  end
end
