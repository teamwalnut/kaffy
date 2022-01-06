defmodule Api.Fixtures do
  @moduledoc """
  Helper module to import all fixtures
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Api.AccountsFixtures
      import Api.AnnotationsFixtures
      import Api.CompaniesFixtures
      import Api.CustomDomainsFixtures
      import Api.DemosFixtures
      import Api.CompanySSOFixtures
      import Api.EditingFixtures
      import Api.PatchingFixtures
      import Api.StorylineCreationFixtures
      import Api.Storylines.ScreenGroupingFixtures
      import Api.Storylines.SmartObjectsFixtures
      import Api.StorylinesFixtures
    end
  end
end
