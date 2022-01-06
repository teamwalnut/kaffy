alias Api.Companies.Member

defprotocol AccessPolicy do
  @spec authorize(t, Member.t(), atom()) :: :ok | {:error, :unauthorized}
  def authorize(struct, actor, relationship)

  @spec preloads(t) :: list
  def preloads(struct)
end
