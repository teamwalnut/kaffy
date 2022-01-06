defmodule Api.Kaffy.Config do
  @moduledoc false
  def create_resources(_conn) do
    [
      accounts: [
        name: "Accounts",
        resources: [
          user: [schema: Api.Accounts.User, admin: Api.Kaffy.Accounts.UserAdmin]
        ]
      ],
      companies: [
        name: "Companies",
        resources: [
          company: [
            schema: Api.Companies.Company,
            admin: Api.Kaffy.Companies.CompanyAdmin
          ],
          member: [schema: Api.Companies.Member, admin: Api.Kaffy.Companies.MemberAdmin]
        ]
      ],
      domains: [
        name: "Custom Domains",
        resources: [
          domain: [
            schema: Api.CustomDomains.CustomDomain,
            admin: Api.Kaffy.CustomDomains.CustomDomainAdmin
          ]
        ]
      ],
      storylines: [
        name: "Storylines",
        resources: [
          storyline: [
            schema: Api.Storylines.Storyline,
            admin: Api.Kaffy.Storylines.StorylineAdmin
          ]
        ]
      ],
      patches: [
        name: "Patches",
        resources: [
          patches: [
            schema: Api.Patching.Patch,
            admin: Api.Kaffy.Patching.PatchAdmin
          ]
        ]
      ]
    ]
  end
end
