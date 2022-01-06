alias Api.Companies.Company
alias Api.Companies.Member
alias Api.Accounts.User

defimpl AccessPolicy, for: Company do
  def preloads(_resource), do: []
  def authorize(resource, actor, relationship)
  # authorize "super admins" to do everything, this is the only rule that also captures the
  # superadmin relationship
  #
  # The is_admin flag on user is only used for making users super admins, and is only given to
  # Walnut employees
  def authorize(_, %Member{user: %User{is_admin: true}}, _), do: :ok
  def authorize(_, %Member{role: :company_admin}, :admin), do: :ok

  def authorize(_, _, _) do
    {:error, :unauthorized}
  end
end
